const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const opencl = b.dependency("opencl", .{
        .target = target,
        .optimize = optimize,
    }).module("opencl");

    const saxpy_exe = b.addExecutable(.{
        .name = "saxpy",
        .root_source_file = b.path("saxpy.zig"),
        .target = target,
        .link_libc = true,
        .optimize = optimize,
    });
    saxpy_exe.root_module.addImport("opencl", opencl);
    b.installArtifact(saxpy_exe);

    const saxpy_run_cmd = b.addRunArtifact(saxpy_exe);
    saxpy_run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        saxpy_run_cmd.addArgs(args);
    }

    const saxpy_run_step = b.step("run-saxpy", "Run the saxpy example");
    saxpy_run_step.dependOn(&saxpy_run_cmd.step);

    const test_step = b.step("test", "Run all examples and see if they work correctly");
    test_step.dependOn(&saxpy_run_cmd.step);
}
