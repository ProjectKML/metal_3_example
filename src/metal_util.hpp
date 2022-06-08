#pragma once

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include <string_view>

namespace metal_3_example {
    class Mesh;

    namespace metal_util {
        void panic(const std::string_view& message) noexcept;
        void panic_if_failed(NSError* error, const std::string_view& message) noexcept;

        void upload_mesh(id<MTLDevice> device, const Mesh& mesh, id<MTLBuffer>& vertex_buffer, id<MTLBuffer>& meshlet_buffer, id<MTLBuffer>& meshlet_data_buffer) noexcept;
    }
}