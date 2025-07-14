const Build = @import("std").Build;
const std = @import("std");
const Target = @import("std").Target;
const Feature = @import("std").Target.Cpu.Feature;

pub fn build(b: *Build) void {
    const features = Target.aarch64.Feature;
    var disabled_features = Feature.Set.empty;
    disabled_features.addFeature(@intFromEnum(features.fp_armv8));
    disabled_features.addFeature(@intFromEnum(features.neon));

    const query = std.Target.Query{
        .cpu_arch = std.Target.Cpu.Arch.aarch64,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
        .cpu_model = std.Target.Query.CpuModel{
            .explicit = &std.Target.aarch64.cpu.cortex_a35,
        },
        .cpu_features_sub = disabled_features,
    };
    const target = b.resolveTargetQuery(query);

    const kernel = b.addExecutable(.{
        .name = "kernel8.elf",
        .root_source_file = b.path("kmain.zig"),
        .target = target,
        .optimize = .Debug,
    });

    kernel.addAssemblyFile(b.path("arch/aarch64/start.S"));
    kernel.addAssemblyFile(b.path("arch/aarch64/entry.S"));
    kernel.addAssemblyFile(b.path("arch/aarch64/delay.S"));

    kernel.setLinkerScript(b.path("arch/aarch64/linker.ld"));
    b.default_step.dependOn(&kernel.step);
    b.installArtifact(kernel);
}
