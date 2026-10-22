## CritLine Midnight v4.7.1-midnight1: first release

Unofficial Midnight port of Critline v4.7.1 by Lombra, published with Lombra's written permission.
Built from the same code as CritLine Forever.

### Midnight support
- Runs on retail WoW: Midnight (Interface 120105).
- The combat log is closed to addons in Midnight. CritLine doesn't try to use it (so you get no "blocked action" popup), and reads your target's combat events instead.
- Records are kept **per damage school** (Physical, Fire, Frost, …), because the game no longer tells addons which spell hit.
- A hit only counts while you are attacking: auto attack or auto repeat is on, or you cast something in the last 3 seconds. The mob must not be tagged by someone else.
- Your pet's hits go in the pet tab when your pet attacks your target and you don't.
- Heals count when you cast something in the last 3 seconds.

### Options and commands
- **Only record while solo** (on by default).
- **Ignore reactive damage** (Thorns, damage shields; on by default).
- **Level filter** is off by default. Set it under Filters → Level filter.
- `/cl status` shows whether recording is running and why the last hit was or wasn't recorded.
- `/cl debug` explains every skipped hit.
- `/cl combatlog` forces combat log tracking, for testing.

### Fixes
- Right-clicking the minimap button, and `/cl`, now open the options.
- Recording keeps working when another addon (for example BigWigs) loads a newer LibDualSpec.
- AuraMonitor waits until combat ends before it scans, because auras are hidden from addons in combat.
- Updated chat and frame APIs that changed in the newer client.

### Other
- New icon.
