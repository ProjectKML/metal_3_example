#pragma once

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include <SDL2/SDL.h>

namespace metal_3_example {
    class Engine final {
    private:
        uint32_t _width;
        uint32_t _height;

        SDL_Window* _window;
        SDL_MetalView _metal_view;
        CAMetalLayer* _metal_layer;

        id<MTLDevice> _device;
        id<MTLCommandQueue> _command_queue;

        void create_window() noexcept;
        void destroy_window() noexcept;
        void create_renderer() noexcept;
        void destroy_renderer() noexcept;
        void create_pipeline() noexcept;
        void destroy_pipeline() noexcept;
        void render_frame() noexcept;
    public:
        Engine(bool debug_mode, uint32_t width, uint32_t height) noexcept;
        ~Engine() noexcept;

        void run_loop() noexcept;
    };
}