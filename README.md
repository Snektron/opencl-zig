# opencl-zig

OpenCL bindings for Zig.

## Overview

This repository attempts to improve the OpenCL programming experience in Zig. This is done by for example translating OpenCL errors into Zig errors, integration with Zig allocators, Zig-friendly boilerplate around OpenCL functions, and adapting the API to common Zig style in general.

opencl-zig generally targets latest Zig, and is tested daily.

The bindings are hand-written and added on a when-required basis: Unlike Vulkan, OpenCL's machine readable API definitions (cl.xml) aren't really suitable to automatically generate Zig bindings. For example, information about the possible errors that a function returns is not available. If required API functionality is missing, please make an issue or a pull request.

## Examples

A saxpy example is available in [examples/saxpy.zig](examples/saxpy.zig). It can be executed by running `zig build --build-file $(pwd)/examples/build.zig run-saxpy` in the opencl-zig root directory.

## Usage

opencl-zig can be included in a Zig project as a regular Zig dependency. First, add a dependency to the bindings to your `build.zig.zon`:
```zig
.{
    .dependencies = .{
        .opencl = .{
            .url = "https://github.com/Snektron/opencl-zig/archive/<commit SHA>.tar.gz",
            .hash = "<dependency hash>",
        },
    },
}
```
In your `build.zig` file, you can then import opencl-zig as usual. Note that you are required to pass the current build mode and target to the opencl-zig dependency:
```zig
pub fn build(b: *std.Build) void {
    const target = ...;
    const optimize = ...;
    const opencl = b.dependency("opencl", .{
        .target = target,
        .optimize = optimize,
    }).module("opencl");

    const exe = ...;
    exe.root_module.addImport("opencl", opencl);
}
```

See [examples/build.zig](examples/build.zig) and [examples/build.zig.zon](examples/build.zig.zon) for a concrete example.

### Caveats

Currently, opencl-zig depends on the `OpenCL` system dependency. On Linux, this is provided by `libOpenCL.so`, which usually either an ICD loader such as [OpenCL-ICD-Loader](https://github.com/KhronosGroup/OpenCL-ICD-Loader) or [ocl-icd](https://github.com/OCL-dev/ocl-icd), or a GPU driver directly. In the future, this project might automatically build an ICD loader automatically, but for now, a system dependency is required. OpenCL headers are not required, these are automatically fetched.

## Design

The bindings are mostly written by translating the [OpenCL API](https://registry.khronos.org/OpenCL/specs/3.0-unified/html/OpenCL_API.html) to Zig in a straight forward manner, though there are some deviations where it makes sense. In general, the bindings are designed along the following guidelines:
- Functions related to a particular OpenCL object live in a type named after that particular object, but without the OpenCL namespace bits and cased in usual Zig Pascal casing. For example, functions that operate on `cl_platform_id` live in `Platform`, and functions that operate on `cl_event` live in `Event`.
- Zig equivalents of OpenCL objects are declared as `extern struct` with `handle` as sole member. This allows us to type pun the Zig type into an OpenCL type to provide a smoother integration.
- Freestanding functions are stripped of their OpenCL namespace too. Create-style functions such as `clCreateContext` are implemented as `Context.create`, and a freestanding alias `createContext` is provided to mirror the OpenCL API more closely.
- Functions that require allocation are implemented using Zig `Allocator`s so that Users only need to make a single call rather than two. See for example `Device.getName`.
- Where it makes sense, `clGet*Info` calls are lowered into a single `getInfo` function. This doesn't really work for info calls that require dynamic size, those are usually implemented as a separate function.
- Not all errors are directly converted into the equivalent Zig error. Generally, they are translated according to the following rules:
  - `CL_SUCCESS` is obviously never translated into an error.
  - Errors that are programmer errors, such as invalid parameter values or lifetime issues, are made `unreachable`. All paths are separated so that the programmer can see which error was triggered more easily.
  - Errors that occur due to issues that the programmer couldn't avoid by programming better, such as resource exhaustion, (kernel) compile errors, etc, are generally translated into Zig errors of the same name. Some exceptions apply, see below.
  - `CL_OUT_OF_HOST_MEMORY` is translated into `error.OutOfMemory` so that it is the same error as returned by allocator implementations.
