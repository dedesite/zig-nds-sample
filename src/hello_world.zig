const c = @cImport({
    @cDefine("ARM9", {});
    @cDefine("cpu", "arm946e_s");
    @cInclude("nds/libversion.h");
    // packed_struct define in ndstypes.h is not well handle by zig
    // so we redefined it
    @cDefine("packed_struct", {});
    @cInclude("nds/ndstypes.h");
    @cInclude("nds/system.h");
    @cInclude("nds/interrupts.h");
    @cInclude("nds/arm9/console.h");
    @cInclude("nds/arm9/video.h");
    @cInclude("nds/arm9/input.h");
    @cInclude("stdio.h");
});

// frame is declare as volatile in the original project, but I don't think volatile in zig
// mean the same thing as in C, but I may be wrong.
var frame: c_int = 0;

export fn vBlank() void {
    frame = frame + 1;
}

export fn main() i32 {
    var touchXY: c.touchPosition = undefined;

    c.irqSet(c.IRQ_VBLANK, vBlank);

    _ = c.consoleDemoInit();

    _ = c.printf("     Hello DS dev'rs using ZIG\n");
    _ = c.printf("     \x1b[32mwww.devkitpro.org\n");
    _ = c.printf("     \x1b[32;1mhttps://ziglang.org\x1b[39m");

    while (true) {
        c.swiWaitForVBlank();
        c.scanKeys();
        const keys: u32 = c.keysDown();
        if ((keys & c.KEY_START) > 0) break;
        c.touchRead(&touchXY);
        _ = c.printf("\x1b[10;0HFrame = %d", frame);
        _ = c.printf("\x1b[16;0HTouch x = %04X, %04X\n", touchXY.rawx, touchXY.px);
        _ = c.printf("Touch y = %04X, %04X\n", touchXY.rawy, touchXY.py);
    }

    return 0;
}
