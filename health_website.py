#!/usr/bin/env python3
"""
Health Diary Generator, nss edition
===================================
Reads run + gym data from health.md (YAML) and renders a single static page
for health.nihars.com in the nss look shared with nih.ar and home.nihars.com:

  • nss teal (#3a807a), square-grid background, dark by default, light by system
  • classless: bare semantic tags only, no class attributes
  • JavaScript-free, no tracking, no external fonts or CDNs

Same input/output paths and run style as before:  python3 health_website.py

Computed extras (from data already in health.md, nothing new to maintain):
  • stats strip: races, total distance, best 10K, money spent, BMI
  • pace per run (time ÷ distance)
  • countdown on planned runs ("In 19 days")
"""

import os
import re
import sys
import html
import logging
from pathlib import Path
from datetime import date, datetime
from urllib.parse import quote

try:
    import yaml
except ImportError:
    print("PyYAML is required. Install it with: pip install pyyaml")
    sys.exit(1)

# ============================================================
# CONFIG: adjust paths to your environment
# ============================================================
IS_DOCKER = (
    os.path.exists('/.dockerenv') or
    os.getenv('RUNNING_IN_DOCKER') == 'true' or
    'docker' in os.getenv('PATH', '').lower()
)

if IS_DOCKER:
    DATA_PATH = Path("/data/notes/data/health.md")
    OUTPUT_PATH = Path("/docker/web/health.nihars.com/index.html")
else:
    DATA_PATH = Path("/home/datar/data/notes/data/health.md")
    OUTPUT_PATH = Path("/home/datar/docker/web/health.nihars.com/index.html")

LOG_LEVEL = logging.INFO
# ============================================================

logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger("health_diary")

# Run fields never shown as label/value rows (handled elsewhere or internal)
SKIP_FIELDS = {"id", "name", "link", "date"}
DATE_FORMATS = ("%d %b %Y", "%d %B %Y", "%Y-%m-%d", "%d-%m-%Y")


# ---------------------------------------------------------------------
# Data loading (YAML)
# ---------------------------------------------------------------------

def load_data(path: Path) -> dict:
    if not path.exists():
        log.error(f"Data file not found: {path}")
        sys.exit(1)
    try:
        with path.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        log.error(f"YAML parse error: {e}")
        sys.exit(1)
    if not isinstance(data, dict):
        log.error("YAML root must be a dictionary")
        sys.exit(1)
    return data


def validate_run(run, kind: str) -> dict:
    if not isinstance(run, dict):
        log.warning(f"Skipping malformed {kind} run entry: {run!r}")
        return {}
    for field in ("name", "date"):
        if not run.get(field):
            log.warning(f"{kind} run missing '{field}': {run}")
            run[field] = run.get(field) or "—"
    return run


def validate_gym_day(day) -> dict:
    if not isinstance(day, dict):
        log.warning(f"Skipping malformed gym day entry: {day!r}")
        return {}
    day["day"] = day.get("day") or "—"
    day["title"] = day.get("title") or "—"
    if not isinstance(day.get("exercises"), list):
        day["exercises"] = []
    return day


# ---------------------------------------------------------------------
# Value helpers (YAML can give str, int, float, date, None)
# ---------------------------------------------------------------------

def text(value) -> str:
    """Plain display text: None → '', 2500.0 → '2500', strings trimmed."""
    if value is None:
        return ""
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    if isinstance(value, (list, tuple)):
        return ", ".join(text(v) for v in value)
    return str(value).strip()


def esc(value) -> str:
    return html.escape(text(value)) or "—"


def number(value):
    """First number found in a value ('67kg' → 67.0), else None."""
    m = re.search(r"\d+(?:\.\d+)?", text(value))
    return float(m.group()) if m else None


def parse_date(value):
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    s = text(value)
    for fmt in DATE_FORMATS:
        try:
            return datetime.strptime(s, fmt).date()
        except ValueError:
            pass
    return None


