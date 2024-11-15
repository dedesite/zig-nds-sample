const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    const blocksDsDir = try std.process.getEnvVarOwned(b.allocator, "BLOCKSDS");
    defer b.allocator.free(blocksDsDir);
    // const devkitArmDir = try std.process.getEnvVarOwned(b.allocator, "DEVKITARM");
    // defer b.allocator.free(devkitArmDir);
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const cross_target = b.resolveTargetQuery(std.Target.Query.parse(.{
        .arch_os_abi = "arm-freestanding-eabi",
        .cpu_features = "arm9",
    }) catch unreachable);

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const obj = b.addObject(.{
        .name = "hello-world",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/hello_world.zig"),
        .target = cross_target,
        .optimize = optimize,
    });

    // Don't know how to set the omit-frame-pointer option now
    // obj.omit_frame_pointer = true;
    obj.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ blocksDsDir, "/libs/libnds/include/" }) });
    obj.addIncludePath(.{ .cwd_relative = "/opt/wonderful/toolchain/gcc-arm-none-eabi/include" });
    obj.addIncludePath(.{ .cwd_relative = "/opt/wonderful/toolchain/gcc-arm-none-eabi/arm-none-eabi/include" });

    const out = b.addInstallFile(obj.getEmittedBin(), "hello_world.o");

    const link = b.addSystemCommand(&[_][]const u8{
        "/opt/wonderful/toolchain/gcc-arm-none-eabi/bin/arm-none-eabi-gcc",
        "-o",
        "./hello_world.elf",
        "zig-out/hello_world.o",
        "-mthumb",
        "-mcpu=arm946e-s+nofp",
        b.fmt("-L{s}", .{b.pathJoin(&.{ blocksDsDir, "/libs/libnds/lib" })}),
        "-Wl,-Map,zig-nds-sample.map",
        "-Wl,--start-group",
        "-lnds9",
        "-lc",
        "-Wl,--end-group",
        b.fmt("-specs={s}", .{b.pathJoin(&.{ blocksDsDir, "/sys/crts/ds_arm9.specs" })}),
    });

    link.step.dependOn(&out.step);

    const rom = b.addSystemCommand(&[_][]const u8{
        b.pathJoin(&.{ blocksDsDir, "/tools/ndstool/ndstool" }),
        "-c",
        "./hello_world.nds",
        "-7",
        b.pathJoin(&.{ blocksDsDir, "/sys/default_arm7/arm7.elf" }),
        "-9",
        "./hello_world.elf",
        "-b",
        b.pathJoin(&.{ blocksDsDir, "/sys/icon.bmp" }),
        "hello_world;built with BlocksDS;github.com/blocksds/sdk",
    });
    rom.step.dependOn(&link.step);

    b.default_step.dependOn(&rom.step);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addSystemCommand(&[_][]const u8{ "desmume", "hello_world.nds" });

    // // By making the run step depend on the install step, it will be run from the
    // // installation directory rather than directly from within the cache directory.
    // // This is not necessary, however, if the application depends on other installed
    // // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // // This allows the user to pass arguments to the application in the build
    // // command itself, like this: `zig build run -- arg1 arg2 etc`
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // // This creates a build step. It will be visible in the `zig build --help` menu,
    // // and can be selected like this: `zig build run`
    // // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
