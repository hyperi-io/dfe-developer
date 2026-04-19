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

## core tier (Hyperi internal)

The `core` tier implies `developer` and adds the Hyperi-internal toolchain (internal
package registry, chat/issue tracker, default VPN, branding).

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
