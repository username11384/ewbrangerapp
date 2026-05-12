import { useEffect, useRef, useState } from 'react'
import './App.css'

import imgBannerHero     from './assets/banners/hero.jpg'
import imgBannerLantana  from './assets/banners/lantanainfestation.jpg'
import imgBannerRangers  from './assets/banners/rangers.jpg'
import imgBannerWetlands from './assets/banners/capeyorkwetlands.jpg'

import imgMap         from './assets/screenshots/map.png'
import imgLog         from './assets/screenshots/log-sighting.png'
import imgSpecies     from './assets/screenshots/species-guide.png'
import imgHub         from './assets/screenshots/hub.png'
import imgTreatment   from './assets/screenshots/treatment.png'
import imgBicontrol   from './assets/screenshots/bicontrol.png'
import imgBloom       from './assets/screenshots/bloom.png'
import imgChecklist   from './assets/screenshots/checklist.png'
import imgConflict    from './assets/screenshots/conflict.png'
import imgDaySync     from './assets/screenshots/day-sync.png'
import imgPatrol      from './assets/screenshots/patrol.png'
import imgSafetyTimer from './assets/screenshots/safetytimer.png'
import imgRedLight    from './assets/screenshots/redlight.png'
import imgVoiceNote   from './assets/screenshots/voicenote.png'
import imgHandover    from './assets/screenshots/handovercard.png'
import imgV1Log       from './assets/screenshots/v1-logscreen.png'

// ─── Hook ────────────────────────────────────────────────────────────────────

function useInView() {
  const ref = useRef(null)
  const [visible, setVisible] = useState(false)
  useEffect(() => {
    const el = ref.current
    if (!el) return
    const obs = new IntersectionObserver(
      ([e]) => { if (e.isIntersecting) setVisible(true) },
      { threshold: 0.07 }
    )
    obs.observe(el)
    return () => obs.disconnect()
  }, [])
  return [ref, visible]
}

// ─── Primitives ───────────────────────────────────────────────────────────────

function Reveal({ children, delay = 0 }) {
  const [ref, visible] = useInView()
  return (
    <div
      ref={ref}
      style={{
        opacity: visible ? 1 : 0,
        transform: visible ? 'none' : 'translateY(12px)',
        transition: `opacity 0.5s ease ${delay}s, transform 0.5s ease ${delay}s`,
      }}
    >
      {children}
    </div>
  )
}

function SH({ n, title }) {
  return (
    <div className="sec-hd">
      <span className="sec-n">{String(n).padStart(2, '0')}</span>
      <h2>{title}</h2>
    </div>
  )
}

function Tbl({ cols, rows, foot }) {
  return (
    <div className="tbl">
      <table>
        <thead><tr>{cols.map((c, i) => <th key={i}>{c}</th>)}</tr></thead>
        <tbody>{rows.map((r, i) => <tr key={i}>{r.map((c, j) => <td key={j}>{c}</td>)}</tr>)}</tbody>
        {foot && <tfoot><tr>{foot.map((c, i) => <td key={i}>{c}</td>)}</tr></tfoot>}
      </table>
    </div>
  )
}

function StatRow({ stats }) {
  return (
    <div className="stat-row">
      {stats.map((s, i) => (
        <div key={i} className="stat">
          <span className="stat-n">{s.n}</span>
          <span className="stat-lbl">{s.label}</span>
        </div>
      ))}
    </div>
  )
}

function Phone({ src, caption }) {
  return (
    <figure className="phone">
      <div className="phone-shell"><img src={src} alt={caption} loading="lazy" /></div>
      {caption && <figcaption>{caption}</figcaption>}
    </figure>
  )
}

function Banner({ src, alt, credit }) {
  return (
    <figure className="banner">
      <img src={src} alt={alt} loading="lazy" />
      <figcaption>{credit}</figcaption>
    </figure>
  )
}

// ─── Data ─────────────────────────────────────────────────────────────────────

const GROUP = [
  ['Immanuel', 'iOS/Android application development (V1–V3); prototyping section; economic constraints research'],
  ['Essy', 'Project details; background research; problem description'],
  ['Marisa', 'Design solution options; option research and evaluation'],
  ['Garv', 'Design criteria; detailed design specification'],
  ['Jai', 'Implementation plan; rollout and cost analysis'],
  ['Caleb', 'Other considerations and recommendations'],
]

const CRITERIA = [
  {
    name: 'Offline-first architecture',
    desc: 'All data must be stored on-device and the application must function completely without internet access. Rangers must be able to share records directly between devices in the field via peer-to-peer Bluetooth sync.',
    why: 'Starlink access is restricted to the ranger office, and there is no mobile network coverage during field operations. A cloud-dependent system cannot function in this environment.',
  },
  {
    name: 'Integrated field workflow',
    desc: 'A ranger should complete a full sighting record — GPS location, photo, species, treatment, and notes — in a single screen without switching applications or referring to paper forms.',
    why: 'Fragmented workflows increase recording time per sighting, raise the likelihood of incomplete records, and reduce adoption (Jayawardena, 2024).',
  },
  {
    name: 'Shared data visibility',
    desc: 'All ranger records must aggregate into a shared map view, colour-coded by species and treatment status, visible to the whole team.',
    why: 'Individual sighting records have limited management value unless the team can see the broader pattern of infestation across the land. Without a shared view, the same areas may be treated twice while others go unmonitored.',
  },
  {
    name: 'Cost-effectiveness and scalability',
    desc: 'The solution must run on existing ranger devices with minimal ongoing infrastructure cost, and must scale to cover the full Lama Lama land mass.',
    why: 'Ranger programs operate on grant funding that can change between cycles. Ongoing licensing or cloud costs create sustainability risk (GRDC, 2025).',
  },
  {
    name: 'Cultural appropriateness',
    desc: 'Rangers must control what is recorded, how it is used, and who has access. The tool must complement Indigenous ecological knowledge — including observation in language — rather than replacing it with standardised data fields.',
    why: 'The Lama Lama Rangers are custodians of their Country. A system that only values GPS coordinates and species counts risks sidelining the knowledge and practices that make their land management effective (ORIC, n.d.).',
  },
  {
    name: 'Ease of use',
    desc: 'The solution must be learnable quickly and usable confidently in the field with minimal technical training.',
    why: 'Rangers have varying technology experience. If the tool is confusing or inconsistent in the field, it will not be adopted regardless of its technical capabilities (Jayawardena, 2024).',
  },
]

