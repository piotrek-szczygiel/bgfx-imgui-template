local IMGUI = "third_party/imgui/"
local BGFX  = "third_party/bgfx/"
local BIMG  = "third_party/bimg/"
local BX    = "third_party/bx/"
local GLFW  = "third_party/glfw/"
local GLM   = "third_party/glm/"

local SHADER_TARGETS = {
    "glsl",
    "spirv",
    "essl",
    "metal",
    "dx9",
    "dx11"
}


target("game")
    set_kind("binary")
    set_default(true)
    add_deps("imgui", "bgfx", "glfw")

    set_languages("c++17")
    set_warnings("all")
    set_rundir("$(projectdir)")

    add_files("src/*.cpp")
    add_includedirs(
        IMGUI,
        BGFX .. "include",
        BX   .. "include",
        GLFW .. "include",
        GLM
    )

    if is_os("windows") then
        add_includedirs(BX .. "include/compat/msvc")
        add_syslinks("gdi32", "shell32", "user32")
        add_defines(
            "GLFW_EXPOSE_NATIVE_WIN32",
            "GLFW_EXPOSE_NATIVE_WGL",
            "_CRT_SECURE_NO_WARNINGS"
        )
        if is_mode("release") then
            add_defines("WINMAIN_AS_ENTRY")
            add_ldflags("/subsystem:windows")
        end
    elseif is_os("linux") then
        add_syslinks("dl", "GL", "pthread", "X11")
        add_defines(
            "GLFW_EXPOSE_NATIVE_X11",
            "GLFW_EXPOSE_NATIVE_GLX"
        )
    elseif is_os("macosx") then
        add_includedirs(BX .. "include/compat/osx")
        add_links(
            "Cocoa.framework",
            "CoreVideo.framework",
            "IOKit.framework",
            "Metal.framework",
            "QuartzCore.framework"
        )
        add_defines(
            "GLFW_EXPOSE_NATIVE_COCOA",
            "GLFW_EXPOSE_NATIVE_NSGL"
        )
    end

    before_build(function (target)
        for _, type in ipairs(SHADER_TARGETS) do
            local dir = vformat("$(projectdir)/assets/shaders/%s", type)
            if not os.exists(dir) then
                os.mkdir(dir)
            end
        end
    end)

    on_clean(function (target)
        for _, type in ipairs(SHADER_TARGETS) do
            local dir = vformat("$(projectdir)/assets/shaders/%s", type)
            if os.exists(dir) then
                os.rmdir(dir)
            end
        end
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


task("shaders")
    set_category("plugin")

    set_menu {
        usage = "xmake shaders",
        description = "Compile shaders from shaders/ directory into assets/shaders/",
        options = {}
    }

    on_run(function()
        local shader_compiler = vformat("$(projectdir)/bin/shaderc")
        if os.host() == "windows" then
            shader_compiler = shader_compiler .. ".exe"
        end

        local vs = os.files("$(projectdir)/shaders/*.v")
        local fs = os.files("$(projectdir)/shaders/*.f")
        local shaders_output = vformat("$(projectdir)/assets/shaders")
        local include = vformat("$(projectdir)/third_party/bgfx/src")

        if not os.exists(shader_compiler) then
            print("Invoke `xmake -F shaderc.lua` before compiling shaders")
            return
        end

        for _, sourcefile in ipairs(table.join(vs, fs)) do
            local filename = path.filename(sourcefile)
            local ext = path.extension(sourcefile)

            local is_vertex = true
            if ext == ".f" then
                is_vertex = false
            end

            for _, type in ipairs(SHADER_TARGETS) do
                local supported = true
                if os.host() ~= "windows" then
                    if type == "dx9" or type == "dx11" then
                        supported = false
                        print("%-10s unsupported platform", "[" .. type .. "]")
                    end
                end

                if supported then
                    local output = path.join(shaders_output, type, filename) .. ".bin"
                    print("%-10s compiling shader %s", "[" .. type .. "]", filename)

                    local args1 = {"-f", sourcefile, "-o", output, "-i", include}
                    local args2 = {"--type", "fragment"}
                    local args3 = ""

                    local dx_type = "p"
                    if is_vertex then
                        args2 = {"--type", "vertex"}
                        dx_type = "v"
                    end

                    if     type == "glsl"  then args3 = {"--platform", "linux",   "--profile", "120"}
                    elseif type == "spirv" then args3 = {"--platform", "linux",   "--profile", "spirv"}
                    elseif type == "essl"  then args3 = {"--platform", "android", "--profile", "120"}
                    elseif type == "metal" then args3 = {"--platform", "osx",     "--profile", "metal"}
                    elseif type == "dx9"   then args3 = {"--platform", "windows", "--profile", dx_type .. "s_3_0"}
                    elseif type == "dx11"  then args3 = {"--platform", "windows", "--profile", dx_type .. "s_4_0"}
                    else print("unknown shader type!")
                    end

                    local shaderc_args = table.join(args1, args2, args3)
                    os.execv(shader_compiler, shaderc_args)
                end
            end
        end
    end)
