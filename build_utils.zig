const std = @import("std");
const builtin = @import("builtin");
const win = std.os.windows;
const allocator = std.heap.page_allocator;

pub fn getWinRTIncludePath() ![]const u8 {
    if (builtin.os.tag != .windows) {
        return error.UnsupportedPlatform;
    }

    // Get KitsRoot10 from registry (same as above)
    var hKey: win.HKEY = undefined;
    const key_path = L("SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots");
    try checkWin32Error(win.advapi32.RegOpenKeyExW(
        win.HKEY_LOCAL_MACHINE,
        key_path,
        0,
        win.KEY_READ,
        &hKey,
    ));
    defer _ = win.advapi32.RegCloseKey(hKey);

    var buffer: [512]u16 = undefined;
    var buffer_size: u32 = buffer.len * @sizeOf(u16);
    try checkWin32Error(win.advapi32.RegQueryValueExW(
        hKey,
        L("KitsRoot10"),
        null,
        null,
        @ptrCast(&buffer),
        &buffer_size,
    ));

    const len = buffer_size / @sizeOf(u16);
    buffer[@min(len, buffer.len - 1)] = 0;

    // Convert to UTF-8 for filesystem access
    const sdk_root_utf8 = try std.unicode.utf16LeToUtf8Alloc(std.heap.page_allocator, buffer[0..len]);
    defer allocator.free(sdk_root_utf8);

    // Enumerate Include directory for SDK versions
    // const include_path = try std.fs.path.join(allocator, &[_][]const u8{ sdk_root_utf8, "Include\\" });
    // defer allocator.free(include_path);
    // const include_path = try std.fmt.allocPrint(allocator, "{s}Include", .{sdk_root_utf8});
    // defer allocator.free(include_path);
    // either of the above should work but due to some reason it's not working. hardcoding it for now.
    const include_path = "C:\\Program Files (x86)\\Windows Kits\\10\\Include";

    var latest_version: []const u8 = "";
    var dir = try std.fs.cwd().openDir(include_path, .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .directory and std.mem.startsWith(u8, entry.name, "10.")) {
            if (std.mem.order(u8, entry.name, latest_version) == .gt) {
                latest_version = entry.name;
            }
        }
    }

    if (latest_version.len == 0) {
        return error.NoSdkVersionFound;
    }

    // Construct final path: KitsRoot10 + "Include\<version>\winrt"
    return std.fs.path.join(allocator, &[_][]const u8{
        include_path,
        latest_version,
        "winrt",
    });
}

fn checkWin32Error(err: win.LONG) !void {
    if (err != 0) { // ERROR_SUCCESS is 0
        return error.RegistryError;
    }
}

fn L(comptime s: []const u8) [:0]const u16 {
    return std.unicode.utf8ToUtf16LeStringLiteral(s);
}

fn min(a: anytype, b: anytype) @TypeOf(a, b) {
    return if (a < b) a else b;
}