const MATRIX_ROWS = [
  ['Offline-first architecture',        '25%', '4', '3', '5'],
  ['Integrated field workflow',         '20%', '1', '2', '5'],
  ['Shared data visibility',            '20%', '1', '2', '5'],
  ['Cost-effectiveness & scalability',  '15%', '4', '2', '5'],
  ['Cultural appropriateness',          '10%', '3', '2', '5'],
  ['Ease of use',                       '10%', '4', '3', '4'],
]

const CONCERNS = [
  ['Data sovereignty — who controls records of Country',
   'All records stored locally on ranger-owned devices. No data transmitted without explicit ranger action. Open-source codebase; community can modify or transfer repository ownership (ORIC, n.d.).'],
  ['Voice and language — structured forms exclude ranger knowledge',
   'Voice memo field allows rangers to record observations in their own words and language, capturing knowledge that dropdowns cannot hold (State of the Environment, 2021).'],
  ['Vendor lock-in — community becomes dependent on external platform',
   'Full codebase available at github.com/immanuel-lam/ewbrangerapp under open-source licence. No proprietary components.'],
  ['Safety — rangers working alone in remote areas',
   'Dedicated Safety tab with check-in timer, emergency SOS over mesh, and hazard logging.'],
  ['Connectivity — system fails when Starlink is down',
   'Bluetooth mesh sync requires no infrastructure. All features function without internet.'],
]

const COST_ROWS = [
  ['Apple Developer Account (TestFlight)', '1',    '$149/year',           '$149',  'Apple (2026)'],
  ['Supabase free tier (500 MB DB, 1 GB storage)', '1', '$0',             '$0',    'Supabase (2026)'],
  ['AWS S3 — est. 50 GB/year (photo records)', '50 GB', '$0.028/GB/month','~$17',  'Amazon Web Services (2026)'],
  ['Android APK distribution (direct install)', '—', '$0',                '$0',    '—'],
]

const JOURNEY = [
  ['Pre-deployment',      'Rangers are consulted on workflow requirements during the design process. Existing patrol habits and paper forms inform app structure.'],
  ['Dry season training', 'Two-day in-person workshop on Country. Rangers learn the logging workflow by completing real test sightings. Senior rangers identified as peer trainers.'],
  ['First patrol season', 'Rangers use the app alongside existing methods. Feedback collected at end-of-shift handover. Bugs reported via ranger office Starlink.'],
  ['Six-month review',    'Development team and rangers review adoption data and workflow issues. Updates released via TestFlight.'],
  ['Long-term',           'YAC optionally takes repository ownership. Rangers train new team members independently. App extended based on community-identified priorities.'],
]

const REFS = [
  'Aboriginal Cultural Landscape Management – Literature Review. (2025). Transport for NSW. https://www.transport.nsw.gov.au/system/files/media/documents/2025/Aboriginal-Cultural-Landscape-Management-Literature-Review.pdf',
  'Amazon Web Services. (2026). Amazon S3 pricing. https://aws.amazon.com/s3/pricing/',
  'Anshumali, A., & Gupta, S. (2025). Lantana camara: A review on ecology, invasion and management. International Journal of Agronomy, 8(2), 864–871.',
  'Apple. (2026). Apple Developer Program. https://developer.apple.com/programs/',
  'Batavia National Park (Cape York Peninsula Aboriginal Land) Management Statement 2014 — extended 2025. (2025). Queensland Parks and Wildlife Service.',
  'Biosecurity Queensland. (2026). Lantana. Business Queensland. https://www.business.qld.gov.au/industries/farms-fishing-forestry/agriculture/biosecurity/plants/invasive/restricted/lantana',
  'Centre for Appropriate Technology. (n.d.). Community planning with the Lama Lama people. https://www.cfat.org.au/community-planning-with-the-lama-lama-people',
  'CyberTracker. (n.d.). Indigenous knowledge. https://cybertracker.org/uses/indigenous-knowledge/',
  'Department of Environment, Science and Innovation (DESI). (n.d.). Cape York Peninsula: Extent of endangered, of concern and no concern at present regional ecosystems. State of the Environment Queensland.',
  'EWB Challenge. (2026). Port Stewart, Lama Lama. Engineers Without Borders Australia. https://ewbchallenge.org/challenge/port-stewart-lama-lama/',
  'Grains Research and Development Corporation (GRDC). (2025). The economics of precision weed management.',
  'Jayawardena, S. (2024). Green Savers: Mobile application solution for environmental conservation and community engagement [Thesis, Centria University of Applied Sciences]. Theseus.',
  'Lam, I. (2026). ewbrangerapp [Source code repository]. GitHub. https://github.com/immanuel-lam/ewbrangerapp',
  'Lama Lama Land and Sea Rangers. (n.d.). Welcome to Lama Lama Country. https://www.lamalama.org.au/',
  'Mousumi, S., & Jahan, N. (2025). Lantana camara L.: Biology, ecology and control. Plant Science Today, 12(2), 95–104.',
  'National Indigenous Australians Agency (NIAA). (n.d.). Indigenous Rangers Program (IRP). https://www.niaa.gov.au/our-work/environment-and-land/indigenous-rangers-program-irp',
  'Office of the Registrar of Indigenous Corporations (ORIC). (n.d.). Taking care of country. https://www.oric.gov.au/corporations-and-registers/corporation-stories/taking-care-country',
  'Queensland Government. (2020). Queensland\'s Protected Area Strategy 2020–2030.',
  'Sahu, N., & Chandola, V. (2025). Offline-first Android architecture for waste management in low connectivity areas. International Journal of Engineering Technology and Computer Science, 10(1).',
  'Sinden, J., Jones, R., Hester, S., Odom, D., Kalisch, C., James, R., & Cacho, O. (2004). The economic impact of weeds in Australia. Agecon Search.',
  'State of the Environment. (2021). Indigenous knowledge and land and sea management. Australian Government.',
  'Supabase. (2026). Pricing. https://supabase.com/pricing',
  'Taylor, D. B. (2017). Threats to Cape York rivers: Q-catchments risk assessment and threat prioritisation. ResearchGate.',
  'Walton, C. (2025). Lantana: Current management status and future prospects. DPI eResearch Archive.',
  'Woinarski, J. (2025). The natural attributes for World Heritage nomination of Cape York Peninsula. DCCEEW.',
  'Cape York Tours. (2023, July 16). What will I do in Cape York? [Photograph]. https://capeyorktours.com.au/what-will-i-do-in-cape-york/',
  'Invasive Species Blog. (2022, October 12). Research reveals invasive Lantana camara reduced growth of maize by 29% in East Usambara, Tanzania [Photograph]. https://blog.invasive-species.org/2022/10/12/research-reveals-invasive-lantana-camara-reduced-growth-of-maize-by-29-in-east-usambara-tanzania/',
  'Lama Lama Land and Sea Rangers. (n.d.). Rangers on Country [Photograph]. Yintjingga Aboriginal Corporation. https://www.lamalama.org.au/about-us/',
  'NRM Regions Australia. (n.d.). Cape York wetlands and native vegetation resilience [Photograph]. https://nrmregionsaustralia.com.au/project/cape-york-wetlands-and-native-vegetation-resilience/',
]

