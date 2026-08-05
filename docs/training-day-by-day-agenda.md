# YAAIF Customer & Partner Training — Day-by-Day Agenda

Facilitator agenda for the **4-day intensive** (Tracks A–F).  
Primary tools: **YAAIF Admin UI** (operate/govern) · **Cursor `yaaif` plugin** (build/iterate).

| | |
|---|---|
| **Cohort size** | ≤12 builders per instructor; operators can be larger |
| **Lab tenant** | Isolated sandbox per org (or per learner if possible) |
| **Timezone** | Adjust blocks to local day; times below assume 09:00–17:30 with breaks |
| **Prereq (developers)** | Cursor + `yaaif` plugin installed; Node ≥ 20; smoke through `yaaif_whoami` |

**Shorter paths**

| Path | Days to use |
|---|---|
| Business-only (operators + light admin) | Day 1 only (+ optional Day 2 morning admin) |
| Partner builders (skip deep operator labs) | Days 1 (A only) → 2–4 as written, compress Track B |
| Advanced-only refresh | Days 3–4 |

---

## Pre-work (async, before Day 1)

**All attendees (~30–45 min)**

- [ ] Watch 10-min “What is YAAIF?” overview (architecture: chat → skills/MCP → ambient → desktop)
- [ ] Confirm Org SSO / sandbox login works for Admin UI
- [ ] Note assigned **tenant** name/UUID

**Developers / partners (~1–2 h)** — *must complete before Day 2 afternoon*

- [ ] Install Cursor **yaaif** plugin (Marketplace or local)
- [ ] Configure profile (`hosted` or `local-hybrid`) via plugin vars / `yaaif_platform_use`
- [ ] Run `/yaaif-login` → `/yaaif-doctor`
- [ ] Confirm `yaaif_whoami` shows correct tenant
- [ ] Skim [getting-started.md](./getting-started.md) + [partner-workflows.md](./partner-workflows.md)

**Instructors**

- [ ] Sandbox tenant seeded: demo chat agent, 1 MCP tool, 1 ambient workflow with HITL, 1 “broken” run for ops lab
- [ ] Desktop worker online for demo (or video fallback)
- [ ] Slide deck + command cheat sheet printed/shared
- [ ] Capstone brief + rubric ready

---

## Day 1 — Foundations, operators, admin start

**Theme:** Shared mental model + operate the platform in the UI.  
**Tracks:** A (all) · B (operators) · C start (admins)

| Time | Block | Audience | Content | Outcomes / labs |
|---|---|---|---|---|
| 09:00–09:20 | Welcome | All | Goals, agenda, sandbox rules, safety (no prod tenants) | Roster + expectations |
| 09:20–10:20 | **A1 Architecture** | All | Chat agents, skills, MCP, ambient, desktop, approvals; when to use which | Decision matrix flashcards |
| 10:20–10:35 | Break | | | |
| 10:35–11:20 | **A2 Tool split** | All | Admin UI = operate/govern; Cursor plugin = build; Desktop app = worker | “Which tool?” quiz (5 Qs) |
| 11:20–12:15 | **A3 Admin UI tour** | All | Control Center, Agents, Skills, Capabilities, Approvals, Workflow/Desktop Runs, LLM Sessions, Workers, Usage | Live click-path; no deep config yet |
| 12:15–13:15 | Lunch | | | |
| 13:15–14:15 | **B1 Chat as end user** | Ops (+ builders observe) | Sign-in, tenant, pick agent, good prompts, file attach (if enabled) | **Lab B1:** Guided chat on demo agent |
| 14:15–15:00 | **B2 Approvals** | Ops | Inbox, claim, approve/reject; impact on ambient | **Lab B2:** Approve staged HITL task |
| 15:00–15:15 | Break | | | |
| 15:15–16:00 | **B3 Run visibility & escalate** | Ops | Workflow Runs, Desktop Runs, LLM Sessions; copy IDs | **Lab B3:** Find failed run + write escalation note |
| 16:00–17:00 | **C1 Users, roles, agents** | Admins (+ builders) | RBAC least privilege; create agent (goal, model, guardrails, skills) | **Lab C1–C2:** Role/user + starter agent |
| 17:00–17:30 | Day 1 wrap | All | Recap; developer pre-work check; parking lot | Exit ticket (3 bullets) |

