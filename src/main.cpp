#include <GLFW/glfw3.h>
#include <bgfx/bgfx.h>
#include <bgfx/platform.h>
#include <stdio.h>

#include <string>

#if BX_PLATFORM_LINUX || BX_PLATFORM_BSD
#define GLFW_EXPOSE_NATIVE_X11
#define GLFW_EXPOSE_NATIVE_GLX
#elif BX_PLATFORM_OSX
#define GLFW_EXPOSE_NATIVE_COCOA
#define GLFW_EXPOSE_NATIVE_NSGL
#elif BX_PLATFORM_WINDOWS
#define GLFW_EXPOSE_NATIVE_WIN32
#define GLFW_EXPOSE_NATIVE_WGL
#endif

#include <GLFW/glfw3native.h>

#include "imgui.h"

#if WINMAIN_AS_ENTRY
#define MAIN() int WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
#else
#define MAIN() int main(int, char **)
#endif

static void reset();

static void glfw_error_callback(int error, const char *description);
static void glfw_window_size_callback(GLFWwindow *window, int width, int height);
static void glfw_key_callback(GLFWwindow *window, int key, int scancode, int action, int mods);
static void glfw_char_callback(GLFWwindow *window, unsigned int codepoint);
static void glfw_mouse_button_callback(GLFWwindow *window, int button, int action, int mods);
static void glfw_scroll_callback(GLFWwindow *window, double xoffset, double yoffset);

static bgfx::ProgramHandle create_program(const char *name);

static bool g_show_stats = false;
static int g_width = 1024;
static int g_height = 768;

MAIN() {
    // Create window using glfw
    glfwSetErrorCallback(glfw_error_callback);
    if (!glfwInit()) return -1;
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);

    auto window = glfwCreateWindow(g_width, g_height, "bgfx + imgui", nullptr, nullptr);
    if (!window) {
        glfwTerminate();
        return -1;
    }

    // Setting some window callbacks
    glfwSetWindowSizeCallback(window, glfw_window_size_callback);
    glfwSetKeyCallback(window, glfw_key_callback);
    glfwSetCharCallback(window, glfw_char_callback);
    glfwSetMouseButtonCallback(window, glfw_mouse_button_callback);
    glfwSetScrollCallback(window, glfw_scroll_callback);

    // Tell bgfx about our window
    bgfx::PlatformData platform_data = {};
#if BX_PLATFORM_LINUX || BX_PLATFORM_BSD
    platform_data.nwh = (void *)(uintptr_t)glfwGetX11Window(window);
    platform_data.ndt = glfwGetX11Display();
#elif BX_PLATFORM_OSX
    platform_data.nwh = glfwGetCocoaWindow(window);
#elif BX_PLATFORM_WINDOWS
    platform_data.nwh = glfwGetWin32Window(window);
#endif  // BX_PLATFORM_
    bgfx::setPlatformData(platform_data);

    // Init bgfx
    bgfx::Init init;
    // init.type = bgfx::RendererType::Vulkan;  // Select rendering backend
    init.vendorId = BGFX_PCI_ID_NONE;  // Choose graphics card vendor
    init.deviceId = 0;                 // Choose which graphics card to use
    init.callback = nullptr;
    if (!bgfx::init(init)) {
        fprintf(stderr, "unable to initialize bgfx\n");
        return -1;
    }

    // Initialize ImGui
    auto imgui_program = create_program("imgui");
    imgui_init(window, imgui_program);

    // Reset display buffers
    reset();

    float last_time = 0;
    float time;
    float dt;
    while (!glfwWindowShouldClose(window)) {
        // Calculate delta time
        time = (float)glfwGetTime();
        dt = time - last_time;
        last_time = time;

        // Poll events
        glfwPollEvents();
        imgui_events(dt);

        // Render
        ImGui::NewFrame();

        bgfx::touch(0);

        ImGui::Begin("Information", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
        ImGui::Text("Current window resolution is %dx%d", g_width, g_height);
        ImGui::End();

        ImGui::ShowDemoWindow();

        bgfx::dbgTextClear();
        bgfx::dbgTextPrintf(0, 0, 0x0f, "Press \x1b[11;mF1\x1b[0m to toggle stats.");
        bgfx::setDebug(g_show_stats ? BGFX_DEBUG_STATS : BGFX_DEBUG_TEXT);

        imgui_render();
        bgfx::frame();
    }

    // Destroy all resources
    imgui_shutdown();
    bgfx::shutdown();
    glfwTerminate();
    return 0;
}

