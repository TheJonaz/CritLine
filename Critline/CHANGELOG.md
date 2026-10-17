# Critline

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
