# Critline – WoW: Forever port

This is an unofficial port of **Critline v4.7.1** to **WoW: Forever** (Interface 16001).

## Copyright and permission

Critline is copyright its author and maintainer, **Lombra** (<https://github.com/Lombra/Critline>).
Earlier versions were created by Sordit and maintained by Uggh and Feyde.

Critline v4.7.1 ships **without an open-source license**. All rights are reserved by the copyright
holder. This port is modified and distributed **only because the copyright holder has given
permission**:

| | |
|---|---|
| Copyright holder | Lombra |
| Permission granted to | The_Yonaz (porter) |
| Form of permission | Written |
| Date of permission | _YYYY-MM-DD (fill in)_ |
| Where it was given | _e.g. e-mail, GitHub issue/PR link, Discord message (fill in)_ |
| Scope | _e.g. port to WoW: Forever and distribute it on CurseForge/WoWInterface (fill in)_ |

The permission covers this port only. It does not place Critline under an open-source license, and
it does not give anyone else the right to modify or redistribute Critline. Ask Lombra directly
for that.

Bundled third-party libraries keep their own licenses, which this permission does not change:
LibStub, CallbackHandler-1.0, AceDB-3.0 and AceLocale-3.0 (Ace3), LibSharedMedia-3.0 (LGPL v2.1),
LibDualSpec-1.0 (BSD, © Adirelle), LibDataBroker-1.1 and Libra (© Lombra).

This port is not affiliated with or endorsed by Blizzard Entertainment.

## What the port changes

WoW: Forever runs on the Midnight engine and has the same addon restrictions. The main
consequence for Critline is that **the combat log is closed to addons**. Registering
`COMBAT_LOG_EVENT_UNFILTERED` raises `ADDON_ACTION_FORBIDDEN`, and Critline gets every hit, crit and
heal from that event.

- **Both TOC files** declare `## Interface: 110000, 16001` and version `v4.7.1-forever1`.
- **Combat log guard (`Core.lua`, `FilterCore.lua`, `Critline_AuraMonitor`).** `Critline:IsCombatLogAvailable()`
  checks whether the client exposes the combat log. The secret value API (`issecretvalue`) existing
  is taken as the sign that it does not. If the combat log is blocked, Critline does not register
  `COMBAT_LOG_EVENT_UNFILTERED` (or the filter module's `UNIT_AURA`) and prints a notice at login.
  The addon then loads cleanly, and existing records, tooltips, the display, the spell list and the
  options all work, but **no new records are registered**.
- **`/cl combatlog`** turns on forced combat log registration (applied after `/reload`). Use it to
  test if Blizzard relaxes the restriction, for example outside encounters. Type it again to turn it
  off.
- **Secret aura data.** Aura scans stop if an aura's spell ID is a secret value, which happens in
  combat, instead of raising an error.
- **API replacements:** `ChatFrame_OpenChat` → `ChatFrameUtil.OpenChat` (with fallback),
  `SendChatMessage` → `C_ChatInfo.SendChatMessage` (with fallback), `SetMinResize`/`SetMaxResize` →
  `SetResizeBounds` (Libra). `AddonCompartmentFrame` registration is skipped if the frame is missing.

## Known limitations

- Under the current Forever rules, **Critline cannot record new records.** No addon-readable
  replacement gives per-hit amounts with spell ID and crit flag. `C_DamageMeter` only gives totals
  per spell, and they are secret in combat. `UNIT_COMBAT` gives amount and crit, but not the spell
  or the attacker.
- Not tested in game at the time of writing. `UIDropDownMenu` (used by Libra and the spell list)
  has been deprecated in modern clients and may need replacing if it is removed.
- This is Lombra's standalone Critline, **not** Titan Panel [CritLine Forever]. Critline has no
  Titan plugin of its own, but its Broker module publishes a LibDataBroker feed per tree, and Titan
  Panel shows those natively.
- Titan Panel [CritLine Forever] also registers `/critline`. With both installed, use `/cl` for Critline.
- SavedVariables are per game client, so records from retail or Classic do not carry over.

## Testing checklist (Forever beta)

1. Install `Critline` and `Critline_AuraMonitor` in `_classic_beta_\Interface\AddOns`.
2. Log in. You should see no Lua errors and no "blocked action" popup. You should see the
   "Combat log access is blocked…" notice.
3. `/cl` opens the options. Check that the display frame, minimap button, spell list and profiles work.
4. `/cl aura` opens the AuraMonitor. Enter and leave combat and check that no errors appear.
5. Optionally, `/cl combatlog` and `/reload`: see whether the client blocks registration.
