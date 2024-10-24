cd iipsav-mpsc && zig build --release=fast && cd ..
cd vyukov && zig build --release=fast && cd ..

hyperfine --warmup 3 \
  iipsav-mpsc/zig-out/bin/zig-exe \
  vyukov/zig-out/bin/zig-exe

# Majority of the time is application startup, which makes testing this with hyperfine subpar.
# Measure timestamps and print instead.

