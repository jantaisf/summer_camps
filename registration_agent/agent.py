"""
Camp Registration Agent
Fills out camp registration forms up to (but not including) payment.
Uses Playwright for browser control and Claude vision to understand forms.

Usage:
    python agent.py <registration-url> [profile.json]
"""

import asyncio
import json
import sys
import base64
from pathlib import Path

import anthropic
from playwright.async_api import async_playwright, Page

# ── System prompt ──────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """You are a browser automation agent filling out summer camp registration forms.
You receive a screenshot of the current page and decide the next single action to take.

STRICT RULES:
- STOP immediately when you see any payment/billing/checkout page (credit card fields, PayPal, etc.)
- Never enter payment or credit card information under any circumstances
- If a CAPTCHA appears, stop and tell the user to solve it manually
- If login/account creation is required, report it and wait for user input
- Fill fields conservatively — if a field is unclear, ask the user
- Prefer visible labels and placeholder text to identify fields over brittle CSS selectors

RESPONSE FORMAT — always return a single JSON object, no markdown, no explanation:

Fill a text/email/phone/date input:
{"action": "fill", "selector": "SELECTOR", "value": "VALUE"}

Click a button or link:
{"action": "click", "selector": "SELECTOR"}

Choose a <select> dropdown:
{"action": "select", "selector": "SELECTOR", "value": "OPTION TEXT OR VALUE"}

Tick a checkbox:
{"action": "check", "selector": "SELECTOR"}

Ask the user a question:
{"action": "ask", "question": "QUESTION"}

Account login/creation needed:
{"action": "account_required", "can_create": true|false, "message": "EXPLANATION"}

CAPTCHA detected — pause for user:
{"action": "captcha", "message": "DESCRIPTION"}

Finished or stopping:
{"action": "stop", "reason": "payment_page|complete|error", "message": "EXPLANATION"}

Wait briefly for page to settle:
{"action": "wait", "ms": 1500}

