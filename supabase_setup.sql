-- ── Step 1: Create admins table first (camps policy references it) ────────
create table admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table admins enable row level security;
create policy "Admin self-read" on admins for select using (user_id = auth.uid());

-- ── Step 2: Create camps table ────────────────────────────────────────────
create table camps (
  id integer primary key,
  name text not null,
  type text not null,
  sleep boolean default false,
  verified boolean default false,
  app_required boolean default false,
  description text,
  age_min integer,
  age_max integer,
  sessions jsonb default '[]',
  apply_info text,
  cost text,
  cost_n numeric,
  location text,
  url text,
  color text default '#0369a1',
  date_range jsonb,
  active boolean default true,
  created_at timestamptz default now()
);
alter table camps enable row level security;
create policy "Public read" on camps for select using (true);
create policy "Admin write" on camps for all
  using (exists(select 1 from admins where user_id = auth.uid()));

-- ── Step 3: Sequence for new camps (starts above existing 1–30 range) ────
create sequence camps_id_seq start 1000;
alter table camps alter column id set default nextval('camps_id_seq');

-- ── Step 4: Insert all 30 camps ───────────────────────────────────────────
insert into camps (id, name, type, sleep, verified, app_required, description, age_min, age_max, sessions, apply_info, cost, cost_n, location, url, color, date_range) values

-- Day camps (id 1–12)
(1, 'Bay Area Discovery Museum Science Camp', 'STEM', false, false, false,
 'Hands-on robotics, chemistry, and ecosystems projects at the museum in a creative environment.',
 4, 10, '[]',
 'Check baykidsmuseum.org for 2026 schedule', '~$425 / week', 425,
 'Sausalito (near SF)', 'https://www.baykidsmuseum.org', '#2563eb',
 '{"s":"2026-06-08","e":"2026-08-07"}'),

(2, 'SF Circus Center Youth Camp', 'Performing Arts', false, false, false,
 'Trapeze, juggling, acrobatics, and aerial arts from professional circus instructors. All levels welcome.',
 7, 14, '[]',
 'Check circuscenter.org for 2026 schedule', '~$650 / week', 650,
 '755 Frederick St, San Francisco', 'https://www.circuscenter.org', '#dc2626',
 '{"s":"2026-06-22","e":"2026-08-07"}'),

(3, 'Golden Gate Park Nature Explorers', 'Nature', false, false, false,
 'Daily hikes, wildlife observation, and environmental science led by SF Rec & Parks naturalists.',
 6, 12, '[]',
 'Check sfrecpark.org for 2026 schedule', '~$300 / week', 300,
 'Golden Gate Park, San Francisco', 'https://sfrecpark.org', '#16a34a',
 '{"s":"2026-07-06","e":"2026-08-14"}'),

(4, 'iD Tech Day Camp at UCSF', 'STEM', false, false, false,
 'Coding, game design, AI, and cybersecurity. Build a real portfolio project to take home.',
 7, 17, '[]',
 'Rolling — check idtech.com for 2026 dates', '~$999 / week', 999,
 'UCSF Mission Bay', 'https://www.idtech.com', '#7c3aed',
 '{"s":"2026-06-08","e":"2026-08-14"}'),

(5, 'Mission Cliffs Rock Climbing Camp', 'Sports', false, false, false,
 'Lead climbing, bouldering, and safety skills at SF''s premier indoor climbing gym.',
 8, 15, '[]',
 'Check touchstoneclimbing.com for 2026 schedule', '~$595 / week', 595,
 '2295 Harrison St, San Francisco', 'https://www.touchstoneclimbing.com/mission-cliffs', '#ea580c',
 '{"s":"2026-06-08","e":"2026-08-14"}'),

(6, 'Young Musicians Program — SFCM', 'Arts', false, false, true,
 'Intensive music training in orchestral instruments, jazz, and chamber music. Public performance finale.',
 9, 17, '[]',
 'Check sfcm.edu for 2026 schedule', '~$1,200 / session', 1200,
 '50 Oak St, San Francisco', 'https://www.sfcm.edu', '#be185d',
 '{"s":"2026-07-13","e":"2026-07-31"}'),

