# Building and running in qemu

Run `make all` to build.

Run `make qemu` to run with qemu.

Run `make qemu-gdb` to start qemu but wait for a gdb connection.
Then, run e.g. `aarch64-linux-gnu-gdb`.

# Random notes
* Got it to boot in qemu.
* Got uart serial to print in qemu.
* Wrote linked-list kernel page allocator; had to adjust max memory after
  noticing display framebuffer being mapped in a region of memory that I thought
  was free to use. Turns out qemu maps the last 64MiB to VideoCore RAM, and
  within that region, at 0x100000, qemu sets up a display framebuffer. Can't
  find docs about this in raspberry pi 3, so need to test if this actually
  happens.
* Starting on multiprocessing, first by doing kernel cooperative multithreading
