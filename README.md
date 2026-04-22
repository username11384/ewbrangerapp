# Lama Lama Rangers — Invasive Plants Field App

An iOS field application built for the Lama Lama Rangers of Yintjingga Aboriginal Corporation (YAC), Cape York Peninsula, Queensland. Built as part of **31265 Communications for IT Professionals — EWB Challenge 2026**.

---

## Overview

Invasive plants including Lantana camara, Rubber Vine, Prickly Acacia, Sicklepod, Giant Rat's Tail Grass, and Pond Apple threaten Lama Lama Country. This app gives rangers the tools to log sightings, coordinate treatment, track patrol coverage, and sync records across the team — all without a reliable internet connection.

---

## Features

### Map
- Satellite and standard map views centred on Port Stewart
- Sighting pins colour-coded by invasive species
- Infestation zone polygons with status overlays (active / under treatment / cleared)
- Patrol area markers
- Layer toggles for sightings, zones, and patrols
- **Bloom Calendar** — seasonal flowering/seeding risk overlay for all 6 species by month, helping rangers prioritise treatments before seed set

### Sighting Log
- Log new sightings with GPS capture, species picker, infestation size, and photos
- Full sighting history with ranger name, relative timestamp, and sync status
- Sighting detail with linked treatment records
- **Lantana Biocontrol Prompt** — when logging a Lantana sighting, rangers are asked if *Aconophora compressa* (Lantana bug) is present; if observed, a warning recommends delaying foliar spray to protect biocontrol

### Treatment Records
- Log treatment method (foliar spray, cut stump, basal bark, mechanical, stem injection, fire management), herbicide product, outcome notes, and optional follow-up date
- **Before/After Photo Comparison** — attach "after" photos to a treatment record; a comparison card in the sighting detail shows the before/after side-by-side

### Patrol
- Start a patrol with a checklist of pre-departure tasks
- **Stamina Metric** — each checklist item has a time estimate; a two-tone bar tracks completed vs remaining time, with a warning at 85% of planned time
- Record patrol area, duration, and notes
- Calendar view of past patrols

### Species Guide
- Reference cards for all 6 invasive plant species
- Identification features, recommended control methods, and seasonal notes
- Promoted to a dedicated tab for quick field access

### Pesticide Inventory
- Track stock levels for herbicide products
- Log usage against treatment records
- Low-stock alerts when quantity falls below threshold

### Tasks
- Assign follow-up tasks to rangers with priority levels and due dates
- Task list filtered by the logged-in ranger

### Hub
- Central dashboard with tiles for: Dashboard, Supplies, Day Sync, Zones, Cloud Sync, Handover, Settings
- **Shift Handover Card** — end-of-shift summary showing today's sightings (with species breakdown and untreated count), patrol duration and checklist completion, pesticide usage, open/overdue tasks, and sync status; exports a shareable text report

### Day Sync (Mesh)
- Peer-to-peer Bluetooth/WiFi sync between ranger devices via MultipeerConnectivity
- No internet required — designed for remote field conditions
- **Zone Conflict Resolver** — when two rangers edit the same zone boundary offline, prompts to Keep Mine / Keep Theirs / Merge instead of silently overwriting (LWW disabled for zone boundaries)

### Cloud Sync (Demo — V3 Preview)
- Fake V3 sync dashboard showing Supabase DB + Storage as primary and S3 as cold backup replica
- Live CoreData counts per database table; DB snapshot (pg_dump) export simulation
- Starlink-style jittery upload speed display (2–14 MB/s)

### Dashboard
- Sightings per month stacked by species (colour-matched bar chart)
- Zone status breakdown
- Sightings by ranger
- Open follow-up tasks and treatments this month

---

## Project Structure

```
ewbapp/
├── CoreData/               # NSManagedObject subclasses + PersistenceController
├── Models/
│   ├── Domain/             # PatrolChecklistItem (with timeEstimateMins), SeasonalAlert
│   ├── DTOs/               # Data transfer objects for repository layer
│   └── Enums/              # InvasiveSpecies, TreatmentMethod, InfestationSize, SyncStatus
├── Repositories/           # CoreData read/write abstraction per entity
├── Services/
│   ├── Auth/               # PIN-based authentication + Keychain storage
│   ├── Location/           # CLLocationManager wrapper with accuracy levels
│   └── Sync/               # SyncEngine, MeshSyncEngine (MultipeerConnectivity), ConflictResolver
├── ViewModels/             # ObservableObject VMs per screen
├── Views/
│   ├── App/                # ContentView, MainTabView
│   ├── Activity/           # ActivityView (Sightings/Patrols/Tasks segments)
│   ├── Dashboard/
│   ├── Guide/              # SpeciesGuideView, SpeciesDetailView
│   ├── Hub/                # HubView, ShiftHandoverView, ConflictResolverView
│   ├── Login/              # LoginView, PINEntryView
│   ├── Map/                # MapView, MapContainerView, BloomCalendarView, zone drawing
│   ├── Patrol/
│   ├── Pesticide/
│   ├── Settings/
│   ├── Sighting/
│   └── Tasks/
├── Resources/              # PortStewartZones, InvasiveSpeciesContent, static data
└── Demo/                   # Demo branch: DemoSeeder, DemoMeshSyncView, DemoLiveSyncView
```

