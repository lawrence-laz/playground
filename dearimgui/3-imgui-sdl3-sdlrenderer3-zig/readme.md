# SDL3
Built SDL3 version 3.2.26 (original commit badbf8da4ee72b3ef599c721ffc9899e8d7c8d90) from https://github.com/castholm/SDL
Using Makefile:
```
ZIG_SYSROOT := $(shell xcrun --show-sdk-path)

all:
	zig build -Dtarget=aarch64-macos --sysroot $(ZIG_SYSROOT) -Doptimize=ReleaseFast

clean:
	rm -rf zig-out .zig-cache
```

# Dear ImGui
Version 1.92.5-docking (commit 3912b3d9a9c1b3f17431aebafd86d2f40ee6e59c) from https://github.com/ocornut/imgui
