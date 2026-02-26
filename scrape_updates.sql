-- ── Scrape Updates: 2026 Date Verification ────────────────────────────────
-- Run this in the Supabase SQL editor.
-- Findings from web scraping all camps, Feb 2026.

-- ── Step 1: Add coming_soon column ────────────────────────────────────────
alter table camps add column if not exists coming_soon boolean default false;

-- ── Step 2: Verified local day camps ──────────────────────────────────────

-- ID 1 Bay Area Discovery Museum: June 8 – Aug 21, $640/week (was ~$425)
update camps set
  verified    = true,
  cost        = '~$640 / week',
  cost_n      = 640,
  date_range  = '{"s":"2026-06-08","e":"2026-08-21"}'
where id = 1;

-- ID 2 Circus Center: June 8 – Aug 14, $650/week (start date moved up from June 22)
update camps set
  verified   = true,
  date_range = '{"s":"2026-06-08","e":"2026-08-14"}'
where id = 2;

-- ID 9 Galileo: June 8 – July 17 confirmed (date_range unchanged, verify flag set)
update camps set verified = true where id = 9;

-- ID 10 Youth Soccer Academy (SF Elite): sfsocceracademy.com offline; SF Elite runs at
-- Beach Chalet, June 9-27. Updating URL and dates.
update camps set
  verified   = true,
  url        = 'https://www.sfelitesc.org/camps',
  location   = 'Beach Chalet, San Francisco',
  date_range = '{"s":"2026-06-09","e":"2026-06-27"}'
where id = 10;

-- ── Step 3: iD Tech overnight — SF State confirmed June 15 – July 24 ──────
update camps set
  verified  = true,
  location  = 'SF State & other university campuses',
  sessions  = '[
    {"s":"2026-06-15","e":"2026-06-21","lbl":"Wk 1 · SF State"},
    {"s":"2026-06-22","e":"2026-06-28","lbl":"Wk 2 · SF State"},
    {"s":"2026-06-29","e":"2026-07-05","lbl":"Wk 3 · SF State"},
    {"s":"2026-07-06","e":"2026-07-12","lbl":"Wk 4 · SF State"},
    {"s":"2026-07-13","e":"2026-07-19","lbl":"Wk 5 · SF State"},
    {"s":"2026-07-20","e":"2026-07-24","lbl":"Wk 6 · SF State"}
  ]'::jsonb
where id = 21;

-- ── Step 4: Sleepaway math camps — verified dates ─────────────────────────

-- ID 23 Canada/USA Mathcamp: June 28 – Aug 2, Champlain College, Burlington VT
update camps set
  verified  = true,
  location  = 'Champlain College, Burlington, VT',
  sessions  = '[{"s":"2026-06-28","e":"2026-08-02","lbl":"Session · 5 wks"}]'::jsonb
where id = 23;

-- ID 24 Ross Mathematics Program: June 14 – July 24, Otterbein University Columbus OH
update camps set
  verified  = true,
  location  = 'Otterbein University, Columbus, OH',
  sessions  = '[{"s":"2026-06-14","e":"2026-07-24","lbl":"Session · 6 wks"}]'::jsonb
where id = 24;

-- ID 25 PROMYS: June 28 – Aug 8, Boston University (confirmed)
update camps set
  verified  = true,
  sessions  = '[{"s":"2026-06-28","e":"2026-08-08","lbl":"Session · 6 wks"}]'::jsonb
where id = 25;

-- ID 26 SUMaC: ONE residential session June 21–July 17 (not two sessions as estimated)
update camps set
  verified     = true,
  description  = 'Rigorous 4-week residential program at Stanford for high schoolers. Abstract algebra, combinatorics, and number theory with Stanford faculty. One residential session per year; online option also offered.',
  sessions     = '[{"s":"2026-06-21","e":"2026-07-17","lbl":"Program I Residential · 4 wks"}]'::jsonb
where id = 26;

-- ID 28 MathPath: Now at University of Portland; cost updated from ~$5k to ~$6,300
update camps set
  location    = 'University of Portland, Portland, OR',
  cost        = '~$6,300 (aid available)',
  cost_n      = 6300,
  apply_info  = 'Qualifying quiz + application due ~Mar 2026 — see mathpath.org'
