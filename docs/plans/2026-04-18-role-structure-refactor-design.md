# Role Structure Refactor — Design

**Status:** Draft
**Date:** 2026-04-18
**Author:** Derek + Claude (brainstorming session)
**Scope:** Track 1 of the two-track April 2026 DFE refresh. Track 2 (Ubuntu 26.04 compatibility / DRAGONFLY gaps) has its own spec.

## Context

The DFE developer environment currently installs almost every tool unconditionally. The `developer` and `developer_core` roles between them carry ~40 task files, and the only filter is Ansible tags — which require the user to know the exact tag name in advance and pass `--tags-exclude` for anything they don't want.

Three pressures make this the right moment to refactor:

1. **Personas have emerged.** Different devs need different toolchains — Rust engineers don't need the Confluent CLI; infra engineers don't need a Rust compiler. One-size-fits-all installs waste time and disk, and the status quo makes it hard to extend (adding any tool means it runs for everyone).
2. **VPN transition.** WireGuard is replacing OpenVPN as the default VPN in the next month or two. OpenVPN needs to become opt-in before the flip, without breaking in-flight users.
3. **Ubuntu 26.04 work (Track 2)** will touch many of the same files — cleaner to land a structural refactor first so the 26.04 bugfixes apply to a stable base.

## Goals

- Introduce **named profiles** (`rust`, `iac`, `openvpn`, `gui_extras`) that compose additively on top of a lean BASE.
- Make the **BASE install lean but universal** — everything every dev genuinely needs, nothing they don't.
- Provide an **opt-out mechanism** for user-facing apps in BASE (Mailspring, Slack, etc.) via `install_<name>: false` variables.
- Support the **WireGuard → OpenVPN transition** by moving OpenVPN into an opt-in profile and making WireGuard the default VPN in BASE.
- **Audit every version pin and external URL** during execution; bucket findings as fix-now / Track-2 / follow-up.
- **Document every tool** with a short rationale: what it does, why we picked it, what it's used for.

## Non-goals

- No new tooling added beyond what's named in this spec (Bruno, Podman Desktop, DBeaver, Freelens, kcat, wl-clipboard).
- No "frontend" profile — deferred until we have real frontend-specific tooling to put in it.
- No macOS support changes. The refactor preserves existing `ansible_facts['distribution'] == 'MacOSX'` branches as-is.
- No per-cloud granularity. `aws`/`azure`/`gcloud` all live in BASE as universal CLIs, not separate sub-profiles.

## Design

### Invocation UX

```bash
./install.sh                                    # BASE only
./install.sh --profile rust                     # BASE + rust
./install.sh --profile rust,iac                 # BASE + rust + iac
./install.sh --profile all                      # BASE + rust + iac + gui_extras (no openvpn)
./install.sh --profile rust,openvpn             # BASE + rust + OpenVPN (transition)
./install.sh --extra-vars install_slack=false   # opt out of Slack
```

Under the hood, `--profile X` maps to `--tags base,X`. `all` expands to `base,rust,iac,gui_extras`. OpenVPN stays out of `all` because it's a transitional, explicit-opt-in bucket. `--tags` remains available for ad-hoc runs.

### Role layout

```
ansible/roles/
├── base/              # renamed from "developer"
├── rust/              # new role (extracted from developer_core)
├── iac/               # new role (extracted from developer + developer_core)
├── gui_extras/        # new role
├── openvpn/           # new role (extracted from developer_core), opt-in
├── rdp/               # unchanged
├── vm_optimizer/      # unchanged
└── system_cleanup/    # unchanged
```

The `developer_core` role dissolves entirely — its task files redistribute. The `developer` role is renamed `base` because it now represents "everything a normal dev gets," not a layer below other layers.

### BASE contents

Every tool listed here installs unconditionally (or with an opt-out var where noted).

**OS plumbing:**
- `init.yml`, `repository.yml`, `security.yml`, `apparmor_userns.yml`, `telemetry.yml`, `wallpaper.yml`, `region.yml`

**Desktop:**
- `desktop.yml`, `gnome.yml`, `nemo.yml`, `avatar.yml`, `ghostty.yml`, `shell_config.yml`

**Core CLI:**
- `utilities.yml` — jq, ripgrep, fzf, tmux, bat, fd-find, rsync, httpie, shellcheck, wl-clipboard *(new)*, etc.
- `git.yml`, `docker.yml`, `c_tools.yml`

**Python (always):**
- `uv.yml` — uv, python3, venv, pytest, pipx

**Editor/browsers:**
- `vscode.yml`, `chrome.yml`, `brave.yml`, `browser_policies.yml`

**Cloud CLIs (universal — needed by normal devs, not just infra):**
- aws, azure, gcloud, gh, jfrog

**Release/CI automation:**
- `nodejs.yml` (+ semantic-release), `act.yml`, `gitleaks.yml`

**Data:**
- Confluent CLI (existing), `kcat` *(new — same auto-detect-latest pattern)*

**Comms / AI / PM (opt-outable):**
- Slack (`install_slack`), Bitwarden (`install_bitwarden`), Claude Code CLI, Linear CLI (`install_linear`), OnlyOffice (`install_onlyoffice`), Mailspring (`install_mailspring`)

**VPN default:**
- `wireguard.yml` *(new, replaces OpenVPN as default)*