def parse_km(value):
    """'10K' / '3.46K' / '10 km' → km as float, else None."""
    m = re.fullmatch(r"\s*(\d+(?:\.\d+)?)\s*(k|km)?\s*", text(value), re.I)
    return float(m.group(1)) if m else None


def parse_minutes(value):
    """'52:00' → 52.0, '107:00' → 107.0, '1:04:30' → 64.5, else None."""
    parts = text(value).split(":")
    try:
        nums = [float(p) for p in parts]
    except ValueError:
        return None
    if len(nums) == 2:
        return nums[0] + nums[1] / 60
    if len(nums) == 3:
        return nums[0] * 60 + nums[1] + nums[2] / 60
    return None


def fmt_clock(minutes: float) -> str:
    """64.5 → '64:30'."""
    total = round(minutes * 60)
    return f"{total // 60}:{total % 60:02d}"


def fmt_money(value) -> str:
    n = number(value)
    if n is None:
        return text(value)
    return "Free" if n == 0 else f"₹{n:,.0f}"


def split_link(value):
    """'indiarunning.com' → ('https://indiarunning.com', '').
    'https://raceiq.in/  ID:5099' → ('https://raceiq.in/', 'ID:5099')."""
    parts = text(value).split(None, 1)
    if not parts:
        return "", ""
    url, rest = parts[0], (parts[1] if len(parts) > 1 else "")
    if not re.match(r"^https?://", url, re.I):
        url = "https://" + url
    return url, rest.strip()


def countdown(d) -> str:
    if d is None:
        return ""
    days = (d - date.today()).days
    if days == 0:
        return "Today"
    if days == 1:
        return "Tomorrow"
    if days > 1:
        return f"In {days} days"
    return f"{-days} days ago"


def by_date(runs: list, newest_first: bool) -> list:
    """Sort by parsed date; unparseable dates always go last."""
    def key(r):
        d = parse_date(r.get("date"))
        if d is None:
            return (1, 0)
        return (0, -d.toordinal() if newest_first else d.toordinal())
    return sorted(runs, key=key)


# ---------------------------------------------------------------------
# Rendering (bare semantic tags only: no class attributes, no JS)
# ---------------------------------------------------------------------

def render_run(run: dict, planned: bool) -> str:
    name = esc(run.get("name"))
    url, link_note = split_link(run.get("link"))
    heading = f'<a href="{html.escape(url)}" rel="noopener">{name} ↗</a>' if url else name

    d = parse_date(run.get("date"))
    km = parse_km(run.get("distance"))
    mins = parse_minutes(run.get("time"))

    rows = []
    for key, value in run.items():
        if key in SKIP_FIELDS or text(value) == "":
            continue
        label = html.escape(str(key).replace("_", " "))
        if key == "cost":
            shown = html.escape(fmt_money(value))
        elif key == "reward":
            shown = f"<mark>{esc(value)}</mark>"
        else:
            shown = esc(value)
        rows.append(f"<div><dt>{label}</dt><dd>{shown}</dd></div>")
        # computed pace goes right after time
        if key == "time" and km and mins:
            rows.append(f"<div><dt>pace</dt><dd>{fmt_clock(mins / km)} /km</dd></div>")
    if link_note:
        rows.append(f"<div><dt>ref</dt><dd>{esc(link_note)}</dd></div>")

    when = f'<p>{esc(run.get("date"))}</p>'
    lead = f"<p>{countdown(d)}</p>" if planned and d else ""

    return f"""
      <article>
        <header><h3>{heading}</h3>{when}</header>
        {lead}
        <dl>{''.join(rows)}</dl>
      </article>"""


def render_gym(day: dict) -> str:
    style = ' style="grid-column:1/-1"' if day.get("full_width") else ""
    items = []
    for ex in day.get("exercises", []):
        s = text(ex)
        m = re.match(r"^(.*?)\s+(\d+\s*x\s*\S+)$", s)
        if m:
            items.append(f"<li><span>{html.escape(m.group(1))}</span><code>{html.escape(m.group(2))}</code></li>")
        elif s:
            items.append(f"<li><span>{html.escape(s)}</span></li>")
    body = f"<ol>{''.join(items)}</ol>" if items else "<p>Rest</p>"
    return f"""
      <article{style}>
        <header><h3>{esc(day.get('title'))}</h3><p>{esc(day.get('day'))}</p></header>
        {body}
      </article>"""