// ─── Nav ──────────────────────────────────────────────────────────────────────

function Nav() {
  const [solid, setSolid] = useState(false)
  useEffect(() => {
    const fn = () => setSolid(window.scrollY > 80)
    window.addEventListener('scroll', fn, { passive: true })
    return () => window.removeEventListener('scroll', fn)
  }, [])
  return (
    <nav className={`nav${solid ? ' nav-solid' : ''}`}>
      <div className="nav-inner">
        <a href="#top" className="nav-brand">Lama Lama Rangers</a>
        <div className="nav-links">
          <a href="#background">Background</a>
          <a href="#options">Options</a>
          <a href="#design">Selection</a>
          <a href="#detailed">Detailed Design</a>
          <a href="#prototype">Prototype</a>
          <a href="#implementation">Implementation</a>
          <a href="#considerations">Considerations</a>
          <a href="#references">References</a>
        </div>
      </div>
    </nav>
  )
}

// ─── Sections ─────────────────────────────────────────────────────────────────

function Hero() {
  const ref = useRef(null)
  useEffect(() => {
    const onScroll = () => {
      if (ref.current) {
        ref.current.style.backgroundPositionY = `calc(40% + ${window.scrollY * 0.35}px)`
      }
    }
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])
  return (
    <section className="hero" id="top" ref={ref} style={{ backgroundImage: `url(${imgBannerHero})` }}>
      <div className="container">
        <p className="eyebrow">EWB Challenge 2026 · Design Area 5 · Project Opportunity 5.5</p>
        <h1>Lama Lama Rangers App</h1>
        <p className="hero-sub">Offline-First Invasive Species Monitoring Tool</p>
        <p className="hero-lede">
          A mobile application built with and for the Lama Lama Land and Sea Rangers to detect,
          document, and manage invasive plant species across Lama Lama Country in Cape York
          Peninsula — without dependence on internet connectivity.
        </p>
        <div className="meta-grid">
          <div className="meta-cell">
            <span className="meta-key">Design Area</span>
            <span className="meta-val">5 — Climate Resilience and Adaptation</span>
          </div>
          <div className="meta-cell">
            <span className="meta-key">Opportunity</span>
            <span className="meta-val">5.5 — Biodiversity and Habitat Protection Tools</span>
          </div>
          <div className="meta-cell full">
            <span className="meta-key">How Might We Statement</span>
            <span className="meta-val">
              How might we support Lama Lama Rangers in detecting and managing invasive plant
              species across their Country without dependence on internet connectivity, in a way
              that complements Indigenous ecological knowledge and maintains community ownership of data?
            </span>
          </div>
          <div className="meta-cell full">
            <span className="meta-key">Keywords</span>
            <div className="kw-list">
              {['invasive species', 'offline-first', 'data sovereignty', 'Indigenous rangers', 'weed management'].map(k => (
                <span key={k}>{k}</span>
              ))}
            </div>
          </div>
        </div>
      </div>
      <p className="hero-credit">Photo: Cape York Tours (2023, July 16). https://capeyorktours.com.au/what-will-i-do-in-cape-york/</p>
    </section>
  )
}

function AckSection() {
  return (
    <section className="ack">
      <div className="container">
        <Reveal>
          <p className="ack-label">Acknowledgement of Country</p>
          <blockquote>
            We acknowledge the Lama Lama people as the Traditional Custodians of the land and sea
            Country on which this project is centred. We pay our respects to Lama Lama Elders past,
            present, and emerging, and recognise their enduring connection to Country — a connection
            expressed through thousands of years of careful land and sea management. This project was
            developed in the context of the Engineers Without Borders Challenge, which was produced in
            partnership with Yintjingga Aboriginal Corporation (YAC). We acknowledge that any technology
            solution proposed for Lama Lama Country must be developed with, not for, the community, and
            that sovereignty over land, knowledge, and data belongs to the Lama Lama people. We are
            grateful for the access to community knowledge and insights provided through the EWB
            Challenge framework.
          </blockquote>
        </Reveal>
      </div>
    </section>
  )
}

function GroupSection() {
  return (
    <section className="section section-alt">
      <div className="container">
        <Reveal>
          <SH n={0} title="Group Declaration" />
          <p>
            All team members contributed directly to this submission. The table below records each
            member's primary responsibilities across the assessment.
          </p>
          <Tbl
            cols={['Group Member', 'Project Contributions']}
            rows={GROUP}
          />
        </Reveal>
      </div>
    </section>
  )
}

function ProjectSection() {
  return (
    <section className="section" id="project">
      <div className="container">
        <Reveal>
          <SH n={1} title="Project Details" />
          <p>
            This project addresses Design Area 5.5 — Biodiversity and Habitat Protection Tools —
            from the 2026 EWB Challenge Design Brief. The Lama Lama Land and Sea Rangers conduct
            invasive plant management across a vast and remote territory in Cape York Peninsula,
            Queensland, but the tools currently available to them were not designed for an environment
            without internet connectivity or sealed road access. The group selected this project
            opportunity because the gap between the rangers' operational knowledge and the technology
            available to support it is both concrete and addressable through a purpose-built software
            solution.
          </p>
          <p>
            <strong>Needs statement.</strong> Lama Lama Rangers need a single, offline-capable tool
            that integrates GPS logging, photo documentation, treatment recording, and peer-to-peer
            data sharing into their existing patrol workflow — without dependence on connectivity
            infrastructure that is not reliably available on Country.
          </p>
        </Reveal>
      </div>
    </section>
  )
}

