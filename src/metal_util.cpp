#include "metal_util.hpp"
#include "mesh.hpp"
#include <iostream>

namespace metal_3_example::metal_util {
    void panic_if_failed(NS::Error* error, const std::string_view& message) noexcept {
        if(error) {
            std::cout << message << " failed: " << error->localizedFailureReason()->cString(NS::StringEncoding::UTF8StringEncoding) << std::endl;
            std::exit(1);
        }
    }

    void upload_mesh(MTL::Device* device, const Mesh& mesh, MTL::Buffer*& vertex_buffer, MTL::Buffer*& meshlet_buffer, MTL::Buffer*& meshlet_data_buffer) noexcept {
        vertex_buffer = device->newBuffer(mesh.get_vertices().data(), mesh.get_vertices().size() * sizeof(Mesh::Vertex), MTL::ResourceStorageModeShared);

        meshlet_buffer = device->newBuffer(mesh.get_meshlets().data(), mesh.get_meshlets().size() * sizeof(Mesh::Meshlet), MTL::ResourceStorageModeShared);

        meshlet_data_buffer = device->newBuffer(mesh.get_meshlet_data().data(), mesh.get_meshlet_data().size() * sizeof(uint32_t), MTL::ResourceStorageModeShared);
    }
}