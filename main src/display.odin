package main

import pd "playdate"

// Playdate screen constants

// The framebuffer is 1 bit per pixel, packed into bytes.
// Each row is 52 bytes wide (400 bits rounded up to the nearest 4-byte boundary).
ROW_BYTES :: 52

// Display holds a reference to the Playdate graphics procs
// and the raw framebuffer for direct pixel writes.
Display :: struct {
    gfx:         ^pd.Api_Graphics_Procs,
    framebuffer: [^]u8,
}

// Call once during .Init, after the pd context is created.
DisplayInit :: proc(gfx: ^pd.Api_Graphics_Procs) -> Display {
    return Display{
        gfx         = gfx,
        framebuffer = gfx.get_frame(),
    }
}

// Fill the entire screen with white.
// Call at the start of each frame before drawing.
DisplayClear :: proc(d: ^Display) {
    d.gfx.clear(pd.Color{solid = .White})
}

// Set a single pixel at (x, y).
// Pass black=true for a dark pixel, false for white.
// Pixels are packed 8-per-byte, MSB first. 1 = white, 0 = black.
DisplaySetPixel :: proc(d: ^Display, x, y: i32, black: bool) {
    if x < 0 || x >= SCREEN_WIDTH || y < 0 || y >= SCREEN_HEIGHT {
        return
    }
    byteIndex := y * ROW_BYTES + x / 8
    bitMask   := u8(1 << uint(7 - (x % 8)))

    if black {
        d.framebuffer[byteIndex] &~= bitMask  // clear bit = black
    } else {
        d.framebuffer[byteIndex] |=  bitMask  // set bit   = white
    }
}

// Mark all rows dirty and flush to the screen.
// Call at the end of each frame after all pixels are written.
DisplayPresent :: proc(d: ^Display) {
    d.gfx.mark_updated_rows(0, SCREEN_HEIGHT - 1)
}