**Day 1 exit criteria**

- [ ] Everyone can explain chat vs ambient vs desktop in one sentence each  
- [ ] Operators completed Labs B1–B3  
- [ ] Admins created/verified a user/role and inspected an agent  
- [ ] Developers confirmed plugin pre-work done (or office hours booked)

**Facilitator notes**

- Keep builders in operator labs — they need empathy for the UX they ship into.  
- Do not open Cursor plugin until Day 2 afternoon (except pre-work help desk).

---

## Day 2 — Tenant admin finish + developer bootstrap

**Theme:** Make a tenant usable; then build the first skill from Cursor.  
**Tracks:** C finish · D Day 1

| Time | Block | Audience | Content | Outcomes / labs |
|---|---|---|---|---|
| 09:00–09:15 | Standup | All | Day 1 recap; unblock logins | |
| 09:15–10:15 | **C2 Skills & Advanced Skills** | Admins + builders | Catalog CRUD vs file tree; enable/map concepts | Inspect demo skill in UI |
| 10:15–11:00 | **C3 MCP in Admin UI** | Admins + builders | Capabilities: transport, endpoint, Test Connection | **Lab C3:** Register/test demo MCP (or validate existing) |
| 11:00–11:15 | Break | | | |
| 11:15–12:15 | **C4 Desktop runtime** | Admins + builders | Workers: provision key → desktop-app register → heartbeat → Desktop Runs | **Lab C4:** Worker online + enqueue test run *(or instructor demo if BYOD blocked)* |
| 12:15–13:15 | Lunch | | | |
| 13:15–13:45 | **C5 Daily admin checklist** | Admins | Control Center, Approvals, Workers, Token/Credit Usage, Guardrails, About | Checklist handout walkthrough |
| 13:45–14:30 | **D1.1–D1.2 Plugin auth** | Developers | Marketplace/local install; profiles; `/yaaif-login`; `/yaaif-doctor` | Doctor green: auth, tenant, `local_tools`, catalog |
| 14:30–15:15 | **D1.3 Catalog literacy** | Developers | `yaaif_catalog_overview`; list agents/skills/MCP/ambient/local tools | **Lab:** Snapshot sandbox catalog |
| 15:15–15:30 | Break | | | |
| 15:30–16:15 | **D1.4 Platform local tools** | Developers | `/yaaif-platform-tools`; never invent `tools:` names; `yaaif_skill_tools_check` | List + inspect one local tool schema |
| 16:15–17:15 | **D1.5 First chat skill** | Developers | `/yaaif-new-skill` → tools check → enable → `yaaif_skill_map_agents_merge` → refresh/reload | **Lab D-Skill#1:** Ship Q&A skill over existing MCP/local tool |
| 17:15–17:30 | Verify + wrap | Developers | Prove skill in Admin UI + chat | Day 2 exit check |

**Operators** (if still in cohort after lunch): optional office hours, self-paced B recap, or dismiss.

**Day 2 exit criteria**

- [ ] Admin path: MCP tested, worker story understood, daily checklist owned  
- [ ] Each developer: `whoami` OK, doctor OK, **one mapped skill**, chat proof in UI  

**Facilitator notes**

- Prefer `yaaif_skill_map_agents_merge` — call out danger of replace wiping mappings.  
- If doctor fails: use [configure-environment.md](./configure-environment.md) (OIDC `.local` vs `.com` cookie issue).

---

## Day 3 — Plan → ambient → verify (builder core)

