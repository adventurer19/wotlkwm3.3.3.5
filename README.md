# WoW 3.3.5 (WotLK) Addons Collection

Custom addons for World of Warcraft 3.3.5a (Wrath of the Lich King).

## Installation

Copy any addon folder to your WoW installation:
```
World of Warcraft/Interface/AddOns/
```

## Addons

### EnemyCooldownTracker
Tracks important enemy cooldowns in PvP. Shows big icons when enemies use abilities like Shadow Dance, Bladestorm, Ice Block, etc.

**Commands:**
- `/ect` - Show help
- `/ect unlock` - Unlock frame to move
- `/ect lock` - Lock frame position
- `/ect test` - Show test cooldowns
- `/ect size <24-128>` - Set icon size
- `/ect sound` - Toggle sound alerts

---

## Creating New Addons

Each addon should be in its own folder with:
- `AddonName.toc` - Table of contents file (required)
- `AddonName.lua` - Main Lua code
- Additional `.lua` files as needed
