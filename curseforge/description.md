# CritLine Forever

**Remembers your highest hits and crits, and flashes a message when you break a record. Ported to WoW: Forever.**

> **Unofficial port, published with permission.** Critline was written and is owned by **Lombra**
> ([original project](https://www.curseforge.com/wow/addons/critline) · [source](https://github.com/Lombra/Critline)).
> Critline has no open-source license, and all rights are reserved by Lombra. This port is modified and
> distributed by The_Yonaz **with Lombra's written permission**. That permission covers this port only.
> Please report problems with this version here, **not** to Lombra.

---

## How it works on WoW: Forever

WoW: Forever has the same addon restrictions as Midnight, so **addons can't read the combat log**. Without
the combat log the game doesn't tell addons which spell hit, so this port changes how records are made:

- Hits are read from your **target's combat events** (and heals on yourself).
- Records are kept **per damage school**: Physical, Fire, Frost, Shadow, mixed schools such as Shadowflame,
  and so on. They are not kept per spell.
- A hit only counts while **you** are attacking: auto attack or auto repeat is on, or you cast something in
  the last 3 seconds. The mob also has to be untagged or tagged by you.
- **Only record while solo** (on by default): in a group, your hits can't be told apart from your
  group's, so nothing is recorded.
- **Ignore reactive damage** (on by default) skips Thorns and damage shield procs.
- Values the game hides (for example during boss encounters) are skipped.

If Blizzard reopens the combat log to addons, you can turn per-spell records back on with `/cl combatlog`.

## Features

- **Records** for damage and healing, normal and critical, with target name and level.
- **Splash**: an on-screen message when you break a record, with optional sound, screenshot and chat output.
- **Display**: a small movable frame with your top records. Hover over it for all records.
- **Spell list**: review, filter, reset, revert and announce records.
- **Filters**: mob, level and outdoor boss filters.
- **LibDataBroker feed**: shows your records in **Titan Panel**, ChocolateBar, Bazooka and other Broker
  displays. Shift-click to post your top records in chat.
- **Minimap button**: left-click toggles the display, right-click opens the options.
- **Profiles**, shared or per character.
- **Critline: AuraMonitor** (optional, separate addon): lists auras on you, for debugging.

## Commands

| Command | What it does |
|---|---|
| `/cl` or `/critline` | Open the options |
| `/cl debug` | Print why a hit was or wasn't recorded |
| `/cl aura` | Open the AuraMonitor (requires Critline: AuraMonitor) |
| `/cl combatlog` | Force combat log tracking (for testing, needs `/reload`) |

## Known limitations

- Records are per school, not per spell. The game no longer tells addons which spell hit.
- While you are attacking, your pet's hits and DoT ticks on your target count as your own. The pet tab
  stays empty.
- Aura filters and the split between direct hits and ticks only work with the combat log.
- **Titan Panel [CritLine Forever]** is a separate Titan Panel plugin (based on the older CritLine by Uggh), not
  part of this addon. It also uses `/critline`, so if you have both, use `/cl`.
- Records from retail or Classic don't carry over, because every game client keeps its own saved variables.

## Credits

- **Lombra**: author, copyright holder and maintainer of Critline
- **Sordit**: original creator of CritLine
- **Uggh, Feyde**: previous maintainers
- **The_Yonaz**: WoW: Forever port

Bundled libraries keep their own licenses: Ace3 (AceDB, AceLocale), CallbackHandler, LibStub,
LibSharedMedia-3.0 (LGPL v2.1), LibDualSpec-1.0 (BSD), LibDataBroker-1.1 and Libra.

*This project is not affiliated with or endorsed by Blizzard Entertainment.*
