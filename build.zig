const std = @import("std");
const sources = @import("sources.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libnng = b.addLibrary(.{
        .name = "nng",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .static,
    });
    libnng.linkLibC();
    
    // Add includes
    for (sources.include_dirs) |include_dir| {
        libnng.addIncludePath(b.path(include_dir));
    }

    // Add sources with flags
    const flags = b.allocator.alloc([]const u8, sources.defines.len + sources.c_flags.len) catch @panic("OOM");
    @memcpy(flags[0..sources.defines.len], sources.defines);
    @memcpy(flags[sources.defines.len..], sources.c_flags);
    
    const nanomq = b.addExecutable(.{
        .name = "nanomq",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    nanomq.linkLibC();
    
    for (sources.include_dirs) |include_dir| {
        nanomq.addIncludePath(b.path(include_dir));
    }

    nanomq.addCSourceFiles(.{
        .files = sources.nanomq_sources,
        .flags = flags,
    });
    nanomq.addCSourceFiles(.{
        .files = sources.nng_sources,
        .flags = flags,
    });

    nanomq.linkSystemLibrary("pthread");
    nanomq.linkSystemLibrary("rt");
    nanomq.linkSystemLibrary("dl");
    nanomq.linkSystemLibrary("mbedtls");
    nanomq.linkSystemLibrary("mbedx509");
    nanomq.linkSystemLibrary("mbedcrypto");
    nanomq.linkSystemLibrary("crypto");

    b.installArtifact(nanomq);

    const nanomq_cli = b.addExecutable(.{
        .name = "nanomq_cli",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    nanomq_cli.linkLibC();
    
    for (sources.include_dirs) |include_dir| {
        nanomq_cli.addIncludePath(b.path(include_dir));
    }

    nanomq_cli.addCSourceFiles(.{
        .files = sources.nanomq_cli_sources,
        .flags = flags,
    });
    nanomq_cli.addCSourceFiles(.{
        .files = sources.nng_sources,
        .flags = flags,
    });

    nanomq_cli.linkSystemLibrary("pthread");
    nanomq_cli.linkSystemLibrary("rt");
    nanomq_cli.linkSystemLibrary("dl");
    nanomq_cli.linkSystemLibrary("mbedtls");
    nanomq_cli.linkSystemLibrary("mbedx509");
    nanomq_cli.linkSystemLibrary("mbedcrypto");
    nanomq_cli.linkSystemLibrary("crypto");

    b.installArtifact(nanomq_cli);
}