SELECTOR TIPS:
- Prefer: 'input[name="firstName"]', 'input[placeholder="First name"]', 'label:has-text("First name") + input'
- For buttons: 'button:has-text("Next")', 'input[type="submit"]'
- For Aria: '[aria-label="Phone number"]'
- Avoid fragile nth-child selectors
"""

# ── Profile helpers ─────────────────────────────────────────────────────────

PROFILE_TEMPLATE = {
    "parent": {
        "first_name": "",
        "last_name": "",
        "email": "",
        "phone": "",
        "address": "",
        "city": "",
        "state": "CA",
        "zip": "",
        "relationship": "Parent"
    },
    "child": {
        "first_name": "",
        "last_name": "",
        "dob": "YYYY-MM-DD",
        "gender": "M or F",
        "grade": "",
        "school": "",
        "allergies": "None",
        "medical_notes": "",
        "swim_level": "Non-swimmer / Beginner / Intermediate / Advanced",
        "t_shirt_size": "YS / YM / YL / AS / AM / AL",
        "emergency_contact": {
            "name": "",
            "relationship": "",
            "phone": ""
        }
    },
    "account": {
        "username_preference": "",   # leave blank to use parent email
        "password": ""               # used if agent needs to create an account
    }
}


def load_profile(path: str = "profile.json") -> dict:
    p = Path(path)
    if not p.exists():
        print(f"\n⚠️  Profile not found at '{path}'")
        print("Creating a template — fill it in and re-run.\n")
        p.write_text(json.dumps(PROFILE_TEMPLATE, indent=2))
        sys.exit(1)
    profile = json.loads(p.read_text())
    # Basic validation
    if not profile.get("parent", {}).get("email"):
        print("⚠️  profile.json: parent.email is required")
        sys.exit(1)
    return profile


# ── Browser helpers ─────────────────────────────────────────────────────────

async def screenshot_b64(page: Page) -> str:
    data = await page.screenshot(full_page=False)
    return base64.standard_b64encode(data).decode()


async def try_action(page: Page, action: dict) -> str | None:
    """Execute an action, return error string on failure or None on success."""
    act = action["action"]
    try:
        if act == "fill":
            await page.fill(action["selector"], str(action["value"]), timeout=6000)
            await page.wait_for_timeout(150)

        elif act == "click":
            await page.click(action["selector"], timeout=6000)
            await page.wait_for_load_state("networkidle", timeout=12000)

        elif act == "select":
            # Try label text first, fall back to value
            try:
                await page.select_option(action["selector"], label=str(action["value"]), timeout=5000)
            except Exception:
                await page.select_option(action["selector"], value=str(action["value"]), timeout=5000)

        elif act == "check":
            await page.check(action["selector"], timeout=5000)

        elif act == "wait":
            await page.wait_for_timeout(action.get("ms", 1000))

        return None
    except Exception as e:
        return str(e)


# ── Main agent loop ─────────────────────────────────────────────────────────

async def run_agent(url: str, profile: dict, client: anthropic.Anthropic):
    async with async_playwright() as pw:
        # Non-headless so user can watch + intervene
        browser = await pw.chromium.launch(headless=False, slow_mo=200)
        context = await browser.new_context(
            viewport={"width": 1280, "height": 900},
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/122.0.0.0 Safari/537.36"
            )
        )
        page = await context.new_page()

        print(f"\n🌐 Navigating to {url}\n")
        await page.goto(url, wait_until="networkidle")

        messages: list[dict] = []
        step = 0
        last_error: str | None = None

        while True:
            step += 1
            img = await screenshot_b64(page)
            current_url = page.url

            # Build user message with screenshot + context
            extra = f"\nNote: last action failed with error: {last_error}" if last_error else ""
            user_content = [
                {
                    "type": "image",
                    "source": {"type": "base64", "media_type": "image/png", "data": img}
                },
                {
                    "type": "text",
                    "text": (
                        f"Step {step}. URL: {current_url}{extra}\n\n"
                        f"Profile:\n{json.dumps(profile, indent=2)}\n\n"
                        "What is the next single action? Respond with JSON only."
                    )
                }
            ]
            messages.append({"role": "user", "content": user_content})
            last_error = None

            # Ask Claude
            response = client.messages.create(
                model="claude-opus-4-6",
                max_tokens=512,
                system=SYSTEM_PROMPT,
                messages=messages
            )
            raw = response.content[0].text.strip()
            messages.append({"role": "assistant", "content": raw})

            # Parse response
            try:
                action = json.loads(raw)
            except json.JSONDecodeError:
                print(f"⚠️  Unparseable response: {raw}")
                last_error = "Response was not valid JSON"
                continue

            act = action.get("action", "")
            detail = {k: v for k, v in action.items() if k != "action"}
            print(f"  [{step:02d}] {act:18s} {json.dumps(detail)}")

            # ── Delegate actions ────────────────────────────────────────────

            if act in ("fill", "click", "select", "check", "wait"):
                err = await try_action(page, action)
                if err:
                    print(f"         ↳ ⚠️  failed: {err}")
                    last_error = err

            elif act == "ask":
                answer = input(f"\n🤖 {action['question']}\nYou: ").strip()
                messages.append({
                    "role": "user",
                    "content": f"User answered: {answer!r}. Continue."
                })

            elif act == "account_required":
                print(f"\n🔐 Account required: {action.get('message','')}")
                if action.get("can_create"):
                    resp = input("Create a new account? (y/n): ").strip().lower()
                    if resp == "y":
                        messages.append({
                            "role": "user",
                            "content": (
                                "User wants to create a new account. "
                                "Use profile.parent.email as the username/email and "
                                "profile.account.password as the password. Proceed."
                            )
                        })
                        continue
                    else:
                        input("Log in manually in the browser, then press Enter to continue...")
                        messages.append({
                            "role": "user",
                            "content": "User has logged in manually. Please continue with registration."
                        })
                        continue
                else:
                    print("Cannot create account automatically. Please log in manually.")
                    input("Press Enter once logged in...")
                    messages.append({
                        "role": "user",
                        "content": "User has logged in manually. Please continue."
                    })
                    continue

            elif act == "captcha":
                print(f"\n🧩 CAPTCHA: {action.get('message','Please solve the CAPTCHA in the browser.')}")
                input("Solve it, then press Enter to continue...")
                messages.append({
                    "role": "user",
                    "content": "CAPTCHA has been solved. Please continue."
                })
                continue

            elif act == "stop":
                reason = action.get("reason", "")
                msg = action.get("message", "")
                if reason == "payment_page":
                    print(f"\n✅ Stopped at payment page — form is ready for your payment details.")
                    print(f"   {msg}")
                elif reason == "complete":
                    print(f"\n🎉 Registration complete! {msg}")
                else:
                    print(f"\n⛔ Stopped: {msg}")
                break

            else:
                print(f"  ⚠️  Unknown action '{act}' — asking Claude to retry")
                last_error = f"Unknown action: {act}"

            await page.wait_for_timeout(400)

        input("\nPress Enter to close the browser...")
        await browser.close()


# ── Entry point ─────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("Usage: python agent.py <registration-url> [profile.json]")
        print("       ANTHROPIC_API_KEY must be set in your environment")
        sys.exit(1)

    url = sys.argv[1]
    profile_path = sys.argv[2] if len(sys.argv) > 2 else "profile.json"
    profile = load_profile(profile_path)

    client = anthropic.Anthropic()  # reads ANTHROPIC_API_KEY from env
    asyncio.run(run_agent(url, profile, client))


if __name__ == "__main__":
    main()
