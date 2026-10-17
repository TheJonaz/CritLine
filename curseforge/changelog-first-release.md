## CritLine Forever v4.7.1-forever8: first release

Unofficial WoW: Forever port of Critline v4.7.1 by Lombra, published with Lombra's written permission.

### WoW: Forever support
- Runs on WoW: Forever (Interface 16001).
- The combat log is closed to addons on Forever. CritLine doesn't try to use it (so you get no "blocked action" popup), and reads your target's combat events instead.
- Records are kept **per damage school** (Physical, Fire, Frost, …), because the game no longer tells addons which spell hit.
- A hit only counts while you are attacking: auto attack or auto repeat is on, or you cast something in the last 3 seconds. The mob must not be tagged by someone else.
- Your pet's hits go in the pet tab when your pet attacks your target and you don't.
- Heals count when you cast something in the last 3 seconds.

### Options and commands
- **Only record while solo** (on by default).
- **Ignore reactive damage** (Thorns, damage shields; on by default).
- **Level filter** is off by default, so mobs below your level count too. Set it under Filters → Level filter.
- `/cl status` shows whether recording is running and why the last hit was or wasn't recorded.
- `/cl debug` explains every skipped hit.
- `/cl combatlog` forces combat log tracking, for testing.

### Fixes
- Right-clicking the minimap button, and `/cl`, now open the options.
- Recording keeps working when another addon (for example BigWigs) loads a newer LibDualSpec.
- Aura scans no longer error in combat when aura data is hidden.
- Updated chat and frame APIs that changed in the newer client.

### Other
- New icon.
