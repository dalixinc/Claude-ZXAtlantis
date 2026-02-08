#!/bin/bash
# Build script for Atlantis Mission

echo "==================================="
echo "Atlantis Mission - Build Script"
echo "==================================="

# Check for assembler
if command -v pasmo &> /dev/null; then
    echo "Using Pasmo assembler..."
    pasmo --tapbas sprite_engine.asm atlantis.tap
    
    if [ $? -eq 0 ]; then
        echo "✓ Build successful!"
        echo "Output: atlantis.tap"
        echo ""
        echo "To run in Fuse emulator:"
        echo "  fuse atlantis.tap"
        echo ""
        echo "Or load in any ZX Spectrum emulator"
    else
        echo "✗ Build failed"
        exit 1
    fi
elif command -v z80asm &> /dev/null; then
    echo "Using z80asm..."
    z80asm -b sprite_engine.asm -o atlantis.bin
    echo "Note: You may need to convert .bin to .tap format"
else
    echo "Error: No Z80 assembler found!"
    echo ""
    echo "Please install one of:"
    echo "  - Pasmo (recommended): https://pasmo.speccy.org/"
    echo "  - z88dk: https://github.com/z88dk/z88dk"
    echo ""
    exit 1
fi
