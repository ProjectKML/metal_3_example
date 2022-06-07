#include "engine.hpp"
#include "util.hpp"

#include <SDL2/SDL_syswm.h>

#include <iostream>

namespace metal_3_example {
    void Engine::create_window() noexcept {
        if(SDL_Init(SDL_INIT_EVERYTHING) != 0) {
            util::panic("SDL_Init");
        }

        _window = SDL_CreateWindow("metal_3_example", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, static_cast<int>(_width), static_cast<int>(_height), SDL_WINDOW_SHOWN);
        if(!_window) {
            std::cerr << "SDL_CreateWindow failed: " << SDL_GetError() << std::endl;
            std::exit(1);
        }

        _metal_view = SDL_Metal_CreateView(_window);
        if(!_metal_view) {
            std::cerr << "SDL_Metal_CreateView failed: " << SDL_GetError() << std::endl;
            std::exit(1);
        }

        _metal_layer = (__bridge CAMetalLayer*)SDL_Metal_GetLayer(_metal_view);
        if(!_metal_layer) {
            std::cerr << "SDL_Metal_GetLayer failed: " << SDL_GetError() << std::endl;
            std::exit(1);
        }
    }

    void Engine::destroy_window() noexcept {
        SDL_Metal_DestroyView(_metal_view);

        SDL_DestroyWindow(_window);
        SDL_Quit();
    }

    void Engine::create_renderer() noexcept {
        _device = MTLCreateSystemDefaultDevice();
        if(!_device) {
            util::panic("MTLCreateSystemDefaultDevice");
        }

        _metal_layer.device = _device;

        _command_queue = [_device newCommandQueue];

        create_pipeline();
    }

    void Engine::destroy_renderer() noexcept {
        destroy_pipeline();

        [_command_queue release];
        [_device release];
    }

    void Engine::create_pipeline() noexcept {
        NSError* error;

        auto library = [_device newLibraryWithFile: @"shaders.metallib" error: &error];
        util::panic_if_failed(error, "MTLDevice::newLibraryWithFile");

        auto mesh_function = [library newFunctionWithName: @"mesh_function"];
        auto fragment_function = [library newFunctionWithName:@"fragment_function"];

        auto mesh_render_pipeline_descriptor = [[MTLMeshRenderPipelineDescriptor alloc] init];
        mesh_render_pipeline_descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        mesh_render_pipeline_descriptor.meshFunction = mesh_function;
        mesh_render_pipeline_descriptor.fragmentFunction = fragment_function;

        _render_pipeline_state = [_device newRenderPipelineStateWithMeshDescriptor: mesh_render_pipeline_descriptor options: MTLPipelineOptionNone reflection: nullptr error: &error];
        util::panic_if_failed(error, "MTLDevice::newRenderPipelineStateWithMeshDescriptor");

        [mesh_render_pipeline_descriptor release];

        [fragment_function release];
        [mesh_function release];

        [library release];
    }

    void Engine::destroy_pipeline() noexcept {
        [_render_pipeline_state release];
    }

    void Engine::render_frame() noexcept {
        @autoreleasepool {
            auto surface = [_metal_layer nextDrawable];

            auto render_pass_descriptor = [MTLRenderPassDescriptor renderPassDescriptor];
            render_pass_descriptor.colorAttachments[0].clearColor = MTLClearColorMake(100.0 / 255.0, 149.0 / 255.0, 237.0 / 255.0, 1.0);
            render_pass_descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
            render_pass_descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
            render_pass_descriptor.colorAttachments[0].texture = surface.texture;

            auto command_buffer = [_command_queue commandBuffer];

            auto render_encoder = [command_buffer renderCommandEncoderWithDescriptor: render_pass_descriptor];

            [render_encoder setRenderPipelineState:_render_pipeline_state];
            [render_encoder drawMeshThreadgroups:MTLSizeMake(1, 1, 1) threadsPerObjectThreadgroup:MTLSizeMake(1, 1, 1) threadsPerMeshThreadgroup:MTLSizeMake(1, 1, 1)];
            [render_encoder endEncoding];

            [command_buffer presentDrawable:surface];
            [command_buffer commit];
        }
    }

    Engine::Engine(bool debug_mode, uint32_t width, uint32_t height) noexcept : _width(width), _height(height) {
        create_window();
        create_renderer();
    }

    Engine::~Engine() noexcept {
        destroy_renderer();
        destroy_window();
    }

    void Engine::run_loop() noexcept {
        bool running = true;

        SDL_Event ev;

        while(running) {
            while(SDL_PollEvent(&ev)) {
                if(ev.type == SDL_QUIT) {
                    running = false;
                }
            }

            render_frame();
        }
    }
}