(7, 'SF Rec & Park Summer Day Camps', 'Sports', false, true, false,
 'Free supervised recreation at neighborhood parks: sports, games, crafts, and field trips.',
 5, 12, '[]',
 'Registration opened March 2026 — check sfrecpark.org', 'Free', 0,
 'Various SF parks & rec centers', 'https://sfrecpark.org/camps', '#0891b2',
 '{"s":"2026-06-08","e":"2026-08-12"}'),

(8, 'Creative Arts Charter Art Camp', 'Arts', false, false, false,
 'Painting, ceramics, printmaking, and digital art with professional artists. Family exhibition at end.',
 7, 14, '[]',
 'Check creativeartsca.org for 2026 schedule', '~$550 / session', 550,
 '1220 Atkinson Dr, San Francisco', 'https://www.creativeartsca.org', '#d97706',
 '{"s":"2026-07-06","e":"2026-07-24"}'),

(9, 'Galileo Innovation Camp', 'Leadership', false, false, false,
 'Project-based camp where kids design, prototype, and pitch inventions. Builds creativity and problem-solving.',
 5, 14, '[]',
 'Rolling — check galileo-camps.com for 2026 dates', '~$549 / week', 549,
 'Multiple SF school sites', 'https://www.galileo-camps.com', '#0d9488',
 '{"s":"2026-06-08","e":"2026-08-14"}'),

(10, 'Youth Soccer Academy — SF Elite', 'Sports', false, false, false,
 'Professional coaching for all skill levels. Sessions grouped by age and ability.',
 6, 16, '[]',
 'Check sfsocceracademy.com for 2026 schedule', '~$375 / week', 375,
 'Crocker Amazon Park, San Francisco', 'https://www.sfsocceracademy.com', '#65a30d',
 '{"s":"2026-06-22","e":"2026-08-07"}'),

(11, 'SFMOMA Art Lab Summer Studio', 'Arts', false, false, false,
 'Museum-inspired artwork across mediums — painting, collage, sculpture — guided by SFMOMA educators.',
 6, 13, '[]',
 'Check sfmoma.org for 2026 schedule', '~$480 / week', 480,
 '151 Third St, San Francisco', 'https://www.sfmoma.org/education', '#9333ea',
 '{"s":"2026-06-08","e":"2026-08-07"}'),

(12, 'Coding with Kids — Python & Web', 'STEM', false, false, false,
 'Beginner-friendly Python, HTML/CSS, and JavaScript. Kids build games and websites in small groups.',
 8, 15, '[]',
 'Rolling — check codingwithkids.com for 2026 dates', '~$499 / week', 499,
 'SF hub locations + online', 'https://www.codingwithkids.com', '#1d4ed8',
 '{"s":"2026-06-08","e":"2026-08-14"}'),

-- Sleepaway camps (id 13–30)
(13, 'Camp Tawonga', 'Traditional', true, true, false,
 'Jewish camp near Yosemite with hiking, swimming, arts, and campfire traditions in a beautiful mountain setting.',
 8, 17,
 '[{"s":"2026-06-07","e":"2026-06-12","lbl":"Taste of Camp 1 · 1 wk (Grades 2–6)"},{"s":"2026-06-14","e":"2026-06-26","lbl":"Session 2a · 2 wks (Grades 3–6)"},{"s":"2026-06-28","e":"2026-07-03","lbl":"Taste of Camp 2 · 1 wk"},{"s":"2026-07-05","e":"2026-07-17","lbl":"Session 3a · 2 wks"},{"s":"2026-07-26","e":"2026-08-07","lbl":"Session 4 · 2 wks"}]',
 'Applications open — see tawonga.org/dates-rates', 'See tawonga.org for 2026 rates', 3200,
 'Groveland, CA (near Yosemite)', 'https://tawonga.org/dates-rates/', '#16a34a',
 null),

(14, 'Skylake Yosemite Camp', 'Traditional', true, true, false,
 'Swimming, kayaking, horseback riding, and archery in the High Sierra foothills. Four 2-week sessions.',
 7, 15,
 '[{"s":"2026-06-14","e":"2026-06-27","lbl":"Session A · 2 wks"},{"s":"2026-06-28","e":"2026-07-11","lbl":"Session B · 2 wks"},{"s":"2026-07-12","e":"2026-07-25","lbl":"Session C · 2 wks"},{"s":"2026-07-26","e":"2026-08-08","lbl":"Session D · 2 wks"}]',
 'See skylake.com/camp-dates-fees for 2026 rates', 'See skylake.com for 2026 rates', 3800,
 'Wishon, CA (High Sierra)', 'https://skylake.com/camp-dates-fees', '#0891b2',
 null),