**Theme:** Multi-capability delivery the partner way.  
**Tracks:** D Day 2 · Capstone start

| Time | Block | Audience | Content | Outcomes / labs |
|---|---|---|---|---|
| 09:00–09:20 | Standup | Builders | Show Skill #1 demos (2–3 volunteers) | Confidence check |
| 09:20–10:20 | **D2.1 Use-case planning** | Builders | `/yaaif-plan`: interview → decompose → **stop for approval** | Decision matrix applied to canned scenario |
| 10:20–11:00 | **D2.2 Dry-run & checklist** | Builders | `yaaif_plan_dry_run`; `yaaif_plan_execution_save` / update step / resume | Dry-run without mutating tenant |
| 11:00–11:15 | Break | | | |
| 11:15–12:30 | **D2.3 Install order** | Builders | MCP → agents → approval strategy → ambient → skills → map → desktop | Execute instructor-approved plan (gated) |
| 12:30–13:30 | Lunch | | | |
| 13:30–14:45 | **D2.4 Ambient + chat trigger** | Builders | `/yaaif-new-workflow`; test-trigger; skill must use `list_ambient_workflows` + `trigger_ambient_workflow` | **Lab:** Chat → ambient e2e |
| 14:45–15:00 | Break | | | |
| 15:00–15:45 | **D2.5 Verify in plugin + UI** | Builders | `yaaif_plan_verify`; Workflow Runs / Approvals / LLM Sessions | Checklist green |
| 15:45–16:30 | **D2.6 Ops hygiene** | Builders | `/yaaif-ops` read-only; correlate IDs; no pause/approve/retry via ops skill | Triage one planted failure |
| 16:30–17:30 | **Capstone kickoff** | Builders | Brief, rubric, team/solo assignment; start plan draft | Plan file started; approval by EOD or next morning |

**Capstone brief (default)**  
*Invoice (or domain) triage in chat → trigger ambient process → HITL approve → completion visible in Admin UI.*

**Day 3 exit criteria**

- [ ] Written `/yaaif-plan` for capstone (or canned scenario) reviewed by instructor  
- [ ] At least one chat→ambient path demonstrated in lab  
- [ ] Learner can narrate install order without notes  

**Facilitator notes**

- Enforce **plan approval before execute** — this is the habit partners must keep.  
- Partner workspace layout reminder: `mcp-servers/`, `skills/`, `ambient-workflows/` — load via bridge, not SQL.

---

## Day 4 — Advanced build, ops, capstone, close

**Theme:** Electives + prove competence + handoff.  
**Tracks:** E · F · Capstone finish

| Time | Block | Audience | Content | Outcomes / labs |
|---|---|---|---|---|
| 09:00–09:15 | Standup | Builders | Capstone plan approvals | Go / no-go per learner |
| 09:15–10:30 | **Capstone build** | Builders | Execute plan; merge mappings; test-trigger; UI proof | Working path or documented blocker |
| 10:30–10:45 | Break | | | |
| 10:45–12:00 | **E electives** *(pick 1–2 by cohort need)* | Builders | See elective menu below | Module lab complete |
| 12:00–13:00 | Lunch | | | |
| 13:00–14:00 | **Capstone demos** | Builders | 5–7 min each: plan → demo → IDs in UI → ops one-liner | Graded against rubric |
| 14:00–14:15 | Break | | | |
| 14:15–15:15 | **F Ops / support** | Builders + ops | Correlate session ↔ ambient ↔ desktop; evidence-only RCA | **Lab F1:** Planted incident write-up |
| 15:15–16:00 | **Safety & production readiness** | Builders | No S2S/desktop/AI-gateway keys in plugin; least privilege; guardrails; sandbox vs prod | Threat-model highlights |
| 16:00–16:45 | **Enablement & 30/60/90** | Leads | Template pack repo; office hours; first production pack goals | Partner lead commitments |
| 16:45–17:15 | Assessment / badges | All | Quiz + checklist sign-off | Operator / Admin / Builder / Ops levels |
| 17:15–17:30 | Close | All | Feedback form; resources; support channel | |

