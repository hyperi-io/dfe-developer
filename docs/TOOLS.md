# DFE Developer Environment — Installed Tools

Per-tool rationale: what it is, why we installed it, why we picked it.

This document mirrors the Ansible role layout. Each profile maps to a role directory under `ansible/roles/`. Opt-out variables are documented at the end.

## Table of contents

- [developer tier (OSS-safe base)](#developer-tier-oss-safe-base)
- [core tier (Hyperi internal)](#core-tier-hyperi-internal)
- [rust profile](#rust-profile)
- [iac profile](#iac-profile)
- [gui_extras profile](#gui_extras-profile)
- [openvpn profile (transitional)](#openvpn-profile-transitional)
- [Opt-out variables](#opt-out-variables)

## developer tier (OSS-safe base)

The `developer` tier is the OSS-safe base — no Hyperi internals, safe for external
contributors on DFE or ESH. Installed by default with `./install.sh --profile developer`.

### Git (+ GitHub CLI, git-lfs)

**Upstream:** https://git-scm.com/, https://cli.github.com/
**What it does:** Distributed version control and a GitHub-aware CLI for PRs, issues, releases, and workflow runs.
**Why it's installed:** Git is the source of truth for every Hyperi repo; the `gh` CLI lets you script PR creation and CI debugging without a browser.
**Why this tool:** Git is non-negotiable. `gh` beats `hub` as the officially maintained GitHub client with first-party support for Actions, Codespaces, and the GraphQL API. `git-lfs` handles the occasional large binary in a few repos.

### Docker

**Upstream:** https://docs.docker.com/engine/
**What it does:** Container runtime and build tooling (Docker Engine + Compose).
**Why it's installed:** The default dev-time container runtime for Hyperi services; Compose covers local multi-service stacks.
**Why this tool:** Docker Engine is installed in preference to Docker Desktop on Linux — no license ambiguity, no extra VM layer, and it works cleanly under rootless mode. Compose v2 (plugin form) is installed instead of the legacy `docker-compose` Python script. Podman Desktop ships in `gui_extras` for users who prefer it.

### uv (+ python3, python3-pytest, pipx)

**Upstream:** https://github.com/astral-sh/uv
**What it does:** Fast Rust-based Python package + project manager (virtualenv, lock, install, run).
**Why it's installed:** Standard interpreter for glue scripts, plus the project/tooling manager Hyperi standardised on.
**Why this tool:** `uv` replaces the `pip`/`pip-tools`/`poetry`/`pyenv`/`virtualenv` stack with one binary that is 10–100x faster, handles interpreter management, and has a consistent lockfile format. `pipx` is kept around for isolated CLI installs that don't warrant a project layout.

### CLI utilities (jq, ripgrep, fzf, tmux, bat, fd-find, rsync, httpie, shellcheck, wl-clipboard, yq, sd, miller, htop, age, parallel)

**Upstream:** various (upstream URLs embedded in the task file)
**What it does:** The unix tool belt: JSON/YAML filtering, fast search, fuzzy selection, terminal multiplexing, syntax-highlighted paging, modern `find`, reliable file sync, readable HTTP client, shell linting, Wayland clipboard bridge, CSV/TSV processing.
**Why it's installed:** Baseline shell productivity; scripts in this repo (and most Hyperi repos) assume these are present.
**Why this tool:** Each picks the modern FOSS replacement where one exists — `ripgrep` over `grep -R`, `fd` over `find`, `bat` over `cat`, `httpie` over raw `curl` for one-shots, `wl-clipboard` (`wl-copy`/`wl-paste`) over `xclip` on Wayland, `sd` over `sed` for simple substitutions, `miller` for tabular pipelines without pulling in pandas. `shellcheck` runs pre-commit on every shell script. `age` is the standard pre-merge encryption tool for sharing secrets during incident work.

### c_tools (gcc/clang, make, autoconf/automake, pkg-config, linker stack)

**Upstream:** https://gcc.gnu.org/, https://llvm.org/, https://www.gnu.org/software/make/
**What it does:** The classic C/C++ toolchain: compilers, linker, `make`, build-system helpers.
**Why it's installed:** A lot of cargo crates, npm native modules, and research tooling compile from source and need a working C toolchain.
**Why this tool:** Distro packages only — no vendored toolchain. `clang` is installed alongside `gcc` because the Rust profile's mold linker integration pairs cleanly with `clang` as the driver. No pinning: tracking the distro's default toolchain keeps ABI drift low.

### VS Code

**Upstream:** https://code.visualstudio.com/
**What it does:** Editor / IDE.
**Why it's installed:** The default editor for the team; extensions for Rust, Python, Terraform, and Kubernetes are assumed by several internal runbooks.
**Why this tool:** Official Microsoft build (not VSCodium) — Remote SSH and the official Microsoft extensions work out of the box, which matters for mixed local/remote workflows. Installed via the upstream apt/dnf repo so that updates flow through the OS package manager.

### Google Chrome

**Upstream:** https://www.google.com/chrome/
**What it does:** Browser.
**Why it's installed:** Primary browser for most team members; needed for enterprise SSO flows and the Hyperi workspace.
**Why this tool:** Chrome is installed alongside Brave so users can pick. Policy hardening is applied via `browser_policies.yml` (telemetry off, safe search on, etc.).

### Brave

**Upstream:** https://brave.com/
**What it does:** Privacy-hardened Chromium browser.
**Why it's installed:** Secondary browser for privacy-sensitive browsing and for testing without Chrome's Google identity attached.
**Why this tool:** Brave over Firefox as the Chromium-family alternative — most internal webapps are tested against Blink, and Brave applies sensible ad/tracker defaults without third-party extensions. Opt out via `install_brave=false`.

### AWS CLI

**Upstream:** https://aws.amazon.com/cli/
**What it does:** Official AWS command-line client.
**Why it's installed:** Touching S3, IAM, EC2, and managed services during incident response and infra work.
**Why this tool:** Installed via the official v2 bundle (not the distro package, which lags). Handles SSO natively, which the apt/dnf packages historically did not.

### Azure CLI

**Upstream:** https://learn.microsoft.com/en-us/cli/azure/
**What it does:** Official Microsoft Azure CLI.
**Why it's installed:** Tenant admin and Graph API access — see the M365 notes in the team handbook.
**Why this tool:** Official Microsoft repo, handles device code auth and Graph rest calls. No third-party alternative worth the compatibility cost.

### Google Cloud CLI

**Upstream:** https://cloud.google.com/sdk/docs
**What it does:** `gcloud` + `gsutil` + bundled components.
**Why it's installed:** Touching GCP projects that host external integrations and partner workloads.
**Why this tool:** Official Google bundle. Distro packages are outdated and miss the component updater.

### Node.js + semantic-release

**Upstream:** https://nodejs.org/, https://github.com/semantic-release/semantic-release
**What it does:** JavaScript runtime + automated versioning/release tool that reads Conventional Commits and publishes to GitHub/npm.
**Why it's installed:** CI reuses `semantic-release` for tag + changelog generation; contributors occasionally run it locally to preview.
**Why this tool:** Node LTS via NodeSource repo (keeps up with security updates faster than distro packages). `semantic-release` is the de-facto tool for Conventional-Commit-driven releases and is what every Hyperi repo's `release.yml` workflow calls.

### act

**Upstream:** https://github.com/nektos/act
**What it does:** Runs GitHub Actions workflows locally using Docker.
**Why it's installed:** Reproduce CI failures without the GitHub Actions round-trip.
**Why this tool:** `act` is the only mature local GHA runner. Accepts the same workflow YAML; bind-mounts the repo; uses the same container images as GitHub-hosted runners.

### gitleaks

**Upstream:** https://github.com/gitleaks/gitleaks
**What it does:** Secrets scanner for git repos (pre-commit + CI).
**Why it's installed:** Catch accidental secret commits before they hit the remote.
**Why this tool:** `gitleaks` is faster than `trufflehog` for pre-commit use and has a cleaner rule format. Runs in both pre-commit hooks (local) and CI (as a GitHub Action).

### Bitwarden

**Upstream:** https://bitwarden.com/
**What it does:** Password manager desktop client.
**Why it's installed:** Default team password manager; vault access for shared credentials.
**Why this tool:** Bitwarden is FOSS, self-hostable (we use the cloud tier), and has the most usable CLI (`bw`) for scripted secret fetches. Opt out via `install_bitwarden=false`.

### Claude Code CLI

**Upstream:** https://docs.anthropic.com/en/docs/claude-code
**What it does:** Anthropic's official coding agent CLI.
**Why it's installed:** Team-standard AI assistant; installed via the official npm package so updates match upstream.
**Why this tool:** Claude Code is the in-house standard for agentic coding workflows. Installed from npm (not a vendored binary) so `npm update -g` keeps it current.

### Linear CLI

**Upstream:** https://linear.app/
**What it does:** CLI for Linear issue tracker.
**Why it's installed:** Create/update issues from the terminal; useful inside scripts that open tickets on failure.
**Why this tool:** This is actually split: an OSS Linear CLI lives in the developer tier (safe for external contributors working against their own Linear workspaces); the Hyperi-workspace-configured variant lives in `core`.

### OnlyOffice Desktop Editors

**Upstream:** https://www.onlyoffice.com/
**What it does:** Desktop office suite (docs/sheets/slides) with MS Office format fidelity.
**Why it's installed:** Review/author `.docx`/`.xlsx` attachments without Microsoft 365 roundtrips.
**Why this tool:** Higher MS Office format fidelity than LibreOffice; FOSS and self-installable (no account required). Opt out via `install_onlyoffice=false`.

### Mailspring

**Upstream:** https://getmailspring.com/
**What it does:** Cross-platform desktop email client with unified inbox.
**Why it's installed:** IMAP/SMTP desktop client for users who don't want Thunderbird or a browser-only workflow.
**Why this tool:** Actively maintained (unlike several abandoned Electron email clients), sane unified inbox, and works with workspace SMTP without plug-ins. Opt out via `install_mailspring=false`.

### kcat (kafkacat)

**Upstream:** https://github.com/edenhill/kcat
**What it does:** Non-JVM CLI producer/consumer for Kafka topics.
**Why it's installed:** Quick topic inspection and message replay without spinning up a JVM client.
**Why this tool:** Way lighter than the Confluent `kafka-console-consumer` scripts; scriptable. Package availability varies (sometimes `kafkacat`, sometimes `kcat`, sometimes a COPR on Fedora) — the task is wrapped in `failed_when: false` pending real-VM verification.

### Confluent CLI

**Upstream:** https://docs.confluent.io/confluent-cli/current/overview.html
**What it does:** Manage Confluent Cloud + Confluent Platform (topics, schemas, connectors).
**Why it's installed:** Required by the data-platform workflows that use managed Kafka.
**Why this tool:** The Kafka GUI alternatives are heavier (Kafka UI, Conduktor); `confluent` is the official supported CLI and covers the schema-registry/connect APIs too.

## core tier (Hyperi internal)

The `core` tier implies `developer` and adds the Hyperi-internal toolchain (internal
package registry, chat/issue tracker, default VPN, branding).

### Slack

**Upstream:** https://slack.com/
**What it does:** Team chat client (desktop GUI).
**Why it's installed:** Primary async comms channel; shipped pre-configured for the Hyperi workspace.
**Why this tool:** Canonical team messaging app. Installed via the official snap/flatpak/rpm rather than the browser-wrapped web version so desktop notifications, screen share, and workspace switching work reliably. Opt out via `install_slack=false` if you prefer the web UI.

### Linear (Hyperi workspace)

**Upstream:** https://linear.app/
**What it does:** Issue tracker + project manager with a fast CLI and keyboard-first UI.
**Why it's installed:** The team's canonical issue tracker. Shipping the CLI inside `core` means ticket automation works out of the box with the Hyperi workspace context.
**Why this tool:** Linear replaced the previous Jira install — orders of magnitude faster, cleaner API, and the CLI is useful in scripts (auto-open a ticket on pipeline failure). Opt out via `install_linear=false`.

### JFrog CLI

**Upstream:** https://jfrog.com/getcli/
**What it does:** Client for JFrog Artifactory / Xray / Distribution.
**Why it's installed:** Pull and publish internal container images, OCI bundles, Helm charts, and cargo/npm packages from the Hyperi internal tier.
**Why this tool:** The internal package registry runs on Artifactory, and `jf` is the only first-party client with both authentication helpers and the upload/download semantics we rely on. The Docker Desktop Artifactory plug-in is GUI-only and not a substitute.

### rclone

**Upstream:** https://rclone.org/
**What it does:** Swiss-army CLI for object storage / cloud sync (S3, GCS, SFTP, WebDAV, plus many SaaS backends).
**Why it's installed:** Mount or sync the Hyperi internal file tier during day-to-day work. Replaces bespoke `aws s3 sync` / NFS-mount scripts that were in the previous install.
**Why this tool:** `rclone` is the only tool that handles every backend the team touches (S3-compatible MinIO, SMB, WebDAV, SSH) with consistent semantics. The crypt backend is also useful for storing backups at rest.

### WireGuard

**Upstream:** https://www.wireguard.com/
**What it does:** Kernel-mode VPN with modern crypto and minimal config surface.
**Why it's installed:** Default VPN for the Hyperi internal tier. Replaces OpenVPN 3 as the primary VPN; OpenVPN is now opt-in via the `openvpn` profile (transitional).
**Why this tool:** WireGuard is in-kernel on both Ubuntu and Fedora, dramatically faster than OpenVPN, and the config is a single `/etc/wireguard/*.conf` file. The peer config is supplied by the operator via `wireguard_peer_config` (deliberately not shipped in the repo).

### Wallpaper + avatar (Hyperi branding)

**Upstream:** n/a — branded assets shipped with this repo.
**What it does:** Sets the GNOME desktop wallpaper and default user avatar to the Hyperi-branded assets.
**Why it's installed:** Light-touch visual marker that you're on a Hyperi-managed workstation — useful in screenshots, shared screens, and onboarding.
**Why this tool:** In-repo asset + dconf write, not a third-party tool. Gated on `has_gnome` so it's a no-op on headless hosts. Trivial to skip via `--skip-tags wallpaper,avatar` if desired.

## rust profile

Rust toolchain plus the build-cache + linker stack used across Hyperi's Rust services.

## iac profile

Infrastructure-as-code: HashiCorp CLI set plus the Kubernetes operator kit.

## gui_extras profile

Optional desktop developer GUIs. Skipped on headless hosts (gated on `has_gnome`).

## openvpn profile (transitional)

Legacy OpenVPN 3 stack. Opt-in only; `core` now defaults to WireGuard. Scheduled
for removal once the internal WireGuard migration completes.

## Opt-out variables

Centralised in `ansible/inventories/localhost/group_vars/all.yml`. All default to `true`
(except `wireguard_peer_config`, which is unset by design).

| Variable | Default | Effect |
|----------|---------|--------|
| `install_bitwarden` | `true` | Bitwarden desktop password manager |
| `install_onlyoffice` | `true` | OnlyOffice desktop editors |
| `install_mailspring` | `true` | Mailspring email client |
| `install_brave` | `true` | Brave browser |
| `install_slack` | `true` | Slack desktop (core tier only) |
| `install_linear` | `true` | Linear CLI (core tier only) |
| `wireguard_peer_config` | unset | Path to a WireGuard peer config file; operators set this |

Override examples:

    ./install.sh --profile developer --extra-vars "install_mailspring=false"
    ./install.sh --profile core --extra-vars "install_slack=false install_linear=false"
