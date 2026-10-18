# Critline

## v4.7.1-forever10 (unofficial WoW: Forever port)

- Fixed a Lua error in combat from Critline: AuraMonitor (`GetAuraDataByIndex(): Auras cannot be accessed when secret`). Auras are hidden from addons in combat, and even asking for them errors, so AuraMonitor now waits until combat ends before it scans. Critline itself no longer scans auras when the combat log is unavailable, because aura filters need the combat log.

## v4.7.1-forever9 (unofficial WoW: Forever port)

- Fixed a Lua error on login (`Profiles.lua:12: attempt to call a nil value`). The profile controls needed the specialization API, which WoW: Forever doesn't have, so the Profiles and Spell profiles pages stayed empty. Spec profiles are now only shown when the game has specializations.

## v4.7.1-forever8 (unofficial WoW: Forever port)

- The level filter is now off by default. With the old default (1), hits on mobs more than one level below you were never recorded, which blocked almost every record while levelling. You can turn it back on under Filters.

## v4.7.1-forever7 (unofficial WoW: Forever port)

- Diagnostics: each session's startup steps, the last 60 hit events with their result, and Lua errors in hit tracking are saved per character in `CritlineDiag` (SavedVariables).

## v4.7.1-forever6 (unofficial WoW: Forever port)

- New `/cl status`: shows the tracking mode, settings that block records, and the last hit event with why it was or wasn't recorded.
- `/cl debug` now gives a reason for every skipped hit.
- A failing LibDualSpec (for example a newer copy loaded by another addon) no longer stops record tracking.

## v4.7.1-forever5 (unofficial WoW: Forever port)

- Pet records without the combat log: hits on your target while your pet attacks it and you don't are recorded in the pet tree. Previously they were dropped.

## v4.7.1-forever4 (unofficial WoW: Forever port)

- New addon icon.
- The TOC files now target WoW: Forever only (Interface 16001), and the addon is named "CritLine Forever".
- Removed the original project's CurseForge and WoWInterface IDs from the TOC; this port is published as a separate project.

## v4.7.1-forever3 (unofficial WoW: Forever port)

- Fix: right-clicking the minimap button (and `/cl`) didn't open the options. Libra no longer overrides the settings category ID on the 12.0 settings API.

## v4.7.1-forever2 (unofficial WoW: Forever port)

- Record hits again without the combat log: read `UNIT_COMBAT` on your target (and heals on yourself), and keep records per damage school (Physical, Fire, ...).
- A hit only counts while you are attacking (auto attack, auto repeat or a cast in the last 3 seconds) and the mob isn't tagged by someone else.
- New options: **Only record while solo** and **Ignore reactive damage** (both on by default).
- Mob, level and outdoor boss filters apply to these records; aura filters don't.

## v4.7.1-forever1 (unofficial WoW: Forever port)

Ported by The_Yonaz with the written permission of the copyright holder, Lombra. See [PORTING.md](PORTING.md).

- Add Interface 16001 (WoW: Forever) to both TOC files.
- Don't register the combat log where the client blocks it (Midnight/Forever addon restrictions); show a notice instead.
- Add `/cl combatlog` to force combat log registration.
- Skip secret aura data instead of erroring.
- Use `ChatFrameUtil.OpenChat`, `C_ChatInfo.SendChatMessage` and `SetResizeBounds` where available.

## [v4.7.1](https://github.com/Lombra/Critline/tree/v4.7.1) (2024-07-29)
[Full Changelog](https://github.com/Lombra/Critline/compare/v4.7.0...v4.7.1) [Previous Releases](https://github.com/Lombra/Critline/releases)

- Add GitHub funding links  
- Remove redundant pkgmeta properties  
- Remove manual change log  
- Update for game version 11.0  
    - Closes #3, #4, #5.  
