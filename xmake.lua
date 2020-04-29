add_rules("mode.debug", "mode.release")

local IMGUI = "third_party/imgui/"
local BGFX  = "third_party/bgfx/"
local BIMG  = "third_party/bimg/"
local BX    = "third_party/bx/"
local GLFW  = "third_party/glfw/"
local GLM   = "third_party/glm/"

local SHADERC        = BGFX .. "tools/shaderc/"
local GLSL_OPTIMIZER = BGFX .. "3rdparty/glsl-optimizer/"
local FCPP           = BGFX .. "3rdparty/fcpp/"
local GLSLANG        = BGFX .. "3rdparty/glslang/"
local SPIRV_HEADERS  = BGFX .. "3rdparty/spirv-headers/"
local SPIRV_CROSS    = BGFX .. "3rdparty/spirv-cross/"
local SPIRV_HEADERS  = BGFX .. "3rdparty/spirv-headers/"
local SPIRV_TOOLS    = BGFX .. "3rdparty/spirv-tools/"

local SHADER_PLATFORMS = {
    "android",
    "asm.js",
    "ios",
    "linux",
    -- "orbis",
    "osx",
    "windows"
}


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
    add_includedirs(
        IMGUI,
        BGFX .. "include",
        BX   .. "include",
        GLFW .. "include",
        GLM
    )
    add_deps("imgui", "bgfx", "glfw", "shaderc")
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
    set_warnings("all")
    bx_compat()



    -- compile shaders inside assets/shaders directory
    after_build(function (target)
        local shaders = vformat("$(projectdir)/assets/shaders")
        os.tryrm(shaders .. "/**.bin")

        for _, platform in ipairs(SHADER_PLATFORMS) do
            os.mkdir(path.join(shaders, platform))
        end

        local include = vformat("$(projectdir)/third_party/bgfx/src")
        local shaderc = path.join(target:targetdir(), "shaderc")

        for _, platform in ipairs(SHADER_PLATFORMS) do
            print("Compiling shaders (" .. platform .. ")")

            for _, filepath in ipairs(os.files(shaders .. "/**.sc")) do
                local base = path.basename(filepath)

                local type = nil
                if base:startswith("fs_") then
                    type = "fragment"
                elseif base:startswith("vs_") then
                    type = "vertex"
                end

                if type then
                    print("  " .. path.filename(filepath))
                    local output = path.join(shaders, platform, base) .. ".bin"

                    os.execv(shaderc, {
                        "-f", filepath,
                        "-o", output,
                        "-i", include,
                        "--type", type,
                        "--platform", platform
                    })
                end
            end
            print()
        end
    end)


target("imgui")
    set_kind("static")
    add_files(IMGUI .. "*.cpp")


target("shaderc")
    set_kind("binary")
    add_deps("fcpp", "glsl-optimizer", "glslang", "spirv-cross", "spirv-tools")
    add_files(
        SHADERC .. "*.cpp",
        BX      .. "src/*.cpp",
        BGFX    .. "src/shader_spirv.cpp",
        BGFX    .. "src/vertexlayout.cpp"
    )
    del_files(
        BX   .. "src/amalgamated.cpp",
        BX   .. "src/crtnone.cpp"
    )
    add_includedirs(
        BX   .. "include",
        BX   .. "3rdparty",
        BGFX .. "include",
        BIMG .. "include",
        FCPP,
        GLSL_OPTIMIZER .. "src/glsl",
        GLSLANG,
        GLSLANG .. "glslang/Include",
        GLSLANG .. "glslang/Public",
        SPIRV_TOOLS .. "include",
        SPIRV_CROSS,
        SPIRV_CROSS .. "include"
    )
    add_defines("__STDC_FORMAT_MACROS")
    if is_os("windows") then
        add_links("user32", "gdi32")
    elseif is_os("linux") then
        add_links("dl", "pthread")
    end
    bx_compat()


