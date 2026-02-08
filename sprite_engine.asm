; ===============================================
; ATLANTIS MISSION - ZX Spectrum Sprite Engine
; ===============================================
; Core sprite rendering system for 48K Spectrum
; Supports variable-size sprites with XOR drawing
; 
; Initial implementation: 16x16 pixel sprites
; Designed to extend to 8x16, 16x24, etc.
;
; Memory Map:
; 16384-22527  : Screen bitmap (6144 bytes)
; 22528-23295  : Screen attributes (768 bytes)
; 23296+       : Our code and data
; ===============================================

        ORG 24000               ; Start of our program

; ===============================================
; Constants
; ===============================================
SCREEN_BASE     EQU 16384       ; Start of screen memory
ATTR_BASE       EQU 22528       ; Start of attribute memory
SCREEN_WIDTH    EQU 32          ; Screen width in bytes
SCREEN_HEIGHT   EQU 24          ; Screen height in character cells

; Keyboard constants (for later)
KEY_UP          EQU 0xFBFE      ; Q-T (for up)
KEY_DOWN        EQU 0xFDFE      ; A-G (for down)
KEY_FIRE        EQU 0x7FFE      ; B-Space (for fire)

; ===============================================
; Sprite Structure (in memory)
; ===============================================
; Each sprite needs:
; +0: X position (0-255)
; +1: Y position (0-191)
; +2: Width in pixels (8, 16, 24, etc.)
; +3: Height in pixels (8, 16, 24, etc.)
; +4: Attribute/color
; +5-6: Address of graphic data (16-bit pointer)
; +7: Status flags (active/inactive, etc.)
;
; Total: 8 bytes per sprite descriptor

SPRITE_X        EQU 0
SPRITE_Y        EQU 1
SPRITE_W        EQU 2
SPRITE_H        EQU 3
SPRITE_ATTR     EQU 4
SPRITE_GFX_LO   EQU 5
SPRITE_GFX_HI   EQU 6
SPRITE_FLAGS    EQU 7

; Sprite flags
FLAG_ACTIVE     EQU 0x01        ; Bit 0: sprite is active

; ===============================================
; Main Program Entry
; ===============================================
START:
        DI                      ; Disable interrupts
        LD SP, 0xFFF0           ; Set stack pointer
        
        CALL CLEAR_SCREEN       ; Clear the screen
        CALL INIT_SPRITES       ; Initialize sprite system
        CALL TEST_SPRITES       ; Run sprite test
        
        ; Main game loop would go here
MAIN_LOOP:
        HALT                    ; Wait for frame
        ; Game logic here
        JR MAIN_LOOP

; ===============================================
; CLEAR_SCREEN - Clear display and attributes
; ===============================================
CLEAR_SCREEN:
        LD HL, SCREEN_BASE
        LD DE, SCREEN_BASE + 1
        LD BC, 6143
        LD (HL), 0
        LDIR                    ; Clear bitmap
        
        LD HL, ATTR_BASE
        LD DE, ATTR_BASE + 1
        LD BC, 767
        LD (HL), 0x07           ; White ink on black paper
        LDIR                    ; Clear attributes
        RET

; ===============================================
; INIT_SPRITES - Initialize sprite system
; ===============================================
INIT_SPRITES:
        ; Clear all sprite descriptors
        LD HL, SPRITE_TABLE
        LD DE, SPRITE_TABLE + 1
        LD BC, MAX_SPRITES * SPRITE_SIZE - 1
        LD (HL), 0
        LDIR
        RET

; ===============================================
; DRAW_SPRITE - Draw a sprite using XOR
; ===============================================
; Input: HL = pointer to sprite descriptor
; Uses: All registers
; XOR drawing allows easy erase by redrawing
; ===============================================
DRAW_SPRITE:
        PUSH HL
        
        ; Check if sprite is active
        LD A, (HL)
        ADD A, SPRITE_FLAGS
        LD L, A
        LD A, (HL)
        AND FLAG_ACTIVE
        POP HL
        RET Z                   ; Return if not active
        
        PUSH HL
        
        ; Get sprite parameters
        LD A, (HL)              ; X position
        LD C, A
        INC HL
        LD A, (HL)              ; Y position
        LD B, A
        INC HL
        LD A, (HL)              ; Width in pixels
        LD (SPRITE_WIDTH_TMP), A
        INC HL
        LD A, (HL)              ; Height in pixels
        LD (SPRITE_HEIGHT_TMP), A
        INC HL
        INC HL                  ; Skip attribute for now
        LD E, (HL)              ; Get graphic data pointer
        INC HL
        LD D, (HL)
        
        ; DE now points to sprite graphic data
        ; B = Y position, C = X position
        
        ; Calculate screen address for (X,Y)
        PUSH DE                 ; Save graphic pointer
        LD A, B                 ; Y position
        LD D, A
        LD E, C                 ; X position
        CALL GET_SCREEN_ADDR    ; Returns address in HL
        EX DE, HL               ; DE = screen address
        POP HL                  ; HL = graphic data
        
        ; Draw the sprite
        LD A, (SPRITE_HEIGHT_TMP)
        LD B, A                 ; B = height in pixels
        
DRAW_SPRITE_ROW:
        PUSH BC
        PUSH DE
        
        ; Draw one row
        LD A, (SPRITE_WIDTH_TMP)
        SRL A                   ; Divide by 8 to get bytes
        SRL A
        SRL A
        LD B, A                 ; B = width in bytes
        
