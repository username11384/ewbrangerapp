# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Context

**EWB Challenge 2026** — Design Area 5: Climate Resilience and Adaptation  
**Project Opportunity 5.5** — Biodiversity and Habitat Protection Tools  
**Focus:** *Lantana camara* (Class 3 declared weed, QLD) management in **Port Stewart, Lama Lama Country, Cape York, Queensland**  
**Partners:** Yintjingga Aboriginal Corporation (YAC) + Lama Lama Rangers

This is the marketing/showcase website for the Lama Lama Rangers iOS field app. It is a React/Vite single-page app deployed to GitHub Pages at `https://immanuel-lam.github.io/ewbrangerapp/`.

**Course:** 31265 Communication for IT Professionals, UTS Autumn 2026  
**Design process framework:** Empathise → Define → Ideate → Prototype → Test

This site lives as an **orphan branch** (`showcase`) inside the iOS repo, checked out as a git worktree at `../showcase/` (sibling of `ewbrangerapp/`).

---

## Team

| Name | Role | Task 3 Section |
|------|------|----------------|
| **Immanuel** (you) | Q1 economic constraints (1b) | **Prototyping** |
| Essy (Francesca Silva Paniagua) | Q2 habitats (1b) | Project details, background, problem description |
| Marisa | Q3 species (1b) | Design solution options |
| Garv Mitter | Q4 traditional management (1b) | Design criteria and detailed design |
| Jai Sloper | Q5 environmental threats (1b) | Implementation plan |
| Caleb | Q6 ecosystem protection (1b) | Other considerations and recommendations |

---

## Assessment Task 3 — Team Website

**Due:** 15 May 2026, 23:59  
**Weight:** 30%  
**Word limit:** ~5,000 words (cover page, ToC, exec summary, references excluded)  
**Submission:** Word doc + URL link to live website; ONE member submits on behalf of team

### Required Sections
1. Acknowledgement of Country *(verify wording with team before submission)*
2. Group Declaration table (all 6 members + contributions)
3. Background / problem description (Essy)
4. Design solution options (Marisa)
5. Design criteria + detailed design (Garv)
6. **Prototyping** ← Immanuel's section
7. Implementation plan (Jai)
8. Other considerations + recommendations (Caleb)
9. References (APA 7th)
10. **Appendix: AI Prompt Log** ← mandatory, must be maintained throughout

### Rubric Summary (30 pts)
| Criteria | Weight |
|----------|--------|
| Content & stakeholder consideration | 15 pts |
| Website design & audience engagement | 9 pts |
| Referencing, citations & AI prompt log | 6 pts |

SPARK peer review score < 0.85 → **zero for website**.

---

## Field Context (Stakeholder Insights — Mihir)

- Country spans ~400–500 km², 4 camps, rangers live on-site
- Access: Sydney → Cairns → Coen (8hr drive) → Port Stewart (1hr unpaved)
- Infrastructure: high-iron water supply, diesel + solar (some non-functional), HF radio, satellite, Starlink at ranger office
- Drones and offline data collection in use
- In-person training is most effective for technology adoption
- AI tools require community consultation before deployment
- Cultural note: Lama Lama are "saltwater people"; **blue is culturally significant**
- Real environmental risks: flood and cyclone
- Follow-up session with Gavin (YAC rep) — recording to be posted online

---

## App: Lama Lama Rangers Field App

**Version:** V3 (32 features)  
**Repo:** `github.com/immanuel-lam/ewbrangerapp`  
**Demo branch:** `demov3` — PIN: `1234`

### Stack
- **iOS:** Swift / SwiftUI, CoreData, MultipeerConnectivity (mesh sync)
- **Android companion:** Jetpack Compose, Room, Google Nearby Connections (behind iOS)

### V3 Feature Additions
- Safety check-ins
- Voice notes
- Herbicide compatibility checker
- Night vision red light mode

### Important Distinctions
- Supabase/S3 dashboard sync = **demo animation only**, not real backend sync — do not misrepresent

---

## Commands

```bash
npm run dev      # dev server at http://localhost:5173/ewbrangerapp/
npm run build    # production build to dist/
npm run preview  # preview the production build locally
```

---

## Architecture

Everything lives in two files:

- **`src/App.jsx`** — the entire app: all data arrays, hooks, animated widget components, section components, and the root `App` export. No separate files, no routing.
- **`src/App.css`** — all styles and animations. Design tokens in `:root`.

`src/main.jsx` is the entry point — just mounts `App` into `#root`.

### Component anatomy in App.jsx

The file is organised top-to-bottom in this order:

