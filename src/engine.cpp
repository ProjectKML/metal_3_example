#include "engine.hpp"
#include "mesh.hpp"
#include "metal_util.hpp"
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

        _metal_layer = (CA::MetalLayer*)SDL_Metal_GetLayer(_metal_view);
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
        _device = MTL::CreateSystemDefaultDevice();
        if(!_device) {
            util::panic("MTLCreateSystemDefaultDevice");
        }

        if (!_device->supportsFamily(MTL::GPUFamilyMetal3)) {
            util::panic("Device does not support metal 3");
        }

        _metal_layer->setDevice(_device);

        _command_queue = _device->newCommandQueue();

        create_depth_texture();
        create_pipeline();
        create_mesh();
    }

    void Engine::destroy_renderer() noexcept {
        destroy_mesh();
        destroy_pipeline();
        destroy_depth_texture();

        _command_queue->release();
        _device->release();
    }

    void Engine::create_depth_texture() noexcept {
        auto depth_texture_descriptor = MTL::TextureDescriptor::alloc()->init();
        depth_texture_descriptor->setTextureType(MTL::TextureType2D);
        depth_texture_descriptor->setPixelFormat(MTL::PixelFormatDepth32Float);
        depth_texture_descriptor->setWidth(_width);
        depth_texture_descriptor->setHeight(_height);
        depth_texture_descriptor->setDepth(1);
        depth_texture_descriptor->setMipmapLevelCount(1);
        depth_texture_descriptor->setSampleCount(1);
        depth_texture_descriptor->setArrayLength(1);
        depth_texture_descriptor->setResourceOptions(MTL::ResourceStorageModePrivate);
        depth_texture_descriptor->setUsage(MTL::TextureUsageRenderTarget);

        _depth_texture = _device->newTexture(depth_texture_descriptor);
        depth_texture_descriptor->release();

        auto depth_stencil_descriptor = MTL::DepthStencilDescriptor::alloc()->init();
        depth_stencil_descriptor->setDepthCompareFunction(MTL::CompareFunctionGreater);
        depth_stencil_descriptor->setDepthWriteEnabled(true);

        _depth_stencil_state = _device->newDepthStencilState(depth_stencil_descriptor);
    }

    void Engine::destroy_depth_texture() noexcept {
        _depth_texture->release();
    }

    void Engine::create_pipeline() noexcept {
        NS::Error* error;

        auto library = _device->newLibrary(NS::String::string("shaders_spv.metallib", NS::StringEncoding::UTF8StringEncoding), &error);
        metal_util::panic_if_failed(error, "MTL::Device::newLibrary");

        auto mesh_function = library->newFunction(NS::String::string("mesh_function", NS::StringEncoding::UTF8StringEncoding));
        auto fragment_function = library->newFunction(NS::String::string("fragment_function", NS::StringEncoding::UTF8StringEncoding));

        auto mesh_render_pipeline_descriptor = MTL::MeshRenderPipelineDescriptor::alloc()->init();
        auto color_attachment = mesh_render_pipeline_descriptor->colorAttachments()->object(0);
        color_attachment->setPixelFormat(MTL::PixelFormatBGRA8Unorm);
        mesh_render_pipeline_descriptor->setDepthAttachmentPixelFormat(MTL::PixelFormatDepth32Float);
        mesh_render_pipeline_descriptor->setMeshFunction(mesh_function);
        mesh_render_pipeline_descriptor->setFragmentFunction(fragment_function);

        _render_pipeline_state = _device->newRenderPipelineState(mesh_render_pipeline_descriptor, MTL::PipelineOptionNone, nullptr, &error);

        metal_util::panic_if_failed(error, "MTL::Device::newRenderPipelineState");

        mesh_render_pipeline_descriptor->release();

        fragment_function->release();
        mesh_function->release();

        library->release();
    }

    void Engine::destroy_pipeline() noexcept {
        _render_pipeline_state->release();
    }

    void Engine::create_mesh() noexcept {
        Mesh mesh("dragon.obj");

        metal_util::upload_mesh(_device, mesh, _vertex_buffer, _meshlet_buffer, _meshlet_data_buffer);
        _num_meshlets = mesh.get_meshlets().size();
    }

    void Engine::destroy_mesh() noexcept {
        _meshlet_data_buffer->release();
        _meshlet_buffer->release();
        _vertex_buffer->release();
    }

    void Engine::render_frame() noexcept {
        _camera.update(0.003, _width, _height);

        auto surface = _metal_layer->nextDrawable();

        auto render_pass_depth_attachment_descriptor = MTL::RenderPassDepthAttachmentDescriptor::alloc()->init();
        render_pass_depth_attachment_descriptor->setClearDepth(0.0);
        render_pass_depth_attachment_descriptor->setLoadAction(MTL::LoadActionClear);
        render_pass_depth_attachment_descriptor->setStoreAction(MTL::StoreActionDontCare);
        render_pass_depth_attachment_descriptor->setTexture(_depth_texture);

        auto render_pass_descriptor = MTL::RenderPassDescriptor::renderPassDescriptor();
        auto color_attachment = render_pass_descriptor->colorAttachments()->object(0);
        color_attachment->setClearColor(MTL::ClearColor(100.0 / 255.0, 149.0 / 255.0, 237.0 / 255.0, 1.0));
        color_attachment->setLoadAction(MTL::LoadActionClear);
        color_attachment->setStoreAction(MTL::StoreActionStore);
        color_attachment->setTexture(surface->texture());
        render_pass_descriptor->setDepthAttachment(render_pass_depth_attachment_descriptor);

        auto command_buffer = _command_queue->commandBuffer();

        auto render_encoder = command_buffer->renderCommandEncoder(render_pass_descriptor);

        auto& mvp = _camera.get_view_projection_matrix();

        render_encoder->setRenderPipelineState(_render_pipeline_state);
        render_encoder->setDepthStencilState(_depth_stencil_state);

        render_encoder->setMeshBytes(&mvp, sizeof(glm::mat4), 0);
        render_encoder->setMeshBuffer(_vertex_buffer, 0, 1);
        render_encoder->setMeshBuffer(_meshlet_buffer, 0, 2);
        render_encoder->setMeshBuffer(_meshlet_data_buffer, 0, 3);

        render_encoder->drawMeshThreadgroups(MTL::Size(_num_meshlets + 31, 1, 1), MTL::Size(1, 1, 1), MTL::Size(32, 1, 1));
        render_encoder->endEncoding();

        command_buffer->presentDrawable(surface);
        command_buffer->commit();

        //cleanup
        surface->release();
        render_pass_depth_attachment_descriptor->release();
        render_pass_descriptor->release();
        command_buffer->release();
        render_encoder->release();
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