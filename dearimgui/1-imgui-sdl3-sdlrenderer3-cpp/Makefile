#CXX = g++
#CXX = clang++

EXE = example_sdl3_sdlrenderer3
SOURCES = main.cpp
SOURCES += imgui.cpp imgui_demo.cpp imgui_draw.cpp imgui_tables.cpp imgui_widgets.cpp
SOURCES += imgui_impl_sdl3.cpp imgui_impl_sdlrenderer3.cpp
OBJS = $(addsuffix .o, $(basename $(notdir $(SOURCES))))
UNAME_S := $(shell uname -s)
LINUX_GL_LIBS = -lGL

CXXFLAGS = -std=c++11 -I.
CXXFLAGS += -g -Wall -Wformat
LIBS =

ifeq ($(UNAME_S), Linux) # LINUX
	ECHO_MESSAGE = "Linux"
	LIBS += -ldl `pkg-config sdl3 --libs`

	CXXFLAGS += `pkg-config sdl3 --cflags`
	CFLAGS = $(CXXFLAGS)
endif

ifeq ($(UNAME_S), Darwin) # APPLE
	ECHO_MESSAGE = "Mac OS X"

	# Link against the SDL3 static library directly
	LIBS += ./lib/libSDL3.a

	# Required Apple frameworks for SDL3
	LIBS += -framework Cocoa \
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
			-framework MetalKit

	# Compiler flags
	CXXFLAGS += -isysroot $(shell xcrun --sdk macosx --show-sdk-path)
	CXXFLAGS += -I/usr/local/include -I/opt/local/include
	CXXFLAGS += -I./include
	CFLAGS = $(CXXFLAGS)
endif

ifeq ($(OS), Windows_NT)
	ECHO_MESSAGE = "MinGW"
	LIBS += -lgdi32 -limm32 `pkg-config --static --libs sdl3`

	CXXFLAGS += `pkg-config --cflags sdl3`
	CFLAGS = $(CXXFLAGS)
endif

##---------------------------------------------------------------------
## BUILD RULES
##---------------------------------------------------------------------

%.o:%.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

%.o:$(IMGUI_DIR)/%.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

%.o:$(IMGUI_DIR)/backends/%.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

all: $(EXE)
	@echo Build complete for $(ECHO_MESSAGE)

$(EXE): $(OBJS)
	$(CXX) -o $@ $^ $(CXXFLAGS) $(LIBS)

clean:
	rm -f $(EXE) $(OBJS)
