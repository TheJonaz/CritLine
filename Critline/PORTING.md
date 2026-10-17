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
  `COMBAT_LOG_EVENT_UNFILTERED` (or the filter module's `UNIT_AURA`). It switches to `UNIT_COMBAT`
  tracking instead and prints a notice at login.
- **`UNIT_COMBAT` tracking (`UnitCombat.lua`, since forever2).** Reads damage and heals on your target,
  and heals on yourself, from `UNIT_COMBAT`. That event gives the amount, the school and whether it
  was a crit, but not the spell or the attacker. So:
  - Records are kept **per damage school** (Physical, Fire, mixed schools such as Shadowflame, ...).
    They are stored under the negated school mask as the spell ID, with the school's name and a
    standard icon.
  - Damage only counts while you are attacking: auto attack or auto repeat (Auto Shot, Shoot) is on,
    or you cast something in the last 3 seconds. It also has to be a mob that isn't tagged by
    someone outside your group. Heals need a cast of your own in the last 3 seconds.
  - **Only record while solo** (on by default) ignores everything while you are in a group, because
    group members' hits can't be told apart from yours.
  - **Ignore reactive damage** (on by default) skips non-physical, non-crit damage that lands within
    0.2 seconds of you taking a hit (Thorns, damage shields).
  - Any value that the client marks secret (for example during boss encounters) is skipped.
  - Mob, level and outdoor boss filters still apply. Aura filters and DoT/direct separation don't.
  - The attribution rules are the same as in Titan Panel [CritLine Forever] by The_Yonaz.
- **`/cl combatlog`** turns on forced combat log registration (applied after `/reload`). Use it to
  test if Blizzard relaxes the restriction, for example outside encounters. Type it again to turn it
  off.
- **Secret aura data.** Aura scans stop if an aura's spell ID is a secret value, which happens in
  combat, instead of raising an error.
- **API replacements:** `ChatFrame_OpenChat` → `ChatFrameUtil.OpenChat` (with fallback),
  `SendChatMessage` → `C_ChatInfo.SendChatMessage` (with fallback), `SetMinResize`/`SetMaxResize` →
  `SetResizeBounds` (Libra). `AddonCompartmentFrame` registration is skipped if the frame is missing.

## Known limitations

- Without the combat log, Critline cannot tell **which spell** hit. `C_DamageMeter` only gives
  totals per spell, and they are secret in combat. `UNIT_COMBAT` gives amount and crit, but not the
  spell or the attacker. Records are therefore per school.
- Pet hits on your target count as yours (in the damage tree) while you are attacking. The pet tree
  is not filled. DoT ticks and hits from others' AoE can be counted while you are attacking.
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
   "The combat log is closed to addons…" notice.
3. Leave your group if you're in one, attack a mob, and check that records such as "Physical" or
   "Fire" show up in the spell list and the display. `/cl debug` prints why a hit was skipped.
4. `/cl` opens the options. Check that the display frame, minimap button, spell list and profiles work.
5. `/cl aura` opens the AuraMonitor. Enter and leave combat and check that no errors appear.
6. Optionally, `/cl combatlog` and `/reload`: see whether the client blocks registration.