(15, 'Camp Augusta', 'Traditional', true, true, false,
 'Coed camp near Nevada City. Campers choose from 60+ activities. Six sessions ranging from 1–2 weeks.',
 8, 16,
 '[{"s":"2026-06-07","e":"2026-06-13","lbl":"Session I · 1 wk (waitlist)"},{"s":"2026-06-14","e":"2026-06-20","lbl":"Session II · 1 wk"},{"s":"2026-06-21","e":"2026-07-04","lbl":"Session III · 2 wks"},{"s":"2026-07-05","e":"2026-07-18","lbl":"Session IV · 2 wks"},{"s":"2026-07-19","e":"2026-08-01","lbl":"Session V · 2 wks"},{"s":"2026-08-02","e":"2026-08-08","lbl":"Session VI · 1 wk (waitlist)"}]',
 'See campaugusta.org/summer/tuition/table/ for rates & availability', 'See campaugusta.org for 2026 rates', 3500,
 'Nevada City, CA', 'https://campaugusta.org/summer/tuition/table/', '#7c3aed',
 null),

(16, 'Camp Winnarainbow', 'Performing Arts', true, true, false,
 'Circus arts camp founded by Wavy Gravy. Juggling, trapeze, clowning, music, and theater. ⚠ 2026 sessions full — waitlist available.',
 7, 17,
 '[]',
 'All 2026 sessions FULL — join waitlist at campwinnarainbow.org', 'See campwinnarainbow.org', 2800,
 'Laytonville, CA (Mendocino County)', 'https://campwinnarainbow.org/dates-rates/', '#e11d48',
 null),

(17, 'URJ Camp Newman', 'Jewish', true, true, false,
 'Reform Jewish overnight camp with Jewish living, outdoor adventure, sports, and arts in Santa Rosa.',
 9, 17,
 '[{"s":"2026-06-09","e":"2026-06-21","lbl":"Session 1 Aleph · 2 wks"},{"s":"2026-06-23","e":"2026-07-05","lbl":"Session 1 Bet · 2 wks"},{"s":"2026-07-07","e":"2026-07-19","lbl":"Session 2 Gimmel · 2 wks"},{"s":"2026-07-21","e":"2026-08-02","lbl":"Session 2 Daled · 2 wks"}]',
 'See campnewman.org/summer/dates-rates/ for 2026 info', 'See campnewman.org for 2026 rates', 4500,
 'Santa Rosa, CA', 'https://campnewman.org/summer/dates-rates/', '#1d4ed8',
 null),

(18, 'Kennolyn Camps', 'Traditional', true, true, false,
 'Multi-activity camp in the Santa Cruz Mountains — horseback riding, archery, arts, and sports. Six sessions.',
 7, 17,
 '[{"s":"2026-06-15","e":"2026-06-20","lbl":"Session 1 · 1 wk"},{"s":"2026-06-22","e":"2026-06-27","lbl":"Session 2 · 1 wk"},{"s":"2026-06-29","e":"2026-07-11","lbl":"Session 3 · 2 wks"},{"s":"2026-07-13","e":"2026-07-25","lbl":"Session 4 · 2 wks"},{"s":"2026-07-27","e":"2026-08-08","lbl":"Session 5 · 2 wks"},{"s":"2026-08-10","e":"2026-08-15","lbl":"Session 6 · 1 wk"}]',
 'Rolling — see kennolyncamps.com/dates-enrollment/', 'See kennolyncamps.com for 2026 rates', 3000,
 'Scotts Valley, CA (Santa Cruz Mtns)', 'https://www.kennolyncamps.com/dates-enrollment/', '#d97706',
 null),

