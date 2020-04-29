add_rules("mode.debug", "mode.release")

local IMGUI = "third_party/imgui/"
local BGFX  = "third_party/bgfx/"
local BIMG  = "third_party/bimg/"
local BX    = "third_party/bx/"
local GLFW  = "third_party/glfw/"
local GLM   = "third_party/glm/"

local SHADER_PLATFORMS = {
    -- "android",
    -- "asm.js",
    -- "ios",
    "linux",
    -- "osx",
    "windows"
}


target("game")
    set_kind("binary")
    set_default(true)
    add_deps("imgui", "bgfx", "glfw")

    set_warnings("all")
    add_rules("shader")

    add_files(
        "src/*.cpp",
        "assets/shaders/fs_*.sc",
        "assets/shaders/vs_*.sc"
    )
    add_includedirs(
        IMGUI,
        BGFX .. "include",
        BX   .. "include",
        GLFW .. "include",
        GLM
    )

    if is_os("windows") then
        add_includedirs(BX .. "include/compat/msvc")
        add_links("gdi32", "shell32", "user32")
        add_defines("_CRT_SECURE_NO_WARNINGS")
        if is_mode("release") then
            add_defines("WINMAIN_AS_ENTRY")
        end
    elseif is_os("linux") then
        add_links("dl", "GL", "pthread", "X11")
    elseif is_os("macosx") then
        add_includedirs(BX .. "include/compat/osx")
        add_links(
            "Cocoa.framework",
            "CoreVideo.framework",
            "IOKit.framework",
            "Metal.framework",
            "QuartzCore.framework"
        )
    end

    before_build(function (target)
        for _, platform in ipairs(SHADER_PLATFORMS) do
            local dir = vformat("$(projectdir)/assets/shaders/%s", platform)
            if not os.exists(dir) then
                os.mkdir(dir)
            end
        end
    end)

    on_clean(function (target)
        for _, platform in ipairs(SHADER_PLATFORMS) do
            local dir = vformat("$(projectdir)/assets/shaders/%s", platform)
            if os.exists(dir) then
                os.rmdir(dir)
            end
        end
    end)

    before_run(function (target)
        os.cd("$(projectdir)")
    end)


target("imgui")
    set_kind("static")
    add_files(IMGUI .. "*.cpp")


target("bgfx")
    set_kind("static")

    add_defines("__STDC_FORMAT_MACROS")

    add_files(
        BGFX .. "src/*.cpp|amalgamated.cpp",
        BIMG .. "src/image.cpp",
        BIMG .. "src/image_gnf.cpp",
        BIMG .. "3rdparty/astc-codec/src/decoder/*.cc",
        BX   .. "src/*.cpp|amalgamated.cpp|crtnone.cpp"
    )
    add_includedirs(
        BX   .. "3rdparty",
        BX   .. "include",
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
        del_files(
            BGFX .. "src/glcontext_glx.cpp",
            BGFX .. "src/glcontext_egl.cpp"
        )
        add_includedirs(BX .. "include/compat/msvc")
    elseif is_os("macosx") then
        add_files(BGFX .. "src/*.mm")
        add_includedirs(BX .. "include/compat/osx")
    end


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
        add_defines("_GLFW_WIN32")
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


rule("shader")
    set_extensions(".sc")
    on_build_file(function (target, sourcefile, opt)
        local shaders = vformat("$(projectdir)/assets/shaders")
        local include = vformat("$(projectdir)/third_party/bgfx/src")

        local base = path.basename(sourcefile)

        local type = nil
        if base:startswith("fs_") then
            type = "fragment"
        elseif base:startswith("vs_") then
            type = "vertex"
        end

        for _, platform in ipairs(SHADER_PLATFORMS) do
            local output = path.join(shaders, platform, base) .. ".bin"
            print("%-10s compiling shader %s...", "[" .. platform .. "]", base)

            os.execv("shaderc", {
                "-f", sourcefile,
                "-o", output,
                "-i", include,
                "--type", type,
                "--platform", platform
            })
        end
    end)
