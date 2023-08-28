Zig nds example
=====================

This is a working nds example written in ZIG.
For now, it's a clone of the [hello_world](https://github.com/devkitPro/nds-examples/tree/master/hello_world) example, but it may evolve to something else in the futur.

Previous version used a modified Makefile, now I try to use Zig build system instead, but it's still very hacky for now.

## Prerequisites

You need to [install devitkit pro](https://devkitpro.org/wiki/devkitPro_pacman) before being able to use this project.
I also use [desmune](https://github.com/TASEmulators/desmume) to automatically run the rom, so you need it in order to use `zig build run`.

Also, the build script will only run on Linux for now.
## Current limitations

- The `@cImport` zig function doesn't parse well anonymous struct and some maccros used by libnds, so I had to manually choose the needed headers instead of directly important `nds.h`. For example, [`sprite.h`](https://github.com/devkitPro/libnds/blob/master/include/nds/arm9/sprite.h) can't be imported via `@cImport`.
- I also had to comment/uncomment a define in [ndstypes.h](https://github.com/devkitPro/libnds/blob/7e8902ac2a9ae3a983fa0519b4f7026d04d7d0fd/include/nds/ndstypes.h#L57) during the build process.

So it's not possible to use "out of the box" `nds.h` but it's a nice start !
