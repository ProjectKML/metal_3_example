#pragma once

#include <Foundation/Foundation.hpp>
#include <Metal/Metal.hpp>

#include <string_view>

namespace metal_3_example {
    class Mesh;

    namespace metal_util {
        void panic(const std::string_view& message) noexcept;
        void panic_if_failed(NS::Error* error, const std::string_view& message) noexcept;

        void upload_mesh(MTL::Device* device, const Mesh& mesh, MTL::Buffer*& vertex_buffer, MTL::Buffer*& meshlet_buffer, MTL::Buffer*& meshlet_data_buffer) noexcept;
    }
}