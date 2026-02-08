# Atlantis Mission - ZX Spectrum Game

## Sprite Engine - Phase 1

This is the core sprite rendering system for our underwater adventure game.

### What's Implemented

✅ **Sprite System:**
- Variable-size sprite structure (currently 16x16)
- XOR-based drawing (allows easy erase by redrawing)
- Sprite descriptor table (supports up to 16 sprites)
- Attribute color management
- Active/inactive sprite flags

✅ **Core Routines:**
- `DRAW_SPRITE` - XOR render any sprite to screen
- `GET_SCREEN_ADDR` - Calculate Spectrum screen memory addresses
- `SET_SPRITE_ATTR` - Set color attributes for sprite area
- `CLEAR_SCREEN` - Initialize display
- `TEST_SPRITES` - Demo showing a simple test sprite

### Building the Code

**Option 1: Using Pasmo (recommended)**
```bash
pasmo --tapbas sprite_engine.asm atlantis.tap
```

**Option 2: Using z88dk**
```bash
z80asm -b sprite_engine.asm -o atlantis.bin
# Then convert to TAP format with bin2tap or appmake
```

**Option 3: Using sjasmplus**
```bash
sjasmplus sprite_engine.asm --raw=atlantis.bin
```

### Running the Code

**In Fuse emulator:**
```bash
fuse atlantis.tap
```
Then at the Spectrum prompt:
```
LOAD ""
```

**In ZEsarUX:**
- File → Open TAP file → atlantis.tap
- The program will auto-load and run

### What You Should See

The program will:
1. Clear the screen
2. Draw a simple test sprite (cyan colored shape) at position (100, 80)
3. Halt in a loop

This demonstrates that the sprite engine is working!

### Current Limitations & Next Steps

**Known Issues:**
- `NEXT_SCAN_LINE` is simplified - needs proper Spectrum screen layout handling
- Only tested with 16x16 sprites so far
- No animation yet (static sprites only)
- No collision detection yet

**Next Phase (Phase 2):**
- Proper scanline calculation for Spectrum's quirky screen layout
- Player sprite with keyboard controls
- Bullet system
- Frame-based movement

### Memory Map

```
16384-22527  : Screen bitmap (6144 bytes)
22528-23295  : Screen attributes (768 bytes)
24000+       : Our code starts here
```

### Sprite Data Format

Sprites are stored as linear bitmap data, left to right, top to bottom.
For a 16x16 sprite: 16 rows × 2 bytes per row = 32 bytes total.

Each bit represents a pixel (1 = on, 0 = off).

Example (16 pixels wide):
```
DB 0x00, 0x00  ; ................
DB 0x01, 0x80  ; .......##.......
```

### Technical Notes

- **XOR Drawing**: We XOR sprites onto the screen. This means drawing the same sprite twice in the same position erases it - perfect for animation!
- **Attributes**: The Spectrum's color system uses 8×8 character cells. We set a 2×2 block of attributes to cover most 16×16 sprites.
- **Screen Layout**: The Spectrum's screen memory is notoriously complex - not linear. Our current implementation is simplified for the proof of concept.

### Credits

Original game concept by [Your Name]
Z80 Implementation: 2026 retro revival project