function BackgroundSection() {
  return (
    <section className="section section-alt" id="background">
      <div className="container">
        <Reveal>
          <SH n={2} title="Background" />
          <Banner
            src={imgBannerLantana}
            alt="Dense Lantana camara infestation"
            credit="Invasive Species Blog. (2022, October 12). Research reveals invasive Lantana camara reduced growth of maize by 29% in East Usambara, Tanzania. https://blog.invasive-species.org/2022/10/12/research-reveals-invasive-lantana-camara-reduced-growth-of-maize-by-29-in-east-usambara-tanzania/"
          />

          <h3>2.1 Context of the Problem</h3>
          <p className="lead">
            Port Stewart sits on Lama Lama Country in Cape York Peninsula, Queensland. The territory
            spans approximately 400,000 to 500,000 hectares of coastal wetland, river systems, savannah
            woodland, and rainforest managed by the Lama Lama Land and Sea Rangers across four ranger
            camps (Lama Lama Land and Sea Rangers, n.d.). Access to Port Stewart requires a flight to
            Cairns, an eight-hour drive to Coen, and a further hour on unpaved track — there are no
            sealed roads to or within the ranger territory (Centre for Appropriate Technology, n.d.).
            Energy is supplied by diesel generators and partial solar. The only broadband connection
            is a Starlink terminal at the ranger office, unavailable in the field.
          </p>
          <p>
            Cape York Peninsula hosts some of the most intact tropical biodiversity in Australia,
            but is under measurable ecological pressure. The Queensland Government's state-of-environment
            monitoring identifies the region as one where a significant proportion of ecosystems have
            been assessed as endangered or of concern (Department of Environment, Science and Innovation
            [DESI], n.d.). Invasive plants are a primary driver. <em>Lantana camara</em> alone is
            listed as a restricted invasive plant under Queensland biosecurity legislation, forming
            dense thickets that suppress native vegetation, reduce native fauna habitat quality, and
            become progressively harder to treat as infestations grow (Biosecurity Queensland, 2026;
            Walton, 2025). Nationally, weeds impose an estimated $4 billion in agricultural losses
            annually, and their ecological cost in sensitive landscapes like Cape York is harder to
            quantify but no less real (Sinden et al., 2004).
          </p>

          <StatRow stats={[
            { n: '400–500k ha', label: 'managed across Lama Lama Country — four ranger camps' },
            { n: '$4B',         label: 'estimated annual weed cost to Australian agriculture' },
            { n: '8 hrs',       label: 'drive from Cairns to site — no sealed roads on Country' },
          ]} />

          <h3>2.2 Significance to Stakeholders</h3>
          <p>
            The Lama Lama Rangers are both the primary stakeholders and the primary users. Ranger-led
            land and sea management integrates Indigenous ecological knowledge with scientific monitoring
            in ways that the State of the Environment (2021) identifies as fundamental to effective
            biodiversity management on Country. Rangers are not technicians implementing an external
            system — they are custodians whose knowledge of the land drives every management decision.
            The Yintjingga Aboriginal Corporation (YAC) holds governance responsibility for ranger
            operations. Data sovereignty — who owns the records of Country — is a direct concern for
            YAC and the broader Lama Lama community (ORIC, n.d.).
          </p>
          <p>
            Downstream stakeholders include Queensland biosecurity authorities, who rely on land
            managers meeting obligations under the <em>Biosecurity Act 2014</em> (Qld) (Biosecurity
            Queensland, 2026), and the broader ecological science community — Cape York Peninsula is
            a candidate site for World Heritage listing, and ranger monitoring data has regional and
            national value (Woinarski, 2025).
          </p>

          <h3>2.3 Existing Solutions</h3>
          <p>
            Several tools are currently used across ranger programs in Australia for environmental
            monitoring. CyberTracker is an established platform used in Indigenous ecological
            monitoring for structured, GPS-referenced field data collection (CyberTracker, n.d.).
            ArcGIS Field Maps provides offline GPS mapping and data collection capability.
            Drone-based aerial survey has been adopted for mapping infestation extent in some Cape
            York programs (DESI, n.d.). Chemical, biological, and mechanical weed control methods —
            including the <em>Aconophora compressa</em> biocontrol agent for <em>Lantana camara</em> —
            are documented within Queensland biosecurity practice (Walton, 2025).
          </p>

          <h3>2.4 Why Existing Solutions Are Insufficient</h3>
          <p>
            None of the existing platforms cover the full monitoring workflow in a single tool.
            CyberTracker does not support peer-to-peer data synchronisation between ranger devices
            without internet — rangers collect data independently and cannot share records in the
            field (CyberTracker, n.d.). ArcGIS Field Maps licensing costs are substantial and
            unsustainable for programs operating on grant funding cycles (GRDC, 2025).
            General-purpose mapping tools do not include the species-specific decision support
            that Lama Lama Rangers require: biocontrol presence checks, herbicide compatibility
            by species, seasonal risk overlays for six specific invasive species, and treatment
            effectiveness tracking at individual sites (Anshumali & Gupta, 2025; Mousumi &
            Jahan, 2025). The fragmentation across GPS devices, cameras, paper treatment records,
            and a centralised database means that team-wide visibility of infestation patterns is
            only achievable through manual post-patrol data consolidation — after the window for
            early intervention may have passed (Walton, 2025).
          </p>

          <h3>2.5 What This Project Aims to Achieve</h3>
          <p>
            This project aims to provide Lama Lama Rangers with a single, offline-capable field
            tool that integrates sighting logging, treatment recording, team data sharing, and
            species-specific decision support into the existing patrol workflow — at near-zero
            ongoing cost and with full community ownership of the data and codebase.
          </p>
        </Reveal>
      </div>
    </section>
  )
}

