# Global Preferences

## TypeScript

- Always use pnpm to management package.json

## ESLint — All JS/TS Projects

Always configure ESLint with these rules in any JavaScript/TypeScript project:

- Blank line before `return` statements
- Blank lines around conditionals, loops (`if`, `for`, `while`, `do`, `switch`, `try`)
- Blank lines after variable declaration blocks (`const/let/var`)
- Blank lines around function/class/export declarations
- Import grouping (blank line after imports)
- `no-inline-comments: warn`
- `react/jsx-no-comment-textnodes: error` (no `{/* */}` JSX comments)
- `curly: ["warn", "multi-line"]`
- `no-console: ["warn", { allow: ["warn", "error"] }]`
- `prefer-const: warn`, `no-var: error`
- Use flat config format (`eslint.config.mjs`)
- Install `eslint-plugin-react` for JSX rules

## Code Style — JSX

- **Never write comments inside JSX** (`{/* ... */}`). They are noise. If the code needs explanation, the component name or variable name should be self-explanatory. When writing or editing JSX, do not add `{/* Header */}`, `{/* CTA */}`, etc. Remove them when found.

## Landing Pages — Standard Setup

Every landing page project should include:

### PWA / iOS
- `manifest.json` in `public/` with `display: standalone`, brand `background_color` and `theme_color`
- Icons: `icon-192.png`, `icon-512.png`, `icon-maskable-512.png` in `public/icons/`
- `apple-icon.png` in `app/` (180x180)
- `icon.svg` in `app/` (favicon, replaces default Next.js `.ico`)
- In metadata: `manifest`, `appleWebApp` with `capable: true`, `statusBarStyle: 'black-translucent'`, `startupImage`
- `viewport-fit=cover` in viewport config to extend content behind iOS status bar
- `pt-[env(safe-area-inset-top)]` on the fixed `<header>` element (not on inner div) so the header grows to accommodate the iOS safe area
- Body `bg-color` must match the brand dark color to avoid white gaps above header in PWA mode

### Meta Tags
- `Viewport` export with `themeColor` (light/dark), `viewportFit: 'cover'`, `maximumScale: 1`, `userScalable: false`
- OpenGraph: `title`, `description`, `siteName`, `url`, `type`, `locale`, `images` (1200x630 `og-image.png`)
- Twitter: `card: 'summary_large_image'`, `title`, `description`, `images`
- `robots` with googleBot config (`max-video-preview`, `max-image-preview`, `max-snippet`)
- `alternates.canonical`

### Header
- Hide on scroll down, show on scroll up (track `lastScrollY` with ref)
- Hamburger menu for mobile (animated 3 bars → X) with fullscreen overlay
- Lock body scroll when mobile menu is open

### Static Export (Cloudflare Pages)
- Use `output: 'export'` in `next.config.ts`
- Dynamic routes (route handlers) must be converted to static files in `public/`
- Cloudflare Pages has 25MB per file limit — use HLS segments for video

### Pages
- Custom `not-found.tsx` with brand logo and styling
- `/terms` page
- `/llm.txt` as static file in `public/` (not a route handler)

## UI — Responsive is non-negotiable

**Any time you add, modify, or rearrange UI elements (buttons, cards,
headers, toolbars, tables, navs, modals, drawers), you MUST handle the
mobile/narrow-viewport layout in the same change.** Desktop-only changes
are considered incomplete and routinely break the mobile screen.

Default checklist before declaring a UI change done:

- **Stack on narrow, side-by-side at the breakpoint**: `flex flex-col md:flex-row`
  (or the project's equivalent — voodu-webui uses `vmd:`) instead of
  `flex flex-wrap` whenever items would compete for horizontal space.
  `flex-wrap` only works when children have natural minimum widths; with
  `flex-1 min-w-0` children collapse to nothing and `break-all` cascades
  into character-per-line nightmares.
- **Action rows shrink-to-content on mobile**: hide button text labels
  (`<span className="hidden md:inline">Label</span>`) and keep the icon
  when 3+ buttons share a row. Icon-only in a tight viewport >>>
  labeled buttons wrapping mid-word.
- **Title blocks need their own row on mobile**: never let `flex-1
  min-w-0` siblings compress a mono identifier under ~200px. Either
  give them `basis-full` on mobile or stack the parent.
- **Tables become cards or scroll-x on mobile**: never expect
  `min-w-[800px]` content to survive 360px. Use `overflow-x-auto` on
  the wrapper OR transpose to cards under the breakpoint.

## Agent Skills — Authoring & Distribution

When building a skill repo meant to be installed via `npx skills add owner/repo`
(the vercel-labs/skills CLI — works across Claude Code, Codex, Cursor, +70 agents):

- **Put the skill in `skills/<name>/`, NEVER at the repo root.** The skill folder
  holds `SKILL.md` + all supporting files (`reference/`, scripts, etc.) together.
  Repo root holds only packaging: `README.md`, `install.sh`, `.gitignore`.
  - **Why:** with a root-level `SKILL.md`, `npx skills add` copies ONLY the
    `SKILL.md` and silently drops sibling dirs like `reference/` → a broken install
    (the agent can't open the docs `SKILL.md` links to). A `skills/<name>/` folder
    is copied whole. The CLI's lockfile (`~/.agents/.skill-lock.json`) records
    `skillPath` — every correct skill shows `skills/<name>/SKILL.md`.
- **`SKILL.md` frontmatter:** only `name` + `description` are required (description
  drives when the skill fires). Reference docs are linked relatively (`reference/x.md`).
- **No per-agent files needed** (`AGENTS.md`, `.cursor/rules`) — the CLI copies the
  same `SKILL.md` to each agent. Select agents with `-a claude-code -a codex -a cursor`,
  `-g` for global, `-y` for non-interactive.
- **Always verify after install**: the installed dir (`~/.agents/skills/<name>/`)
  must contain `SKILL.md` AND `reference/` — e.g. `ls ~/.agents/skills/<name>/reference | wc -l`,
  and confirm every `reference/*.md` the `SKILL.md` links to actually resolves.
- **Slash commands (`commands/*.md` → `/name:verb`) are Claude-Code-only**, outside the
  Agent Skills spec; `npx skills` won't install them. Keep CLI/command docs as `reference/`
  files (one per verb) so they ship cross-agent. An optional `install.sh` can symlink
  `skills/<name>` → `~/.claude/skills/<name>` for local Claude dev.
