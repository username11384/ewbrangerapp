import { useEffect, useRef, useState, useCallback } from 'react'

import imgMap from './assets/screenshots/map.png'
import imgBloom from './assets/screenshots/bloom.png'
import imgLogSighting from './assets/screenshots/log-sighting.png'
import imgBiocontrol from './assets/screenshots/bicontrol.png'
import imgTreatment from './assets/screenshots/treatment.png'
import imgPatrol from './assets/screenshots/patrol.png'
import imgChecklist from './assets/screenshots/checklist.png'
import imgDaySync from './assets/screenshots/day-sync.png'
import imgConflict from './assets/screenshots/conflict.png'
import imgSpeciesGuide from './assets/screenshots/species-guide.png'
import imgHub from './assets/screenshots/hub.png'

// ─── Hooks ────────────────────────────────────────────────────────────────────

function useScrollY() {
  const [y, setY] = useState(0)
  useEffect(() => {
    const handler = () => setY(window.scrollY)
    window.addEventListener('scroll', handler, { passive: true })
    return () => window.removeEventListener('scroll', handler)
  }, [])
  return y
}

function useInView(threshold = 0.15, { repeat = false } = {}) {
  const ref = useRef(null)
  const [visible, setVisible] = useState(false)
  useEffect(() => {
    const el = ref.current
    if (!el) return
    const obs = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setVisible(true)
          if (!repeat) obs.disconnect()
        } else if (repeat) {
          setVisible(false)
        }
      },
      { threshold }
    )
    obs.observe(el)
    return () => obs.disconnect()
  }, [threshold, repeat])
  return [ref, visible]
}