function ProblemSection() {
  return (
    <section className="section" id="problem">
      <div className="container">
        <Reveal>
          <SH n={3} title="Problem Description" />

          <div className="needs">
            <p className="needs-lbl">User needs statement</p>
            <p>
              Lama Lama Rangers need a mobile tool that works without internet, records invasive plant
              sightings and treatment actions in one workflow, shares data between devices in the field,
              and keeps the whole team informed — so infestations can be detected early and managed
              effectively across a remote landscape.
            </p>
          </div>

          <p className="lead">
            Invasive plant monitoring at Port Stewart is currently split across disconnected tools:
            GPS units, cameras, paper forms, and a centralised database that rangers access only at
            the office. Each patrol generates records that must be manually consolidated after the
            fact, creating gaps in coverage and delays in identifying where infestations are
            concentrated. Early detection is critical — research confirms that small infestations of
            <em> Lantana camara</em> are significantly cheaper and faster to treat than established
            stands (Walton, 2025). In a landscape without roads, where patrols cover large distances
            by foot and boat, a ranger who must choose between completing a patrol and stopping to
            document properly will choose the patrol. The tool has to fit the workflow, not the other
            way around.
          </p>

          <h3>3.1 Design Criteria</h3>
          <div>
            {CRITERIA.map((c, i) => (
              <Reveal key={i} delay={i * 0.04}>
                <div className="criterion">
                  <h4>{c.name}</h4>
                  <p>{c.desc}</p>
                  <p className="criterion-why"><em>{c.why}</em></p>
                </div>
              </Reveal>
            ))}
          </div>
        </Reveal>
      </div>
    </section>
  )
}

function OptionsSection() {
  return (
    <section className="section section-alt" id="options">
      <div className="container">
        <Reveal>
          <SH n={4} title="Design Solution Options" />

          <div className="opt">
            <h3>Option 1 — Enhanced Paper-Based System</h3>
            <p>
              Standardised paper forms with a structured layout for recording GPS coordinates (read
              from a handheld unit), photograph reference numbers, species identification, infestation
              size estimate, and treatment details. Forms are collected at the end of each patrol and
              digitised at the ranger office. Existing ranger programs in remote areas have used
              paper-based systems as a low-cost baseline (State of the Environment, 2021).
            </p>
            <p>
              This option is low cost, requires no training in new technology, and functions in any
              conditions. However, it fails to address the coordination gap: records cannot be shared
              between rangers in the field, GPS coordinates require a separate device, and digitisation
              at the office introduces delays and data loss risk. It does not enable early detection at scale.
            </p>
          </div>

          <div className="opt">
            <h3>Option 2 — Adaptation of CyberTracker</h3>
            <p>
              CyberTracker is an open-source platform used in Indigenous ecological monitoring that
              supports structured GPS-referenced data collection via mobile devices (CyberTracker, n.d.).
              Adapting it for the Lama Lama context would involve configuring species-specific forms and
              deploying it on ranger devices. It supports offline data collection and has an established
              track record in ranger programs.
            </p>
            <p>
              CyberTracker does not support peer-to-peer synchronisation between devices without internet,
              meaning rangers cannot share data in the field. It does not include the treatment decision
              support — herbicide compatibility checks, biocontrol prompts — that the Lama Lama context
              requires. Configuration for six species with seasonal risk overlays and follow-up tracking
              would require significant technical effort on a platform not designed for this use case.
            </p>
          </div>

          <div className="opt">
            <h3>Option 3 — Purpose-Built Offline-First Mobile Application</h3>
            <p>
              A custom application built for iOS and Android, open-source, deployed on existing ranger
              devices. All core functions operate offline. Rangers share records directly between devices
              over Bluetooth mesh. The application includes species-specific decision support, a shared
              map view, and safety features for remote field operations (Sahu & Chandola, 2025;
              Jayawardena, 2024).
            </p>
            <p>
              This option requires the greatest upfront design and development effort, but is the only
              option that meets all six criteria. The open-source codebase means the community is not
              locked into any vendor and retains full control of the tool.
            </p>
          </div>
        </Reveal>
      </div>
    </section>
  )
}

function SelectionSection() {
  return (
    <section className="section" id="design">
      <div className="container">
        <Reveal>
          <SH n={5} title="Design Selection" />
          <p>
            Options were scored against each criterion on a scale of 1 to 5, where 1 = does not
            meet the criterion and 5 = fully meets the criterion. Weights reflect the relative
            importance of each criterion to the Port Stewart context, with offline functionality
            weighted most heavily given the non-negotiable connectivity constraint.
          </p>
          <Tbl
            cols={['Criterion', 'Weight', 'Option 1: Paper', 'Option 2: CyberTracker', 'Option 3: Purpose-Built App']}
            rows={MATRIX_ROWS}
            foot={['Weighted Total', '100%', '2.65', '2.35', '4.90']}
          />
          <p>
            <strong>Justification.</strong> Option 1 scores well on offline functionality and ease
            of use — paper always works — but scores 1 on both workflow integration and shared data
            visibility, which are the core functional requirements. Paper records cannot aggregate
            into a team-wide map view. Option 2 scores higher on workflow than paper but fails on
            peer-to-peer sync, and the absence of species-specific decision support limits its fit
            for this context. Option 3 scores 5 across five of six criteria. The only criterion
            where it does not score maximum is ease of use, given that a custom application requires
            ranger onboarding — addressed in the implementation plan through in-person training.{' '}
            <strong>Option 3 was selected.</strong>
          </p>
        </Reveal>
      </div>
    </section>
  )
}

