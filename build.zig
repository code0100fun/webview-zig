const std = @import("std");
const utils = @import("build_utils.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const webview = b.dependency("webview", .{
        .target = target,
        .optimize = optimize,
    });

    const webviewRaw = b.addTranslateC(.{
        .root_source_file = webview.path("core/include/webview/webview.h"),
        .optimize = optimize,
        .target = target,
    });

    const webview_mod = b.addModule("webview", .{
        .root_source_file = b.path("src/webview.zig"),
    });
    webview_mod.addImport("webviewRaw", webviewRaw.createModule());

    const staticLib = b.addStaticLibrary(.{
        .name = "webviewStatic",
        .optimize = optimize,
        .target = target,
    });
    staticLib.addIncludePath(webview.path("core/include/webview/"));
    staticLib.root_module.addCMacro("WEBVIEW_STATIC", "");
    // staticLib.root_module.addCMacro("WEBVIEW_EDGE", "");

    staticLib.linkLibCpp();
    switch (target.result.os.tag) {
        .windows => {
            const winrt_path = utils.getWinRTIncludePath() catch unreachable;
            staticLib.addIncludePath(std.Build.LazyPath{ .cwd_relative = winrt_path });
            staticLib.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++14"} });
            staticLib.addIncludePath(b.path("external/WebView2/"));
            staticLib.linkSystemLibrary("ole32");
            staticLib.linkSystemLibrary("shlwapi");
            staticLib.linkSystemLibrary("version");
            staticLib.linkSystemLibrary("advapi32");
            staticLib.linkSystemLibrary("shell32");
            staticLib.linkSystemLibrary("user32");
        },
        .macos => {
            staticLib.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            staticLib.linkFramework("WebKit");
        },
        .freebsd => {
            staticLib.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            staticLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/cairo/" });
            staticLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/gtk-3.0/" });
            staticLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/glib-2.0/" });
            staticLib.addIncludePath(.{ .cwd_relative = "/usr/local/lib/glib-2.0/include/" });
            staticLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/webkitgtk-4.0/" });
            staticLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/pango-1.0/" });
            staticLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/harfbuzz/" });
            staticLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/gdk-pixbuf-2.0/" });
            staticLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/atk-1.0/" });
            staticLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/libsoup-3.0/" });
            staticLib.linkSystemLibrary("gtk-3");
            staticLib.linkSystemLibrary("webkit2gtk-4.0");
        },
        else => {
            staticLib.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            staticLib.linkSystemLibrary("gtk+-3.0");
            staticLib.linkSystemLibrary("webkit2gtk-4.0");
        },
    }
    b.installArtifact(staticLib);

    const sharedLib = b.addSharedLibrary(.{
        .name = "webviewShared",
        .optimize = optimize,
        .target = target,
    });
    sharedLib.addIncludePath(webview.path("core/include/webview/"));

    sharedLib.root_module.addCMacro("WEBVIEW_BUILD_SHARED", "");
    // sharedLib.root_module.addCMacro("WEBVIEW_EDGE", "");
    sharedLib.linkLibCpp();
    switch (target.result.os.tag) {
        .windows => {
            const winrt_path = utils.getWinRTIncludePath() catch unreachable;
            sharedLib.addIncludePath(std.Build.LazyPath{ .cwd_relative = winrt_path });
            sharedLib.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++14"} });
            sharedLib.addIncludePath(b.path("external/WebView2/"));
            sharedLib.linkSystemLibrary("ole32");
            sharedLib.linkSystemLibrary("shlwapi");
            sharedLib.linkSystemLibrary("version");
            sharedLib.linkSystemLibrary("advapi32");
            sharedLib.linkSystemLibrary("shell32");
            sharedLib.linkSystemLibrary("user32");
        },
        .macos => {
            sharedLib.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            sharedLib.linkFramework("WebKit");
        },
        .freebsd => {
            sharedLib.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            sharedLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/cairo/" });
            sharedLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/gtk-3.0/" });
            sharedLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/glib-2.0/" });
            sharedLib.addIncludePath(.{ .cwd_relative = "/usr/local/lib/glib-2.0/include/" });
            sharedLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/webkitgtk-4.0/" });
            sharedLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/pango-1.0/" });
            sharedLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/harfbuzz/" });
            sharedLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/gdk-pixbuf-2.0/" });
            sharedLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/atk-1.0/" });
            sharedLib.addIncludePath(.{ .cwd_relative = "/usr/local/include/libsoup-3.0/" });
            sharedLib.linkSystemLibrary("gtk-3");
            sharedLib.linkSystemLibrary("webkit2gtk-4.0");
        },
        else => {
            sharedLib.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            sharedLib.linkSystemLibrary("gtk+-3.0");
            sharedLib.linkSystemLibrary("webkit2gtk-4.0");
        },
    }
    b.installArtifact(sharedLib);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });
    unit_tests.root_module.addImport("webviewRaw", webviewRaw.createModule());
    unit_tests.linkLibrary(staticLib);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