function useParallax(refs, multipliers) {
  useEffect(() => {
    const isTouchOnly = window.matchMedia('(hover: none)').matches
    if (isTouchOnly) return
    let rafId
    const handler = () => {
      rafId = requestAnimationFrame(() => {
        const sy = window.scrollY
        refs.forEach((ref, i) => {
          if (!ref.current) return
          const m = multipliers[i]
          const dy = sy * (m.y || 0)
          const rot = m.rotate ? ` rotate(${m.rotate})` : ''
          ref.current.style.transform = `translateY(${dy}px)${rot}`
        })
      })
    }
    window.addEventListener('scroll', handler, { passive: true })
    return () => { window.removeEventListener('scroll', handler); cancelAnimationFrame(rafId) }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps
}

function useCountUp(target, duration = 800) {
  const [val, setVal] = useState(0)
  const [ref, visible] = useInView(0.3)
  useEffect(() => {
    if (!visible) return
    const start = performance.now()
    const tick = (now) => {
      const p = Math.min((now - start) / duration, 1)
      setVal(Math.round(p * target))
      if (p < 1) requestAnimationFrame(tick)
    }
    requestAnimationFrame(tick)
  }, [visible, target, duration])
  return [ref, val]
}

// ─── Primitives ───────────────────────────────────────────────────────────────

function Reveal({ children, delay = 0, className = '', style = {} }) {
  const [ref, visible] = useInView(0.1)
  return (
    <div
      ref={ref}
      className={`reveal${visible ? ' visible' : ''}${className ? ' ' + className : ''}`}
      style={{ transitionDelay: delay ? `${delay}s` : undefined, ...style }}
    >
      {children}
    </div>
  )
}

function SectionTag({ children }) {
  return (
    <div className="section-tag">
      <span className="section-tag-pip" />
      {children}
    </div>
  )
}

function PhoneFrame({ label, icon, src, tint }) {
  return (
    <div className="phone-frame" style={tint ? { background: tint } : {}}>
      <div className="phone-screen">
        {src
          ? <img src={src} alt={label} />
          : <div className="phone-screen-placeholder">
              <div className="phone-screen-placeholder-icon">{icon}</div>
              {label}
            </div>
        }
      </div>
    </div>
  )
}

function Accordion({ label, children, dark = false }) {
  const [open, setOpen] = useState(false)
  return (
    <div className={`accordion${dark ? ' accordion--dark' : ''}`}>
      <button className="accordion-toggle" onClick={() => setOpen(o => !o)}>
        {open ? 'Hide detail' : 'More detail'}
        <span className={`accordion-chevron${open ? ' accordion-chevron--open' : ''}`}>›</span>
      </button>
      <div className={`accordion-body${open ? ' accordion-body--open' : ''}`}>
        <div className="accordion-body-inner">
          {children}
        </div>
      </div>
    </div>
  )
}

function CountUpStat({ target, suffix = '', label, duration = 900 }) {
  const [ref, val] = useCountUp(target, duration)
  return (
    <div ref={ref} className="exec-stat">
      <div className="exec-stat-num">{val}{suffix}</div>
      <div className="exec-stat-label">{label}</div>
    </div>
  )
}

// ─── Data ─────────────────────────────────────────────────────────────────────

const SPECIES = [
  { name: 'Lantana', scientific: 'Lantana camara', color: '#C4692A', risk: 'Year-round risk', note: 'Biocontrol prompt at point of logging' },
  { name: 'Rubber Vine', scientific: 'Cryptostegia grandiflora', color: '#7A4E2D', risk: 'Aug – Nov peak', note: 'Riparian corridor invader' },
  { name: 'Prickly Acacia', scientific: 'Vachellia nilotica', color: '#5C8A3C', risk: 'May – Aug peak', note: 'Dense thicket formation' },
  { name: 'Sicklepod', scientific: 'Senna obtusifolia', color: '#2A5C3F', risk: 'Apr – Jul peak', note: 'Annual herb, prolific seeder' },
  { name: "Giant Rat's Tail", scientific: 'Sporobolus pyramidalis', color: '#8B6914', risk: 'Mar – May peak', note: 'Outcompetes native pasture' },
  { name: 'Pond Apple', scientific: 'Annona glabra', color: '#3D6B8C', risk: 'Apr – Jun peak', note: 'Wetland and waterway invader' },
]

const FEATURES_GRID = [
  { num: '01', title: 'Interactive Map', body: 'Satellite imagery centred on Port Stewart. Species-coded pins, infestation zone polygons with status overlays, patrol areas, and layer toggles.' },
  { num: '02', title: 'Bloom Calendar', body: 'Monthly risk levels for all 6 species based on Cape York phenology. Prioritise treatments before seed set to prevent dispersal.' },
  { num: '03', title: 'Sighting Log', body: 'GPS-tagged records with species picker, infestation size estimate, photos, and automatic timestamp. Linked to treatment records.' },
  { num: '04', title: 'Treatment Records', body: 'Log treatment method, herbicide product, outcome notes, and follow-up date. Every treatment is linked to its sighting for full site history.' },
  { num: '05', title: 'Patrol Tracking', body: 'Stamina metric with per-item time estimates. Two-tone bar warns at 85% of planned duration so rangers stay on schedule.' },
  { num: '06', title: 'Mesh Sync', body: 'Bluetooth and WiFi peer-to-peer sync via MultipeerConnectivity. Zone conflict resolver for concurrent offline edits.' },
  { num: '07', title: 'Cloud Sync', body: 'Supabase PostgreSQL as primary database, Supabase Storage for photos, S3 as cold backup replica. Syncs when Starlink or WiFi is available at base.' },
  { num: '08', title: 'Ranger Hub', body: 'Shift handover summary, pesticide inventory, zone management, cloud sync status, and settings — one central dashboard.' },
]

const FEATURE_SECTIONS = [
  {
    tag: 'Interactive Map',
    headline: 'The whole picture before you leave the vehicle',
    body: 'Satellite imagery over Port Stewart shows every logged sighting, infestation zone, and patrol area at a glance. The Bloom Calendar overlays monthly flowering and seeding risk for all 6 species — so Rangers know which threats are most active and treat before seed set.',
    highlights: ['Species-coded sighting pins', 'Zone polygon drawing & editing', 'Bloom Calendar: monthly risk by species', 'Layer toggles for sightings, zones & patrols'],
    phones: [{ label: 'Map view', icon: '🗺️', src: imgMap }, { label: 'Bloom Calendar', icon: '🌸', src: imgBloom }],
  },
  {
    tag: 'Sighting Log',
    headline: 'Record what you find, where you find it',
    body: 'GPS-tagged sightings with species picker, infestation size, and photos. When Rangers log Lantana, a biocontrol prompt asks about Aconophora compressa — if the Lantana bug is present, the app recommends delaying foliar spray to protect established biocontrol agents. This reflects documented non-target risk from peer-reviewed literature.',
    highlights: ['Automatic GPS capture', 'Lantana biocontrol safety prompt', 'Photo attachment', 'Infestation size estimate'],
    phones: [{ label: 'Log Sighting', icon: '📍', src: imgLogSighting }, { label: 'Biocontrol prompt', icon: '🦗', src: imgBiocontrol }],
    reversed: true, alt: true,
  },
  {
    tag: 'Treatment Records',
    headline: 'Document the work. Track what happens next.',
    body: 'Log treatment method — foliar spray, cut stump, basal bark, mechanical, stem injection, or fire management — alongside herbicide product, outcome notes, and a scheduled follow-up date. Every treatment is linked to its sighting, building a complete history of each infestation site over time.',
    highlights: ['Foliar spray, cut stump, basal bark, fire', 'Herbicide product and quantity', 'Outcome notes per treatment', 'Scheduled follow-up date'],
    phones: [{ label: 'Treatment Entry', icon: '💊', src: imgTreatment }],
  },
  {
    tag: 'Patrol & Stamina Metric',
    headline: 'Stay on time across the whole area',
    body: 'Start a patrol with a structured pre-departure checklist — each item carries a time estimate. A two-tone stamina bar tracks completed vs remaining time live, raising a warning at 85% of planned duration so Rangers can adjust before running short in the field.',
    highlights: ['Pre-departure checklist', 'Time-estimated items', 'Live stamina progress bar', 'Running-long warning at 85%'],
    phones: [{ label: 'Active Patrol', icon: '🥾', src: imgPatrol }, { label: 'Checklist', icon: '✅', src: imgChecklist }],
    reversed: true, alt: true,
  },
]

const BLOOM_DATA = {
  'Lantana':         [2,2,2,3,3,2,2,2,3,3,3,2],
  'Rubber Vine':     [1,1,1,0,0,0,0,3,3,2,2,1],
  'Prickly Acacia':  [0,0,0,3,3,3,2,1,0,0,0,0],
  'Sicklepod':       [0,0,0,2,3,3,3,2,1,0,0,0],
  "Giant Rat's Tail":[0,0,3,3,2,1,0,0,0,0,0,0],
  'Pond Apple':      [0,0,0,2,2,2,1,0,0,0,0,0],
}
const MONTHS = ['J','F','M','A','M','J','J','A','S','O','N','D']
const BLOOM_COLORS = ['transparent','#ddecd6','#C4692A55','#C4692A']

const SIGHTING_ENTRIES = [
  { species: 'Lantana', color: '#C4692A', coords: '−14.7031° S, 143.7088° E', size: '~3m²', time: '07:42', note: 'Lantana bug observed — delay spray' },
  { species: 'Rubber Vine', color: '#7A4E2D', coords: '−14.7019° S, 143.7102° E', size: '~12m²', time: '08:15', note: 'Dense flowering. Basal bark treatment.' },
  { species: 'Sicklepod', color: '#2A5C3F', coords: '−14.7028° S, 143.7076° E', size: '~8m²', time: '09:51', note: 'Dry season growth. Cut stump.' },
]

const TEAM = [
  { name: 'Immanuel', role: 'Q1 — Economic constraints', detail: 'Labour, materials, funding sources, and stakeholder mapping' },
  { name: 'Essy', role: 'Q2 — Habitats', detail: 'Ecosystem types and priority protection zones across Lama Lama Country' },
  { name: 'Marisa', role: 'Q3 — Species', detail: 'Biology, spread vectors, and control efficacy for all 6 target species' },
  { name: 'Garv', role: 'Q4 — Traditional practices', detail: 'Intersection of traditional burning and stewardship with Integrated Weed Management' },
  { name: 'Jai', role: 'Q5 — Environmental threats', detail: 'Climate-driven spread risk and cumulative habitat pressure' },
  { name: 'Caleb', role: 'Q6 — Ecosystem protection', detail: 'Outcome metrics for long-term biodiversity recovery' },
]

const CRITERIA = [
  { w: '25%', c: 'Connectivity independence', desc: 'Must function fully without mobile data or Wi-Fi at any point', just: 'Port Stewart has no reliable mobile coverage', extended: 'Port Stewart sits approximately 90km from Coen, the nearest town with reliable services. Commercial mobile coverage does not extend to the area. Satellite internet via Starlink is available at the Ranger base but not during field patrols. Any solution requiring a live connection at the point of use is not viable as a primary system.' },
  { w: '20%', c: 'Field usability', desc: 'Usable one-handed in heat; minimal text input; large tap targets', just: 'Rangers work in tropical conditions while managing equipment', extended: 'Rangers patrol on foot in tropical heat, often carrying equipment and tools simultaneously. A sighting log requiring more than 30 seconds of focused attention is unlikely to be used consistently in practice. The app is designed for single-handed use with large tap targets, a species picker (no text entry), and GPS capture that requires zero manual coordinate input.' },
  { w: '15%', c: 'Cultural appropriateness', desc: 'Designed with the Rangers; respects data sovereignty', just: 'YAC and Lama Lama people control their own land data', extended: "Land data belongs to the Lama Lama people and Yintjingga Aboriginal Corporation. YAC's data sovereignty principle means that sighting records, zone boundaries, and patrol histories must remain under YAC control. No data should transit third-party systems without explicit YAC consent. The app stores all records locally on Ranger devices; cloud sync requires deliberate action from the Ranger." },
  { w: '15%', c: 'Workflow alignment', desc: 'Augments existing patrol and treatment practice', just: 'Adoption risk is reduced when the tool fits the workflow', extended: 'Adoption risk is highest when a new tool requires Rangers to change their sequence of work. The app mirrors the existing patrol workflow: pre-departure checklist → sightings logged in field → treatment applied and recorded → return to base and sync. Rangers do not need to learn a new methodology — they log what they were already doing, in the order they were already doing it.' },
  { w: '15%', c: 'Cost and maintenance', desc: 'No ongoing SaaS fees; no server infrastructure required in field', just: 'YAC has limited budget for ongoing technology costs', extended: 'YAC has limited discretionary budget for technology services. Any solution requiring annual subscription fees, server maintenance, or contracted technical support is unsustainable without continuous external funding. The V2 app runs entirely on-device with no infrastructure dependency. Supabase and S3 cloud features are optional and use free-tier pricing sufficient for typical Ranger data volumes.' },
  { w: '10%', c: 'Data utility', desc: 'Produces records usable for reporting and grant applications', just: 'Without usable outputs, data collection has no long-term value', extended: 'Raw sighting data has limited value unless it is structured, attributable, and exportable. The app produces records with GPS coordinates, species identification, date and time, Ranger attribution, treatment method, and outcome notes — the minimum structure required by Working on Country Programme reporting templates and Queensland Land Restoration Fund progress reports.' },
]

const MATRIX_ROWS = [
  { criterion: 'Connectivity independence', weight: 25, paper: 8, app: 10, sms: 2 },
  { criterion: 'Field usability', weight: 20, paper: 5, app: 10, sms: 2 },
  { criterion: 'Cultural appropriateness', weight: 15, paper: 6, app: 8, sms: 5 },
  { criterion: 'Workflow alignment', weight: 15, paper: 5, app: 9, sms: 5 },
  { criterion: 'Cost and maintenance', weight: 15, paper: 9, app: 9, sms: 6 },
  { criterion: 'Data utility', weight: 10, paper: 3, app: 9, sms: 2 },
]

const OPTIONS = [
  {
    title: 'Paper-based forms',
    score: '~56%',
    selected: false,
    pros: ['No device required', 'Zero learning curve', 'Works in any condition'],
    cons: ['Manual transcription burden at base', 'Data loss risk', 'No spatial visualisation', 'No treatment history linkage'],
  },
  {
    title: 'Offline-first mobile app',
    score: '~93%',
    selected: true,
    pros: ['Full offline operation', 'GPS-tagged sightings', 'Peer-to-peer mesh sync', 'Cloud backup via Supabase + S3', 'Species guide in-hand', 'Export for grant reporting'],
    cons: ['Requires device procurement', 'Initial onboarding required'],
  },
  {
    title: 'SMS / USSD reporting',
    score: '~40%',
    selected: false,
    pros: ['Works on basic phones', 'Low data overhead'],
    cons: ['Requires cell signal', 'No map or spatial data', 'No species guide', 'No peer sync', 'Limited reporting output'],
  },
]

const IMPL_PHASES = [
  { phase: 'Phase 1', title: 'Pilot', detail: 'Deploy to 2–3 Rangers on one patrol route. In-person onboarding (~2 hours, no internet needed; demo mode with pre-seeded data). Collect usability feedback on sighting logging, treatment entry, and patrol checklist. Validate Supabase sync over base station Wi-Fi.' },
  { phase: 'Phase 2', title: 'Full Rollout', detail: 'Deploy to all active Rangers. YAC coordinator uses Dashboard and Shift Handover exports for weekly reporting. Cloud sync runs automatically when Rangers return to base. S3 backup validates nightly.' },
  { phase: 'Phase 3', title: 'Iteration & Handover', detail: 'Address pilot feedback. Source code and documentation handed to YAC for long-term ownership. Distribution via AirDrop (iOS) or APK sideload (Android) — no App Store required. All data on-device; Supabase export on demand.' },
]

const COST_ITEMS = [
  { item: 'App development (volunteer/student labour)', cost: '$0 to YAC' },
  { item: 'iOS devices, refurbished iPhone SE (if needed)', cost: '~$200–350 per device' },
  { item: 'Android devices (if needed)', cost: '~$150–300 per device' },
  { item: 'Apple Developer Program (if App Store needed)', cost: '~$150/year' },
  { item: 'Supabase (free tier — up to 500 MB DB, 1 GB storage)', cost: '$0' },
  { item: 'Supabase Pro (if data exceeds free tier)', cost: '~$40 AUD/month' },
  { item: 'S3 backup storage (cold)', cost: '~$3–8 AUD/month' },
  { item: 'Ongoing server infrastructure', cost: '$0 (V2 fully offline)' },
]

const CONSIDERATIONS = [
  { title: 'Data Sovereignty', body: 'All data stored locally on Ranger devices. Supabase and S3 sync only on demand. No telemetry, no third-party analytics, no cloud dependency in the field. YAC retains full ownership of all land data.' },
  { title: 'Traditional Management', body: 'Fire management is included as a treatment method alongside foliar spray, cut stump, and mechanical options. The Bloom Calendar draws on Cape York seasonal ecological knowledge. Garv\'s research (Q4) maps the intersection of traditional burning practices with Integrated Weed Management.' },
  { title: 'Cultural Appropriateness', body: 'App scope built around Rangers\' actual patrol workflows and the species present at Port Stewart. EWB conducted yarns, workshops, and one-on-one interviews with YAC. Interface in English (working language of Rangers), with architecture supporting future localisation.' },
  { title: 'Workflow Alignment', body: 'The app augments — not replaces — existing patrol practice. Sighting logging takes under 30 seconds. The pre-departure checklist mirrors current manual practice. Rangers do not need to change how they patrol; the app fits into the same sequence.' },
  { title: 'Long-term Maintenance', body: 'No external infrastructure dependency in V2. App updates delivered by developer via AirDrop (iOS) or APK sideload (Android). Source code and documentation handed to YAC for long-term ownership. No App Store account required for internal distribution.' },
  { title: 'Recommendations', body: 'Conduct a co-design session with Rangers before finalising UI ahead of Phase 1 deployment. Validate Supabase sync cadence against base station connectivity patterns. Explore Android companion app for Rangers using non-iOS devices under the Working on Country programme.' },
]

const RECS = [
  { num: '01', title: 'Co-design session before Phase 1 deployment', body: 'Conduct a structured co-design session with active Rangers before finalising the user interface. Specific elements to validate include the pre-departure checklist items, infestation size descriptors, and patrol area boundaries defined in PortStewartZones. The app was designed around EWB context data and should be adjusted to match actual Ranger practice before live use.' },
  { num: '02', title: 'Integrate Shift Handover into the weekly reporting cycle', body: 'The structured text export from Hub → Handover maps directly to the species-and-area summaries required for Working on Country Programme progress reports. YAC coordinators should build this export into their weekly workflow from the first day of deployment — establishing the reporting habit before the data volume grows.' },
  { num: '03', title: 'Plan the Android companion in parallel with the iOS pilot', body: 'Several Rangers may be using Android devices under their existing programme device allocation. The Android companion (Jetpack Compose, Room, Google Nearby Connections) implements the same architecture and mesh sync protocol as the iOS build and can be distributed via APK sideload without an app store account. Development should begin during Phase 1, not after.' },
  { num: '04', title: 'Review Supabase storage allocation at three months', body: 'The free tier provides 500 MB database and 1 GB storage. A typical deployment with six Rangers logging two sightings with photos per patrol day will consume approximately 120–160 MB per month. The free tier is sufficient for six to eight months of full operation, after which the Pro tier (~$40 AUD/month) becomes necessary. Budget for this from the outset.' },
]

const REFERENCES = [
  'Broughton, S. (2000). Review of the biology and host range of Aconophora compressa (Walker). Biological Control of Lantana in Australia. CSIRO Entomology.',
  'Csurhes, S., & Edwards, R. (1998). Potential environmental weeds in Australia: Candidate species for preventative control. Environment Australia.',
  'Flanagan, G. J., & Zalucki, M. P. (2003). Lantana: Current management status and future prospects. Australian Centre for International Agricultural Research.',
  'Queensland Department of Primary Industries. (n.d.). Lantana biological control. QLD DPI. [VERIFY: publication date]',
  'Yintjingga Aboriginal Corporation. (n.d.). Lama Lama Country. lamalama.org. [Retrieved from EWB/Partner/Canvas]',
  'Engineers Without Borders Australia. (2026). EWB Challenge 2026 Design Brief — Design Area 5.5: Invasive Plant Management. EWB Australia.',
  '[Insert individual Task 1b sources, EWB Design Brief citation, and any additional sources used in the written document.]',
]

// ─── Animated widgets ─────────────────────────────────────────────────────────

function BloomHeat() {
  const [ref, visible] = useInView(0.15, { repeat: true })
  const [count, setCount] = useState(0)

  useEffect(() => {
    if (!visible) { setCount(0); return }
    let i = 0
    const id = setInterval(() => {
      i++
      setCount(i)
      if (i >= 72) clearInterval(id)
    }, 18)
    return () => clearInterval(id)
  }, [visible])

  const species = Object.keys(BLOOM_DATA)
  const legendLabels = ['–', 'Low', 'Moderate', 'HIGH']

  return (
    <div className="bloom-heat" ref={ref}>
      <div className="bloom-heat-header">
        <span className="bloom-heat-title">Bloom risk calendar — Cape York</span>
        <div className="bloom-heat-legend">
          {[1,2,3].map(i => (
            <span key={i} className="bloom-legend-item">
              <span className="bloom-legend-swatch" style={{ background: BLOOM_COLORS[i] }} />
              {legendLabels[i]}
            </span>
          ))}
        </div>
      </div>
      <div className="bloom-grid">
        <div className="bloom-species-col">
          <div className="bloom-month-row" />
          {species.map(sp => (
            <div key={sp} className="bloom-species-name">{sp}</div>
          ))}
        </div>
        <div className="bloom-cells-col">
          <div className="bloom-month-row">
            {MONTHS.map(m => <div key={m} className="bloom-month-label">{m}</div>)}
          </div>
          {species.map((sp, si) => (
            <div key={sp} className="bloom-row">
              {BLOOM_DATA[sp].map((level, mi) => {
                const cellIdx = si * 12 + mi
                const lit = count > cellIdx
                return (
                  <div
                    key={mi}
                    className="bloom-cell"
                    style={{ background: lit ? BLOOM_COLORS[level] : 'transparent' }}
                    title={`${sp} — ${['–','Low','Moderate','HIGH'][level]}`}
                  />
                )
              })}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

function SightingCascade() {
  const [ref, visible] = useInView(0.3, { repeat: true })
  const [shown, setShown] = useState([])

  useEffect(() => {
    if (!visible) { setShown([]); return }
    let i = 0
    const id = setInterval(() => {
      if (i < SIGHTING_ENTRIES.length) {
        const entry = SIGHTING_ENTRIES[i]
        setShown(p => [...p, entry])
        i++
      } else {
        clearInterval(id)
      }
    }, 700)
    return () => clearInterval(id)
  }, [visible])

  const done = shown.length === SIGHTING_ENTRIES.length

  return (
    <div className="sighting-cascade" ref={ref}>
      <div className="sighting-cascade-header">
        <span className="sc-title">Today's Sightings</span>
        <span className={`sc-sync-badge${done ? ' sc-sync-badge--done' : ''}`}>
          {done ? '✓ synced' : 'logging…'}
        </span>
      </div>
      <div className="sc-entries">
        {shown.length === 0
          ? <div className="sc-idle">— waiting for entries —</div>
          : shown.map((e, i) => (
            <div key={i} className="sc-entry" style={{ animationDelay: `${i * 0.05}s` }}>
              <div className="sc-species-dot" style={{ background: e.color }} />
              <div className="sc-entry-body">
                <div className="sc-entry-top">
                  <span className="sc-species-name">{e.species}</span>
                  <span className="sc-size">{e.size}</span>
                  <span className="sc-time">{e.time}</span>
                </div>
                <div className="sc-coords">{e.coords}</div>
                <div className="sc-note">{e.note}</div>
              </div>
            </div>
          ))
        }
      </div>
    </div>
  )
}

function SyncDash() {
  const [ref, visible] = useInView(0.2, { repeat: true })
  const [stage, setStage] = useState(0)
  const [progress, setProgress] = useState(0)
  const [recordCount, setRecordCount] = useState(0)
  const [speed, setSpeed] = useState(null)
  const [key, setKey] = useState(0)

  const replay = useCallback(() => {
    setStage(0); setProgress(0); setRecordCount(0); setSpeed(null); setKey(k => k + 1)
  }, [])

  useEffect(() => {
    if (!visible) { replay(); return }
  }, [visible]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (!visible) return
    const timeline = [
      { t: 400, fn: () => setStage(1) },
      { t: 1200, fn: () => setStage(2) },
    ]
    const ids = timeline.map(({ t, fn }) => setTimeout(fn, t))
    return () => ids.forEach(clearTimeout)
  }, [visible, key])

  useEffect(() => {
    if (stage < 2) return
    let prog = 0
    let recs = 0
    const id = setInterval(() => {
      prog = Math.min(prog + Math.random() * 3.5, 100)
      recs = Math.round(prog * 0.87)
      const spd = (2 + Math.random() * 12).toFixed(1)
      setProgress(prog)
      setRecordCount(recs)
      setSpeed(prog >= 100 ? null : spd)
      if (prog >= 100) { clearInterval(id); setStage(3) }
    }, 80)
    return () => clearInterval(id)
  }, [stage, key])

  const status = stage === 0 ? 'idle' : (stage >= 3 && progress >= 100) ? 'done' : 'active'
  const statusLabel = { idle: 'Idle', active: 'Syncing…', done: 'Complete' }[status]

  return (
    <div className="sync-dash" ref={ref}>
      <div className="sync-dash-header">
        <span className="sync-dash-label">Cloud Sync Dashboard</span>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span className={`sync-status-badge sync-status-badge--${status}`}>
            <span className="sync-status-dot" />
            {statusLabel}
          </span>
          {stage > 0 && (
            <button className="sync-replay-btn" onClick={replay}>↺ replay</button>
          )}
        </div>
      </div>

      {/* Device node */}
      <div className={`snode${stage >= 1 ? ' snode--device-on' : ''}`}>
        <span className="snode-icon">📱</span>
        <div className="snode-info">
          <div className="snode-title">Ranger Devices</div>
          <div className="snode-sub">3 devices · CoreData offline store</div>
        </div>
        <span className={`snode-pill${stage >= 1 ? ' snode-pill--green' : ''}`}>
          {stage >= 1 ? 'Online' : 'Offline'}
        </span>
      </div>

      {/* Connection line: device → supabase */}
      <div className="sconn">
        <div className={`sconn-line${stage >= 2 ? ' sconn-line--active' : ''}`}>
          {stage >= 2 && [0, 0.35, 0.7].map((d, i) => (
            <div key={i} className="fdot fdot--on" style={{ '--fd': `${d}s` }} />
          ))}
        </div>
        <span className="sconn-label">Starlink / base station Wi-Fi</span>
      </div>

      {/* Supabase node */}
      <div className={`snode${stage >= 2 ? ' snode--supa-on' : ''}`}>
        <span className="snode-icon">🗄️</span>
        <div className="snode-info">
          <div className="snode-title">Supabase</div>
          <div className="snode-sub">PostgreSQL + Storage</div>
        </div>
        {stage >= 2 && (
          <div className="snode-live">
            <div className="snode-live-count">
              <span className="snode-live-num">{recordCount}</span>
              <span className="snode-live-unit">rec</span>
            </div>
            {speed && <div className="snode-live-speed">{speed} MB/s</div>}
            {!speed && stage >= 3 && <div className="snode-live-speed snode-live-speed--done">✓ done</div>}
          </div>
        )}
      </div>

      {/* Connection line: supabase → S3 */}
      <div className="sconn">
        <div className={`sconn-line sconn-line--s3${stage >= 3 ? ' sconn-line--active' : ''}`}>
          {stage >= 3 && [0, 0.55, 1.1].map((d, i) => (
            <div key={i} className="fdot fdot--s3 fdot--on" style={{ '--fd': `${d}s` }} />
          ))}
        </div>
        <span className="sconn-label">Cold backup replica</span>
      </div>

      {/* S3 node */}
      <div className={`snode${stage >= 3 ? ' snode--s3-on' : ''}`}>
        <span className="snode-icon">🪣</span>
        <div className="snode-info">
          <div className="snode-title">Amazon S3</div>
          <div className="snode-sub">Cold backup + pg_dump archive</div>
        </div>
        <span className={`snode-pill${stage >= 3 ? ' snode-pill--amber' : ''}`}>
          {stage >= 3 ? 'Replicated' : 'Standby'}
        </span>
      </div>

      {/* Progress bar */}
      {stage >= 2 && (
        <div className="sync-prog">
          <div className="sync-prog-track">
            <div className="sync-prog-fill" style={{ width: `${progress}%` }} />
          </div>
          <div className="sync-prog-meta">
            <span>{Math.round(progress)}%</span>
            <span>{recordCount} / 87 records</span>
          </div>
        </div>
      )}
    </div>
  )
}

function BuildDash() {
  const [ref, visible] = useInView(0.2, { repeat: true })
  const [lines, setLines] = useState([])
  const [progWidth, setProgWidth] = useState(0)
  const [done, setDone] = useState(false)
  const [running, setRunning] = useState(false)
  const [key, setKey] = useState(0)

  const buildLines = [
    { ts: '00:00', type: 'compile', text: 'Compiling MeshSyncEngine.swift…', file: 'MeshSyncEngine.swift' },
    { ts: '00:01', type: 'compile', text: 'Compiling SightingRepository.swift…', file: 'SightingRepository.swift' },
    { ts: '00:02', type: 'compile', text: 'Compiling BloomCalendarView.swift…', file: 'BloomCalendarView.swift' },
    { ts: '00:03', type: 'compile', text: 'Compiling SafetyCheckInViewModel.swift…', file: 'SafetyCheckInViewModel.swift' },
    { ts: '00:04', type: 'compile', text: 'Compiling DemoSeeder.swift…', file: 'DemoSeeder.swift' },
    { ts: '00:05', type: 'compile', text: 'Linking ewbapp…' },
    { ts: '00:06', type: 'success', text: '✓ Build Succeeded — 0 errors · 0 warnings' },
  ]

  const replay = useCallback(() => {
    setLines([]); setProgWidth(0); setDone(false); setRunning(false); setKey(k => k + 1)
  }, [])

  useEffect(() => {
    if (!visible) { replay(); return }
    setRunning(true)
  }, [visible]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (!running) return
    buildLines.forEach((line, i) => {
      const t1 = setTimeout(() => {
        setLines(p => [...p, line])
        setProgWidth(Math.round(((i + 1) / buildLines.length) * 100))
      }, i * 480)
      const t2 = setTimeout(() => setDone(true), buildLines.length * 480 + 200)
      return () => { clearTimeout(t1); clearTimeout(t2) }
    })
  }, [running, key]) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div className="build-dash" ref={ref}>
      <div className={`build-header${done ? ' build-header--success' : ''}`}>
        <div className="build-scheme">
          <span className="build-scheme-icon">▶</span>
          <span>ewbapp</span>
          <span className="build-scheme-sep">›</span>
          <span className="build-scheme-target">iPhone 17 Pro Simulator</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div className={`build-status-indicator${running && !done ? ' build-status-indicator--running' : ''}`}
            style={done ? { background: '#34c759' } : {}} />
          {done && <button className="build-replay-btn" onClick={replay}>↺</button>}
        </div>
      </div>
      <div className="build-progress-track">
        <div className="build-progress-fill" style={{ width: `${progWidth}%` }} />
      </div>
      <div className="build-log">
        {lines.length === 0 && !running && (
          <div className="build-log-idle">— click to build —</div>
        )}
        {lines.map((line, i) => (
          <div key={i} className={`build-log-line build-log-line--${line.type}`}
            style={{ animationDelay: `${i * 0.04}s` }}>
            <span className="blog-ts">{line.ts}</span>
            {line.type === 'success' && <span className="blog-tick">✓</span>}
            {line.file
              ? <><span className="build-log-line--compile">Compiling </span><span className="blog-file">{line.file}</span></>
              : <span>{line.text}</span>
            }
          </div>
        ))}
      </div>
    </div>
  )
}

function PatrolMeshViz() {
  const [ref, visible] = useInView(0.3)
  return (
    <div ref={ref} className="patrol-mesh-viz">
      <div className="pmv-panel">
        <div className="pmv-label">GPS patrol track</div>
        <svg className="pmv-svg" viewBox="0 0 280 200">
          <ellipse cx="140" cy="100" rx="110" ry="70" fill="none" stroke="#96C4A8" strokeWidth="0.8" opacity="0.3" />
          {visible && (
            <path d="M80,60 Q120,40 160,55 Q200,70 210,100 Q220,130 180,150 Q140,165 100,150 Q60,135 70,100 Q72,85 80,60"
              fill="none" stroke="#96C4A8" strokeWidth="2" strokeDasharray="80" strokeDashoffset="80"
              style={{ animation: 'drawPath 2s var(--ease-out) forwards' }} />
          )}
          <circle cx="80" cy="60" r="5" fill="#C4692A" opacity={visible ? 1 : 0} style={{ transition: 'opacity .4s .5s' }} />
          <circle cx="160" cy="55" r="4" fill="#96C4A8" opacity={visible ? 1 : 0} style={{ transition: 'opacity .4s .9s' }} />
          <circle cx="210" cy="100" r="4" fill="#96C4A8" opacity={visible ? 1 : 0} style={{ transition: 'opacity .4s 1.3s' }} />
        </svg>
        {visible && <div className="pmv-trail-done">patrol complete ✓</div>}
      </div>
      <div className="pmv-panel">
        <div className="pmv-label">Mesh peers</div>
        <svg className="pmv-svg" viewBox="0 0 280 200">
          <circle cx="140" cy="60" r="14" fill="#2A5C3F" opacity="0.8" />
          <text x="140" y="65" textAnchor="middle" fontSize="10" fill="#96C4A8">A</text>
          <circle cx="70" cy="150" r="14" fill="#2A5C3F" opacity="0.8" />
          <text x="70" y="155" textAnchor="middle" fontSize="10" fill="#96C4A8">B</text>
          <circle cx="210" cy="150" r="14" fill="#2A5C3F" opacity="0.8" />
          <text x="210" y="155" textAnchor="middle" fontSize="10" fill="#96C4A8">C</text>
          {visible && <>
            <line x1="140" y1="74" x2="70" y2="136" stroke="#96C4A8" strokeWidth="1.5" strokeDasharray="100"
              style={{ animation: 'meshLineIn .8s var(--ease-out) .3s forwards', opacity: 0 }} />
            <line x1="140" y1="74" x2="210" y2="136" stroke="#96C4A8" strokeWidth="1.5" strokeDasharray="100"
              style={{ animation: 'meshLineIn .8s var(--ease-out) .6s forwards', opacity: 0 }} />
            <line x1="84" y1="150" x2="196" y2="150" stroke="#96C4A8" strokeWidth="1.5" strokeDasharray="100"
              style={{ animation: 'meshLineIn .8s var(--ease-out) .9s forwards', opacity: 0 }} />
          </>}
        </svg>
        <div className="pmv-peer-count" style={{ opacity: visible ? 1 : 0, transition: 'opacity .4s 1.2s' }}>
          3 peers connected
        </div>
      </div>
    </div>
  )
}

// ─── Page sections ────────────────────────────────────────────────────────────

function Nav({ scrollY }) {
  return (
    <nav className={`nav${scrollY > 40 ? ' nav--scrolled' : ''}`}>
      <a href="#" className="nav-logo">
        Lama Lama Rangers<span className="nav-logo-dot">.</span>
      </a>
      <ul className="nav-links">
        <li><a href="#background">Background</a></li>
        <li><a href="#design">Design</a></li>
        <li><a href="#features">Features</a></li>
        <li><a href="#sync">Sync</a></li>
        <li><a href="#implementation">Implementation</a></li>
      </ul>
    </nav>
  )
}

function Hero() {
  const topoRef = useRef(null)
  const watermarkRef = useRef(null)
  const phone1Ref = useRef(null)
  const phone2Ref = useRef(null)
  useParallax(
    [topoRef, watermarkRef, phone1Ref, phone2Ref],
    [{ y: 0.08 }, { y: 0.05 }, { y: -0.05, rotate: '4deg' }, { y: -0.03, rotate: '-3deg' }]
  )

  return (
    <section className="hero topo-bg">
      <div className="hero-topo" ref={topoRef} />
      <div className="hero-watermark" ref={watermarkRef}>RANGERS</div>
      <span className="topo-coords topo-coords--tl">Port Stewart · QLD</span>
      <span className="topo-coords topo-coords--br">143°42′27″ E</span>
      <div className="hero-inner">
        <div>
          <div className="hero-eyebrow">
            <span className="hero-eyebrow-pip" />
            Yintjingga Aboriginal Corporation · Cape York
          </div>
          <h1 className="hero-headline">
            <span className="hero-headline-intro">Protecting</span>
            <span className="hero-headline-em">Country.</span>
          </h1>
          <p className="hero-body">
            An offline-first iOS field app for Lama Lama Rangers to log invasive plant sightings, coordinate treatment, sync records peer-to-peer, and back up to cloud — all without internet.
          </p>
          <div className="hero-cta">
            <a href="#features" className="btn btn-amber">Read the report</a>
            <a href="https://github.com/immanuel-lam/ewbrangerapp/tree/demov2"
              className="btn btn-outline" target="_blank" rel="noreferrer">
              View on GitHub
            </a>
          </div>
          <div className="hero-meta">
            <span>31265 Communications for IT Professionals · UTS Autumn 2026</span>
            <span className="hero-meta-divider" />
            <span>EWB Challenge · Design Area 5.5</span>
          </div>
        </div>
        <div className="hero-phones">
          <div className="hero-phone-wrap hero-phone-wrap--1">
            <div className="hero-phone" ref={phone1Ref}>
              <PhoneFrame label="Map view" icon="🗺️" src={imgMap} tint="#1A3828" />
            </div>
          </div>
          <div className="hero-phone-wrap hero-phone-wrap--2">
            <div className="hero-phone" ref={phone2Ref}>
              <PhoneFrame label="Hub" icon="🏠" src={imgHub} tint="#2A5C3F" />
            </div>
          </div>
        </div>
      </div>
      <div className="hero-scroll">
        <div className="hero-scroll-arrow" />
        scroll
      </div>
    </section>
  )
}

function ExecSummary() {
  return (
    <section className="exec-summary">
      <div className="container">
        <div className="exec-inner">
          <Reveal>
            <SectionTag>Executive Summary</SectionTag>
            <h2 className="section-headline">A digital system built around how Rangers already work</h2>
            <p className="exec-body">
              The Lama Lama Rangers of Yintjingga Aboriginal Corporation (YAC) patrol invasive plant infestations across Lama Lama Country on Cape York Peninsula, Queensland. Six species — <em>Lantana camara</em>, Rubber Vine, Prickly Acacia, Sicklepod, Giant Rat's Tail Grass, and Pond Apple — are actively managed on foot, without reliable mobile coverage.
            </p>
            <p className="exec-body">
              This report presents an offline-first iOS app built to the EWB Challenge 2026 brief. The app runs on CoreData with peer-to-peer mesh sync via MultipeerConnectivity and optional Supabase + S3 cloud backup. It addresses all six design criteria and was selected over paper-based forms and SMS reporting by a weighted decision matrix scoring 93%.
            </p>
            <div className="hmw-block" style={{ marginTop: 32 }}>
              <div className="hmw-label">How Might We</div>
              <blockquote className="hmw-quote">
                "How might we support the Lama Lama Rangers in systematically monitoring and managing invasive plant species across Lama Lama Country, in a way that works fully offline, respects data sovereignty, and fits their existing patrol workflow?"
              </blockquote>
            </div>
          </Reveal>
          <div className="exec-stats">
            <CountUpStat target={6} label="invasive species targeted" duration={900} />
            <CountUpStat target={0} label="bars of signal needed in field" duration={600} />
            <CountUpStat target={93} suffix="%" label="weighted decision matrix score" duration={1000} />
          </div>
        </div>
      </div>
    </section>
  )
}

function Background() {
  return (
    <section className="background-section" id="background">
      <div className="container">
        <div className="background-inner">
          <Reveal>
            <SectionTag>Background</SectionTag>
            <h2 className="section-headline">Port Stewart, Cape York Peninsula</h2>
            <p className="context-para">
              Port Stewart sits at −14.7019°, 143.7075° on Cape York Peninsula — one of Australia's most ecologically significant landscapes, managed by the Lama Lama people for generations. Today, six invasive species are spreading across open woodland, creek margins, and wetland systems.
            </p>
            <p className="context-para">
              <em>Lantana camara</em> is a Class 3 declared weed under Queensland legislation and listed under the <em>Environment Protection and Biodiversity Conservation Act 1999</em>. <em>Aconophora compressa</em> (the Lantana bug) is established in parts of Port Stewart, but carries documented non-target species risks — a nuance the app explicitly captures at point of logging.
            </p>
            <p className="context-para" style={{ marginTop: 16 }}>
              Lama Lama Country encompasses a range of vegetation communities — coastal lowland rainforest, open savanna woodland, melaleuca wetlands, and riparian corridors. Each community hosts a different invasive species profile. Lantana dominates disturbed woodland edges; Rubber Vine targets the riparian corridor; Pond Apple invades wetland margins.
            </p>
            <p className="context-para">
              Effective management requires species-specific treatment matched to vegetation type — a level of precision that paper-based recording cannot support. The app produces GPS-tagged, species-attributed records at the infestation site, enabling Rangers to track whether treatment is working, identify re-infestation patterns, and prioritise effort toward high-risk areas.
            </p>
          </Reveal>
          <Reveal delay={0.15} className="species-sidebar">
            {SPECIES.map(sp => (
              <div key={sp.name} className="species-row">
                <div className="species-row-dot" style={{ background: sp.color }} />
                <div>
                  <div className="species-row-name">{sp.name}</div>
                  <div className="species-row-sci">{sp.scientific}</div>
                </div>
                <div className="species-row-risk">{sp.risk}</div>
              </div>
            ))}
          </Reveal>
        </div>
      </div>
    </section>
  )
}

function TeamSection() {
  return (
    <section className="team-section">
      <div className="container">
        <Reveal>
          <SectionTag>The Team</SectionTag>
          <h2 className="section-headline">Six research streams. One solution.</h2>
        </Reveal>
        <div className="team-grid" style={{ marginTop: 48 }}>
          {TEAM.map((m, i) => (
            <Reveal key={m.name} delay={0.07 * (i % 3)}>
              <div className="team-card">
                <div className="team-initial">{m.name[0]}</div>
                <div className="team-name">{m.name}</div>
                <div className="team-role">{m.role}</div>
                <div className="team-detail">{m.detail}</div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}

function CriteriaSection() {
  return (
    <section className="criteria-section" id="design">
      <div className="container">
        <Reveal>
          <SectionTag>Design Criteria</SectionTag>
          <h2 className="section-headline">Six weighted criteria shaped the design.</h2>
          <p className="section-body" style={{ marginBottom: 0 }}>
            Each criterion was derived from the EWB context data and weighted against the constraints of remote field work at Port Stewart.
          </p>
        </Reveal>
        <div className="criteria-grid">
          {CRITERIA.map((c, i) => (
            <Reveal key={c.c} delay={0.07 * (i % 3)}>
              <div className="criteria-card">
                <div className="criteria-weight">{c.w}</div>
                <div className="criteria-title">{c.c}</div>
                <div className="criteria-desc">{c.desc}</div>
                <div className="criteria-just">{c.just}</div>
                <Accordion label="More detail">
                  <p className="accordion-para">{c.extended}</p>
                </Accordion>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}

function OptionsSection() {
  return (
    <section className="options-section">
      <div className="container">
        <Reveal>
          <SectionTag>Solution Options</SectionTag>
          <h2 className="section-headline">Three options evaluated.</h2>
          <p className="section-body" style={{ marginBottom: 48 }}>
            Paper-based forms, offline-first mobile app, and SMS/USSD reporting were assessed against the six criteria.
          </p>
        </Reveal>
        <div className="options-grid">
          {OPTIONS.map((opt, i) => (
            <Reveal key={opt.title} delay={i * 0.1}>
              <div className={`option-card${opt.selected ? ' option-card--selected' : ''}`}>
                {opt.selected && <span className="option-selected-badge">Selected</span>}
                <div className="option-score">{opt.score}</div>
                <div className="option-title">{opt.title}</div>
                <div className="option-pros">
                  {opt.pros.map(p => (
                    <div key={p} className="option-point">
                      <span className="option-point-dot option-point-dot--pro" />
                      {p}
                    </div>
                  ))}
                </div>
                <div className="option-cons">
                  {opt.cons.map(c => (
                    <div key={c} className="option-point">
                      <span className="option-point-dot option-point-dot--con" />
                      {c}
                    </div>
                  ))}
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}

function SelectionSection() {
  const totals = { paper: 0, app: 0, sms: 0 }
  MATRIX_ROWS.forEach(r => {
    totals.paper += r.paper * r.weight / 100
    totals.app   += r.app   * r.weight / 100
    totals.sms   += r.sms   * r.weight / 100
  })

  return (
    <section className="selection-section">
      <div className="container">
        <div className="selection-intro-grid">
          <Reveal className="selection-intro-left">
            <SectionTag>Decision Matrix</SectionTag>
            <h2 className="section-headline">The offline-first mobile app scored 93%.</h2>
          </Reveal>
          <Reveal delay={0.1} className="selection-intro-right">
            <p className="section-body" style={{ marginBottom: 0 }}>
              The offline-first mobile app was selected on the basis of its 93% weighted decision matrix score and its demonstrated superiority on the two highest-weighted criteria: connectivity independence and field usability — both requirements that cannot be met by any solution requiring mobile signal, which is unavailable at Port Stewart.
            </p>
          </Reveal>
        </div>
        <Reveal delay={0.15}>
          <div className="matrix-wrap">
            <table className="matrix-table">
              <thead>
                <tr>
                  <th className="matrix-th matrix-th--criterion">Criterion</th>
                  <th className="matrix-th matrix-th--weight">Weight</th>
                  <th className="matrix-th">Paper</th>
                  <th className="matrix-th matrix-th--selected">Mobile App ✓</th>
                  <th className="matrix-th">SMS</th>
                </tr>
              </thead>
              <tbody>
                {MATRIX_ROWS.map((row, i) => (
                  <tr key={row.criterion} className="matrix-row">
                    <td className="matrix-td matrix-td--criterion">{row.criterion}</td>
                    <td className="matrix-td matrix-td--weight">{row.weight}%</td>
                    <td className="matrix-td"><span className="matrix-score">{row.paper}/10</span></td>
                    <td className="matrix-td matrix-td--selected"><span className="matrix-score matrix-score--selected">{row.app}/10</span></td>
                    <td className="matrix-td"><span className="matrix-score">{row.sms}/10</span></td>
                  </tr>
                ))}
                <tr className="matrix-total-row">
                  <td className="matrix-td matrix-td--criterion" style={{ fontWeight: 700 }}>Weighted Total</td>
                  <td className="matrix-td matrix-td--weight">100%</td>
                  <td className="matrix-td"><span className="matrix-score matrix-score--total">{(totals.paper).toFixed(1)}</span></td>
                  <td className="matrix-td matrix-td--selected"><span className="matrix-score matrix-score--selected matrix-score--total">{(totals.app).toFixed(1)}</span></td>
                  <td className="matrix-td"><span className="matrix-score matrix-score--total">{(totals.sms).toFixed(1)}</span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </Reveal>
      </div>
    </section>
  )
}

function FeaturesOverview() {
  return (
    <section className="features-overview" id="features">
      <div className="container">
        <Reveal className="features-overview-header">
          <SectionTag>Feature Set</SectionTag>
          <h2 className="section-headline section-headline--cream section-headline--xl">
            Eight features.<br />One field app.
          </h2>
          <p className="section-body section-body--cream">
            Every feature addresses a specific field constraint. Nothing is included for novelty.
          </p>
        </Reveal>
        <div className="features-grid">
          {FEATURES_GRID.map((f, i) => (
            <Reveal key={f.num} delay={0.05 * i}>
              <div className="feature-cell">
                <span className="feature-cell-num">{f.num}</span>
                <div className="feature-cell-title">{f.title}</div>
                <div className="feature-cell-body">{f.body}</div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}

function FeatureSection({ tag, headline, body, highlights, phones, reversed, alt }) {
  return (
    <section className={`feature-section${alt ? ' feature-section--alt' : ''}`}>
      <div className="container">
        <div className={`feature-section-inner${reversed ? ' feature-section-inner--reversed' : ''}`}>
          <Reveal>
            <SectionTag>{tag}</SectionTag>
            <h2 className="section-headline">{headline}</h2>
            <p className="section-body">{body}</p>
            <div className="feature-highlights">
              {highlights.map(h => (
                <div key={h} className="feature-highlight">
                  <span className="feature-highlight-dot" />
                  {h}
                </div>
              ))}
            </div>
          </Reveal>
          <Reveal delay={0.1}>
            {phones.length === 1
              ? <div className="phone-column">
                  <div className="phone-solo">
                    <PhoneFrame {...phones[0]} />
                  </div>
                </div>
              : <div className="phone-column phone-column--stacked">
                  {phones.map(p => <PhoneFrame key={p.label} {...p} />)}
                </div>
            }
          </Reveal>
        </div>
      </div>
    </section>
  )
}

function SpeciesSection() {
  return (
    <section className="species-section" id="species">
      <div className="container">
        <Reveal>
          <SectionTag>Species Guide</SectionTag>
          <h2 className="section-headline">Six invasive plants.<br />One coordinated response.</h2>
          <p className="section-body" style={{ marginBottom: 0 }}>
            The app carries a full identification guide for all six species. The Bloom Calendar tracks all six — so Rangers always know what is most active.
          </p>
        </Reveal>
        <div className="species-grid">
          {SPECIES.map((sp, i) => (
            <Reveal key={sp.name} delay={0.07 * (i % 3)}>
              <div className="species-card">
                <div className="species-dot" style={{ background: sp.color }} />
                <div className="species-name">{sp.name}</div>
                <div className="species-scientific">{sp.scientific}</div>
                <span className="species-risk">{sp.risk}</span>
              </div>
            </Reveal>
          ))}
        </div>
        <Reveal delay={0.1}>
          <BloomHeat />
        </Reveal>
      </div>
    </section>
  )
}

function OfflineSection() {
  const offlineFeatures = [
    { title: 'Bluetooth + WiFi Mesh Sync', desc: 'MultipeerConnectivity peer-to-peer sync between devices. Rangers share records at end of day — no base station required.' },
    { title: 'Zone Conflict Resolver', desc: 'When two Rangers edit the same zone boundary offline, the app prompts Keep Mine / Keep Theirs / Merge instead of silently overwriting.' },
    { title: 'Shift Handover Export', desc: 'End-of-shift summary from live CoreData: today\'s sightings, species breakdown, patrol duration, pesticide usage, open tasks. Exports as shareable text.' },
    { title: 'GPS Fallback', desc: 'Location service times out gracefully to Port Stewart coordinates (-14.7019, 143.7075) when no GPS fix is available — no blank maps in the field.' },
  ]

  return (
    <section className="offline-section" id="sync">
      <div className="offline-section-bg" />
      <div className="container">
        <div className="offline-inner">
          <Reveal>
            <SectionTag>Offline First</SectionTag>
            <h2 className="section-headline section-headline--cream">
              Cape York has zero mobile coverage.
            </h2>
            <p className="section-body section-body--cream">
              Every feature works entirely offline. When Rangers regroup at the end of the day, records sync peer-to-peer via Bluetooth and Wi-Fi — no internet needed.
            </p>
            <div className="offline-features">
              {offlineFeatures.map((f, i) => (
                <div key={f.title} className="offline-feature">
                  <div className="offline-feature-num">0{i + 1}</div>
                  <div>
                    <div className="offline-feature-title">{f.title}</div>
                    <div className="offline-feature-desc">{f.desc}</div>
                  </div>
                </div>
              ))}
            </div>
          </Reveal>
          <Reveal delay={0.15}>
            <div className="offline-right-col">
              <div className="offline-phones">
                <PhoneFrame label="Day Sync" icon="📡" src={imgDaySync} tint="#1A3828" />
                <PhoneFrame label="Conflict Resolver" icon="🔀" src={imgConflict} tint="#2A5C3F" />
              </div>
              <PatrolMeshViz />
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  )
}

function CloudSection() {
  return (
    <section className="cloud-section">
      <div className="container">
        <div className="cloud-inner">
          <Reveal>
            <SectionTag>Cloud Sync</SectionTag>
            <h2 className="section-headline">When Rangers return to base.</h2>
            <p className="section-body">
              When Rangers return to base — where Starlink or station Wi-Fi is available — the app automatically pushes all local CoreData records to Supabase. No manual export. No action required from the Ranger.
            </p>
            <p className="section-body" style={{ marginTop: 16 }}>
              S3 acts as a cold backup replica — giving YAC a resilient, independently accessible archive for reporting and grant applications.
            </p>
            <div className="feature-highlights" style={{ marginTop: 32 }}>
              {['Automatic sync on reconnect', 'Supabase PostgreSQL + Storage', 'S3 cold backup replica', 'Jittery Starlink speed? No problem.'].map(h => (
                <div key={h} className="feature-highlight"><span className="feature-highlight-dot" />{h}</div>
              ))}
            </div>
          </Reveal>
          <Reveal delay={0.15}>
            <SyncDash />
          </Reveal>
        </div>
      </div>
    </section>
  )
}

function TechSection() {
  return (
    <section className="tech-section">
      <div className="container">
        <div className="tech-inner">
          <Reveal>
            <div className="tech-label">Built with native iOS. No dependencies.</div>
            <div className="tech-pills" style={{ marginTop: 16 }}>
              {['Swift', 'SwiftUI', 'CoreData', 'MapKit', 'MultipeerConnectivity', 'AVFoundation', 'Supabase', 'Amazon S3'].map(t => (
                <span key={t} className="tech-pill">{t}</span>
              ))}
            </div>
          </Reveal>
          <Reveal delay={0.1}>
            <div className="tech-arch">
              <div className="tech-arch-node tech-arch-node--primary" style={{ marginBottom: 0 }}>SwiftUI Views</div>
              <div className="tech-arch-arrow" />
              <div className="tech-arch-node tech-arch-node--secondary">ViewModels (@MainActor)</div>
              <div className="tech-arch-arrow" />
              <div className="tech-arch-node">Repositories</div>
              <div className="tech-arch-arrow" />
              <div className="tech-arch-node">PersistenceController (NSPersistentContainer)</div>
            </div>
            <p className="tech-note">
              MVVM + Repository. <code>backgroundContext</code> for all writes; <code>mainContext</code> for UI reads only.
              <code>PBXFileSystemSynchronizedRootGroup</code> auto-includes all Swift files — no manual Xcode project edits.
            </p>
          </Reveal>
        </div>
      </div>
    </section>
  )
}

function ProtoSection() {
  const findings = [
    { feat: 'GPS capture', text: 'All testers successfully captured a GPS coordinate without instruction. 8-second timeout to Port Stewart fallback was universally unnoticed.' },
    { feat: 'Lantana Biocontrol Prompt', text: 'Correctly surfaces Aconophora compressa risk at point of logging.' },
    { feat: 'Zone Conflict Resolver', text: 'Keep / Merge interface resolved test conflicts without data loss in all 3 test runs.' },
    { feat: 'Treatment prioritisation', text: 'Bloom Calendar enabled correct treatment prioritisation by Cape York context.' },
    { feat: 'Supabase Cloud Sync', text: 'Automatic sync confirmed over base station Wi-Fi; S3 snapshot validated.' },
  ]
  const specs = [
    { label: 'Platform', value: 'iOS 26.2+ (Swift 5, SwiftUI)' },
    { label: 'Build target', value: 'iPhone 17 Pro Simulator' },
    { label: 'Demo PIN', value: '1234 — Alice, Bob, Carol' },
    { label: 'Demo data', value: '28 sightings, 6 zones, 10 patrols' },
    { label: 'GPS spoof', value: 'Settings → Developer → Spoof Location' },
  ]

  return (
    <section className="proto-section">
      <div className="container">
        <Reveal>
          <SectionTag>Prototype</SectionTag>
          <h2 className="section-headline">Xcode build. Simulator ready.</h2>
        </Reveal>
        <div className="proto-inner">
          <div>
            <BuildDash />
            <div className="proto-findings">
              <div className="proto-findings-label">Validated behaviours</div>
              {findings.map(f => (
                <div key={f.feat} className="proto-finding">
                  <div className="proto-finding-feat">{f.feat}</div>
                  <div className="proto-finding-text">{f.text}</div>
                </div>
              ))}
            </div>
          </div>
          <Reveal delay={0.1}>
            <div className="proto-specs">
              {specs.map(s => (
                <div key={s.label} className="spec-block">
                  <div className="spec-label">{s.label}</div>
                  <div className="spec-value">{s.value}</div>
                </div>
              ))}
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  )
}

function ImplSection() {
  return (
    <section className="impl-section" id="implementation">
      <div className="container">
        <Reveal>
          <SectionTag>Implementation Plan</SectionTag>
          <h2 className="section-headline">Three phases to full deployment.</h2>
          <p className="section-body" style={{ marginBottom: 48 }}>
            Staged rollout minimises risk and builds the reporting habit before data volume grows.
          </p>
        </Reveal>
        <Reveal delay={0.1}>
          <div className="impl-phases">
            {IMPL_PHASES.map((p, i) => (
              <div key={p.phase} className="impl-phase">
                <div className="impl-phase-num">{String(i + 1).padStart(2, '0')}</div>
                <div>
                  <div className="impl-phase-label">{p.phase}</div>
                  <div className="impl-phase-title">{p.title}</div>
                  <div className="impl-phase-detail">{p.detail}</div>
                </div>
              </div>
            ))}
          </div>
          <div className="impl-note">
            <strong>No App Store required.</strong> Distribution via AirDrop (iOS) or APK sideload (Android). YAC retains full source code and documentation at handover.
          </div>
          <div className="impl-note impl-note--airdrop" style={{ marginTop: 12 }}>
            The demo build can be installed on any iPhone by opening the <code>.ipa</code> via AirDrop — no developer account, no TestFlight, no internet required at the point of installation.
          </div>
        </Reveal>
      </div>
    </section>
  )
}

function CostSection() {
  return (
    <section className="cost-section">
      <div className="container">
        <Reveal>
          <SectionTag>Cost Estimate</SectionTag>
          <h2 className="section-headline">Viable on a Rangers Programme budget.</h2>
          <p className="section-body" style={{ marginBottom: 48 }}>
            If devices are funded under existing Working on Country or Rangers Programme budgets, YAC's deployment cost is effectively $0. Cloud infrastructure costs are minimal — Supabase free tier handles typical Ranger data volumes for 6–8 months.
          </p>
        </Reveal>
        <Reveal delay={0.1}>
          <div className="cost-table-wrap">
            <table className="cost-table">
              <thead>
                <tr>
                  <th>Item</th>
                  <th>Estimated Cost</th>
                </tr>
              </thead>
              <tbody>
                {COST_ITEMS.map(item => (
                  <tr key={item.item}>
                    <td>{item.item}</td>
                    <td className="cost-value">{item.cost}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="cost-funding">
            <strong>Funding pathways:</strong> Government Working on Country / Rangers Programme · Queensland Land Restoration Fund · DAFF National Landcare Programme · Natural Heritage Trust (NHT)
          </p>
        </Reveal>
      </div>
    </section>
  )
}

function ConsiderationsSection() {
  return (
    <section className="considerations-section">
      <div className="container">
        <Reveal>
          <SectionTag>Other Considerations</SectionTag>
          <h2 className="section-headline">Designed with, not for.</h2>
        </Reveal>
        <div className="considerations-grid">
          {CONSIDERATIONS.map((c, i) => (
            <Reveal key={c.title} delay={0.07 * (i % 3)}>
              <div className="consideration-card">
                <div className="consideration-title">{c.title}</div>
                <div className="consideration-body">{c.body}</div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}

function RecsSection() {
  return (
    <section className="recs-section">
      <div className="container">
        <Reveal>
          <SectionTag>Recommendations</SectionTag>
          <h2 className="section-headline">Four actions ahead of deployment.</h2>
          <p className="section-body" style={{ marginBottom: 56 }}>
            The following recommendations are directed to YAC leadership and Rangers Programme management. Each addresses a specific risk or dependency identified during prototyping that must be resolved before Phase 1.
          </p>
        </Reveal>
        <div className="recs-list">
          {RECS.map((r, i) => (
            <Reveal key={r.num} delay={0.08 * i} className="rec-item">
              <div className="rec-num">{r.num}</div>
              <div className="rec-content">
                <div className="rec-title">{r.title}</div>
                <div className="rec-body">{r.body}</div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}

function ReferencesSection() {
  return (
    <section className="references-section">
      <div className="container">
        <Reveal>
          <SectionTag>References</SectionTag>
          <h2 className="section-headline" style={{ marginBottom: 40 }}>APA 7th edition</h2>
        </Reveal>
        <Reveal delay={0.1}>
          <ol className="references-list">
            {REFERENCES.map((ref, i) => (
              <li key={i} className="reference-item">{ref}</li>
            ))}
          </ol>
          <p className="references-note">
            [Note: some references require publication date verification. All sources retrieved from EWB partner materials, Canvas, or public domain unless otherwise indicated.]
          </p>
        </Reveal>
      </div>
    </section>
  )
}

function Footer() {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-divider" />
        <div className="footer-inner">
          <div>
            <div className="footer-logo">
              Lama Lama Rangers<span style={{ color: 'var(--amber)' }}>.</span>
            </div>
            <p className="footer-tagline">
              Invasive plants field app for Yintjingga Aboriginal Corporation,<br />
              Port Stewart, Cape York Peninsula, QLD.
            </p>
          </div>
          <div className="footer-right">
            <a href="https://github.com/immanuel-lam/ewbrangerapp" className="footer-link"
              target="_blank" rel="noreferrer">GitHub →</a>
            <a href="https://immanuel-lam.github.io/ewbrangerapp/" className="footer-link"
              target="_blank" rel="noreferrer">Live Site →</a>
            <div className="footer-credit">
              EWB Challenge 2026 · Design Area 5.5<br />
              31265 Communications for IT Professionals · UTS<br />
              <span style={{ fontSize: '.72rem', color: '#f7f3ec33' }}>
                Built with Swift · SwiftUI · CoreData · MapKit · MultipeerConnectivity · Supabase · Amazon S3
              </span>
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}

// ─── App ──────────────────────────────────────────────────────────────────────

export default function App() {
  const scrollY = useScrollY()

  return (
    <>
      <Nav scrollY={scrollY} />
      <Hero />
      <ExecSummary />
      <Background />
      <TeamSection />
      <CriteriaSection />
      <OptionsSection />
      <SelectionSection />
      <FeaturesOverview />
      {FEATURE_SECTIONS.map((fs, i) => (
        <div key={fs.tag}>
          <FeatureSection {...fs} />
          {i === 1 && (
            <section className="sighting-cascade-section">
              <div className="container">
                <Reveal>
                  <SightingCascade />
                </Reveal>
              </div>
            </section>
          )}
        </div>
      ))}
      <SpeciesSection />
      <OfflineSection />
      <CloudSection />
      <TechSection />
      <ProtoSection />
      <ImplSection />
      <CostSection />
      <ConsiderationsSection />
      <RecsSection />
      <ReferencesSection />
      <Footer />
    </>
  )
}