function DetailedSection() {
  return (
    <section className="section section-alt" id="detailed">
      <div className="container">
        <Reveal>
          <SH n={6} title="Detailed Design" />
          <Banner
            src={imgBannerRangers}
            alt="Lama Lama Land and Sea Rangers on Country"
            credit="Lama Lama Land and Sea Rangers. (n.d.). Rangers on Country. Yintjingga Aboriginal Corporation. https://www.lamalama.org.au/about-us/"
          />
          <p className="lead">
            The Lama Lama Rangers App is an offline-first mobile application for iOS (Swift/SwiftUI)
            and Android (Jetpack Compose). Every core function operates without internet connectivity.
            Data is stored locally using CoreData (iOS) and Room (Android). Peer-to-peer sync between
            ranger devices uses Apple MultipeerConnectivity (iOS) and Google Nearby Connections (Android).
            When the ranger office Starlink is available, records sync to cloud storage via Supabase
            and AWS S3.
          </p>
          <p className="fig">Figure 1: Application architecture — offline-first data flow from device storage to Bluetooth mesh sync to cloud sync when connectivity is available.</p>

          <StatRow stats={[
            { n: '6',  label: 'invasive species covered in the offline plant guide' },
            { n: '5',  label: 'primary application sections' },
            { n: '0 bars', label: 'connectivity required — full functionality offline' },
          ]} />

          <p>The application has six primary sections:</p>
          <div>
            <div className="feat">
              <h4>Map</h4>
              <p>
                Displays all logged sightings as colour-coded pins, organised by species or treatment
                status. Rangers can filter by species, activate the seasonal risk overlay
                (phenology-based, highlighting active weed zones by month), or zoom into specific
                ranger camp areas. All data loads from local storage — no signal required during patrol.
              </p>
            </div>
            <div className="feat">
              <h4>Activity Logging</h4>
              <p>
                In one screen, a ranger pins the GPS location, attaches a photo, selects the species,
                estimates infestation area, records treatment method, and adds a voice memo. The
                Herbicide Compatibility Checker confirms the correct product and warns against applying
                foliar spray when <em>Aconophora compressa</em> biocontrol agents are present —
                spraying in this context undermines long-term management (Walton, 2025). The Treatment
                Effectiveness Tracker logs follow-up observations at the same site across patrols.
              </p>
            </div>
            <div className="feat">
              <h4>Plant Guide</h4>
              <p>
                A fully offline reference library covering identification features, control methods,
                herbicide mixing ratios, and an Equipment Maintenance Log for six invasive species:{' '}
                <em>Lantana camara</em>, Rubber Vine, Prickly Acacia, Sicklepod, Giant Rat's Tail
                Grass, and Pond Apple (DESI, n.d.; Batavia National Park Management Statement, 2025).
              </p>
            </div>
            <div className="feat">
              <h4>Ranger Safety</h4>
              <p>
                A GPS Hazard Logger, Safety Check-In Timer (alerts team devices if a ranger misses
                check-in), Emergency SOS over Bluetooth mesh, and Night Vision Red Light Mode. This
                tab addresses the real risks of working alone in isolated Country, including conditions
                following high-impact weather events such as Cyclone Narelle (EWB Challenge, 2026).
              </p>
            </div>
            <div className="feat">
              <h4>Hub</h4>
              <p>
                Team-wide dashboard showing sighting trends, treatment coverage, and a Zone Conflict
                Resolver for when two rangers have edited the same zone boundary offline.
              </p>
            </div>
          </div>

          <div className="phones">
            <Phone src={imgMap}     caption="Map — colour-coded sightings" />
            <Phone src={imgLog}     caption="Activity logging" />
            <Phone src={imgSpecies} caption="Plant guide" />
            <Phone src={imgHub}     caption="Hub dashboard" />
          </div>
          <p className="fig">Figure 2: Map, Activity Logging, Plant Guide, and Hub screens.</p>

          <div className="phones">
            <Phone src={imgSafetyTimer} caption="Safety check-in timer" />
            <Phone src={imgRedLight}    caption="Night vision mode" />
            <Phone src={imgVoiceNote}   caption="Voice memo recording" />
            <Phone src={imgConflict}    caption="Zone conflict resolver" />
          </div>
          <p className="fig">Figure 3: Ranger Safety tab and team coordination screens.</p>

          <h3>Community Concerns and Mitigations</h3>
          <Tbl cols={['Concern', 'How the Design Addresses It']} rows={CONCERNS} />
        </Reveal>
      </div>
    </section>
  )
}

function ProtoSection() {
  return (
    <section className="section" id="prototype">
      <div className="container">
        <Reveal>
          <SH n={7} title="Prototyping" />

          <h3>7.1 What Was Prototyped and Why</h3>
          <p className="lead">
            The prototype focused on the full end-to-end field workflow: from launching the app on
            a ranger device through GPS sighting capture, treatment logging, and Bluetooth mesh
            synchronisation to a second device. This workflow was prioritised because it is the
            highest-risk interaction — if rangers cannot complete a sighting record quickly in the
            field, they will not use the tool. Visual design and navigation were also validated
            through three progressive versions.
          </p>

          <h3>7.2 Construction Process</h3>
          <p>
            Three versions were developed using Swift/SwiftUI for iOS and Jetpack Compose for Android,
            with CoreData for local persistence and Apple MultipeerConnectivity for Bluetooth mesh sync.
            Each version was built on the previous codebase, with new features developed on isolated
            branches and merged after testing. The full codebase and version history are publicly
            available at{' '}
            <a href="https://github.com/immanuel-lam/ewbrangerapp" target="_blank" rel="noreferrer">
              github.com/immanuel-lam/ewbrangerapp
            </a>{' '}
            (Lam, 2026).
          </p>

          <StatRow stats={[
            { n: '3',  label: 'prototype versions — V1 proof of concept through V3 current' },
            { n: '32', label: 'features in the V3 release' },
            { n: '2',  label: 'physical iOS devices used for mesh sync testing' },
          ]} />

          <h3>7.3 Version Progression</h3>
          <div className="versions">
            <div className="ver">
              <span className="ver-tag">V1</span>
              <div className="ver-body">
                <h4>Proof of Concept</h4>
                <p>
                  Scoped to <em>Lantana camara</em> only. Validated the core data model: a sighting
                  tied to a GPS location, species, and treatment record. Features: GPS sighting log,
                  basic map centred on Port Stewart, treatment recording, CoreData persistence, PIN
                  authentication, three-tab UI. V1 confirmed the data model was appropriate but
                  exposed two critical gaps: single-species scope did not reflect reality, and the
                  absence of peer-to-peer sync meant rangers had no way to share records in the field.
                </p>
                <div className="phones phones-sm" style={{ gridTemplateColumns: 'repeat(2, 1fr)', maxWidth: 320 }}>
                  <Phone src={imgV1Log} caption="V1 log screen" />
                  <Phone src={imgLog}   caption="V3 log screen" />
                </div>
                <p className="fig" style={{ textAlign: 'left' }}>Figure 4: V1 → V3 log screen progression.</p>
              </div>
            </div>
            <div className="ver">
              <span className="ver-tag">V2</span>
              <div className="ver-body">
                <h4>Full Redesign</h4>
                <p>
                  Extended to six invasive species. Architecture moved to MVVM + Repository pattern.
                  Key additions: Bloom Calendar (seasonal risk overlay), satellite/standard map views
                  with infestation zone polygons, Lantana Biocontrol Prompt, before/after photo
                  comparison, patrol checklist with stamina metric, Bluetooth mesh sync via
                  MultipeerConnectivity, Shift Handover Card (generates end-of-shift summary from
                  live CoreData counts), Zone Conflict Resolver.
                </p>
              </div>
            </div>
            <div className="ver">
              <span className="ver-tag">V3</span>
              <div className="ver-body">
                <h4>Current</h4>
                <p>
                  Twelve features added: dedicated Ranger Safety tab (check-in timer, hazard logger,
                  emergency SOS, night vision mode), voice memo support, phenology alerts integrated
                  into logging flow, Herbicide Compatibility Checker in treatment entry, Treatment
                  Effectiveness Tracker, Equipment Maintenance Log, Ranger Status Broadcast over mesh,
                  and cloud sync via Supabase and AWS S3 for when ranger office Starlink is available.
                  All V3 features function without internet.
                </p>
              </div>
            </div>
          </div>

          <div className="phones">
            <Phone src={imgTreatment} caption="Treatment entry (V3)" />
            <Phone src={imgBicontrol} caption="Biocontrol prompt" />
            <Phone src={imgBloom}     caption="Bloom calendar" />
            <Phone src={imgChecklist} caption="Patrol checklist" />
          </div>
          <p className="fig">Figure 5: Treatment entry with Herbicide Compatibility Checker, Biocontrol Prompt, Bloom Calendar, and Patrol Checklist.</p>

          <h3>7.4 Testing</h3>
          <p>
            The prototype was tested on physical iOS devices across the core logging workflow,
            Bluetooth mesh synchronisation between two devices, and offline map loading without
            network access. The Zone Conflict Resolver was tested by seeding conflicting zone
            edits from two devices and validating the merge interface.
          </p>

          <h3>7.5 Results and Modifications</h3>
          <p>
            Bluetooth mesh sync was confirmed reliable between two iOS devices without internet.
            Offline map loading from CoreData was validated. The V2 patrol stamina metric was
            flagged as a lower priority feature in the context of the broader workflow and retained
            as optional. The Herbicide Compatibility Checker was moved from a standalone screen in
            V2 to the treatment entry flow in V3 after testing showed rangers were unlikely to
            access it separately before spraying. Full test logs are provided in Appendix 2 for reference.
          </p>
        </Reveal>
      </div>
    </section>
  )
}

