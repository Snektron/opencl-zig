const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const test_step = b.step("test", "Run all the tests");

    const opencl = b.addModule("opencl", .{
        .root_source_file = b.path("src/opencl.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });

    // TODO: Instead of relying on a system package,
    // we should either package the OpenCL-ICD-Loader
    // with Zig or manually load function pointers
    // from the OpenCL library.
    opencl.linkSystemLibrary("OpenCL", .{});

    const test_target = b.addTest(.{ .root_module = opencl });
    test_step.dependOn(&b.addRunArtifact(test_target).step);
}
