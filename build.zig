const std = @import("std");

test

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const headers = b.dependency("opencl_headers", .{});

    const opencl = b.addModule("opencl", .{
        .root_source_file = b.path("src/opencl.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    opencl.addIncludePath(headers.path(""));
    // TODO: Instead of relying on a system package,
    // we should either package the OpenCL-ICD-Loader
    // with Zig or manually load function pointers
    // from the OpenCL library.
    opencl.linkSystemLibrary("OpenCL", .{});
}
