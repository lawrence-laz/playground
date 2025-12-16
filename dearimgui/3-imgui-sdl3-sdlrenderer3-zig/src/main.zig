const std = @import("std");
const builtin = @import("builtin");
const c = @cImport({
    @cDefine("SDL_DISABLE_OLD_NAMES", {});
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_revision.h");
    @cDefine("SDL_MAIN_HANDLED", {});
    @cInclude("SDL3/SDL_main.h");
    @cInclude("dcimgui.h");
    @cInclude("dcimgui_impl_sdl3.h");
    @cInclude("dcimgui_impl_sdlrenderer3.h");
});

pub fn main() !void {
    // --- Initialize SDL ---
    if (!c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_GAMEPAD)) {
        std.debug.print("Error: SDL_Init(): {s}\n", .{c.SDL_GetError()});
        return;
    }

    const main_scale = c.SDL_GetDisplayContentScale(c.SDL_GetPrimaryDisplay());
    const window_flags = c.SDL_WINDOW_RESIZABLE | c.SDL_WINDOW_HIDDEN | c.SDL_WINDOW_HIGH_PIXEL_DENSITY;

    const window = c.SDL_CreateWindow(
        "Dear ImGui SDL3+SDL_Renderer example",
        @intFromFloat(1280 * main_scale),
        @intFromFloat(800 * main_scale),
        window_flags,
    );
    if (window == null) {
        std.debug.print("Error: SDL_CreateWindow(): {s}\n", .{c.SDL_GetError()});
        return;
    }

    const renderer = c.SDL_CreateRenderer(window, null);
    if (renderer == null) {
        std.debug.print("Error: SDL_CreateRenderer(): {s}\n", .{c.SDL_GetError()});
        return;
    }
    _ = c.SDL_SetRenderVSync(renderer, 1);

    _ = c.SDL_SetWindowPosition(window, c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED);
    _ = c.SDL_ShowWindow(window);

    // --- Setup Dear ImGui ---
    _ = c.ImGui_CreateContext(null);
    const io = c.ImGui_GetIO();
    io.*.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard;
    io.*.ConfigFlags |= c.ImGuiConfigFlags_NavEnableGamepad;
    io.*.ConfigFlags |= c.ImGuiConfigFlags_DockingEnable;

    c.ImGui_StyleColorsDark(null);
    const style = c.ImGui_GetStyle();
    c.ImGuiStyle_ScaleAllSizes(style, main_scale);
    style.*.FontScaleDpi = main_scale;

    _ = c.cImGui_ImplSDL3_InitForSDLRenderer(window, renderer);
    _ = c.cImGui_ImplSDLRenderer3_Init(renderer);

    var show_demo_window: bool = true;
    var show_another_window: bool = false;
    var clear_color: c.ImVec4 = .{ .x = 0.45, .y = 0.55, .z = 0.60, .w = 1.0 };
    var done: bool = false;

    while (!done) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) {
            _ = c.cImGui_ImplSDL3_ProcessEvent(&event);
            if (event.type == c.SDL_EVENT_QUIT) done = true;
            if (event.type == c.SDL_EVENT_WINDOW_CLOSE_REQUESTED and
                event.window.windowID == c.SDL_GetWindowID(window))
            {
                done = true;
            }
        }

        if ((c.SDL_GetWindowFlags(window) & c.SDL_WINDOW_MINIMIZED) != 0) {
            c.SDL_Delay(10);
            continue;
        }

        // --- Start frame ---
        _ = c.cImGui_ImplSDLRenderer3_NewFrame();
        c.cImGui_ImplSDL3_NewFrame();
        c.ImGui_NewFrame();

        // Demo window
        if (show_demo_window) c.ImGui_ShowDemoWindow(&show_demo_window);

        // Custom window
        {
            var f: f32 = 0.0;
            var counter: i32 = 0;

            _ = c.ImGui_Begin("Hello, world!", &show_demo_window, 0);
            c.ImGui_Text("This is some useful text.");
            _ = c.ImGui_Checkbox("Demo Window", &show_demo_window);
            _ = c.ImGui_Checkbox("Another Window", &show_another_window);
            _ = c.ImGui_SliderFloat("float", &f, 0.0, 1.0);
            _ = c.ImGui_ColorEdit3("clear color", &clear_color.x, c.ImGuiColorEditFlags_None);
            if (c.ImGui_Button("Button")) counter += 1;
            _ = c.ImGui_SameLine();
            c.ImGui_Text("counter = %d", counter);
            c.ImGui_Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / io.*.Framerate, io.*.Framerate);
            c.ImGui_End();
        }

        if (show_another_window) {
            _ = c.ImGui_Begin("Another Window", &show_another_window, 0);
            c.ImGui_Text("Hello from another window!");
            if (c.ImGui_Button("Close Me")) show_another_window = false;
            c.ImGui_End();
        }

        // --- Rendering ---
        c.ImGui_Render();
        _ = c.SDL_SetRenderScale(renderer, io.*.DisplayFramebufferScale.x, io.*.DisplayFramebufferScale.y);
        _ = c.SDL_SetRenderDrawColorFloat(renderer, clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        _ = c.SDL_RenderClear(renderer);
        _ = c.cImGui_ImplSDLRenderer3_RenderDrawData(c.ImGui_GetDrawData(), renderer);
        _ = c.SDL_RenderPresent(renderer);
    }

    // --- Cleanup ---
    c.cImGui_ImplSDLRenderer3_Shutdown();
    c.cImGui_ImplSDL3_Shutdown();
    c.ImGui_DestroyContext(null);

    c.SDL_DestroyRenderer(renderer);
    c.SDL_DestroyWindow(window);
    c.SDL_Quit();
}
