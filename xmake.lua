add_rules("mode.debug", "mode.release")

local IMGUI = "third_party/imgui/"
local BGFX = "third_party/bgfx/"
local BIMG = "third_party/bimg/"
local BX = "third_party/bx/"
local GLFW = "third_party/glfw/"


function bx_compat()
    if is_os("windows") then
        add_includedirs(BX .. "include/compat/msvc")
    elseif is_os("macosx") then
        add_includedirs(BX .. "include/compat/osx")
    end
end


target("game")
    set_kind("binary")
    set_default(true)
    add_files("src/*.cpp")
    add_deps("imgui", "bgfx", "glfw")
    add_includedirs(
        IMGUI,
        BGFX .. "include",
        BX .. "include",
        GLFW .. "include"
    )
    add_links("imgui", "bgfx", "glfw")
    if is_os("windows") then
        add_links("gdi32", "shell32", "user32")
        if is_mode("release") then
            add_defines("WINMAIN_AS_ENTRY")
        end
    elseif is_os("linux") then
        add_links("dl", "GL", "pthread", "X11")
    elseif is_os("macosx") then
        add_links(
            "Cocoa.framework",
            "CoreVideo.framework",
            "IOKit.framework",
            "Metal.framework",
            "QuartzCore.framework"
        )
    end
    set_warnings("all", "error")
    bx_compat()


target("imgui")
    set_kind("static")
    add_files(IMGUI .. "*.cpp")


target("bgfx")
    set_kind("static")
    add_defines("__STDC_FORMAT_MACROS")
    add_files(
        BGFX .. "src/*.cpp",
        BIMG .. "src/image.cpp",
        BIMG .. "src/image_gnf.cpp",
        BIMG .. "3rdparty/astc-codec/src/decoder/*.cc",
        BX .. "src/*.cpp"
    )
    del_files(
        BGFX .. "src/amalgamated.cpp",
        BX .. "src/amalgamated.cpp",
        BX .. "src/crtnone.cpp"
    )
    add_includedirs(
        BX .. "3rdparty",
        BX .. "include",
        BIMG .. "include",
        BGFX .. "include",
        BGFX .. "3rdparty",
        BGFX .. "3rdparty/dxsdk/include",
        BGFX .. "3rdparty/khronos",
        BIMG .. "3rdparty/astc-codec",
        BIMG .. "3rdparty/astc-codec/include"
    )
    if is_mode("debug") then
        add_defines("BGFX_CONFIG_DEBUG=1")
    end
    if is_os("windows") then
        add_defines("_CRT_SECURE_NO_WARNINGS")
        del_files(
            BGFX .. "src/glcontext_glx.cpp",
            BGFX .. "src/glcontext_egl.cpp"
        )
    elseif is_os("macosx") then
        add_files(BGFX .. "src/*.mm")
    end
    bx_compat()


target("glfw")
    set_kind("static")
    add_files(
        GLFW .. "src/context.c",
        GLFW .. "src/egl_context.c",
        GLFW .. "src/init.c",
        GLFW .. "src/input.c",
        GLFW .. "src/monitor.c",
        GLFW .. "src/osmesa_context.c",
        GLFW .. "src/vulkan.c",
        GLFW .. "src/window.c"
    )
    add_includedirs(GLFW .. "include")
    if is_os("windows") then
        add_defines("_GLFW_WIN32", "_CRT_SECURE_NO_WARNINGS")
        add_files(
            GLFW .. "src/win32_*.c",
            GLFW .. "src/wgl_context.c"
        )
    elseif is_os("linux") then
        add_defines("_GLFW_X11")
        add_files(
            GLFW .. "src/glx_context.c",
            GLFW .. "src/linux*.c",
            GLFW .. "src/posix*.c",
            GLFW .. "src/x11*.c",
            GLFW .. "src/xkb*.c"
        )
    elseif is_os("macosx") then
        add_defines("_GLFW_COCOA")
        add_files(
            GLFW .. "src/cocoa_*.c",
            GLFW .. "src/cocoa_*.m",
            GLFW .. "src/posix_thread.c",
            GLFW .. "src/nsgl_context.m",
            GLFW .. "src/egl_context.c",
            GLFW .. "src/nsgl_context.m",
            GLFW .. "src/osmesa_context.c"
        )
    end