function ImplSection() {
  return (
    <section className="section section-alt" id="implementation">
      <div className="container">
        <Reveal>
          <SH n={8} title="Implementation Plan" />

          <h3>8.1 Installation and Community Training</h3>
          <p className="lead">
            The iOS application is distributed via Apple TestFlight — no App Store approval required,
            no new hardware needed. An Android APK is distributed directly to Android devices in the
            ranger fleet. Installation is completed with development team support via the ranger
            office Starlink connection.
          </p>
          <p>
            A two-day in-person training workshop is proposed for the 2026 dry season (May–July),
            when the Coen–Port Stewart track is most reliably passable. In-person, hands-on training
            is the most effective model for technology adoption in remote community contexts (Centre
            for Appropriate Technology, n.d.). The workshop covers the core logging workflow, map
            navigation, Bluetooth mesh sync, and safety features. Rangers with greater technical
            confidence act as peer trainers for future onboarding of new team members, embedding the
            knowledge within the community rather than maintaining external dependency.
          </p>

          <h3>8.2 Rollout and Ongoing Use</h3>
          <p>
            Following training, rangers use the application across active patrol seasons. Bug reports
            and feedback are collected via the ranger office Starlink connection. The shift handover
            card — which generates a plain-text summary of patrol activity from live CoreData records
            — provides a daily data quality check without requiring rangers to access additional
            systems. The Hub dashboard gives ranger coordinators a team-wide view of sighting trends
            and coverage gaps.
          </p>

          <div className="phones phones-sm">
            <Phone src={imgHandover} caption="Shift handover card" />
            <Phone src={imgDaySync}  caption="Day sync view" />
            <Phone src={imgPatrol}   caption="Patrol log" />
          </div>
          <p className="fig">Figure 6: Shift handover card (auto-generated from CoreData), day sync, and patrol log.</p>

          <h3>8.3 Evaluation</h3>
          <p>
            Success is measured across three dimensions: adoption rate (proportion of patrols with
            digital records logged), data completeness (proportion of sightings with GPS, photo,
            species, and treatment fields complete), and sync reliability (proportion of field records
            successfully shared between devices via Bluetooth mesh). A six-month review after initial
            deployment is recommended to assess these metrics and identify workflow improvements.
          </p>

          <h3>8.4 Community Ownership</h3>
          <p>
            The GitHub repository is available for transfer to YAC ownership on request. All data
            remains on ranger-owned devices unless rangers explicitly sync to cloud. The open-source
            codebase means YAC or any future technical partner can modify, extend, or audit the
            application without requiring engagement with the original development team. No external
            party holds access to ranger data.
          </p>

          <h3>8.5 Repair and Failure Pathways</h3>
          <p>
            The application is software-only — hardware failure defaults to the ranger's existing
            device repair pathways. Application bugs are addressed through TestFlight updates
            delivered via Starlink. If the Starlink terminal is offline for an extended period, all
            core app functions continue to operate, and mesh sync between ranger devices remains
            available. Cloud data is a backup, not a dependency.
          </p>
        </Reveal>
      </div>
    </section>
  )
}

function CostSection() {
  return (
    <section className="section" id="cost">
      <div className="container">
        <Reveal>
          <SH n={9} title="Cost Analysis" />
          <h3>Software Cost Summary</h3>
          <Tbl
            cols={['Item', 'Quantity', 'Unit Cost (AUD/year)', 'Total (AUD/year)', 'Source']}
            rows={COST_ROWS}
            foot={['Total Year 1', '', '', '~$166', '']}
          />
          <StatRow stats={[
            { n: '~$166',      label: 'total Year 1 software cost' },
            { n: '$0',         label: 'ongoing licensing — no vendor lock-in' },
            { n: '$500–2,000', label: 'per-seat cost of commercial GIS alternatives (GRDC, 2025)' },
          ]} />

          <h3>Maintenance and Ongoing Costs</h3>
          <p>
            If data volume grows beyond Supabase free tier thresholds in subsequent years, a Supabase
            Pro subscription at approximately $300/year would still be significantly below commercial
            alternatives. Licensed GIS platforms commonly carry per-seat fees of $500–$2,000 per year
            (GRDC, 2025). All development iteration costs are absorbed through open-source contribution
            or volunteer time — there are no vendor fees.
          </p>
          <h3>Financial Sustainability</h3>
          <p>
            The ~$166 annual cost is fundable through existing ranger program operational budgets without
            requiring a separate grant. The Indigenous Rangers Program (NIAA, n.d.) and the Queensland
            Protected Area Strategy 2020–2030 (Queensland Government, 2020) both provide funding pathways
            for ranger program operational tools that can be cited in future grant applications. The
            absence of hardware costs — achieved by deploying on existing ranger devices — is the primary
            cost advantage over any alternative that requires new equipment procurement.
          </p>
        </Reveal>
      </div>
    </section>
  )
}