where id = 28;

-- ID 29 HCSSiM: June 28 – Aug 8 (was July 5 – Aug 15 estimated)
update camps set
  verified  = true,
  sessions  = '[{"s":"2026-06-28","e":"2026-08-08","lbl":"Session · 6 wks"}]'::jsonb
where id = 29;

-- ID 30 MathILy: June 28 – Aug 1 (was July 5 – Aug 8 estimated)
update camps set
  verified  = true,
  sessions  = '[{"s":"2026-06-28","e":"2026-08-01","lbl":"Session · 5 wks"}]'::jsonb
where id = 30;

-- ── Step 5: Data corrections ──────────────────────────────────────────────

-- ID 19: "Camp Hammer" doesn't exist — YMCA SF runs Camp Jones Gulch (La Honda, CA)
update camps set
  name        = 'YMCA Camp Jones Gulch',
  description = 'YMCA overnight camp near La Honda, CA — swimming, archery, canoeing, zip-lining, and team-building in the redwoods. Sessions range from 3 days to 2 weeks for ages 6–16.',
  location    = 'La Honda, CA (San Mateo County)',
  url         = 'https://www.ymcasf.org/ymca-camp-jones-gulch-summer-camp',
  coming_soon = true,
  sessions    = '[{"s":"2026-06-14","e":"2026-08-07","lbl":"Summer Season · specific sessions TBD"}]'::jsonb
where id = 19;

-- ID 22: Camp Mendocino is run by Boys & Girls Clubs of SF, NOT YMCA
update camps set
  name        = 'Camp Mendocino',
  description = 'Outdoor adventure camp run by Boys & Girls Clubs of San Francisco in the Mendocino Woodlands — hiking, archery, river swimming, campfires, and eco-education. Six 10-day sessions.',
  url         = 'https://www.campmendocino.org/',
  coming_soon = true
where id = 22;

-- ID 27 AwesomeMath: Changed from residential to ONLINE ONLY as of 2026
-- Three 3-week online sessions; sleep = false
update camps set
  sleep       = false,
  verified    = true,
  description = 'Live online olympiad math program (lectures recorded). Fully online as of 2026 — no longer residential. Three 3-week sessions: Jun 8–26, Jun 29–Jul 17, Jul 20–Aug 7.',
  location    = 'Online',
  cost        = '~$1,200 / session',
  cost_n      = 1200,
  apply_info  = 'Rolling enrollment — see awesomemath.org. Sessions: Jun 8–26, Jun 29–Jul 17, Jul 20–Aug 7.',
  sessions    = '[]'::jsonb,
  date_range  = '{"s":"2026-06-08","e":"2026-08-07"}'
where id = 27;

-- ── Step 6: Camp Lemma (ID 1002) — verified two sessions ──────────────────
-- Day math camp, rising 4th–9th grade, two one-week sessions, $480/week
update camps set
  verified   = true,
  sleep      = false,
  cost       = '~$480 / week',
  cost_n     = 480,
  age_min    = 9,
  age_max    = 15,
  sessions   = '[]'::jsonb,
  date_range = '{"s":"2026-06-15","e":"2026-06-26"}',
  apply_info = 'See camplemma.org — Session 1 (rising 6th–9th): June 15–19; Session 2 (rising 4th–6th): June 22–26'
where id = 1002;

-- ── Step 7: coming_soon flags ─────────────────────────────────────────────
update camps set coming_soon = true
where id in (
  3,    -- SF Rec & Park Nature Explorers: registration opens March 2026
  5,    -- Mission Cliffs: no 2026 dates published
  6,    -- SFCM Young Musicians: specific 2026 program TBD
  8,    -- Creative Arts Charter Art Camp: no 2026 info found
  11,   -- SFMOMA Art Lab: no 2026 dates published
  12,   -- Coding with Kids: no 2026 SF dates found
  1000, -- Bay Club: 2026 registration via app only (dates not public)
  1001, -- Presidio Knolls: "Summer 2026 info coming soon"
  1003  -- Tenacious Tennis: registration open but no specific dates published
);

-- ── Verify the changes ─────────────────────────────────────────────────────
-- select id, name, verified, coming_soon, sessions, date_range
-- from camps order by id;
