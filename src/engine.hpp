#pragma once

#include "camera.hpp"

#include <Metal/Metal.hpp>
#include <QuartzCore/QuartzCore.hpp>

#include <SDL2/SDL.h>

namespace metal_3_example {
    class Engine final {
    private:
        uint32_t _width;
        uint32_t _height;

        SDL_Window* _window;
        SDL_MetalView _metal_view;
        CA::MetalLayer* _metal_layer;

        MTL::Device* _device;
        MTL::CommandQueue* _command_queue;
        MTL::RenderPipelineState* _render_pipeline_state;
        MTL::Texture* _depth_texture;
        MTL::DepthStencilState* _depth_stencil_state;

        MTL::Buffer* _vertex_buffer;
        MTL::Buffer* _meshlet_buffer;
        MTL::Buffer* _meshlet_data_buffer;
        size_t _num_meshlets;

        Camera _camera;

        void create_window() noexcept;
        void destroy_window() noexcept;
        void create_renderer() noexcept;
        void destroy_renderer() noexcept;
        void create_depth_texture() noexcept;
        void destroy_depth_texture() noexcept;
        void create_pipeline() noexcept;
        void destroy_pipeline() noexcept;
        void create_mesh() noexcept;
        void destroy_mesh() noexcept;
        void render_frame() noexcept;
    public:
        Engine(bool debug_mode, uint32_t width, uint32_t height) noexcept;
        ~Engine() noexcept;

        void run_loop() noexcept;
    };
}