(19, 'YMCA Camp Hammer', 'Traditional', true, false, false,
 'YMCA overnight camp with swimming, climbing wall, zip lines, and team-building activities. Dates estimated.',
 7, 16,
 '[{"s":"2026-06-22","e":"2026-06-27","lbl":"Session 1 · 1 wk (est.)"},{"s":"2026-06-29","e":"2026-07-04","lbl":"Session 2 · 1 wk (est.)"},{"s":"2026-07-06","e":"2026-07-11","lbl":"Session 3 · 1 wk (est.)"},{"s":"2026-07-13","e":"2026-07-18","lbl":"Session 4 · 1 wk (est.)"},{"s":"2026-07-20","e":"2026-07-25","lbl":"Session 5 · 1 wk (est.)"},{"s":"2026-07-27","e":"2026-08-01","lbl":"Session 6 · 1 wk (est.)"},{"s":"2026-08-03","e":"2026-08-08","lbl":"Session 7 · 1 wk (est.)"}]',
 'Check ymcasf.org for 2026 dates (estimated above)', '~$950 / week', 950,
 'Scotts Valley, CA', 'https://www.ymcasf.org/program/overnight-summer-camps/', '#dc2626',
 null),

(20, 'Cazadero Performing Arts Camp', 'Performing Arts', true, true, true,
 'Intensive residential music and arts camp in the redwoods — orchestra, band, choir, dance, and theater.',
 9, 18,
 '[{"s":"2026-06-15","e":"2026-06-20","lbl":"Young Musicians · 1 wk"},{"s":"2026-06-23","e":"2026-07-04","lbl":"Middle School · 2 wks"},{"s":"2026-07-07","e":"2026-07-18","lbl":"High School · 2 wks"},{"s":"2026-07-21","e":"2026-08-01","lbl":"Junior High · 2 wks"}]',
 'Registration open — see cazadero.org/schedule-fees/', 'See cazadero.org for 2026 rates', 3100,
 'Cazadero, CA (Sonoma County)', 'https://www.cazadero.org/schedule-fees/', '#9333ea',
 null),

(21, 'iD Tech Overnight Camp', 'STEM', true, false, false,
 'Residential STEM camp at top university campuses — coding, game dev, AI, robotics, and cybersecurity. Weekly rolling sessions.',
 10, 17,
 '[{"s":"2026-06-07","e":"2026-06-13","lbl":"Session 1 · 1 wk (est.)"},{"s":"2026-06-14","e":"2026-06-20","lbl":"Session 2 · 1 wk (est.)"},{"s":"2026-06-21","e":"2026-06-27","lbl":"Session 3 · 1 wk (est.)"},{"s":"2026-06-28","e":"2026-07-04","lbl":"Session 4 · 1 wk (est.)"},{"s":"2026-07-05","e":"2026-07-11","lbl":"Session 5 · 1 wk (est.)"},{"s":"2026-07-12","e":"2026-07-18","lbl":"Session 6 · 1 wk (est.)"},{"s":"2026-07-19","e":"2026-07-25","lbl":"Session 7 · 1 wk (est.)"},{"s":"2026-07-26","e":"2026-08-01","lbl":"Session 8 · 1 wk (est.)"},{"s":"2026-08-02","e":"2026-08-08","lbl":"Session 9 · 1 wk (est.)"}]',
 'Rolling — check idtech.com for exact 2026 campus dates', '~$1,249 / week', 1249,
 'Stanford, UCLA & other campuses', 'https://www.idtech.com', '#2563eb',
 null),

(22, 'Camp Mendocino (YMCA)', 'Nature', true, false, false,
 'Outdoor adventure in the Mendocino Woodlands — hiking, archery, river swimming, campfires, and eco-education.',
 7, 15,
 '[{"s":"2026-06-28","e":"2026-07-11","lbl":"Session 1 · 2 wks (est.)"},{"s":"2026-07-12","e":"2026-07-25","lbl":"Session 2 · 2 wks (est.)"},{"s":"2026-07-26","e":"2026-08-08","lbl":"Session 3 · 2 wks (est.)"}]',
 'Check ymcasf.org for 2026 dates (estimated above)', '~$2,600 / 2-week session', 2600,
 'Mendocino Woodlands, CA', 'https://www.ymcasf.org/camps', '#15803d',
 null),

(23, 'Canada/USA Mathcamp', 'STEM', true, false, true,
 'Prestigious 5-week residential program for mathematically talented students (13–18). Proof-based math, top faculty, collaborative culture at a rotating university campus.',
 13, 18,
 '[{"s":"2026-07-05","e":"2026-08-08","lbl":"Session · 5 wks (est.)"}]',
 'Application due ~Mar 2026 — see mathcamp.org/students/', '~$5,500 (aid available)', 5500,
 'University campus (location varies yearly)', 'https://mathcamp.org/students/', '#1d4ed8',
 null),

