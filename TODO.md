# TODO - DFE Developer Environment

## Completed This Session

- [x] Add `app-notifications = no-clipboard-copy` to Ghostty Linux config
  - Disables the copy notification popup
  - Syncs project config with actual machine config

## Immediate Tasks

- [x] **desktop-mode script for maclike/winlike swap**
  - Single script: `desktop-mode --winlike` / `desktop-mode --maclike`
  - Auto-detects DBUS from running GNOME session
  - Falls back to saved preference + autostart when GNOME not running
  - Supports `--user <name>` for cross-user switching (requires root)
  - Deployed to `/usr/local/sbin/desktop-mode` via Ansible

- [ ] **maclike toast/notification bug**
  - Ghostty numeric toasts never seem to clear in maclike taskbar
  - Notifications stack up and persist instead of dismissing
  - Investigate whether this is Dash to Dock or GNOME Shell issue

## Platform Support

## Testing

## Documentation

## Future Enhancements

## Code Quality

## Security

## Role-structure refactor follow-ups

- **[parked]** VM smoke tests for `feat/role-structure-refactor`. Full
  `--profile developer` and `--profile core,all` runs against an Ubuntu 24.04
  clone, plus `tests/assertions/oss_safe.sh` post-install check. Re-enable
  after user has VM-provisioning time available. Checklist lives at
  `docs/plans/2026-04-18-audit-findings.md` under "VM smoke test results".
- **[parked]** Fedora VM smoke test. Provision a Fedora 42 test template, then
  run the profile matrix against it. Fedora paths currently verified via
  check-mode syntax only.
- Track 2 audit items: see `docs/plans/2026-04-18-audit-findings.md`
  "Flag for Track 2" section.
- Consider de-duplicating `core/vars/macos.yml` and `developer/vars/macos.yml`
  via a top-level `group_vars` entry (reviewer suggestion from Chunk 3).

---

**Note:** Completed tasks are documented in STATE.md and CHANGELOG.md
