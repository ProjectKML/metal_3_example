#include "engine.hpp"
#include "mesh.hpp"
#import "metal_util.hpp"
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

        create_depth_texture();
        create_pipeline();
        create_mesh();
    }

    void Engine::destroy_renderer() noexcept {
        destroy_mesh();
        destroy_pipeline();
        destroy_depth_texture();

        [_command_queue release];
        [_device release];
    }

    void Engine::create_depth_texture() noexcept {
        auto depth_texture_descriptor= [[MTLTextureDescriptor alloc] init];
        depth_texture_descriptor.textureType = MTLTextureType2D;
        depth_texture_descriptor.pixelFormat = MTLPixelFormatDepth32Float;
        depth_texture_descriptor.width = _width;
        depth_texture_descriptor.height = _height;
        depth_texture_descriptor.depth = 1;
        depth_texture_descriptor.mipmapLevelCount = 1;
        depth_texture_descriptor.sampleCount = 1;
        depth_texture_descriptor.arrayLength = 1;
        depth_texture_descriptor.resourceOptions = MTLResourceStorageModePrivate;

        _depth_texture = [_device newTextureWithDescriptor: depth_texture_descriptor];
        [depth_texture_descriptor release];

        auto depth_stencil_descriptor = [[MTLDepthStencilDescriptor alloc] init];
        depth_stencil_descriptor.depthCompareFunction = MTLCompareFunctionGreater;
        depth_stencil_descriptor.depthWriteEnabled = true;

        _depth_stencil_state = [_device newDepthStencilStateWithDescriptor: depth_stencil_descriptor];
    }

    void Engine::destroy_depth_texture() noexcept {
        [_depth_texture release];
    }

    void Engine::create_pipeline() noexcept {
        NSError* error;

        auto library = [_device newLibraryWithFile: @"shaders.metallib" error: &error];
        metal_util::panic_if_failed(error, "MTLDevice::newLibraryWithFile");

        auto mesh_function = [library newFunctionWithName: @"mesh_function"];
        auto fragment_function = [library newFunctionWithName:@"fragment_function"];

        auto mesh_render_pipeline_descriptor = [[MTLMeshRenderPipelineDescriptor alloc] init];
        mesh_render_pipeline_descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        mesh_render_pipeline_descriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
        mesh_render_pipeline_descriptor.meshFunction = mesh_function;
        mesh_render_pipeline_descriptor.fragmentFunction = fragment_function;

        _render_pipeline_state = [_device newRenderPipelineStateWithMeshDescriptor: mesh_render_pipeline_descriptor options: MTLPipelineOptionNone reflection: nullptr error: &error];
        metal_util::panic_if_failed(error, "MTLDevice::newRenderPipelineStateWithMeshDescriptor");

        [mesh_render_pipeline_descriptor release];

        [fragment_function release];
        [mesh_function release];

        [library release];
    }

    void Engine::destroy_pipeline() noexcept {
        [_render_pipeline_state release];
    }

    void Engine::create_mesh() noexcept {
        Mesh mesh("dragon.obj");

        metal_util::upload_mesh(_device, mesh, _vertex_buffer, _meshlet_buffer, _meshlet_data_buffer);
        _num_meshlets = mesh.get_meshlets().size();
    }

    void Engine::destroy_mesh() noexcept {
        [_meshlet_data_buffer release];
        [_meshlet_buffer release];
        [_vertex_buffer release];
    }

    void Engine::render_frame() noexcept {
        @autoreleasepool {
            _camera.update(0.003, _width, _height);

            auto surface = [_metal_layer nextDrawable];

            auto render_pass_depth_attachment_descriptor = [[MTLRenderPassDepthAttachmentDescriptor alloc] init];
            render_pass_depth_attachment_descriptor.clearDepth = 0.0;
            render_pass_depth_attachment_descriptor.loadAction = MTLLoadActionClear;
            render_pass_depth_attachment_descriptor.storeAction = MTLStoreActionDontCare;
            render_pass_depth_attachment_descriptor.texture = _depth_texture;

            auto render_pass_descriptor = [MTLRenderPassDescriptor renderPassDescriptor];
            render_pass_descriptor.colorAttachments[0].clearColor = MTLClearColorMake(100.0 / 255.0, 149.0 / 255.0, 237.0 / 255.0, 1.0);
            render_pass_descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
            render_pass_descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
            render_pass_descriptor.colorAttachments[0].texture = surface.texture;
            render_pass_descriptor.depthAttachment = render_pass_depth_attachment_descriptor;

            auto command_buffer = [_command_queue commandBuffer];

            auto render_encoder = [command_buffer renderCommandEncoderWithDescriptor: render_pass_descriptor];

            auto& mvp = _camera.get_view_projection_matrix();

            [render_encoder setRenderPipelineState:_render_pipeline_state];
            [render_encoder setDepthStencilState: _depth_stencil_state];

            [render_encoder setMeshBytes: &mvp length: sizeof(glm::mat4) atIndex: 0];
            [render_encoder setMeshBuffer: _vertex_buffer offset: 0 atIndex: 1];
            [render_encoder setMeshBuffer: _meshlet_buffer offset: 0 atIndex: 2];
            [render_encoder setMeshBuffer: _meshlet_data_buffer offset: 0 atIndex: 3];

            [render_encoder drawMeshThreadgroups:MTLSizeMake(_num_meshlets + 31, 1, 1) threadsPerObjectThreadgroup:MTLSizeMake(1, 1, 1) threadsPerMeshThreadgroup:MTLSizeMake(32, 1, 1)];
            [render_encoder endEncoding];

            [command_buffer presentDrawable:surface];
            [command_buffer commit];
        }
    }

    Engine::Engine(bool debug_mode, uint32_t width, uint32_t height) noexcept : _width(width), _height(height), _camera(glm::vec3(0.0f), glm::vec3(0.0f)) {
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
            SDL_ShowCursor(SDL_DISABLE);
            SDL_SetWindowGrab(_window, SDL_TRUE);
            SDL_SetRelativeMouseMode(SDL_TRUE);

            while(SDL_PollEvent(&ev)) {
                if(ev.type == SDL_QUIT) {
                    running = false;
                }
                else if(ev.type == SDL_MOUSEMOTION) {
                    _camera.move_mouse(ev.motion.xrel, ev.motion.yrel);
                }
                else if(ev.type == SDL_KEYDOWN) {
                    if(ev.key.keysym.sym == SDLK_ESCAPE) {
                        running = false;
                    }
                }
            }

            render_frame();
        }
    }
}