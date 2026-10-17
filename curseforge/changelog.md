## CritLine Forever v4.7.1-forever6

- New `/cl status`: shows whether tracking is running, which settings can block records, and the last hit with
  the reason it was or wasn't recorded.
- `/cl debug` now explains every skipped hit.
- Fixed: a newer LibDualSpec loaded by another addon (for example BigWigs) could stop recording.

## CritLine Forever v4.7.1-forever5

- Pet records: hits on your target while your pet attacks it and you don't are now recorded in the pet tab.
  Previously they weren't recorded at all. While you attack too, the game doesn't say who hit, so those
  hits still count as yours.

## CritLine Forever v4.7.1-forever4: first release

Unofficial WoW: Forever port of Critline v4.7.1 by Lombra, published with Lombra's written permission.

### WoW: Forever support
- Runs on WoW: Forever (Interface 16001).
- The combat log is closed to addons on Forever. Critline doesn't try to use it (so you get no
  "blocked action" popup), and reads your target's combat events instead.
- Records are kept **per damage school** (Physical, Fire, Frost, …), because the game no longer tells
  addons which spell hit.
- A hit only counts while you are attacking: auto attack or auto repeat is on, or you cast something
  in the last 3 seconds. The mob must not be tagged by someone else.
- Heals count when you cast something in the last 3 seconds.

### New options
- **Only record while solo** (on by default).
- **Ignore reactive damage** (Thorns, damage shields; on by default).
- `/cl combatlog` forces combat log tracking, for testing.

### Fixes
- Right-clicking the minimap button, and `/cl`, now open the options.
- Aura scans no longer error in combat when aura data is hidden.
- Updated chat and frame APIs that changed in the newer client.

### Other
- New icon.