### Day 4 elective menu (Track E)

| Code | Module | Cursor path | UI validation | When to choose |
|---|---|---|---|---|
| **E1** | MCP scaffold/deploy/register | `/yaaif-new-mcp` or `yaaif_mcp_link_or_create` | Capabilities test | Custom APIs |
| **E2** | HITL approval strategies | strategy create/publish + ambient approval nodes | Approvals inbox | Any gated workflow |
| **E3** | Desktop skills + worker mapping | desktop skill + `yaaif_desktop_skill_mapping_set` | Workers / Desktop Runs | SAP GUI / OS automation |
| **E4** | Ambient patterns | Linear / branching / recon-resolve | Two-graph optional | Batch + later clearance |
| **E5** | Skill lifecycle deep dive | guided draft, edit section, validate module | Advanced Skills parity | Heavy skill authors |

**Day 4 exit criteria**

- [ ] Capstone demoed or formally deferred with RCA  
- [ ] Ops lab RCA submitted with correlation IDs  
- [ ] Level badge criteria checked (see below)  

---

## Assessment checklist (end of Day 4)

| Level | Proof |
|---|---|
| **Operator** | Labs B1–B3 + short quiz (approvals, IDs, escalation) |
| **Admin** | Tenant baseline (user/role/agent) + MCP or worker lab |
| **Builder** | Capstone: plan approved → installed → verified → demoed |
| **Ops** | RCA with correlation IDs; no unsafe mutations |

---

## Timing cheat sheet (facilitator)

| Day | Must-not-skip | Can cut if behind |
|---|---|---|
| 1 | A1 architecture, B2 approvals, B3 escalate | Deep Advanced Skills |
| 2 | C4 worker story (demo OK), D1.5 first skill | C5 deep dive |
| 3 | Plan-before-create, chat→ambient, verify | Long ops section (move to Day 4) |
| 4 | Capstone demos, safety | Extra electives (assign as homework) |

---

## Command & UI quick reference (handout)

| Intent | Cursor | Admin UI |
|---|---|---|
| Login / tenant | `/yaaif-login`, `yaaif_ensure_session`, `yaaif_set_tenant` | Top-bar tenant |
| Connectivity | `/yaaif-doctor` | Control Center, About |
| Catalog snapshot | `yaaif_catalog_overview` | Agents, Skills, Capabilities, Workflows |
| Plan use case | `/yaaif-plan` | — |
| New skill | `/yaaif-new-skill` | Skills / Advanced Skills |
| New MCP | `/yaaif-new-mcp` | Capabilities |
| New ambient | `/yaaif-new-workflow` | Workflow Runs (observe) |
| Local tool names | `/yaaif-platform-tools` | — |
| Triage | `/yaaif-ops` | LLM Sessions, Workflow/Desktop Runs |
| Approvals | *(ops skill is read-only)* | Approvals inbox |
| Workers | `yaaif_desktop_workers_list` + mapping tools | Workers, Desktop Runs |

**Install order (builders):** MCP → agents → approval strategy → ambient → skills → map (merge) → desktop mappings.

---

## Office hours (post-training)

| When | Focus |
|---|---|
| +1 week | Doctor / auth / first skill blockers |
| +2 weeks | Capstone → production pack review |
| +3–4 weeks | Ambient/HITL/desktop deep help |
| +30 days | “First production skill/workflow” check-in |

---

## Related docs

- [getting-started.md](./getting-started.md)
- [partner-workflows.md](./partner-workflows.md)
- [install-and-smoke.md](./install-and-smoke.md)
- [configure-environment.md](./configure-environment.md)
- [platform-local-tools.md](./platform-local-tools.md)
- [ops-support.md](./ops-support.md)
- Product Admin UI: `docs/` versioned Getting Started + Core Workflows
