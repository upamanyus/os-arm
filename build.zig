const Builder = @import("std").build.Builder;
const std = @import("std");

pub fn build(b: *Builder) void {
    const kernel = b.addExecutable("kernel8.elf", "kmain.zig");
    kernel.setOutputDir("build");

    kernel.addAssemblyFile("arch/aarch64/start.S");
    kernel.addAssemblyFile("arch/aarch64/switch.S");

    // kernel.setBuildMode(b.standardReleaseOptions());

    kernel.setBuildMode(std.builtin.Mode.ReleaseSmall);
    // kernel.setBuildMode(std.builtin.Mode.ReleaseSafe);
    // NOTE: doing Mode.Debug includes some unused functions in the kernel and
    // bloats the size. ReleaseSafe gets rid of that stuff

    kernel.setTarget(
        std.zig.CrossTarget{
            .cpu_arch = std.Target.Cpu.Arch.aarch64,
            .os_tag = std.Target.Os.Tag.freestanding,
            .abi = std.Target.Abi.none,
            .cpu_model = std.zig.CrossTarget.CpuModel{
                .explicit = &std.Target.aarch64.cpu.cortex_a35,
            },
        },
    );

    kernel.setLinkerScriptPath(std.build.FileSource.relative("arch/aarch64/linker.ld"));
    b.default_step.dependOn(&kernel.step);
}
