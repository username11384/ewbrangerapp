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

function PhoneFrame({ label, icon, src }) {
  return (
    <div className="phone-frame">
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

function FigurePlaceholder({ num, caption, src }) {
  return (
    <figure style={{ margin: '32px 0' }}>
      {src
        ? <img src={src} alt={caption} style={{ width: '100%', borderRadius: 'var(--r-lg)', display: 'block' }} />
        : <div style={{
            background: 'var(--cream-dark)',
            border: '1px dashed var(--divider)',
            borderRadius: 'var(--r-lg)',
            padding: '40px 24px',
            textAlign: 'center',
            color: 'var(--ink-muted)',
            fontSize: '.82rem',
            minHeight: 120,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}>
            [Figure {num} — image to be added]
          </div>
      }
      <figcaption className="fig-caption" style={{ marginTop: 10 }}>
        <strong>Figure {num}.</strong> {caption}
      </figcaption>
    </figure>
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
  { name: 'Sicklepod', scientific: 'Senna obtusifolia', color: '#0077B6', risk: 'Apr – Jul peak', note: 'Annual herb, prolific seeder' },
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
    phones: [{ label: 'Map view', src: imgMap }, { label: 'Bloom Calendar', src: imgBloom }],
    figStart: 1,
  },
  {
    tag: 'Sighting Log',
    headline: 'Record what you find, where you find it',
    body: 'GPS-tagged sightings with species picker, infestation size, and photos. When Rangers log Lantana, a biocontrol prompt asks about Aconophora compressa — if the Lantana bug is present, the app recommends delaying foliar spray to protect established biocontrol agents. This reflects documented non-target risk from peer-reviewed literature.',
    highlights: ['Automatic GPS capture', 'Lantana biocontrol safety prompt', 'Photo attachment', 'Infestation size estimate'],
    phones: [{ label: 'Log Sighting', src: imgLogSighting }, { label: 'Biocontrol prompt', src: imgBiocontrol }],
    reversed: true, alt: true,
    figStart: 3,
  },
  {
    tag: 'Treatment Records',
    headline: 'Document the work. Track what happens next.',
    body: 'Log treatment method — foliar spray, cut stump, basal bark, mechanical, stem injection, or fire management — alongside herbicide product, outcome notes, and a scheduled follow-up date. Every treatment is linked to its sighting, building a complete history of each infestation site over time.',
    highlights: ['Foliar spray, cut stump, basal bark, fire', 'Herbicide product and quantity', 'Outcome notes per treatment', 'Scheduled follow-up date'],
    phones: [{ label: 'Treatment Entry', src: imgTreatment }],
    figStart: 5,
  },
  {
    tag: 'Patrol & Stamina Metric',
    headline: 'Stay on time across the whole area',
    body: 'Start a patrol with a structured pre-departure checklist — each item carries a time estimate. A two-tone stamina bar tracks completed vs remaining time live, raising a warning at 85% of planned duration so Rangers can adjust before running short in the field.',
    highlights: ['Pre-departure checklist', 'Time-estimated items', 'Live stamina progress bar', 'Running-long warning at 85%'],
    phones: [{ label: 'Active Patrol', src: imgPatrol }, { label: 'Checklist', src: imgChecklist }],
    reversed: true, alt: true,
    figStart: 6,
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
const BLOOM_COLORS = ['transparent','#ADE8F4','#0096C755','#0077B6']

const SIGHTING_ENTRIES = [
  { species: 'Lantana', color: '#C4692A', coords: '−14.7031° S, 143.7088° E', size: '~3m²', time: '07:42', note: 'Lantana bug observed — delay spray' },
  { species: 'Rubber Vine', color: '#7A4E2D', coords: '−14.7019° S, 143.7102° E', size: '~12m²', time: '08:15', note: 'Dense flowering. Basal bark treatment.' },
  { species: 'Sicklepod', color: '#0077B6', coords: '−14.7028° S, 143.7076° E', size: '~8m²', time: '09:51', note: 'Dry season growth. Cut stump.' },
]

const CRITERIA = [
  { w: '25%', c: 'Offline-first architecture', desc: 'All data stored on-device; app functions completely without internet; peer-to-peer Bluetooth sync between devices', just: 'Starlink access is restricted to the ranger office — no mobile network coverage exists during field operations', extended: 'This is the non-negotiable baseline. Starlink is available at the ranger office only, and there is no mobile network coverage during field operations. A cloud-dependent system cannot function in this environment. Any feature that requires connectivity — however occasionally — is unavailable to a ranger in the field and cannot be relied upon.' },
  { w: '20%', c: 'Integrated field workflow', desc: 'A ranger completes a full sighting record — GPS, photo, species, treatment, notes — in a single screen without switching apps or referring to paper', just: 'Rangers work in physically demanding tropical conditions and carry equipment simultaneously', extended: 'Rangers patrol on foot in tropical heat, often carrying tools and equipment simultaneously. A sighting record requiring more than 30 seconds of focused attention is unlikely to be completed consistently in practice. Fragmented workflows — switching between apps or devices to capture GPS, photo, and notes separately — raise recording time and reduce adoption (Jayawardena, 2024).' },
  { w: '20%', c: 'Shared data visibility', desc: 'All ranger records aggregate into a shared map view, colour-coded by species and treatment status, visible to the whole team', just: 'Individual sighting records have limited management value without a team-wide view of infestation patterns across the land', extended: 'Individual sighting records have limited management value unless the team can see the broader pattern of infestation across the land. Without a shared view, the same areas may be treated twice while others go unmonitored. The current paper-based system produces records that are not accessible to the whole team in real time.' },
  { w: '15%', c: 'Cost-effectiveness & scalability', desc: 'Runs on existing ranger devices with minimal ongoing infrastructure cost; scales to cover the full Lama Lama land mass without per-seat fees', just: 'Ranger programs operate on grant funding cycles — ongoing licensing or cloud costs create sustainability risk', extended: 'Ranger programs operate on grant funding that can change between cycles. Ongoing licensing or cloud costs create sustainability risk (GRDC, 2025). The ~$166 annual software cost is fundable through existing ranger program operational budgets without requiring a separate grant application.' },
  { w: '10%', c: 'Cultural appropriateness', desc: 'Rangers control what is recorded, how it is used, and who has access; complements Indigenous ecological knowledge rather than replacing it', just: 'The Lama Lama Rangers are custodians of their Country — data sovereignty belongs to the community, not the app developer', extended: "The Lama Lama Rangers are custodians of their Country. A system that only values GPS coordinates and species counts risks sidelining the knowledge and practices that make their land management effective (Aboriginal Cultural Landscape Management, 2025; ORIC, n.d.). Voice memo support allows rangers to record observations in language." },
  { w: '10%', c: 'Ease of use', desc: 'Learnable quickly and usable confidently in the field with minimal technical training; accessible to rangers with varying technology experience', just: 'Rangers have varying technology experience — a tool that is confusing in the field will not be adopted regardless of its capabilities', extended: 'Rangers have varying technology experience. If the tool is confusing or inconsistent in the field, it will not be adopted regardless of its technical capabilities (Jayawardena, 2024). The prototype was designed for in-person training, with a two-day workshop as the primary onboarding mechanism.' },
]

const MATRIX_ROWS = [
  { criterion: 'Offline-first architecture', weight: 25, paper: 4, cyber: 3, app: 5 },
  { criterion: 'Integrated field workflow', weight: 20, paper: 1, cyber: 2, app: 5 },
  { criterion: 'Shared data visibility', weight: 20, paper: 1, cyber: 2, app: 5 },
  { criterion: 'Cost-effectiveness & scalability', weight: 15, paper: 4, cyber: 2, app: 5 },
  { criterion: 'Cultural appropriateness', weight: 10, paper: 3, cyber: 2, app: 5 },
  { criterion: 'Ease of use', weight: 10, paper: 4, cyber: 3, app: 4 },
]
const MATRIX_TOTALS = { paper: 2.65, cyber: 2.35, app: 4.90 }

const OPTIONS = [
  {
    title: 'Option 1 — Enhanced Paper-Based System',
    score: '2.65/5',
    selected: false,
    pros: ['No device required', 'Zero learning curve', 'Works in any conditions'],
    cons: ['Cannot share records between rangers in the field', 'Separate GPS device required', 'Digitisation delays data availability', 'Does not enable early detection at scale'],
  },
  {
    title: 'Option 2 — Adaptation of CyberTracker',
    score: '2.35/5',
    selected: false,
    pros: ['Offline data collection', 'Established track record in ranger programs', 'Open-source platform'],
    cons: ['No peer-to-peer sync without internet', 'No treatment decision support or herbicide compatibility', 'No biocontrol prompts', 'Configuration effort for six-species seasonal overlays'],
  },
  {
    title: 'Option 3 — Purpose-Built Offline-First App',
    score: '4.90/5',
    selected: true,
    pros: ['Full offline operation', 'GPS-tagged sightings with peer-to-peer mesh sync', 'Species-specific decision support and biocontrol prompts', 'Open-source codebase — community owns the tool'],
    cons: ['Greatest upfront design and development effort', 'Requires ranger onboarding'],
  },
]

const IMPL_PHASES = [
  { phase: '8.1', title: 'Installation and Community Training', detail: 'The iOS application is distributed via Apple TestFlight — no App Store approval required. An Android APK is distributed directly to Android devices. A two-day in-person training workshop during the 2026 dry season (May–July) covers the core logging workflow, map navigation, Bluetooth mesh sync, and safety features. In-person, hands-on training is the most effective model for technology adoption in remote community contexts (Centre for Appropriate Technology, n.d.). Rangers with greater technical confidence act as peer trainers for future onboarding of new team members.' },
  { phase: '8.2', title: 'Rollout and Ongoing Use', detail: 'Following training, rangers use the application across active patrol seasons. Bug reports and feedback are collected via the ranger office Starlink. The shift handover card — which generates a plain-text summary of patrol activity from live CoreData records — provides a daily data quality check. The Hub dashboard gives ranger coordinators a team-wide view of sighting trends and coverage gaps.' },
  { phase: '8.3', title: 'Evaluation', detail: 'Success is measured across three dimensions: adoption rate (proportion of patrols with digital records logged), data completeness (proportion of sightings with GPS, photo, species, and treatment fields complete), and sync reliability (proportion of field records successfully shared between devices via Bluetooth mesh). Adoption and completeness are reviewed monthly by the ranger coordinator; sync reliability is assessed via the Hub dashboard. A six-month review with both the development team and ranger leadership is recommended to assess aggregate metrics and identify workflow friction. Any metric consistently below 80% over two consecutive months triggers a structured design review.' },
  { phase: '8.4', title: 'Community Ownership', detail: 'The GitHub repository is available for transfer to YAC ownership on request. All data remains on ranger-owned devices unless rangers explicitly sync to cloud. The open-source codebase means YAC or any future technical partner can modify, extend, or audit the application without requiring engagement with the original development team. No external party holds access to ranger data.' },
  { phase: '8.5', title: 'Repair and Failure Pathways', detail: 'The application is software-only — hardware failure defaults to the ranger\'s existing device repair pathways. Application bugs are addressed through TestFlight updates delivered via Starlink. If the Starlink terminal is offline for an extended period, all core app functions continue to operate, and mesh sync between ranger devices remains available. Cloud data is a backup, not a dependency.' },
]

const COST_ITEMS = [
  { item: 'Apple Developer Account (TestFlight)', qty: '1', unit: '$149/yr', total: '$149', source: 'Apple (2026)' },
  { item: 'Supabase free tier (500MB DB, 1GB storage)', qty: '1', unit: '$0', total: '$0', source: 'Supabase (2026)' },
  { item: 'AWS S3 storage — est. 50GB/yr (photo records)', qty: '50 GB', unit: '$0.028/GB/mo', total: '~$17', source: 'AWS (2026)' },
  { item: 'Android APK distribution (direct install)', qty: '—', unit: '$0', total: '$0', source: '—' },
]

const CONSIDERATIONS = [
  { title: 'Biosecurity obligations', body: 'Lama Lama Rangers operating under priority weed action plans are required under the Biosecurity Act 2014 (Qld) to take reasonable steps to prevent the spread of restricted invasive plants (Biosecurity Queensland, 2026). The app\'s timestamped, GPS-referenced treatment records provide an auditable log of management actions at each site, directly supporting compliance.' },
  { title: 'Biocontrol integration', body: 'The Lantana Biocontrol Prompt warns rangers not to apply foliar spray if Aconophora compressa biocontrol agents are present — an error that would undermine long-term management at the site (Walton, 2025). No existing general-purpose tool provides this check. It is embedded in the treatment entry flow so the decision is made before spraying, not as a retrospective check.' },
  { title: 'Cultural protocols', body: 'Voice memo support allows rangers to record observations in language and in their own words, capturing ecological knowledge that structured data fields cannot hold (State of the Environment, 2021). Any future extension — drone data import, community-facing dashboards, integration with external databases — must be subject to YAC and ranger community consultation before development proceeds.' },
  { title: 'Infrastructure resilience', body: 'The Bluetooth mesh architecture means team data sharing does not depend on the Starlink terminal remaining operational. Following events like Cyclone Narelle, which caused significant infrastructure damage across Cape York, a monitoring system dependent on a single connectivity point risks extended outage precisely when coordinated land management is most needed (EWB Challenge, 2026). Mesh-first sync is a direct response to that risk.' },
]

const RECS = [
  { num: '01', title: 'Formal usability review before full deployment', body: 'Conduct a formal usability review with Lama Lama Rangers during the 2026 dry season, before full deployment, to identify workflow issues specific to field conditions not captured during development. This review should cover the sighting logging flow, treatment entry, and Bluetooth mesh sync between multiple devices.' },
  { num: '02', title: 'Bring Android to full feature parity', body: 'Bring the Android app to full feature parity with the iOS version so all ranger devices are supported regardless of platform. The Android companion (Jetpack Compose, Room, Google Nearby Connections) implements the same architecture and mesh sync protocol as the iOS build and can be distributed via APK sideload without an app store account.' },
  { num: '03', title: 'Investigate integration with Queensland weed mapping databases', body: 'Investigate integration with Queensland weed mapping databases, subject to explicit YAC consent on data sharing scope, to allow ranger records to contribute to regional monitoring programs. Data sovereignty must be preserved: any integration that transmits records outside YAC control requires formal community authorisation.' },
  { num: '04', title: 'Annual species scope review with YAC', body: 'Establish an annual review with YAC to assess whether the six-species scope remains current and whether the priority weed action plan has identified additional species for inclusion. The app architecture supports adding species to the data model without structural changes.' },
  { num: '05', title: 'Explore grant funding for training and development', body: 'Explore grant funding through the Indigenous Rangers Program (NIAA, n.d.) and Queensland Protected Area Strategy 2020–2030 (Queensland Government, 2020) to support training costs and any future development work. The ~$166 annual software cost is a strong case for small-grant inclusion.' },
]

const REFERENCES = [
  'Aboriginal Cultural Landscape Management – Literature Review. (2025). Transport for NSW. https://www.transport.nsw.gov.au/system/files/media/documents/2025/Aboriginal-Cultural-Landscape-Management-Literature-Review.pdf',
  'Amazon Web Services. (2026). Amazon S3 pricing. https://aws.amazon.com/s3/pricing/',
  'Anshumali, A., & Gupta, S. (2025). Lantana camara: A review on ecology, invasion and management. International Journal of Agronomy, 8(2), 864–871. https://www.agronomyjournals.com/archives/2025/vol8issue2/PartC/8-2-24-864.pdf',
  'Apple. (2026). Apple Developer Program. https://developer.apple.com/programs/',
  'Batavia National Park (Cape York Peninsula Aboriginal Land) Management Statement 2014 — extended 2025. (2025). Queensland Parks and Wildlife Service. https://parks.qld.gov.au/__data/assets/pdf_file/0023/166415/batavia-np-extended-2025.pdf',
  'Biosecurity Queensland. (2026). Lantana. Business Queensland. https://www.business.qld.gov.au/industries/farms-fishing-forestry/agriculture/biosecurity/plants/invasive/restricted/lantana',
  'Centre for Appropriate Technology. (n.d.). Community planning with the Lama Lama people. https://www.cfat.org.au/community-planning-with-the-lama-lama-people',
  'CyberTracker. (n.d.). Indigenous knowledge. https://cybertracker.org/uses/indigenous-knowledge/',
  'Department of Environment, Science and Innovation (DESI). (n.d.). Cape York Peninsula: Extent of endangered, of concern and no concern at present regional ecosystems. State of the Environment Queensland. https://www.stateoftheenvironment.detsi.qld.gov.au/biodiversity/terrestrial-ecosystems/extent-of-endangered-of-concern-and-no-concern-at-present-regional-ecosystems/cape-york-peninsula',
  'EWB Challenge. (2026). Port Stewart, Lama Lama. Engineers Without Borders Australia. https://ewbchallenge.org/challenge/port-stewart-lama-lama/',
  'Grains Research and Development Corporation (GRDC). (2025). The economics of precision weed management. https://grdc.com.au/resources-and-publications/all-publications/publications/2025/the-economics-of-precision-weed-management',
  'Jayawardena, S. (2024). Green Savers: Mobile application solution for environmental conservation and community engagement [Thesis, Centria University of Applied Sciences]. Theseus. https://www.theseus.fi/bitstream/handle/10024/893477/Jayawardena_Shajan.pdf',
  'Lam, I. (2026). ewbrangerapp [Source code repository]. GitHub. https://github.com/immanuel-lam/ewbrangerapp',
  'Lama Lama Land and Sea Rangers. (n.d.). Welcome to Lama Lama Country. https://www.lamalama.org.au/',
  'Mousumi, S., & Jahan, N. (2025). Lantana camara L.: Biology, ecology and control. Plant Science Today, 12(2), 95–104. https://horizonepublishing.com/index.php/PST/article/view/9506',
  'National Indigenous Australians Agency (NIAA). (n.d.). Indigenous Rangers Program (IRP). https://www.niaa.gov.au/our-work/environment-and-land/indigenous-rangers-program-irp',
  'Office of the Registrar of Indigenous Corporations (ORIC). (n.d.). Taking care of country. https://www.oric.gov.au/corporations-and-registers/corporation-stories/taking-care-country',
  'Queensland Government. (2020). Queensland\'s Protected Area Strategy 2020–2030. https://parks.des.qld.gov.au/__data/assets/pdf_file/0016/212524/qld-protected-area-strategy-2020-30.pdf',
  'Sahu, N., & Chandola, V. (2025). Offline-first Android architecture for waste management in low connectivity areas. International Journal of Engineering Technology and Computer Science, 10(1). https://ijetcsit.org/index.php/ijetcsit/article/download/657/596',
  'Sinden, J., Jones, R., Hester, S., Odom, D., Kalisch, C., James, R., & Cacho, O. (2004). The economic impact of weeds in Australia. Agecon Search. https://ageconsearch.umn.edu/record/12278/',
  'State of the Environment. (2021). Indigenous knowledge and land and sea management. Australian Government. https://soe.dcceew.gov.au/biodiversity/management/indigenous-knowledge-and-land-and-sea-management',
  'Supabase. (2026). Pricing. https://supabase.com/pricing',
  'Taylor, D. B. (2017). Threats to Cape York rivers: Q-catchments risk assessment and threat prioritisation. ResearchGate. https://www.researchgate.net/publication/316494929',
  'Walton, C. (2025). Lantana: Current management status and future prospects. DPI eResearch Archive. https://era.dpi.qld.gov.au/id/eprint/5260/1/mn102lantana_current_management_status_and_future_76357.pdf',
  'Woinarski, J. (2025). The natural attributes for World Heritage nomination of Cape York Peninsula. DCCEEW. https://www.dcceew.gov.au/sites/default/files/env/resources/5ab50983-6bb4-4d87-8298-f1bcf1ab652a/files/sciencepanelreport.pdf',
]

const GROUP_DECLARATION_DATA = [
  { name: 'Immanuel Lam', area: 'Economic constraints (Q1)', contributions: 'iOS/Android application development (V1–V3); prototyping section; cost model and implementation plan; AT3 website' },
  { name: 'Francesca (Essy) Silva Paniagua', area: 'Habitats (Q2)', contributions: 'Project details; background research; problem description' },
  { name: 'Marisa [surname]', area: 'Species (Q3)', contributions: 'Design solution options; option research and evaluation' },
  { name: 'Garv Mitter', area: 'Traditional management (Q4)', contributions: 'Design criteria; detailed design specification' },
  { name: 'Jai Sloper', area: 'Environmental threats (Q5)', contributions: 'Implementation plan; rollout and cost analysis' },
  { name: 'Caleb [surname]', area: 'Ecosystem protection (Q6)', contributions: 'Other considerations and recommendations' },
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
          <ellipse cx="140" cy="100" rx="110" ry="70" fill="none" stroke="#00B4D8" strokeWidth="0.8" opacity="0.3" />
          {visible && (
            <path d="M80,60 Q120,40 160,55 Q200,70 210,100 Q220,130 180,150 Q140,165 100,150 Q60,135 70,100 Q72,85 80,60"
              fill="none" stroke="#00B4D8" strokeWidth="2" strokeDasharray="80" strokeDashoffset="80"
              style={{ animation: 'drawPath 2s var(--ease-out) forwards' }} />
          )}
          <circle cx="80" cy="60" r="5" fill="#C4692A" opacity={visible ? 1 : 0} style={{ transition: 'opacity .4s .5s' }} />
          <circle cx="160" cy="55" r="4" fill="#00B4D8" opacity={visible ? 1 : 0} style={{ transition: 'opacity .4s .9s' }} />
          <circle cx="210" cy="100" r="4" fill="#00B4D8" opacity={visible ? 1 : 0} style={{ transition: 'opacity .4s 1.3s' }} />
        </svg>
        {visible && <div className="pmv-trail-done">patrol complete ✓</div>}
      </div>
      <div className="pmv-panel">
        <div className="pmv-label">Mesh peers</div>
        <svg className="pmv-svg" viewBox="0 0 280 200">
          <circle cx="140" cy="60" r="14" fill="#0077B6" opacity="0.8" />
          <text x="140" y="65" textAnchor="middle" fontSize="10" fill="#00B4D8">A</text>
          <circle cx="70" cy="150" r="14" fill="#0077B6" opacity="0.8" />
          <text x="70" y="155" textAnchor="middle" fontSize="10" fill="#00B4D8">B</text>
          <circle cx="210" cy="150" r="14" fill="#0077B6" opacity="0.8" />
          <text x="210" y="155" textAnchor="middle" fontSize="10" fill="#00B4D8">C</text>
          {visible && <>
            <line x1="140" y1="74" x2="70" y2="136" stroke="#00B4D8" strokeWidth="1.5" strokeDasharray="100"
              style={{ animation: 'meshLineIn .8s var(--ease-out) .3s forwards', opacity: 0 }} />
            <line x1="140" y1="74" x2="210" y2="136" stroke="#00B4D8" strokeWidth="1.5" strokeDasharray="100"
              style={{ animation: 'meshLineIn .8s var(--ease-out) .6s forwards', opacity: 0 }} />
            <line x1="84" y1="150" x2="196" y2="150" stroke="#00B4D8" strokeWidth="1.5" strokeDasharray="100"
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
        <li><a href="#project">Project</a></li>
        <li><a href="#background">Background</a></li>
        <li><a href="#design">Criteria</a></li>
        <li><a href="#features">Design</a></li>
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
          <div className="hero-eyebrow-rule" />
          <h1 className="hero-headline">
            <span className="hero-headline-intro">Protecting</span>
            <span className="hero-headline-em">Country.</span>
          </h1>
          <p className="hero-body">
            An offline-first iOS field app for Lama Lama Rangers to log invasive plant sightings, coordinate treatment, sync records peer-to-peer, and back up to cloud — all without internet.
          </p>
          <div className="hero-cta">
            <a href="#features" className="btn btn-amber">Read the report</a>
            <a href="https://github.com/immanuel-lam/ewbrangerapp/tree/demov3"
              className="btn btn-outline" target="_blank" rel="noreferrer">
              View on GitHub
            </a>
          </div>
          <div className="hero-meta">
            <span>31265 Communications for IT Professionals · UTS Autumn 2026</span>
            <span className="hero-meta-divider" />
            <span>EWB Challenge · Design Area 5 · Project Opportunity 5.5</span>
          </div>
        </div>
        <div className="hero-phones">
          <div className="hero-phone-wrap hero-phone-wrap--1">
            <div className="hero-phone" ref={phone1Ref}>
              <PhoneFrame label="Map view" icon="🗺️" src={imgMap} />
            </div>
          </div>
          <div className="hero-phone-wrap hero-phone-wrap--2">
            <div className="hero-phone" ref={phone2Ref}>
              <PhoneFrame label="Hub" icon="🏠" src={imgHub} />
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
            <div className="exec-meta-row">
              <span className="exec-meta-item"><span className="exec-meta-label">Design Area</span> 5 — Climate Resilience and Adaptation</span>
              <span className="exec-meta-divider" />
              <span className="exec-meta-item"><span className="exec-meta-label">Keywords</span> invasive species · offline-first · data sovereignty · Indigenous rangers · weed management · peer-to-peer sync</span>
            </div>
            <h2 className="section-headline">A field tool built around how Rangers already work</h2>
            <p className="exec-body">
              Invasive plants — particularly <em>Lantana camara</em> and five further species — are spreading across Lama Lama Country faster than current documentation systems can track them. The Lama Lama Rangers App is an offline-first mobile application for iOS and Android that gives rangers a single tool to log sightings via GPS, record treatment actions, share data with the team over Bluetooth mesh, and consult a species guide — all without internet access.
            </p>
            <p className="exec-body">
              The design was developed iteratively across three versions in response to the specific constraints of Port Stewart: no sealed roads, no mobile network, and Starlink access restricted to the ranger office. It was selected over paper-based forms and CyberTracker by a weighted decision matrix scoring 4.90/5.
            </p>
            <div className="hmw-block" style={{ marginTop: 32 }}>
              <div className="hmw-label">How Might We</div>
              <blockquote className="hmw-quote">
                "How might we support Lama Lama Rangers in detecting and managing invasive plant species across their Country without dependence on internet connectivity, in a way that complements Indigenous ecological knowledge and maintains community ownership of data?"
              </blockquote>
            </div>
          </Reveal>
          <div className="exec-stats">
            <CountUpStat target={6} label="invasive species targeted" duration={900} />
            <CountUpStat target={0} label="bars of signal needed in field" duration={600} />
            <CountUpStat target={166} suffix=" AUD" label="estimated annual software cost (yr 1)" duration={1000} />
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
              Port Stewart sits on Lama Lama Country in Cape York Peninsula, Queensland. The territory spans approximately 400,000 to 500,000 hectares of coastal wetland, river systems, savannah woodland, and rainforest managed by the Lama Lama Land and Sea Rangers across four ranger camps (Lama Lama Land and Sea Rangers, n.d.). Access requires a flight to Cairns, an eight-hour drive to Coen, and a further hour on unpaved track. The only broadband connection is a Starlink terminal at the ranger office, unavailable in the field.
            </p>
            <p className="context-para">
              Cape York Peninsula hosts some of the most intact tropical biodiversity in Australia but is under measurable ecological pressure. Invasive plants are a primary driver. <em>Lantana camara</em> alone is listed as a restricted invasive plant under Queensland biosecurity legislation, forming dense thickets that suppress native vegetation and become progressively harder to treat as infestations grow (Biosecurity Queensland, 2026; Walton, 2025). Nationally, weeds impose an estimated $4 billion in agricultural losses annually (Sinden et al., 2004).
            </p>
            <p className="context-para">
              The Lama Lama Rangers are both the primary stakeholders and the primary users. Ranger-led land and sea management integrates Indigenous ecological knowledge with scientific monitoring in ways the State of the Environment (2021) identifies as fundamental to effective biodiversity management. Data sovereignty — who owns the records of Country — is a direct concern for Yintjingga Aboriginal Corporation (YAC) and the broader Lama Lama community (ORIC, n.d.).
            </p>
            <p className="context-para">
              Several tools are used across ranger programs in Australia for environmental monitoring. CyberTracker supports GPS-referenced field data collection but does not support peer-to-peer synchronisation without internet (CyberTracker, n.d.). ArcGIS Field Maps licensing is substantial and unsustainable for programs on grant funding cycles (GRDC, 2025). None of the existing platforms cover the full monitoring workflow in a single tool that operates completely offline.
            </p>
            <p className="context-para">
              The result is a data gap: rangers work with GPS units, cameras, paper treatment records, and a centralised database accessed only at the office. Team-wide visibility of infestation patterns is only achievable through manual post-patrol data consolidation — after the window for early intervention may have passed (Walton, 2025). This project aims to close that gap.
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
            An enhanced paper-based system, adaptation of CyberTracker, and a purpose-built offline-first app were assessed against the six criteria.
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
  return (
    <section className="selection-section">
      <div className="container">
        <div className="selection-intro-grid">
          <Reveal className="selection-intro-left">
            <SectionTag>Decision Matrix</SectionTag>
            <h2 className="section-headline">The purpose-built app scored 4.90/5.</h2>
          </Reveal>
          <Reveal delay={0.1} className="selection-intro-right">
            <p className="section-body" style={{ marginBottom: 0 }}>
              Options were scored on a scale of 1–5 against each criterion. Weights reflect the relative importance of each criterion to the Port Stewart context, with offline functionality weighted most heavily given the non-negotiable connectivity constraint. Option 3 scores 5 across five of six criteria and was selected.
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
                  <th className="matrix-th">CyberTracker</th>
                  <th className="matrix-th matrix-th--selected">Purpose-Built App ✓</th>
                </tr>
              </thead>
              <tbody>
                {MATRIX_ROWS.map((row) => (
                  <tr key={row.criterion} className="matrix-row">
                    <td className="matrix-td matrix-td--criterion">{row.criterion}</td>
                    <td className="matrix-td matrix-td--weight">{row.weight}%</td>
                    <td className="matrix-td"><span className="matrix-score">{row.paper}/5</span></td>
                    <td className="matrix-td"><span className="matrix-score">{row.cyber}/5</span></td>
                    <td className="matrix-td matrix-td--selected"><span className="matrix-score matrix-score--selected">{row.app}/5</span></td>
                  </tr>
                ))}
                <tr className="matrix-total-row">
                  <td className="matrix-td matrix-td--criterion" style={{ fontWeight: 700 }}>Weighted Total</td>
                  <td className="matrix-td matrix-td--weight">100%</td>
                  <td className="matrix-td"><span className="matrix-score matrix-score--total">{MATRIX_TOTALS.paper.toFixed(2)}</span></td>
                  <td className="matrix-td"><span className="matrix-score matrix-score--total">{MATRIX_TOTALS.cyber.toFixed(2)}</span></td>
                  <td className="matrix-td matrix-td--selected"><span className="matrix-score matrix-score--selected matrix-score--total">{MATRIX_TOTALS.app.toFixed(2)}</span></td>
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

function FeatureSection({ tag, headline, body, highlights, phones, reversed, alt, index = 0, figStart = 1 }) {
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
                  <figure className="phone-solo">
                    <PhoneFrame {...phones[0]} />
                    <figcaption className="fig-caption">Figure {figStart}. {phones[0].label}</figcaption>
                  </figure>
                </div>
              : <div className="phone-column phone-column--stacked">
                  {phones.map((p, j) => (
                    <figure key={p.label} className="phone-figure">
                      <PhoneFrame {...p} />
                      <figcaption className="fig-caption">{`Figure ${figStart + j}. ${p.label}`}</figcaption>
                    </figure>
                  ))}
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
                <PhoneFrame label="Day Sync" icon="📡" src={imgDaySync} />
                <PhoneFrame label="Conflict Resolver" icon="🔀" src={imgConflict} />
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
  const specs = [
    { label: 'Platform', value: 'iOS (Swift/SwiftUI) + Android (Jetpack Compose)' },
    { label: 'Build target', value: 'iPhone 17 Pro Simulator' },
    { label: 'Demo PIN', value: '1234 — Alice, Bob, Carol' },
    { label: 'Demo data', value: '28 sightings, 6 zones, 10 patrols' },
    { label: 'Repo', value: 'github.com/immanuel-lam/ewbrangerapp' },
  ]

  return (
    <section className="proto-section">
      <div className="container">
        <Reveal>
          <SectionTag>Prototyping</SectionTag>
          <h2 className="section-headline">Three versions. Full end-to-end field workflow.</h2>
        </Reveal>

        <Reveal delay={0.05}>
          <h3 className="section-label" style={{ marginTop: 40, marginBottom: 8 }}>7.1 What Was Prototyped and Why</h3>
          <p className="context-para">
            The prototype focused on the full end-to-end field workflow: from launching the app on a ranger device through GPS sighting capture, treatment logging, and Bluetooth mesh synchronisation to a second device. This workflow was prioritised because it is the highest-risk interaction — if rangers cannot complete a sighting record quickly in the field, they will not use the tool. Visual design and navigation were also validated through three progressive versions.
          </p>
        </Reveal>

        <Reveal delay={0.05}>
          <h3 className="section-label" style={{ marginTop: 32, marginBottom: 8 }}>7.2 Construction Process</h3>
          <p className="context-para">
            Three versions were developed using Swift/SwiftUI for iOS and Jetpack Compose for Android, with CoreData for local persistence and Apple MultipeerConnectivity for Bluetooth mesh sync. Each version was built on the previous codebase, with new features developed on isolated branches and merged after testing. The full codebase and version history are publicly available at github.com/immanuel-lam/ewbrangerapp (Lam, 2026).
          </p>
        </Reveal>

        <div className="proto-inner">
          <div>
            <h3 className="section-label" style={{ marginBottom: 8 }}>7.3 Version Progression</h3>
            <div className="proto-findings">
              {[
                { feat: 'Version 1 — Proof of Concept', text: 'Scoped to Lantana camara only. Validated the core data model: a sighting tied to a GPS location, species, and treatment record. V1 confirmed the data model was appropriate but exposed two critical gaps: single-species scope did not reflect reality, and the absence of peer-to-peer sync meant rangers had no way to share records in the field.' },
                { feat: 'Version 2 — Full Redesign', text: 'Extended to six invasive species. Key additions: Bloom Calendar, satellite map views with infestation zone polygons, Lantana Biocontrol Prompt, patrol checklist with stamina metric, Bluetooth mesh sync via MultipeerConnectivity, Shift Handover Card, Zone Conflict Resolver.' },
                { feat: 'Version 3 — Current', text: 'Twelve features added: dedicated Ranger Safety tab (check-in timer, hazard logger, emergency SOS, night vision mode), voice memo support, Herbicide Compatibility Checker, Treatment Effectiveness Tracker, Equipment Maintenance Log, Ranger Status Broadcast, and cloud sync via Supabase and AWS S3. All V3 features function without internet.' },
              ].map(f => (
                <div key={f.feat} className="proto-finding">
                  <div className="proto-finding-feat">{f.feat}</div>
                  <div className="proto-finding-text">{f.text}</div>
                </div>
              ))}
            </div>
            <FigurePlaceholder num={3} caption="Design progression from V1 to V3 — architecture, feature set, and UI evolution across three versions." src={`${import.meta.env.BASE_URL}design-progression.jpg`} />
            <FigurePlaceholder num={4} caption="App screenshots — Map view, Activity Logging, Plant Guide, and Ranger Safety tab." />
          </div>
          <Reveal delay={0.1}>
            <h3 className="section-label" style={{ marginBottom: 8 }}>Build specs</h3>
            <div className="proto-specs">
              {specs.map(s => (
                <div key={s.label} className="spec-block">
                  <div className="spec-label">{s.label}</div>
                  <div className="spec-value">{s.value}</div>
                </div>
              ))}
            </div>
            <div style={{ marginTop: 24 }}>
              <BuildDash />
            </div>
          </Reveal>
        </div>

        <Reveal delay={0.1}>
          <h3 className="section-label" style={{ marginTop: 40, marginBottom: 8 }}>7.4 Testing</h3>
          <p className="context-para">
            The prototype was tested on physical iOS devices across the core logging workflow, Bluetooth mesh synchronisation between two devices, and offline map loading without network access. The Zone Conflict Resolver was tested by seeding conflicting zone edits from two devices and validating the merge interface.
          </p>
          <h3 className="section-label" style={{ marginTop: 24, marginBottom: 8 }}>7.5 Results and Modifications</h3>
          <p className="context-para">
            Bluetooth mesh sync was confirmed reliable between two iOS devices without internet. Offline map loading from CoreData was validated. The V2 patrol stamina metric was flagged as a lower priority feature and retained as optional. The Herbicide Compatibility Checker was moved from a standalone screen in V2 to the treatment entry flow in V3 after testing showed rangers were unlikely to access it separately before spraying.
          </p>
        </Reveal>
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
          <h2 className="section-headline">Five-part implementation plan.</h2>
          <p className="section-body" style={{ marginBottom: 48 }}>
            Training, rollout, evaluation, community ownership, and failure pathways — each addressed before deployment.
          </p>
        </Reveal>
        <Reveal delay={0.1}>
          <div className="impl-phases">
            {IMPL_PHASES.map((p) => (
              <div key={p.phase} className="impl-phase">
                <div className="impl-phase-num">{p.phase}</div>
                <div>
                  <div className="impl-phase-title">{p.title}</div>
                  <div className="impl-phase-detail">{p.detail}</div>
                </div>
              </div>
            ))}
          </div>
          <div className="impl-note">
            <strong>No App Store required.</strong> Distribution via Apple TestFlight (iOS) or APK sideload (Android). YAC retains full source code and documentation at handover.
          </div>
          <div className="impl-note impl-note--airdrop" style={{ marginTop: 12 }}>
            If the Starlink terminal is offline for an extended period, all core app functions continue to operate, and mesh sync between ranger devices remains available. Cloud data is a backup, not a dependency.
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
          <SectionTag>Cost Analysis</SectionTag>
          <h2 className="section-headline">~$166 AUD annually. Viable on a Rangers Programme budget.</h2>
          <p className="section-body" style={{ marginBottom: 48 }}>
            The ~$166 annual cost is fundable through existing ranger program operational budgets without requiring a separate grant. All development iteration costs are absorbed through open-source contribution — there are no vendor fees.
          </p>
        </Reveal>
        <Reveal delay={0.1}>
          <div className="cost-table-wrap">
            <table className="cost-table">
              <thead>
                <tr>
                  <th>Item</th>
                  <th>Qty</th>
                  <th>Unit Cost (AUD/yr)</th>
                  <th>Total (AUD/yr)</th>
                  <th>Source</th>
                </tr>
              </thead>
              <tbody>
                {COST_ITEMS.map(item => (
                  <tr key={item.item}>
                    <td>{item.item}</td>
                    <td>{item.qty}</td>
                    <td>{item.unit}</td>
                    <td className="cost-value">{item.total}</td>
                    <td style={{ fontSize: '.8rem', color: 'var(--ink-muted)' }}>{item.source}</td>
                  </tr>
                ))}
                <tr>
                  <td colSpan={3} style={{ fontWeight: 700, color: 'var(--ink)' }}>Total Year 1</td>
                  <td className="cost-value">~$166</td>
                  <td></td>
                </tr>
              </tbody>
            </table>
          </div>
          <p className="cost-funding" style={{ marginBottom: 12 }}>
            <strong>Maintenance:</strong> If data volume grows beyond Supabase free tier in subsequent years, Supabase Pro at ~$300/yr remains significantly below licensed GIS alternatives at $500–$2,000 per seat (GRDC, 2025).
          </p>
          <p className="cost-funding">
            <strong>Funding pathways:</strong> Indigenous Rangers Program (NIAA) · Queensland Protected Area Strategy 2020–2030 · Working on Country Programme · DAFF National Landcare Programme
          </p>
        </Reveal>
      </div>
    </section>
  )
}

const COMMUNITY_JOURNEY = [
  { stage: 'Pre-deployment', experience: 'Rangers are consulted on workflow requirements during the design process. Existing patrol habits and paper forms inform app structure.' },
  { stage: 'Dry season training', experience: 'Two-day in-person workshop on Country. Rangers learn the logging workflow by completing real test sightings. Senior rangers identified as peer trainers.' },
  { stage: 'First patrol season', experience: 'Rangers use the app alongside existing methods. Feedback collected at end-of-shift handover. Bugs reported via ranger office Starlink.' },
  { stage: 'Six-month review', experience: 'Development team and rangers review adoption data and workflow issues. Updates released via TestFlight.' },
  { stage: 'Long-term', experience: 'YAC optionally takes repository ownership. Rangers train new team members independently. App extended based on community-identified priorities.' },
]

function ConsiderationsSection() {
  return (
    <section className="considerations-section">
      <div className="container">
        <Reveal>
          <SectionTag>Other Considerations</SectionTag>
          <h2 className="section-headline">Designed with, not for.</h2>
        </Reveal>
        <div className="considerations-grid" style={{ gridTemplateColumns: 'repeat(2, 1fr)' }}>
          {CONSIDERATIONS.map((c, i) => (
            <Reveal key={c.title} delay={0.07 * (i % 2)}>
              <div className="consideration-card">
                <div className="consideration-title">{c.title}</div>
                <div className="consideration-body">{c.body}</div>
              </div>
            </Reveal>
          ))}
        </div>
        <Reveal delay={0.15}>
          <h3 className="section-label" style={{ marginTop: 48, marginBottom: 16, fontSize: '.78rem' }}>Community Journey Map</h3>
          <div className="cost-table-wrap">
            <table className="cost-table">
              <thead>
                <tr>
                  <th style={{ width: '20%' }}>Stage</th>
                  <th>Ranger Experience</th>
                </tr>
              </thead>
              <tbody>
                {COMMUNITY_JOURNEY.map(row => (
                  <tr key={row.stage}>
                    <td style={{ fontWeight: 600, color: 'var(--ink)', whiteSpace: 'nowrap' }}>{row.stage}</td>
                    <td>{row.experience}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Reveal>
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
          <h2 className="section-headline">Five recommendations.</h2>
          <p className="section-body" style={{ marginBottom: 56 }}>
            Directed to YAC leadership and Rangers Programme management. Each addresses a specific risk, dependency, or opportunity identified during development.
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
            APA 7th edition. All URLs verified at time of citation. Sources retrieved from EWB partner materials, peer-reviewed journals, government publications, and public repositories.
          </p>
        </Reveal>
      </div>
    </section>
  )
}

function ProjectDetails() {
  return (
    <section className="project-details-section" id="project">
      <div className="container">
        <Reveal>
          <SectionTag>Project Details</SectionTag>
          <div className="project-meta-grid">
            <div className="project-meta-item">
              <div className="project-meta-label">Design Area</div>
              <div className="project-meta-value">5 — Climate Resilience and Adaptation</div>
            </div>
            <div className="project-meta-item">
              <div className="project-meta-label">Project Opportunity</div>
              <div className="project-meta-value">5.5 — Biodiversity and Habitat Protection Tools</div>
            </div>
            <div className="project-meta-item">
              <div className="project-meta-label">Subject</div>
              <div className="project-meta-value">31265 Communications for IT Professionals · UTS Autumn 2026</div>
            </div>
            <div className="project-meta-item">
              <div className="project-meta-label">Tutorial &amp; Zone</div>
              <div className="project-meta-value">Tutorial 02 — Dhanesh</div>
            </div>
            <div className="project-meta-item">
              <div className="project-meta-label">Group Name</div>
              <div className="project-meta-value">Garv Fan Club</div>
            </div>
          </div>
          <h2 className="section-headline" style={{ marginTop: 48 }}>Why this matters</h2>
          <p className="section-body">
            This project addresses Design Area 5.5 — Biodiversity and Habitat Protection Tools — from the 2026 EWB Challenge Design Brief. The Lama Lama Land and Sea Rangers conduct invasive plant management across a vast and remote territory in Cape York Peninsula, Queensland, but the tools currently available to them were not designed for an environment without internet connectivity or sealed road access.
          </p>
          <p className="section-body" style={{ marginTop: 16 }}>
            The group selected this project opportunity because the gap between the rangers' operational knowledge and the technology available to support it is both concrete and addressable. No existing commercial solution covers the full monitoring workflow in a single tool that operates offline, supports peer-to-peer data sharing in the field, and maintains community ownership of land data.
          </p>
          <div className="hmw-block" style={{ marginTop: 32, background: 'var(--green-50)', border: '1px solid var(--green-200)' }}>
            <div className="hmw-label" style={{ color: 'var(--green-700)' }}>Needs Statement</div>
            <blockquote className="hmw-quote" style={{ color: 'var(--ink)' }}>
              Lama Lama Rangers need a single, offline-capable tool that integrates GPS logging, photo documentation, treatment recording, and peer-to-peer data sharing into their existing patrol workflow — without dependence on connectivity infrastructure that is not reliably available on Country.
            </blockquote>
          </div>
        </Reveal>
      </div>
    </section>
  )
}

function AcknowledgementSection() {
  return (
    <section className="acknowledgement-section" id="acknowledgement">
      <div className="container">
        <div className="acknowledgement-inner">
          <div className="acknowledgement-label">Acknowledgement of Country</div>
          <blockquote className="acknowledgement-quote">
            We acknowledge the Lama Lama people as the Traditional Custodians of the land and sea Country on which this project is centred. We pay our respects to Lama Lama Elders past, present, and emerging, and recognise their enduring connection to Country — a connection expressed through thousands of years of careful land and sea management.
          </blockquote>
          <p className="acknowledgement-body">
            This project was developed in the context of the Engineers Without Borders Challenge, which was produced in partnership with Yintjingga Aboriginal Corporation (YAC). We acknowledge that any technology solution proposed for Lama Lama Country must be developed with, not for, the community, and that sovereignty over land, knowledge, and data belongs to the Lama Lama people. We are grateful for the access to community knowledge and insights provided through the EWB Challenge framework.
          </p>
        </div>
      </div>
    </section>
  )
}

function GroupDeclarationSection() {
  return (
    <section className="declaration-section" id="declaration">
      <div className="container">
        <Reveal>
          <SectionTag>Group Declaration</SectionTag>
          <h2 className="section-headline">Individual Contributions</h2>
          <p className="section-body" style={{ marginBottom: 0 }}>
            Each team member led one research question as primary author. All members reviewed the final design solution and contributed feedback on the AT3 deliverables.
          </p>
        </Reveal>
        <Reveal delay={0.1}>
          <div className="declaration-table-wrap">
            <table className="declaration-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Research Area</th>
                  <th>Contributions to AT3</th>
                </tr>
              </thead>
              <tbody>
                {GROUP_DECLARATION_DATA.map((row, i) => (
                  <tr key={row.name} className={i % 2 === 1 ? 'declaration-row--alt' : ''}>
                    <td className="declaration-td--name">{row.name}</td>
                    <td className="declaration-td--area">{row.area}</td>
                    <td>{row.contributions}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="declaration-statements">
            <div className="declaration-statement">
              <div className="declaration-statement-label">Originality</div>
              <p className="declaration-statement-text">
                All written analysis, design rationale, and decision-making in this report represents the original work of the group. Source material is cited in accordance with APA 7th edition. Contributions attributed to specific team members above are accurate.
              </p>
            </div>
            <div className="declaration-statement">
              <div className="declaration-statement-label">Generative AI Use</div>
              <p className="declaration-statement-text">
                Generative AI (Claude by Anthropic) was used to assist with: writing and editing website copy, generating React component code for this site, structuring arguments, and reviewing content for clarity. AI was not used to generate the research content, technical analysis, or design decisions in the report. A full prompt log is included in the appendices.
              </p>
            </div>
          </div>
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
              EWB Challenge 2026 · Design Area 5 · Project Opportunity 5.5<br />
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
      <GroupDeclarationSection />
      <AcknowledgementSection />
      <ProjectDetails />
      <Background />
      <CriteriaSection />
      <OptionsSection />
      <SelectionSection />
      <FeaturesOverview />
      {FEATURE_SECTIONS.map((fs, i) => (
        <div key={fs.tag}>
          <FeatureSection {...fs} index={i} />
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
