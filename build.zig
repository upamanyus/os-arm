const Build = @import("std").Build;
const std = @import("std");
const Target = @import("std").Target;
const Feature = @import("std").Target.Cpu.Feature;

pub fn build(b: *Build) void {
    const features = Target.arm.Feature;
    var disabled_features = Feature.Set.empty;
    disabled_features.addFeature(@intFromEnum(features.fp_armv8));
    disabled_features.addFeature(@intFromEnum(features.neon));
    var enabled_features = Feature.Set.empty;
    enabled_features.addFeature(@intFromEnum(features.soft_float));

    const target = b.resolveTargetQuery(std.zig.CrossTarget{
        .cpu_arch = std.Target.Cpu.Arch.aarch64,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
        .cpu_model = std.zig.CrossTarget.CpuModel{
            .explicit = &std.Target.aarch64.cpu.cortex_a35,
        },
        .cpu_features_sub = disabled_features,
        .cpu_features_add = enabled_features,
    });

    const kernel = b.addExecutable(.{
        .name = "kernel8.elf",
        .root_source_file = b.path("kmain.zig"),
        .target = target,
        .optimize = .ReleaseSafe,
    });
    // kernel.setOutputDir("build");

    kernel.addAssemblyFile(b.path("arch/aarch64/start.S"));
    kernel.addAssemblyFile(b.path("arch/aarch64/switch.S"));
    kernel.addAssemblyFile(b.path("arch/aarch64/entry.S"));

    kernel.setLinkerScriptPath(b.path("arch/aarch64/linker.ld"));
    b.default_step.dependOn(&kernel.step);
    b.installArtifact(kernel);
}
