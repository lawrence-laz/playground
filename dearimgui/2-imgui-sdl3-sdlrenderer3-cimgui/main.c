// main.c - Dear ImGui SDL3 + SDL_Renderer example using cimgui (C)

#define CIMGUI_DEFINE_ENUMS_AND_STRUCTS
#define CIMGUI_USE_SDL3
#define CIMGUI_USE_SDLRENDERER3
#include "cimgui.h"
#include "cimgui_impl.h"
#include <SDL3/SDL.h>
#include <stdio.h>
#include <stdbool.h>

#ifdef __EMSCRIPTEN__
#include "../libs/emscripten/emscripten_mainloop_stub.h"
#endif

int main(int argc, char** argv)
{
    // Setup SDL
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD))
    {
        printf("Error: SDL_Init(): %s\n", SDL_GetError());
        return 1;
    }

    float main_scale = SDL_GetDisplayContentScale(SDL_GetPrimaryDisplay());
    SDL_WindowFlags window_flags = SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIDDEN | SDL_WINDOW_HIGH_PIXEL_DENSITY;
    SDL_Window* window = SDL_CreateWindow("Dear ImGui SDL3+SDL_Renderer example",
                                          (int)(1280 * main_scale),
                                          (int)(800 * main_scale),
                                          window_flags);
    if (!window)
    {
        printf("Error: SDL_CreateWindow(): %s\n", SDL_GetError());
        return 1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, NULL);
    SDL_SetRenderVSync(renderer, 1);
    if (!renderer)
    {
        SDL_Log("Error: SDL_CreateRenderer(): %s\n", SDL_GetError());
        return 1;
    }

    SDL_SetWindowPosition(window, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED);
    SDL_ShowWindow(window);

    // Setup Dear ImGui context
    igCreateContext(NULL);
    ImGuiIO* io = igGetIO_Nil(); 
    io->ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    io->ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;
    io->ConfigFlags |= ImGuiConfigFlags_DockingEnable;

    // Setup style
    igStyleColorsDark(NULL);
    ImGuiStyle* style = igGetStyle();
    ImGuiStyle_ScaleAllSizes(style, main_scale);
    style->FontScaleDpi = main_scale;

    // Setup Platform/Renderer backends
    ImGui_ImplSDL3_InitForSDLRenderer(window, renderer);
    ImGui_ImplSDLRenderer3_Init(renderer);

    // State
    bool show_demo_window = true;
    bool show_another_window = false;
    ImVec4 clear_color = {0.45f, 0.55f, 0.60f, 1.00f};
    int done = 0;

#ifdef __EMSCRIPTEN__
    io->IniFilename = NULL;
    EMSCRIPTEN_MAINLOOP_BEGIN
#else
    while (!done)
#endif
    {
        SDL_Event event;
        while (SDL_PollEvent(&event))
        {
            ImGui_ImplSDL3_ProcessEvent(&event);
            if (event.type == SDL_EVENT_QUIT)
                done = 1;
            if (event.type == SDL_EVENT_WINDOW_CLOSE_REQUESTED &&
                event.window.windowID == SDL_GetWindowID(window))
                done = 1;
        }

        if (SDL_GetWindowFlags(window) & SDL_WINDOW_MINIMIZED)
        {
            SDL_Delay(10);
            continue;
        }

        // Start frame
        ImGui_ImplSDLRenderer3_NewFrame();
        ImGui_ImplSDL3_NewFrame();
        igNewFrame();

        // Demo window
        if (show_demo_window)
            igShowDemoWindow(&show_demo_window);

        // Custom window
        {
            static float f = 0.0f;
            static int counter = 0;

            igBegin("Hello, world!", &show_demo_window, 0);
            igText("This is some useful text.");
            igCheckbox("Demo Window", &show_demo_window);
            igCheckbox("Another Window", &show_another_window);
            igSliderFloat("float", &f, 0.0f, 1.0f, "%.3f", 1.0f);
            igColorEdit3("clear color", (float*)&clear_color, ImGuiColorEditFlags_None);
            if (igButton("Button", (ImVec2){0,0}))
                counter++;
            igSameLine(0.0f, -1.0f);
            igText("counter = %d", counter);
            igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / io->Framerate, io->Framerate);
            igEnd();
        }

        if (show_another_window)
        {
            igBegin("Another Window", &show_another_window, 0);
            igText("Hello from another window!");
            if (igButton("Close Me", (ImVec2){0,0}))
                show_another_window = false;
            igEnd();
        }

        // Rendering
        igRender();
        SDL_SetRenderScale(renderer, io->DisplayFramebufferScale.x, io->DisplayFramebufferScale.y);
        SDL_SetRenderDrawColorFloat(renderer, clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        SDL_RenderClear(renderer);
        ImGui_ImplSDLRenderer3_RenderDrawData(igGetDrawData(), renderer);
        SDL_RenderPresent(renderer);
    }
#ifdef __EMSCRIPTEN__
    EMSCRIPTEN_MAINLOOP_END;
#endif

    // Cleanup
    ImGui_ImplSDLRenderer3_Shutdown();
    ImGui_ImplSDL3_Shutdown();
    igDestroyContext(NULL);

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
