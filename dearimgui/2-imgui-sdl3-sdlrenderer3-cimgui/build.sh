rm -rf cimgui_impl.o cimgui.o imgui_demo.o imgui_draw.o imgui_impl_sdl3.o imgui_impl_sdlrenderer3.o imgui_tables.o imgui_widgets.o imgui.o main.o example.out
echo "Cleared"

c++ -c \
    imgui.cpp imgui_draw.cpp imgui_tables.cpp imgui_widgets.cpp imgui_demo.cpp \
    imgui_impl_sdl3.cpp imgui_impl_sdlrenderer3.cpp \
    -I./include \
    -I./include/imgui \
    -DIMGUI_IMPL_API='extern "C"' \
    -std=c++11
echo "Dear ImGui compiled"

c++ -c cimgui_impl.cpp cimgui.cpp -I. -I./include -std=c++11 
echo "CImGui compiled"

# Compile Application code
cc -c main.c -I. -I./include
echo "Application compiled"

# Link
c++ -o example.out \
    imgui.o imgui_draw.o imgui_tables.o imgui_widgets.o imgui_demo.o imgui_impl_sdl3.o imgui_impl_sdlrenderer3.o \
    cimgui_impl.o cimgui.o main.o \
    -Wl,-force_load,./lib/libSDL3.a \
    -framework Cocoa \
    -framework IOKit \
    -framework CoreVideo \
    -framework AVFoundation \
    -framework CoreMedia \
    -framework CoreAudio \
    -framework AudioToolbox \
    -framework GameController \
    -framework CoreHaptics \
    -framework CoreServices \
    -framework CoreText \
    -framework CoreFoundation \
    -framework CoreGraphics \
    -framework QuartzCore \
    -framework Carbon \
    -framework UniformTypeIdentifiers \
    -framework ForceFeedback \
    -framework Metal \
    -framework MetalKit \
    -isysroot $(xcrun --sdk macosx --show-sdk-path) \
    -lm
echo "Linking compiled"

./example.out
