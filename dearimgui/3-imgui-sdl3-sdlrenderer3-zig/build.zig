const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const app_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });

    if (target.result.os.tag == .windows and target.result.abi == .msvc) {
        // Work around a problematic definition in wchar.h in Windows SDK version 10.0.26100.0
        app_mod.addCMacro("_Avx2WmemEnabledWeakValue", "_Avx2WmemEnabled");
    }

    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
        .lto = .none,
        .preferred_linkage = .static,
    });
    const sdl_lib = sdl_dep.artifact("SDL3");
    app_mod.linkLibrary(sdl_lib);

    const exe = b.addExecutable(.{
        .name = "_3_imgui_sdl3_sdlrenderer3_zig",
        .root_module = app_mod,
    });

    // app_mod.addImport("sdl", sdl_dep.module("sdl"));
    app_mod.addIncludePath(sdl_dep.path("include"));

    b.installArtifact(exe);

    const imgui_c_srcs = .{
        "lib/imgui/dcimgui_impl_sdl3.cpp",
        "lib/imgui/dcimgui_impl_sdlrenderer3.cpp",
        "lib/imgui/dcimgui_internal.cpp",
        "lib/imgui/dcimgui.cpp",
        "lib/imgui/imgui_demo.cpp",
        "lib/imgui/imgui_draw.cpp",
        "lib/imgui/imgui_tables.cpp",
        "lib/imgui/imgui_widgets.cpp",
        "lib/imgui/imgui.cpp",
        "lib/imgui/imgui_impl_sdl3.cpp",
        "lib/imgui/imgui_impl_sdlrenderer3.cpp",
    };
    inline for (imgui_c_srcs) |src| {
        exe.root_module.addCSourceFile(.{ .file = b.path(src), .flags = &.{} });
    }
    exe.root_module.addIncludePath(b.path("include/imgui"));

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    // By making the run step depend on the default step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