### Profile contents

**`rust`** — Rust toolchain and cargo-installed developer tooling.
- rustup, cargo, bacon, nextest, deny, tarpaulin, chef, cargo-sweep, sccache, mold

**`iac`** — Infrastructure-as-code tooling.
- terraform, vault, helm, kubectl, k9s, kubectx/kubens, minikube, argocd, dive

**`openvpn`** — Legacy VPN stack (transitional).
- openvpn3 CLI, `openvpn3-indicator` tray, `openvpn3-service-netcfg --config-set systemd-resolved yes`
- **Deletion target:** once WireGuard migration completes (~2026-06), this role is removed.

**`gui_extras`** — Optional GUI applications.
- Freelens (k8s cluster GUI), Bruno (API client), Podman Desktop (container GUI, FOSS alternative to Docker Desktop), DBeaver Community (universal DB client)

### Opt-out convention

Pattern: each opt-outable task declares an `install_<name>` variable that defaults to `true`. The include is gated with `when: install_<name> | default(true)`.

Standardize on this variable list in BASE (can be expanded in future):
- `install_slack`
- `install_bitwarden`
- `install_linear`
- `install_onlyoffice`
- `install_mailspring`
- `install_brave`

Foundational tools are deliberately **not** opt-outable: git, docker, uv, utilities, security, repository, shell_config. Removing these breaks too much downstream tooling to be worth supporting.

### Tool documentation deliverable

A new docs file (`docs/TOOLS.md`) must be created as part of this refactor. For each tool in BASE and in every profile, it lists:

- **Name + upstream link**
- **Bucket** — BASE (opt-outable or not), rust, iac, gui_extras, openvpn
- **What it does** — one sentence
- **Why it's installed** — what workflow it supports at Hyperi (build/CI/release/secrets/infra/comms/etc.)
- **Why this tool** — the rationale for picking this over alternatives (e.g. "Bruno over Postman because local-first and no account required")

Structure: table of contents by bucket, then one short subsection per tool. Target size: ~500-900 words per profile's worth of tools.

The README's "What's installed" section is replaced with a short summary and a link to `docs/TOOLS.md`.

### Audit — bundled into execution

During implementation, grep every task file for external references and hard-coded versions:
- `url:`, `baseurl:`, `gpgkey:`, `key:`, `repo:` (apt_repository), `src:` (download URLs)
- `version:` values, `*_version` set_fact variables
- PPA names, `apt_key`, `rpm_key` URLs

For each, evaluate: (a) still reachable? (b) pin justified? (c) upstream drifted?

**Bucket findings:**
- **Fix-now** (trivial, zero-risk): bad repo URL, accidental pin, obviously obsolete apt source → fix inline.
- **Flag for Track 2 (Ubuntu 26.04)**: anything that only breaks on 26.04 → note in Track 2 spec.
- **Defer to TODO.md**: larger follow-ups that need real investigation.

Known intentional pins (do not touch):
- `grd_patched_version` — we own the GRD patch.
- HashiCorp Ubuntu release fallback `>24.04 → noble` — deliberate.
- `min_*_version` in `init.yml` — gate checks, not pins.

## Backward compatibility

- Existing tag names are preserved where sensible (`--tags rust`, `--tags azure`, `--tags vscode`). The refactor reorganizes file layout but keeps tag identifiers stable so long-running inventories don't break.
- `install.sh --core` → aliases to `--profile rust,iac` with a deprecation warning for one release, then removed.
- `install.sh --all` → aliases to `--profile all`.
- The `developer_core` role is removed from `playbooks/main.yml`. Runs that explicitly reference it (shouldn't exist, but check) will fail loudly.

## Testing

- `test.sh` adds profile-matrix check-mode runs: base-only, rust, iac, gui_extras, all. Catches playbook-level regressions before VM testing.
- One full end-to-end run on a fresh Ubuntu 24.04 VM with `--profile all,openvpn` to validate nothing in the refactor broke existing behaviour.
- One BASE-only run on Ubuntu 24.04 to confirm the lean baseline actually boots a usable environment.
- macOS runs validated in check-mode only — no full-VM regression testing on mac (existing posture).

## Risks and mitigations

- **Inventory files referencing removed roles.** Mitigation: grep the repo for `developer_core` references (playbooks, vars, docs) during migration, update or delete.
- **Users expecting `install.sh` with no args to install everything.** Mitigation: the lean-BASE default is a behaviour change — README needs a clear migration note and `--profile all` shown prominently.
- **Opt-out variables overlooked during future work.** Mitigation: variable list centralized in `group_vars/all.yml` with defaults, so new tasks inherit the opt-out check by convention.
- **Audit findings balloon scope.** Mitigation: tri-state bucketing (fix-now / Track-2 / defer) is the guardrail — anything non-trivial escapes this spec.

## Open questions

None after brainstorming — all design decisions confirmed. Questions that might surface during implementation will be handled in the plan review.

## Related

- Track 2 spec (pending) — Ubuntu 26.04 compatibility + DRAGONFLY.md gaps. Will consume the `iac`/BASE layout defined here.
- `~/Downloads/DRAGONFLY.md` — source of several Track 2 findings, some of which (wl-clipboard, kcat) are pulled into Track 1.
- `docs/plans/2026-03-25-grd-30hz-patch.md` — previous planning doc, sibling format.