function ConsiderationsSection() {
  return (
    <section className="section section-alt" id="considerations">
      <div className="container">
        <Reveal>
          <SH n={10} title="Other Considerations" />
          <Banner
            src={imgBannerWetlands}
            alt="Cape York wetlands and native vegetation"
            credit="NRM Regions Australia. (n.d.). Cape York wetlands and native vegetation resilience. https://nrmregionsaustralia.com.au/project/cape-york-wetlands-and-native-vegetation-resilience/"
          />

          <div>
            <div className="con">
              <h4>Biosecurity obligations</h4>
              <p>
                Lama Lama Rangers operating under priority weed action plans are required under the{' '}
                <em>Biosecurity Act 2014</em> (Qld) to take reasonable steps to prevent the spread
                of restricted invasive plants (Biosecurity Queensland, 2026). The app's timestamped,
                GPS-referenced treatment records provide an auditable log of management actions at
                each site, directly supporting legal compliance.
              </p>
            </div>
            <div className="con">
              <h4>Biocontrol integration</h4>
              <p>
                The Lantana Biocontrol Prompt warns rangers not to apply foliar spray if{' '}
                <em>Aconophora compressa</em> biocontrol agents are present — an error that would
                undermine long-term management at the site (Walton, 2025). No existing
                general-purpose tool provides this check. It is embedded in the treatment entry flow
                so the decision is made before spraying, not as a retrospective check.
              </p>
            </div>
            <div className="con">
              <h4>Cultural protocols</h4>
              <p>
                Voice memo support allows rangers to record observations in language and in their own
                words, capturing ecological knowledge that structured data fields cannot hold (State
                of the Environment, 2021). Any future extension — drone data import, community-facing
                dashboards, integration with external databases — must be subject to YAC and ranger
                community consultation before development proceeds. The principle of designing with,
                not for, applies beyond the initial build.
              </p>
            </div>
            <div className="con">
              <h4>Infrastructure resilience</h4>
              <p>
                The Bluetooth mesh architecture means team data sharing does not depend on the
                Starlink terminal remaining operational. Following events like Cyclone Narelle, which
                caused significant infrastructure damage across the Cape York region, a monitoring
                system that depends on a single connectivity point risks extended outage precisely
                when coordinated land management is most needed (EWB Challenge, 2026). Mesh-first
                sync is a direct response to that risk.
              </p>
            </div>
          </div>

          <h3>Community Journey Map</h3>
          <Tbl cols={['Stage', 'Ranger Experience']} rows={JOURNEY} />
        </Reveal>
      </div>
    </section>
  )
}

function RecsSection() {
  return (
    <section className="section" id="recommendations">
      <div className="container">
        <Reveal>
          <SH n={11} title="Recommendations" />
          <ol className="recs">
            <li>
              Conduct a formal usability review with Lama Lama Rangers during the 2026 dry season,
              before full deployment, to identify workflow issues specific to field conditions not
              captured during development.
            </li>
            <li>
              Bring the Android app to full feature parity with the iOS version so all ranger devices
              are supported regardless of platform.
            </li>
            <li>
              Investigate integration with Queensland weed mapping databases, subject to explicit YAC
              consent on data sharing scope, to allow ranger records to contribute to regional
              monitoring programs.
            </li>
            <li>
              Establish an annual review with YAC to assess whether the six-species scope remains
              current, and whether the priority weed action plan has identified additional species
              for inclusion.
            </li>
            <li>
              Explore grant funding through the Indigenous Rangers Program (NIAA, n.d.) and
              Queensland Protected Area Strategy (Queensland Government, 2020) to support training
              costs and any future development work.
            </li>
          </ol>
        </Reveal>
      </div>
    </section>
  )
}

function RefsSection() {
  return (
    <section className="section section-refs" id="references">
      <div className="container">
        <Reveal>
          <SH n={12} title="References" />
          <ul className="refs">
            {REFS.map((r, i) => <li key={i}>{r}</li>)}
          </ul>
        </Reveal>
      </div>
    </section>
  )
}

function PromptLogSection() {
  return (
    <section className="section section-alt" id="prompt-log">
      <div className="container">
        <Reveal>
          <div className="sec-hd">
            <span className="sec-n">A4</span>
            <h2>Appendix: AI Prompt Log</h2>
          </div>
          <p>Generated using Claude Sonnet 4.6 (claude.ai) for content drafting and structure.</p>
          <Tbl
            cols={['Prompt', 'AI Response Summary', 'How It Was Used / Modified']}
            rows={[[
              'Planning doc + references provided; requested full website draft following assessment template',
              'Full 4000-word draft across all 11 sections with APA7 inline citations, decision matrix, implementation plan, and cost analysis',
              'Reviewed by all team members; Port Stewart-specific context verified against EWB brief and individual research; statistics verified against cited sources; team names and contributions updated',
            ]]}
          />
        </Reveal>
      </div>
    </section>
  )
}

function Footer() {
  return (
    <footer className="footer">
      <div className="container">
        <p>Lama Lama Rangers App · EWB Challenge 2026 · 31265 Communication for IT Professionals, UTS</p>
        <p>Design Area 5.5 — Biodiversity and Habitat Protection Tools · Yintjingga Aboriginal Corporation</p>
      </div>
    </footer>
  )
}

// ─── Root ─────────────────────────────────────────────────────────────────────

export default function App() {
  return (
    <>
      <Nav />
      <main>
        <Hero />
        <AckSection />
        <GroupSection />
        <ProjectSection />
        <BackgroundSection />
        <ProblemSection />
        <OptionsSection />
        <SelectionSection />
        <DetailedSection />
        <ProtoSection />
        <ImplSection />
        <CostSection />
        <ConsiderationsSection />
        <RecsSection />
        <RefsSection />
        <PromptLogSection />
      </main>
      <Footer />
    </>
  )
}
