#include <GLFW/glfw3.h>
#include <bgfx/bgfx.h>
#include <bx/math.h>
#include <imgui.h>

static bgfx::VertexLayout g_imgui_vertex_layout;
static bgfx::TextureHandle g_imgui_font_texture;
static bgfx::UniformHandle g_imgui_font_uniform;
static bgfx::ProgramHandle g_imgui_program;

static GLFWwindow* g_imgui_window = NULL;
static GLFWcursor* g_imgui_cursors[ImGuiMouseCursor_COUNT] = {};

static const bgfx::ViewId g_imgui_view_id = 200;

static const char* imgui_get_clipboard(void* window) {
    return glfwGetClipboardString((GLFWwindow*)window);
}

static void imgui_set_clipboard(void* window, const char* text) {
    glfwSetClipboardString((GLFWwindow*)window, text);
}

static void imgui_init(GLFWwindow* window, bgfx::ProgramHandle program) {
    g_imgui_window = window;
    g_imgui_program = program;

    unsigned char* data;
    int width, height;
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();

    // Setup vertex declaration
    g_imgui_vertex_layout.begin()
        .add(bgfx::Attrib::Position, 2, bgfx::AttribType::Float)
        .add(bgfx::Attrib::TexCoord0, 2, bgfx::AttribType::Float)
        .add(bgfx::Attrib::Color0, 4, bgfx::AttribType::Uint8, true)
        .end();

    // Create font
    io.Fonts->AddFontDefault();
    io.Fonts->GetTexDataAsRGBA32(&data, &width, &height);
    g_imgui_font_texture = bgfx::createTexture2D((uint16_t)width, (uint16_t)height, false, 1, bgfx::TextureFormat::BGRA8, 0,
                                                 bgfx::copy(data, width * height * 4));
    g_imgui_font_uniform = bgfx::createUniform("s_tex", bgfx::UniformType::Sampler);

    // Setup render callback
    // io.RenderDrawListsFn = imgui_render;

    // Setup back-end capabilities flags
    io.BackendFlags |= ImGuiBackendFlags_HasMouseCursors;
    io.BackendFlags |= ImGuiBackendFlags_HasSetMousePos;

    // Key mapping
    io.KeyMap[ImGuiKey_Tab] = GLFW_KEY_TAB;
    io.KeyMap[ImGuiKey_LeftArrow] = GLFW_KEY_LEFT;
    io.KeyMap[ImGuiKey_RightArrow] = GLFW_KEY_RIGHT;
    io.KeyMap[ImGuiKey_UpArrow] = GLFW_KEY_UP;
    io.KeyMap[ImGuiKey_DownArrow] = GLFW_KEY_DOWN;
    io.KeyMap[ImGuiKey_PageUp] = GLFW_KEY_PAGE_UP;
    io.KeyMap[ImGuiKey_PageDown] = GLFW_KEY_PAGE_DOWN;
    io.KeyMap[ImGuiKey_Home] = GLFW_KEY_HOME;
    io.KeyMap[ImGuiKey_End] = GLFW_KEY_END;
    io.KeyMap[ImGuiKey_Insert] = GLFW_KEY_INSERT;
    io.KeyMap[ImGuiKey_Delete] = GLFW_KEY_DELETE;
    io.KeyMap[ImGuiKey_Backspace] = GLFW_KEY_BACKSPACE;
    io.KeyMap[ImGuiKey_Space] = GLFW_KEY_SPACE;
    io.KeyMap[ImGuiKey_Enter] = GLFW_KEY_ENTER;
    io.KeyMap[ImGuiKey_Escape] = GLFW_KEY_ESCAPE;
    io.KeyMap[ImGuiKey_A] = GLFW_KEY_A;
    io.KeyMap[ImGuiKey_C] = GLFW_KEY_C;
    io.KeyMap[ImGuiKey_V] = GLFW_KEY_V;
    io.KeyMap[ImGuiKey_X] = GLFW_KEY_X;
    io.KeyMap[ImGuiKey_Y] = GLFW_KEY_Y;
    io.KeyMap[ImGuiKey_Z] = GLFW_KEY_Z;

    io.SetClipboardTextFn = imgui_set_clipboard;
    io.GetClipboardTextFn = imgui_get_clipboard;
    io.ClipboardUserData = g_imgui_window;

#if BX_PLATFORM_WINDOWS
    io.ImeWindowHandle = (void*)glfwGetWin32Window(g_imgui_window);
#endif

    g_imgui_cursors[ImGuiMouseCursor_Arrow] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
    g_imgui_cursors[ImGuiMouseCursor_TextInput] = glfwCreateStandardCursor(GLFW_IBEAM_CURSOR);
    g_imgui_cursors[ImGuiMouseCursor_ResizeAll] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
    g_imgui_cursors[ImGuiMouseCursor_ResizeNS] = glfwCreateStandardCursor(GLFW_VRESIZE_CURSOR);
    g_imgui_cursors[ImGuiMouseCursor_ResizeEW] = glfwCreateStandardCursor(GLFW_HRESIZE_CURSOR);
    g_imgui_cursors[ImGuiMouseCursor_ResizeNESW] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
    g_imgui_cursors[ImGuiMouseCursor_ResizeNWSE] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
    g_imgui_cursors[ImGuiMouseCursor_Hand] = glfwCreateStandardCursor(GLFW_HAND_CURSOR);
}