def render_stats(meta: dict, recent: list) -> str:
    tiles = []

    def tile(label, value):
        if value:
            tiles.append(f"<div><dt>{label}</dt><dd>{html.escape(value)}</dd></div>")

    # Race totals, computed from recent runs
    dists = [parse_km(r.get("distance")) for r in recent]
    total_km = sum(k for k in dists if k)
    tens = [parse_minutes(r.get("time")) for r in recent if parse_km(r.get("distance")) == 10]
    tens = [t for t in tens if t]
    spent = sum(n for n in (number(r.get("cost")) for r in recent) if n)

    tile("Races", str(len(recent)) if recent else "")
    tile("Distance", f"{total_km:g} km" if total_km else "")
    tile("Best 10K", fmt_clock(min(tens)) if tens else "")
    tile("Spent", f"₹{spent:,.0f}" if spent else "")

    # Body metrics
    weight, height = text(meta.get("weight")), text(meta.get("height"))
    tile("Weight", weight)
    tile("Height", height)

    bmi = text(meta.get("bmi"))
    w, h = number(weight), number(height)
    if not bmi and w and h:
        bmi = f"{w / (h / 100) ** 2:.1f}"
    tile("BMI", bmi)

    bf = text(meta.get("body_fat"))
    tile("Body fat", bf if not bf or bf.endswith("%") else f"{bf}%")

    return f"<dl>{''.join(tiles)}</dl>" if tiles else ""


def section(sid: str, title: str, note: str, cards: str, empty: str) -> str:
    return f"""
    <section id="{sid}">
      <h2>{title} <small>{note}</small></h2>
      {cards or f'<p>{empty}</p>'}
    </section>"""


def favicon() -> str:
    svg = ("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'>"
           "<rect width='48' height='48' rx='10' fill='#3a807a'/>"
           "<polyline points='8,26 16,26 20,15 27,34 31,21 35,26 40,26' fill='none' "
           "stroke='#fff' stroke-width='3.5' stroke-linecap='round' stroke-linejoin='round'/></svg>")
    return "data:image/svg+xml," + quote(svg)


LOGO = """<svg viewBox="0 0 48 48" width="44" height="44" aria-hidden="true">
        <rect width="48" height="48" rx="10" fill="#3a807a"/>
        <polyline points="8,26 16,26 20,15 27,34 31,21 35,26 40,26" fill="none" stroke="#fff"
                  stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>"""


def render_page(meta: dict, planned: list, recent: list, gym: list) -> str:
    title = esc(meta.get("title") or "Health Diary")
    subtitle = esc(meta.get("subtitle") or "Run • Lift • Improve")
    tagline = html.escape(text(meta.get("tagline")))
    footer = html.escape(text(meta.get("footer")))
    updated = html.escape(text(meta.get("last_updated")) or date.today().strftime("%d %b %Y"))

    planned = by_date(planned, newest_first=False)
    recent = by_date(recent, newest_first=True)

    stats = render_stats(meta, recent)
    planned_html = "".join(render_run(r, True) for r in planned)
    recent_html = "".join(render_run(r, False) for r in recent)
    gym_html = "".join(render_gym(d) for d in gym)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="{subtitle}">
  <meta name="color-scheme" content="dark light">
  <meta name="theme-color" content="#3a807a">
  <link rel="icon" type="image/svg+xml" href="{favicon()}">
  <title>{title}</title>
  <style>{CSS}</style>