(24, 'Ross Mathematics Program', 'STEM', true, false, true,
 'Intensive 6-week number theory immersion at Ohio State University. Students explore deep mathematics with mentorship from leading mathematicians. Founded 1957.',
 15, 18,
 '[{"s":"2026-06-14","e":"2026-07-25","lbl":"Session · 6 wks (est.)"}]',
 'Application due ~Apr 2026 — see rossprogram.org', '~$5,000 (aid available)', 5000,
 'Ohio State University, Columbus, OH', 'https://rossprogram.org', '#b45309',
 null),

(25, 'PROMYS at Boston University', 'STEM', true, false, true,
 'Six-week summer program for high schoolers passionate about math. Explore number theory through discovery, problem sets, and collaboration. Founded 1989.',
 14, 18,
 '[{"s":"2026-06-28","e":"2026-08-08","lbl":"Session · 6 wks (est.)"}]',
 'Application due ~Apr 2026 — see promys.org', '~$5,600 (aid available)', 5600,
 'Boston University, Boston, MA', 'https://promys.org', '#dc2626',
 null),

(26, 'Stanford University Math Camp (SUMaC)', 'STEM', true, false, true,
 'Rigorous 4-week residential program at Stanford for high schoolers. Abstract algebra, combinatorics, and number theory with Stanford faculty. Two sessions.',
 15, 18,
 '[{"s":"2026-06-28","e":"2026-07-25","lbl":"Program A · 4 wks (est.)"},{"s":"2026-07-26","e":"2026-08-22","lbl":"Program B · 4 wks (est.)"}]',
 'Application due ~Feb/Mar 2026 — see sumac.stanford.edu', '~$6,000', 6000,
 'Stanford University, Palo Alto, CA', 'https://sumac.stanford.edu', '#b91c1c',
 null),

(27, 'AwesomeMath Summer Program', 'STEM', true, false, false,
 'Three-week residential olympiad math program at multiple university campuses. Focuses on competition math, problem solving, and mathematical olympiad preparation.',
 10, 17,
 '[{"s":"2026-06-28","e":"2026-07-18","lbl":"Session 1 · 3 wks (est.)"},{"s":"2026-07-19","e":"2026-08-08","lbl":"Session 2 · 3 wks (est.)"}]',
 'Rolling registration — see awesomemath.org', '~$4,200 / session', 4200,
 'UC San Diego, Cornell & other campuses', 'https://www.awesomemath.org', '#7c3aed',
 null),

(28, 'MathPath', 'STEM', true, false, true,
 'Four-week residential program for gifted middle schoolers (ages 11–14). Discovery-based curriculum with recreational math, logic puzzles, and advanced topics.',
 11, 14,
 '[{"s":"2026-07-05","e":"2026-08-01","lbl":"Session · 4 wks (est.)"}]',
 'Qualifying quiz + application due ~Mar 2026 — see mathpath.org', '~$5,000 (aid available)', 5000,
 'University campus (location varies yearly)', 'http://www.mathpath.org', '#0891b2',
 null),

(29, 'Hampshire College Summer Studies in Math', 'STEM', true, false, true,
 'Highly selective 6-week intensive for mathematically gifted students. Collaborative, proof-based exploration of advanced and recreational mathematics. Known as HCSSiM.',
 14, 18,
 '[{"s":"2026-07-05","e":"2026-08-15","lbl":"Session · 6 wks (est.)"}]',
 'Application due ~Feb/Mar 2026 — see hcssim.org', '~$5,200 (aid available)', 5200,
 'Hampshire College, Amherst, MA', 'https://www.hcssim.org', '#065f46',
 null),

(30, 'MathILy', 'STEM', true, false, true,
 'Selective 5-week residential camp focused on mathematical exploration and rigor. Strong community of math-lovers; curriculum built around discovery and proof.',
 14, 18,
 '[{"s":"2026-07-05","e":"2026-08-08","lbl":"Session · 5 wks (est.)"}]',
 'Application due ~Mar 2026 — see mathily.org', '~$5,000 (aid available)', 5000,
 'Bryn Mawr College, Bryn Mawr, PA', 'http://www.mathily.org', '#9333ea',
 null);

-- ── Step 5: Promote yourself to admin ────────────────────────────────────
-- Find your UUID in Supabase → Authentication → Users, then run:
-- insert into admins (user_id) values ('<your-user-uuid>');