DRAW_SPRITE_BYTE:
        LD A, (HL)              ; Get sprite byte
        LD C, A
        LD A, (DE)              ; Get screen byte
        XOR C                   ; XOR sprite onto screen
        LD (DE), A
        INC HL
        INC DE
        DJNZ DRAW_SPRITE_BYTE
        
        ; Move to next screen row
        POP DE
        CALL NEXT_SCAN_LINE     ; DE = next scan line
        POP BC
        DJNZ DRAW_SPRITE_ROW
        
        POP HL
        RET

; ===============================================
; GET_SCREEN_ADDR - Calculate screen address
; ===============================================
; Input: D = Y coordinate (0-191)
;        E = X coordinate (0-255)
; Output: HL = screen memory address
; ===============================================
GET_SCREEN_ADDR:
        LD A, D                 ; Get Y
        AND 0xC0               ; Get bits 6-7
        OR 0x40                ; Set base screen address
        LD H, A
        
        LD A, D
        AND 0x07               ; Get scanline within character
        RRCA
        RRCA
        RRCA
        OR E                   ; Add X byte position
        SRL A
        SRL A
        SRL A
        LD L, A
        
        LD A, D
        AND 0x38               ; Get character row
        ADD A, H
        LD H, A
        
        RET

; ===============================================
; NEXT_SCAN_LINE - Move to next scanline
; ===============================================
; Input: DE = current screen address
; Output: DE = next scanline address
; ===============================================
NEXT_SCAN_LINE:
        INC D                   ; Simple increment for now
        ; This is simplified - proper version needs
        ; to handle Spectrum's weird screen layout
        ; For proof of concept this works for small sprites
        RET

; ===============================================
; SET_SPRITE_ATTR - Set sprite attributes
; ===============================================
; Input: HL = pointer to sprite descriptor
; Sets the attribute bytes for sprite area
; ===============================================
SET_SPRITE_ATTR:
        ; Get sprite position and size
        LD A, (HL)              ; X
        LD C, A
        INC HL
        LD A, (HL)              ; Y
        LD B, A
        INC HL
        LD A, (HL)              ; Width
        INC HL
        LD A, (HL)              ; Height
        INC HL
        LD A, (HL)              ; Attribute color
        LD E, A
        
        ; Calculate attribute address
        ; This is simplified - sets 2x2 character blocks
        LD A, B
        SRL A
        SRL A
        SRL A                   ; Y / 8
        LD D, A
        LD A, C
        SRL A
        SRL A
        SRL A                   ; X / 8
        
        ; Calculate attr address = ATTR_BASE + (Y/8)*32 + (X/8)
        LD H, 0
        LD L, D
        ADD HL, HL              ; * 2
        ADD HL, HL              ; * 4
        ADD HL, HL              ; * 8
        ADD HL, HL              ; * 16
        ADD HL, HL              ; * 32
        LD D, 0
        LD A, C
        SRL A
        SRL A
        SRL A
        LD C, A
        ADD HL, BC
        LD BC, ATTR_BASE
        ADD HL, BC
        
        ; Set 2x2 block of attributes
        LD (HL), E
        INC HL
        LD (HL), E
        LD BC, 31
        ADD HL, BC
        LD (HL), E
        INC HL
        LD (HL), E
        
        RET

; ===============================================
; TEST_SPRITES - Test sprite rendering
; ===============================================
TEST_SPRITES:
        ; Create a test sprite: simple diver shape
        LD HL, SPRITE_TABLE
        LD (HL), 100            ; X = 100
        INC HL
        LD (HL), 80             ; Y = 80
        INC HL
        LD (HL), 16             ; Width = 16
        INC HL
        LD (HL), 16             ; Height = 16
        INC HL
        LD (HL), 0x47           ; Cyan ink on black paper
        INC HL
        LD DE, TEST_SPRITE_GFX
        LD (HL), E              ; Graphic data pointer (low)
        INC HL
        LD (HL), D              ; Graphic data pointer (high)
        INC HL
        LD (HL), FLAG_ACTIVE    ; Active flag
        
        ; Draw it
        LD HL, SPRITE_TABLE
        CALL SET_SPRITE_ATTR
        CALL DRAW_SPRITE
        
        RET

; ===============================================
; Data Section
; ===============================================

; Temporary variables
SPRITE_WIDTH_TMP:  DB 0
SPRITE_HEIGHT_TMP: DB 0

; Sprite table (can hold up to 16 sprites for now)
MAX_SPRITES     EQU 16
SPRITE_SIZE     EQU 8
SPRITE_TABLE:   DS MAX_SPRITES * SPRITE_SIZE

; Test sprite graphic data (16x16 pixels = 32 bytes)
; Simple diver shape for testing
TEST_SPRITE_GFX:
        DB 0x00, 0x00           ; ................
        DB 0x01, 0x80           ; .......##.......
        DB 0x03, 0xC0           ; ......####......
        DB 0x07, 0xE0           ; .....######.....
        DB 0x0F, 0xF0           ; ....########....
        DB 0x0F, 0xF0           ; ....########....
        DB 0x1F, 0xF8           ; ...##########...
        DB 0x1F, 0xF8           ; ...##########...
        DB 0x0F, 0xF0           ; ....########....
        DB 0x07, 0xE0           ; .....######.....
        DB 0x03, 0xC0           ; ......####......
        DB 0x07, 0xE0           ; .....######.....
        DB 0x0E, 0x70           ; ....###..###....
        DB 0x1C, 0x38           ; ...###....###...
        DB 0x18, 0x18           ; ...##......##...
        DB 0x00, 0x00           ; ................

; ===============================================
; Program End
; ===============================================
END START