</head>
<body>
  <header>
    {LOGO}
    <div>
      <h1>{title}</h1>
      <p>{subtitle}</p>
      {f'<p>{tagline}</p>' if tagline else ''}
    </div>
    <nav>
      <a href="#stats">Stats</a>
      <a href="#planned">Planned</a>
      <a href="#recent">Recent</a>
      <a href="#gym">Gym</a>
    </nav>
  </header>

  <main>
    {section("stats", "Stats", "at a glance", stats, "No stats yet.")}
    {section("planned", "Planned", str(len(planned)), planned_html, "No planned runs yet.")}
    {section("recent", "Recent runs", str(len(recent)), recent_html, "No recent runs logged yet.")}
    {section("gym", "Gym schedule", f"{len(gym)} days", gym_html, "No gym schedule set.")}
  </main>

  <footer>
    <span>{footer}</span>
    <span>Updated {updated}</span>
  </footer>
</body>
</html>
"""


# ---------------------------------------------------------------------
# nss stylesheet: tokens + element selectors only (classless)
# ---------------------------------------------------------------------

CSS = """
:root {
  --nss-accent: #3a807a;
  --nss-accent-hi: #5fb3ab;
  --nss-bg: #0e1514;
  --nss-surface: #141e1d;
  --nss-fg: #e6efed;
  --nss-muted: #8fa3a0;
  --nss-line: #24312f;
  --nss-grid: rgba(58, 128, 122, .10);
  --nss-sans: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  --nss-mono: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  --nss-radius: 8px;
}
@media (prefers-color-scheme: light) {
  :root {
    --nss-accent-hi: #2d6862;
    --nss-bg: #f5f8f7;
    --nss-surface: #ffffff;
    --nss-fg: #16211f;
    --nss-muted: #5b6e6b;
    --nss-line: #d8e2e0;
    --nss-grid: rgba(58, 128, 122, .08);
  }
}

*, *::before, *::after { box-sizing: border-box; }
html { -webkit-text-size-adjust: 100%; scroll-behavior: smooth; }
body {
  margin: 0;
  font: 16px/1.55 var(--nss-sans);
  color: var(--nss-fg);
  background-color: var(--nss-bg);
  background-image:
    linear-gradient(var(--nss-grid) 1px, transparent 1px),
    linear-gradient(90deg, var(--nss-grid) 1px, transparent 1px);
  background-size: 24px 24px;
}
a:focus-visible { outline: 2px solid var(--nss-accent); outline-offset: 2px; }

/* Page frame */
body > header, main, body > footer { max-width: 68rem; margin: 0 auto; padding-inline: 1rem; }

/* Header */
body > header {
  display: grid; grid-template-columns: auto 1fr; align-items: center;
  gap: .5rem 1rem; padding-block: 2rem 1.5rem;
}
body > header svg { width: 3rem; height: 3rem; }
h1 { margin: 0; font-size: clamp(1.6rem, 6vw, 2.4rem); line-height: 1.1; letter-spacing: -.02em; }
body > header div p { margin: .3rem 0 0; }
body > header div p:first-of-type {
  font: 600 .75rem var(--nss-mono); text-transform: uppercase;
  letter-spacing: .16em; color: var(--nss-accent-hi);
}
body > header div p + p { color: var(--nss-muted); font-size: .9rem; }

nav { grid-column: 1 / -1; display: flex; flex-wrap: wrap; gap: .5rem; margin-top: .75rem; }
nav a {
  padding: .35rem .85rem; border: 1px solid var(--nss-line); border-radius: 999px;
  background: var(--nss-surface); color: var(--nss-fg); text-decoration: none;
  font: 500 .72rem var(--nss-mono); text-transform: uppercase; letter-spacing: .12em;
}
nav a:hover { border-color: var(--nss-accent); color: var(--nss-accent-hi); }

/* Sections: card grid, headings and stats span the full row */
main { display: grid; gap: 2.5rem; padding-bottom: 2.5rem; }
section {
  display: grid; gap: 1rem; scroll-margin-top: 1rem;
  grid-template-columns: repeat(auto-fill, minmax(min(100%, 18rem), 1fr));
}
section > h2, section > dl, section > p { grid-column: 1 / -1; }
section > p { margin: 0; color: var(--nss-muted); }
h2 {
  display: flex; align-items: baseline; gap: .6rem; margin: 0;
  padding-left: .7rem; border-left: 3px solid var(--nss-accent);
  font: 600 .85rem var(--nss-mono); text-transform: uppercase; letter-spacing: .14em;
}
h2 small { color: var(--nss-muted); font-weight: 400; }