1. **Hooks** — `useScrollY`, `useInView`, `useParallax`, `useCountUp`
2. **Primitives** — `Reveal` (scroll-triggered fade-in), `SectionTag`, `PhoneFrame`, `Accordion`, `CountUpStat`
3. **Data arrays** — `SPECIES`, `FEATURES_GRID`, `FEATURE_SECTIONS`, `BLOOM_DATA`, `SIGHTING_ENTRIES`, `CRITERIA`, `MATRIX_ROWS`, `OPTIONS`, `IMPL_PHASES`, `COST_ITEMS`, `CONSIDERATIONS`, `RECS`, `REFERENCES`, `GROUP_DECLARATION_DATA`
4. **Animated widgets** — `BloomHeat`, `SightingCascade`, `SyncDash`, `BuildDash`, `PatrolMeshViz`
5. **Page sections** — `Nav`, `Hero`, `ExecSummary`, `Background`, `CriteriaSection`, `OptionsSection`, `SelectionSection`, `FeaturesOverview`, `FeatureSection`, `SpeciesSection`, `OfflineSection`, `CloudSection`, `TechSection`, `ProtoSection`, `ImplSection`, `CostSection`, `ConsiderationsSection`, `RecsSection`, `ReferencesSection`, `ProjectDetails`, `AcknowledgementSection`, `GroupDeclarationSection`, `Footer`
6. **Root `App`** — composes all sections in page order

### Key patterns

- `useInView` wraps `IntersectionObserver` — `repeat: true` makes the widget re-animate each time it re-enters the viewport. Used by all animated widgets and `Reveal`.
- `useParallax` applies scroll-driven `translateY` transforms directly to DOM refs — desktop only (skipped when `(hover: none)` matches).
- `Reveal` is a generic scroll-triggered fade-in wrapper. Use it for any new section content.
- `PhoneFrame` renders either a screenshot `<img>` or a placeholder with icon + label.

### Design tokens (`:root` in App.css)

| Token | Value | Use |
|---|---|---|
| `--green-700` / `--green-200` | #2A5C3F / #96C4A8 | Primary palette |
| `--amber` | #C4692A | Accent, CTAs |
| `--cream` | #F7F3EC | Page background, body text on dark |
| `--ink` | #131F17 | Body text |
| `--font-display` | Gloock, Georgia, serif | Headlines |
| `--font-body` | Epilogue, system-ui | Body text |
| `--font-mono` | SF Mono, Fira Mono, Menlo | Code elements |

### Design Principles
- Minimal formatting — professional, not casual
- Visual-first presentation
- Problem-before-feature framing (establish ranger's situation, then describe what the feature does about it)

### Screenshots

`src/assets/screenshots/*.png` — 11 app screenshots imported at the top of `App.jsx`. Replace a PNG file to update the corresponding phone frame.

---

## Key Constraints

- `vite.config.js` sets `base: '/ewbrangerapp/'` — required for GitHub Pages subdirectory hosting; do not change it.
- All page content stays inline in `App.jsx` — no separate data files or component files.
- All git commands must run from `showcase/`. Do not run `git checkout` inside `ewbrangerapp/` — that directory stays on `demov3`.

---

## Deployment

Push to the `showcase` branch — GitHub Actions builds and deploys to `gh-pages` automatically. Live site updates within ~1 minute.

---

## Referencing Rules

- **Style:** APA 7th edition throughout
- **Minimum sources:** ≥5 total; ≥3 from EWB/lamalama.org; ≥1 external academic source
- CRAP test: Currency, Relevance, Authority, Purpose
- Peer-reviewed journals and academic books preferred
- Self-citation (GitHub repo) valid but does not count toward academic source minimum
- AI prompt log required in appendices — cite Claude use in-text

---

## Key Principles

1. Community consultation is **prerequisite** for AI/tech deployment — not optional
2. In-person training is most effective for tech adoption with rangers
3. Demo vs real functionality must be clearly distinguished in all writing
4. Problem-first framing: describe ranger situation before describing the feature
5. Referencing errors have high grade cost — reference list needs careful final review
6. APA 7th: match in-text citations exactly to reference list entries

---

## Tools & Integrations

| Tool | Purpose |
|------|---------|
| Linear (workspace: "Ilworkspace", prefix ILW-) | Personal task management |
| Trello (Today / This Week / Later) | Shared team board |
| GitHub (`immanuel-lam/ewbrangerapp`) | App repo |
| Google Drive (owned by Marisa) | Shared team folder |
| Canva (MCP) | Presentation design |
| Excalidraw (MCP) | Mindmapping |
| Claude Code | React/website implementation |

---

## Open Questions (as of 10 May 2026)

- [ ] Which HMW statement did the group finalise for the 2b presentation?
- [ ] Verify Acknowledgement of Country wording with team
- [ ] AI prompt log — is it being maintained by all members?
- [ ] Gavin (YAC rep) follow-up session recording — has it been posted?