static void reset() {
    bgfx::reset(g_width, g_height);
    imgui_reset(g_width, g_height);
    bgfx::setViewClear(0, BGFX_CLEAR_COLOR | BGFX_CLEAR_DEPTH, 0x1a1a1fff);
    bgfx::setViewRect(0, 0, 0, bgfx::BackbufferRatio::Equal);
}

static void glfw_error_callback(int error, const char *description) {
    fprintf(stderr, "GLFW error %d: %s\n", error, description);
}

static void glfw_window_size_callback(GLFWwindow *window, int width, int height) {
    g_width = width;
    g_height = height;
    reset();
}

static void glfw_key_callback(GLFWwindow *window, int key, int scancode, int action, int mods) {
    imgui_key_callback(window, key, scancode, action, mods);

    if (!imgui_want_keyboard()) {  // Ignore when ImGui has keyboard focus
        if (key == GLFW_KEY_F1 && action == GLFW_PRESS) g_show_stats = !g_show_stats;
    }
}

static void glfw_char_callback(GLFWwindow *window, unsigned int codepoint) {
    imgui_char_callback(window, codepoint);
}

static void glfw_mouse_button_callback(GLFWwindow *window, int button, int action, int mods) {
    imgui_mouse_button_callback(window, button, action, mods);
}

static void glfw_scroll_callback(GLFWwindow *window, double xoffset, double yoffset) {
    imgui_scroll_callback(window, xoffset, yoffset);
}

static const bgfx::Memory *load_file(const char *filename) {
    auto file = fopen(filename, "rb");
    if (!file) {
        fprintf(stderr, "unable to open file: %s\n", filename);
        return nullptr;
    }
    fseek(file, 0, SEEK_END);
    size_t file_size = ftell(file);
    rewind(file);
    const bgfx::Memory *mem = bgfx::alloc((uint32_t)file_size + 1);
    size_t read_size = fread(mem->data, 1, file_size, file);
    if (read_size != file_size) {
        fprintf(stderr, "read %llu bytes instead of %llu\n", read_size, file_size);
        return nullptr;
    }
    mem->data[mem->size - 1] = 0;
    return mem;
}

static const char *get_shader_type() {
    switch (bgfx::getRendererType()) {
        case bgfx::RendererType::Noop:
        case bgfx::RendererType::Direct3D9:
            return "dx9";
        case bgfx::RendererType::Direct3D11:
        case bgfx::RendererType::Direct3D12:
            return "dx11";
        case bgfx::RendererType::OpenGL:
            return "glsl";
        case bgfx::RendererType::OpenGLES:
            return "essl";
        case bgfx::RendererType::Metal:
            return "metal";
        case bgfx::RendererType::Vulkan:
            return "spirv";
        default:
            return "unknown";
    }
}

static bgfx::ProgramHandle create_program(const char *name) {
    char vs_path[256];
    char fs_path[256];

    snprintf(vs_path, sizeof(vs_path), "assets/shaders/%s/%s.v.bin", get_shader_type(), name);
    snprintf(fs_path, sizeof(fs_path), "assets/shaders/%s/%s.f.bin", get_shader_type(), name);

    auto vs = bgfx::createShader(load_file(vs_path));
    auto fs = bgfx::createShader(load_file(fs_path));
    return bgfx::createProgram(vs, fs, true);
}