/* Stats strip */
section > dl {
  display: grid; gap: .75rem; margin: 0;
  grid-template-columns: repeat(auto-fill, minmax(min(100%, 9rem), 1fr));
}
section > dl > div {
  padding: .8rem 1rem; background: var(--nss-surface);
  border: 1px solid var(--nss-line); border-radius: var(--nss-radius);
}
section > dl dt {
  font: .66rem var(--nss-mono); text-transform: uppercase;
  letter-spacing: .12em; color: var(--nss-muted);
}
section > dl dd { margin: .15rem 0 0; font-size: 1.3rem; font-weight: 600; font-variant-numeric: tabular-nums; }

/* Cards */
article {
  display: flex; flex-direction: column; gap: .8rem; padding: 1rem 1.1rem;
  background: var(--nss-surface); border: 1px solid var(--nss-line);
  border-radius: var(--nss-radius); transition: border-color .2s, transform .2s;
}
article:hover { border-color: var(--nss-accent); transform: translateY(-2px); }
article header { display: flex; justify-content: space-between; align-items: baseline; gap: .75rem; }
h3 { margin: 0; font-size: 1rem; line-height: 1.3; }
h3 a { color: inherit; text-decoration: none; border-bottom: 1px solid var(--nss-accent); }
h3 a:hover { color: var(--nss-accent-hi); }
article header p {
  margin: 0; white-space: nowrap; color: var(--nss-muted);
  font: .7rem var(--nss-mono); text-transform: uppercase; letter-spacing: .08em;
}
article > p {
  margin: 0; color: var(--nss-accent-hi);
  font: 600 .74rem var(--nss-mono); text-transform: uppercase; letter-spacing: .12em;
}
article dl { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: .55rem 1rem; margin: 0; }
article dt {
  font: .62rem var(--nss-mono); text-transform: uppercase;
  letter-spacing: .12em; color: var(--nss-muted);
}
article dd { margin: 0; font-size: .88rem; overflow-wrap: anywhere; font-variant-numeric: tabular-nums; }
mark { background: none; color: var(--nss-accent-hi); font-weight: 600; }

/* Gym exercise list */
ol { display: grid; gap: .4rem; margin: 0; padding: 0; list-style: none; }
li {
  display: flex; justify-content: space-between; align-items: baseline; gap: .75rem;
  padding-bottom: .4rem; border-bottom: 1px dashed var(--nss-line); font-size: .88rem;
}
li:last-child { padding-bottom: 0; border-bottom: 0; }
li code { font: .74rem var(--nss-mono); color: var(--nss-accent-hi); white-space: nowrap; }

/* Footer */
body > footer {
  display: flex; flex-wrap: wrap; justify-content: space-between; gap: .5rem;
  padding-block: 1.25rem 2rem; border-top: 1px solid var(--nss-line);
  font: .7rem var(--nss-mono); text-transform: uppercase; letter-spacing: .1em; color: var(--nss-muted);
}

@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  article { transition: none; }
  article:hover { transform: none; }
}
"""


# ---------------------------------------------------------------------
def main():
    data = load_data(DATA_PATH)
    meta = data.get("meta") or {}
    runs = data.get("runs") or {}

    planned = [r for r in (validate_run(r, "planned") for r in (runs.get("planned") or [])) if r]
    recent = [r for r in (validate_run(r, "recent") for r in (runs.get("recent") or [])) if r]
    gym = [d for d in (validate_gym_day(d) for d in (data.get("gym") or [])) if d]

    page = render_page(meta, planned, recent, gym)

    # Atomic write: a half-written page is never served
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    tmp = OUTPUT_PATH.with_name(OUTPUT_PATH.name + ".tmp")
    tmp.write_text(page, encoding="utf-8")
    os.replace(tmp, OUTPUT_PATH)
    log.info(f"Health diary written to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