target("bgfx")
    set_kind("static")
    add_files(
        BGFX .. "src/*.cpp",
        BIMG .. "src/image.cpp",
        BIMG .. "src/image_gnf.cpp",
        BIMG .. "3rdparty/astc-codec/src/decoder/*.cc",
        BX   .. "src/*.cpp"
    )
    del_files(
        BGFX .. "src/amalgamated.cpp",
        BX   .. "src/amalgamated.cpp",
        BX   .. "src/crtnone.cpp"
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
    add_defines("__STDC_FORMAT_MACROS")
    if is_mode("debug") then
        add_defines("BGFX_CONFIG_DEBUG=1")
    end
    if is_os("windows") then
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


target("fcpp")
    set_kind("static")
    add_files(FCPP .. "*.c")
    del_files(FCPP .. "usecpp.c")
    add_includedirs(FCPP)
    add_defines(
        "NINCLUDE=64",
        "NWORK=65536",
        "NBUFF=65536",
        "OLD_PREPROCESSOR=0"
    )


target("glsl-optimizer")
    set_kind("static")
    add_files(
        GLSL_OPTIMIZER .. "src/glsl/glcpp/*.c",
        GLSL_OPTIMIZER .. "src/util/*.c",
        GLSL_OPTIMIZER .. "src/mesa/program/*.c",
        GLSL_OPTIMIZER .. "src/mesa/main/*.c",
        GLSL_OPTIMIZER .. "src/glsl/*.cpp",
        GLSL_OPTIMIZER .. "src/glsl/*.c"
    )
    del_files(GLSL_OPTIMIZER .. "src/glsl/main.cpp")
    add_includedirs(
        GLSL_OPTIMIZER .. "include",
        GLSL_OPTIMIZER .. "src/mesa",
        GLSL_OPTIMIZER .. "src/mapi",
        GLSL_OPTIMIZER .. "src/glsl",
        GLSL_OPTIMIZER .. "src"
    )
    if is_os("windows") then
        add_defines(
            "__STDC__",
            "__STDC_VERSION__=199901L",
            "strdup=_strdup",
            "alloca=_alloca",
            "isascii=__isascii"
        )
    end


target("glslang")
    set_kind("static")
    add_files(
        GLSLANG .. "glslang/GenericCodeGen/*.cpp",
        GLSLANG .. "glslang/MachineIndependent/*.cpp",
        GLSLANG .. "glslang/MachineIndependent/preprocessor/*.cpp",
        GLSLANG .. "hlsl/*.cpp",
        GLSLANG .. "SPIRV/*.cpp",
        GLSLANG .. "OGLCompilersDLL/*.cpp"
    )
    add_includedirs(
        GLSLANG,
        GLSLANG     .. "glslang/Include",
        GLSLANG     .. "glslang/Public",
        SPIRV_TOOLS .. "include",
        SPIRV_TOOLS .. "source"
    )
    add_defines(
        "ENABLE_OPT=1",
        "ENABLE_HLSL=1"
    )
    if is_os("windows") then
        add_files(GLSLANG .. "glslang/OSDependent/Windows/ossource.cpp")
    else
        add_files(GLSLANG .. "glslang/OSDependent/Unix/ossource.cpp")
    end


target("spirv-cross")
    set_kind("static")
    add_files(SPIRV_CROSS .. "*.cpp")
    add_includedirs(
        SPIRV_CROSS,
        SPIRV_CROSS .. "include"
    )
    add_defines("SPIRV_CROSS_EXCEPTIONS_TO_ASSERTIONS")


target("spirv-tools")
    set_kind("static")
    add_files(
        SPIRV_TOOLS .. "source/*.cpp",
        SPIRV_TOOLS .. "source/opt/*.cpp",
        SPIRV_TOOLS .. "source/reduce/*.cpp",
        SPIRV_TOOLS .. "source/util/*.cpp",
        SPIRV_TOOLS .. "source/val/*.cpp"
    )
    add_includedirs(
        SPIRV_TOOLS,
        SPIRV_TOOLS   .. "include",
        SPIRV_TOOLS   .. "include/generated",
        SPIRV_TOOLS   .. "source",
        SPIRV_HEADERS .. "include"
    )
