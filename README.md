# Lama Lama Rangers — Lantana Control Field App

An iOS field application built for the Lama Lama Rangers of Yintjingga Aboriginal Corporation (YAC), Cape York Peninsula, Queensland. Built as part of **31265 Communications for IT Professionals — EWB Challenge 2026**.

---

## Overview

Lantana camara is one of the most invasive weeds in Australia. This app gives Lama Lama Rangers the tools to log sightings, coordinate treatment, track patrol coverage, and sync records across the team — all without a reliable internet connection.

---

## Features

### Map
- Satellite and standard map views centred on Port Stewart
- Sighting pins colour-coded by Lantana variant
- Infestation zone polygons with status overlays (active / under treatment / cleared)
- Patrol area markers
- Layer toggles for sightings, zones, and patrols

### Sighting Log
- Log new sightings with GPS capture, variant picker, infestation size, and up to 3 photos
- Full sighting history with ranger name, relative timestamp, and sync status
- Sighting detail with linked treatment records

### Treatment Records
- Log treatment method (cut stump, splat gun, foliar spray, basal bark), herbicide product, outcome notes, and optional follow-up date
- Treatment history linked to individual sightings

### Patrol
- Start a patrol with a checklist of pre-departure tasks
- Record patrol area, duration, and notes
- Calendar view of past patrols

### Variant Guide
- Reference cards for all six Lantana camara variants found in the region
- Identifying features, recommended control methods with instructions, and seasonal notes
- Biocontrol warning banner for pink Lantana during the wet season (Nov–Mar)

### Pesticide Inventory
- Track stock levels for herbicide products
- Log usage against treatment records
- Low-stock alerts when quantity falls below threshold

### Tasks
- Assign follow-up tasks to rangers with priority levels and due dates
- Task list filtered by the logged-in ranger

### Mesh Sync (End of Day Sync)
- Peer-to-peer Bluetooth/WiFi sync between ranger devices via MultipeerConnectivity
- No internet required — designed for remote field conditions
- Conflict resolution for records edited on multiple devices

### Dashboard
- Sightings per month by variant (colour-matched line chart)
- Zone status breakdown
- Sightings by ranger
- Open follow-up tasks and treatments this month

---

## Project Structure

```
ewbapp/
├── CoreData/               # NSManagedObject subclasses + PersistenceController
├── Models/
│   ├── DTOs/               # Data transfer objects for repository layer
│   └── Enums/              # LantanaVariant, TreatmentMethod, InfestationSize, SyncStatus
├── Repositories/           # CoreData read/write abstraction per entity
├── Services/
│   ├── Auth/               # PIN-based authentication + Keychain storage
│   ├── Location/           # CLLocationManager wrapper with accuracy levels
│   └── Sync/               # SyncEngine, MeshSyncEngine (MultipeerConnectivity), ConflictResolver
├── ViewModels/             # ObservableObject VMs per screen
├── Views/
│   ├── App/                # ContentView, MainTabView, MoreView
│   ├── Dashboard/
│   ├── Guide/              # VariantGuideView, VariantDetailView
│   ├── Login/              # LoginView, PINEntryView
│   ├── Map/                # MapView (MKMapView wrapper), MapContainerView, zone drawing
│   ├── Patrol/
│   ├── Pesticide/
│   ├── Settings/
│   ├── Sighting/
│   └── Tasks/
├── Resources/              # PortStewartZones, LantanaVariantContent, static data
└── Demo/                   # Demo branch only: DemoSeeder, DemoMeshSyncView, DeveloperSettings
```

---

## Branches

| Branch | Purpose |
|---|---|
| `main` | Production build — starts clean, real GPS, real peer sync |
| `demo` | Demo build — pre-seeded with realistic data, fake mesh sync animation, GPS spoof in Developer settings |
| `v1-poc` | Original proof-of-concept (archived) |

---

## Requirements

- Xcode 16+
- iOS 18+ target
- No third-party dependencies — Swift + SwiftUI + CoreData + MapKit + MultipeerConnectivity only

---

## Running the Demo Build

1. Checkout the `demo` branch
2. Build and run on a simulator or device
3. Log in as any ranger (PIN: `1234` for all demo accounts)
4. Data is pre-seeded on first launch — 6 zones, 28 sightings, 10 patrols, pesticide stocks, and tasks
5. To reset data: Settings → Reset App Data

### GPS Spoofing (Demo)
Settings → Developer → Spoof Location — pick any zone or patrol area centroid to simulate being on-site at Port Stewart without leaving your desk.

---

## Academic Context

This app was developed for the **EWB Challenge 2026** as part of unit **31265 Communications for IT Professionals** at UTS. The EWB (Engineers Without Borders) Challenge pairs university students with community organisations to address real development needs.

**Partner organisation:** Yintjingga Aboriginal Corporation (YAC), Port Stewart, Cape York Peninsula, QLD
**Problem domain:** Lantana camara weed management on Lama Lama Country
