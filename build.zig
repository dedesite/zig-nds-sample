const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const cross_target = std.zig.CrossTarget.parse(.{
        .arch_os_abi = "arm-freestanding-eabi",
        .cpu_features = "arm9",
    }) catch unreachable;

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const obj = b.addObject(.{
        .name = "hello-world",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "source/hello_world.zig" },
        .target = cross_target,
        .optimize = optimize,
        //.flags = &.{"-fomit-frame-pointer"},
    });

    obj.omit_frame_pointer = true;
    // obj.generated_bin = std.Build.GeneratedFile{ .step = &obj.step, .path = "./build/hello_world.o" };
    obj.addIncludePath(.{ .path = "/opt/devkitpro/libnds/include/"});
    obj.addIncludePath(.{ .path = "/opt/devkitpro/devkitARM/arm-none-eabi/include"});

    const out = b.addInstallFile(obj.getEmittedBin(), "hello_world.o");
    //out.step.dependOn(&obj.step);
    // obj.addCompileFlags([][]const u8 {
    //     "-DARM9",
    //     "-Dcpu=arm946e_s"
    // });

    const link = b.addSystemCommand(&[_][]const u8{
        "arm-none-eabi-gcc",
        "-specs=ds_arm9.specs",
        "-g",
        "-mthumb",
        "-Wl,-Map,zig-nds-sample.map",
        "zig-out/hello_world.o",
        "-L/opt/devkitpro/libnds/lib",
        "-lnds9",
        "-o",
        "./zig-nds-sample.elf"
    });

    link.step.dependOn(&out.step);

    const rom = b.addSystemCommand(&[_][]const u8{
        "ndstool",
        "-c",
        "./zig-nds-sample.nds",
        "-9",
        "./zig-nds-sample.elf",
        "-b",
        "/opt/devkitpro/libnds/icon.bmp",
        "zig-nds-sample;built with devkitARM;http://devkitpro.org",
    });
    rom.step.dependOn(&link.step);

    b.default_step.dependOn(&rom.step);
    // const install_object = b.addInstallFile(obj.getOutputSource(), "hello-world.o");
    // b.getInstallStep().dependOn(&install_object.step);
    //obj.override_dest_dir = std.Build.InstallDir{ .custom = "obj" };

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    //b.installArtifact(obj);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addSystemCommand(&[_][]const u8{
        "desmume",
        "zig-nds-sample.nds"
    });

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