---

## Branches

| Branch | Purpose |
|---|---|
| `main` | Production build — starts clean, real GPS, real peer sync |
| `demonewui` | Demo build — multi-species, new design system, pre-seeded data, all demo features |
| `demov3` | Extended demo — all of `demonewui` plus 12 new features (see below) |
| `v1-poc` | Original proof-of-concept (archived) |

---

## Requirements

- Xcode 17+
- iOS 26.2+ target
- No third-party dependencies — Swift + SwiftUI + CoreData + MapKit + MultipeerConnectivity only

---

## demov3 Features

The `demov3` branch adds 12 features on top of the `demonewui` base:

| # | Feature | Entry point |
|---|---|---|
| 1 | **Safety Check-In** | Safety tab → countdown timer, "I'm Safe" button |
| 2 | **Hazard Logger** | Hub → Hazards tile → Log Hazard |
| 3 | **Voice Notes** | Log Sighting → voice recorder field |
| 4 | **Photo Size Estimation** | Log Sighting → size estimation overlay |
| 5 | **Phenology Alerts** | Log Sighting → contextual alert banner per species + window |
| 6 | **Herbicide Checker** | Treatment Entry → "Check herbicide" button |
| 7 | **Treatment Effectiveness** | Sighting Detail → Record Follow-Up |
| 8 | **Per-Area Patrol Checklists** | Patrol → checklist toolbar button |
| 9 | **Pesticide Stock Alerts** | Dashboard → alert banner; Hub → Supplies |
| 10 | **Equipment Maintenance Log** | Hub → Equipment tile |
| 11 | **Ranger Status Broadcast** | Day Sync → ranger status list |
| 12 | **Night Mode (Red Light)** | Settings → Display → Theme |

### New CoreData entities in demov3

- `Equipment` — tracked equipment with service dates and maintenance history
- `MaintenanceRecord` — individual service events linked to an `Equipment`
- `SafetyCheckIn` — persisted check-in sessions for the Safety tab
- `HazardLog` — GPS-tagged hazard records with type, severity, and photo

---

## Running the Demo Build

1. Checkout the `demov3` branch (or `demonewui` for the base feature set)
2. Build and run on a simulator or device
3. Log in as any ranger (PIN: `1234` for all demo accounts)
4. Data is pre-seeded on first launch — 6 zones, 28 sightings across 6 species, 10 patrols, pesticide stocks, and tasks
5. To reset data: Settings → Reset App Data

### Key demo flows (core)
- **Map → Bloom button** — seasonal invasive species risk calendar
- **Log Sighting → select Lantana** — shows biocontrol prompt
- **Sighting Detail → Add Treatment → attach after photos → view detail** — before/after comparison card
- **Hub → Day Sync → run sync → Zone Conflicts** — conflict resolver demo
- **Hub → Handover** — shift summary with live CoreData counts
- **Hub → Cloud Sync** — fake Supabase + S3 sync with Starlink speed simulation
- **Patrol → Start → checklist** — time estimates and stamina bar

### Key demo flows (demov3 additions)
- **Safety tab** — set a check-in interval, "I'm Safe" button resets countdown
- **Log Sighting → microphone icon** — record and play back a voice note
- **Log Sighting → size icon** — drag overlay rectangle to estimate infestation area
- **Log Sighting → any species in season** — phenology alert banner fires automatically
- **Treatment Entry → "Check herbicide"** — herbicide/species/method compatibility check
- **Sighting Detail → Record Follow-Up** — log regrowth level against an earlier treatment
- **Hub → Equipment** — add equipment, log maintenance, see overdue items highlighted
- **Hub → Hazards** — log a GPS hazard with severity and type
- **Day Sync screen** — ranger status list broadcast over mesh
- **Settings → Display → Theme** — switch to Red Light mode for night vision

### GPS Spoofing (Demo)
Settings → Developer → Spoof Location — pick any zone or patrol area centroid to simulate being on-site at Port Stewart without leaving your desk.

---

## Academic Context

This app was developed for the **EWB Challenge 2026** as part of unit **31265 Communications for IT Professionals** at UTS. The EWB (Engineers Without Borders) Challenge pairs university students with community organisations to address real development needs.

**Partner organisation:** Yintjingga Aboriginal Corporation (YAC), Port Stewart, Cape York Peninsula, QLD
**Problem domain:** Invasive plant management on Lama Lama Country