static void imgui_reset(uint16_t width, uint16_t height) {
    bgfx::setViewRect(g_imgui_view_id, 0, 0, bgfx::BackbufferRatio::Equal);
}

static void imgui_events(float dt) {
    ImGuiIO& io = ImGui::GetIO();

    // Setup display size
    int window_w, window_h;
    int frame_w, frame_h;
    glfwGetWindowSize(g_imgui_window, &window_w, &window_h);
    glfwGetFramebufferSize(g_imgui_window, &frame_w, &frame_h);
    io.DisplaySize = ImVec2((float)window_w, (float)window_h);
    io.DisplayFramebufferScale = ImVec2(window_w > 0 ? ((float)frame_w / window_w) : 0, window_h > 0 ? ((float)frame_h / window_h) : 0);

    // Setup time step
    io.DeltaTime = dt;

    // Update mouse position
    const ImVec2 mouse_pos_backup = io.MousePos;
    io.MousePos = ImVec2(-FLT_MAX, -FLT_MAX);

#if BX_PLATFORM_EMSCRIPTEN
    const bool focused = true;
#else
    const bool focused = glfwGetWindowAttrib(g_imgui_window, GLFW_FOCUSED) != 0;
#endif

    if (focused) {
        if (io.WantSetMousePos) {
            glfwSetCursorPos(g_imgui_window, (double)mouse_pos_backup.x, (double)mouse_pos_backup.y);
        } else {
            double mouse_x, mouse_y;
            glfwGetCursorPos(g_imgui_window, &mouse_x, &mouse_y);
            io.MousePos = ImVec2((float)mouse_x, (float)mouse_y);
        }
    }

    // Update mouse cursor
    if (!(io.ConfigFlags & ImGuiConfigFlags_NoMouseCursorChange) && glfwGetInputMode(g_imgui_window, GLFW_CURSOR) != GLFW_CURSOR_DISABLED) {
        ImGuiMouseCursor imgui_cursor = ImGui::GetMouseCursor();
        if (imgui_cursor == ImGuiMouseCursor_None || io.MouseDrawCursor) {
            // Hide OS mouse cursor if imgui is drawing it or if it wants no cursor
            glfwSetInputMode(g_imgui_window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
        } else {
            // Show OS mouse cursor
            glfwSetCursor(g_imgui_window,
                          g_imgui_cursors[imgui_cursor] ? g_imgui_cursors[imgui_cursor] : g_imgui_cursors[ImGuiMouseCursor_Arrow]);
            glfwSetInputMode(g_imgui_window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
        }
    }
}

static void imgui_render() {
    ImGui::Render();
    ImDrawData* draw_data = ImGui::GetDrawData();

    for (int ii = 0, num = draw_data->CmdListsCount; ii < num; ++ii) {
        bgfx::TransientVertexBuffer tvb;
        bgfx::TransientIndexBuffer tib;

        const ImDrawList* draw_list = draw_data->CmdLists[ii];
        uint32_t num_vertices = (uint32_t)draw_list->VtxBuffer.size();
        uint32_t num_indices = (uint32_t)draw_list->IdxBuffer.size();

        if (!bgfx::getAvailTransientVertexBuffer(num_vertices, g_imgui_vertex_layout) || !bgfx::getAvailTransientIndexBuffer(num_indices)) {
            break;
        }

        bgfx::allocTransientVertexBuffer(&tvb, num_vertices, g_imgui_vertex_layout);
        bgfx::allocTransientIndexBuffer(&tib, num_indices);

        ImDrawVert* verts = (ImDrawVert*)tvb.data;
        memcpy(verts, draw_list->VtxBuffer.begin(), num_vertices * sizeof(ImDrawVert));

        ImDrawIdx* indices = (ImDrawIdx*)tib.data;
        memcpy(indices, draw_list->IdxBuffer.begin(), num_indices * sizeof(ImDrawIdx));

        uint32_t offset = 0;
        for (const ImDrawCmd *cmd = draw_list->CmdBuffer.begin(), *cmdEnd = draw_list->CmdBuffer.end(); cmd != cmdEnd; ++cmd) {
            if (cmd->UserCallback) {
                cmd->UserCallback(draw_list, cmd);
            } else if (0 != cmd->ElemCount) {
                uint64_t state = BGFX_STATE_WRITE_RGB | BGFX_STATE_WRITE_A | BGFX_STATE_MSAA;
                bgfx::TextureHandle th = g_imgui_font_texture;
                if (cmd->TextureId != NULL) {
                    th.idx = uint16_t(uintptr_t(cmd->TextureId));
                }
                state |= BGFX_STATE_BLEND_FUNC(BGFX_STATE_BLEND_SRC_ALPHA, BGFX_STATE_BLEND_INV_SRC_ALPHA);
                const uint16_t xx = uint16_t(bx::max(cmd->ClipRect.x, 0.0f));
                const uint16_t yy = uint16_t(bx::max(cmd->ClipRect.y, 0.0f));
                bgfx::setScissor(xx, yy, uint16_t(bx::min(cmd->ClipRect.z, 65535.0f) - xx),
                                 uint16_t(bx::min(cmd->ClipRect.w, 65535.0f) - yy));
                bgfx::setState(state);
                bgfx::setTexture(0, g_imgui_font_uniform, th);
                bgfx::setVertexBuffer(0, &tvb, 0, num_vertices);
                bgfx::setIndexBuffer(&tib, offset, cmd->ElemCount);
                bgfx::submit(g_imgui_view_id, g_imgui_program);
            }

            offset += cmd->ElemCount;
        }
    }
}

static void imgui_shutdown() {
    for (ImGuiMouseCursor cursor_n = 0; cursor_n < ImGuiMouseCursor_COUNT; cursor_n++) {
        glfwDestroyCursor(g_imgui_cursors[cursor_n]);
        g_imgui_cursors[cursor_n] = NULL;
    }

    bgfx::destroy(g_imgui_font_uniform);
    bgfx::destroy(g_imgui_font_texture);
    bgfx::destroy(g_imgui_program);
    ImGui::DestroyContext();
}

void imgui_key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    ImGuiIO& io = ImGui::GetIO();
    if (key >= 0 && key < IM_ARRAYSIZE(io.KeysDown)) {
        if (action == GLFW_PRESS) {
            io.KeysDown[key] = true;
        } else if (action == GLFW_RELEASE) {
            io.KeysDown[key] = false;
        }
    }

    io.KeyCtrl = io.KeysDown[GLFW_KEY_LEFT_CONTROL] || io.KeysDown[GLFW_KEY_RIGHT_CONTROL];
    io.KeyShift = io.KeysDown[GLFW_KEY_LEFT_SHIFT] || io.KeysDown[GLFW_KEY_RIGHT_SHIFT];
    io.KeyAlt = io.KeysDown[GLFW_KEY_LEFT_ALT] || io.KeysDown[GLFW_KEY_RIGHT_ALT];
    io.KeySuper = io.KeysDown[GLFW_KEY_LEFT_SUPER] || io.KeysDown[GLFW_KEY_RIGHT_SUPER];

    // return io.WantCaptureKeyboard;
}

void imgui_char_callback(GLFWwindow* window, unsigned int codepoint) {
    ImGuiIO& io = ImGui::GetIO();
    io.AddInputCharacter(codepoint);
}

void imgui_mouse_button_callback(GLFWwindow* window, int button, int action, int mods) {
    ImGuiIO& io = ImGui::GetIO();
    if (button >= 0 && button < IM_ARRAYSIZE(io.MouseDown)) {
        if (action == GLFW_PRESS) {
            io.MouseDown[button] = true;
        } else if (action == GLFW_RELEASE) {
            io.MouseDown[button] = false;
        }
    }

    // return io.WantCaptureMouse;
}

void imgui_scroll_callback(GLFWwindow* window, double xoffset, double yoffset) {
    ImGuiIO& io = ImGui::GetIO();
    io.MouseWheelH += (float)xoffset;
    io.MouseWheel += (float)yoffset;

    // return io.WantCaptureMouse;
}

bool imgui_want_keyboard() {
    ImGuiIO& io = ImGui::GetIO();
    return io.WantCaptureKeyboard;
}

bool imgui_want_mouse() {
    ImGuiIO& io = ImGui::GetIO();
    return io.WantCaptureMouse;
}
