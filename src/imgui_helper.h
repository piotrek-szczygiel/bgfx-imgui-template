#pragma once

#include <GLFW/glfw3.h>
#include <bgfx/bgfx.h>
#include <bgfx/platform.h>

void imgui_init(GLFWwindow* window, bgfx::ProgramHandle program);
void imgui_reset(uint16_t width, uint16_t height);

void imgui_events(float dt);
void imgui_render();

void imgui_shutdown();

void imgui_key_callback(GLFWwindow* window, int key, int scancode, int action, int mods);
void imgui_char_callback(GLFWwindow* window, unsigned int codepoint);
void imgui_mouse_button_callback(GLFWwindow* window, int button, int action, int mods);
void imgui_scroll_callback(GLFWwindow* window, double xoffset, double yoffset);
bool imgui_want_keyboard();
bool imgui_want_mouse();
