#include "metal_util.hpp"
#include "mesh.hpp"
#include <iostream>

namespace metal_3_example::metal_util {
    void panic_if_failed(NSError* error, const std::string_view& message) noexcept {
        if(error) {
            NSLog(@"%@ failed: %@", @(message.data()), error);
            std::exit(1);
        }
    }

    void upload_mesh(id<MTLDevice> device, const Mesh& mesh, id<MTLBuffer>& vertex_buffer, id<MTLBuffer>& meshlet_buffer, id<MTLBuffer>& meshlet_data_buffer) noexcept {
        vertex_buffer = [device newBufferWithBytes: mesh.get_vertices().data() length: mesh.get_vertices().size() * sizeof(Mesh::Vertex)
                                           options: MTLResourceStorageModeShared];
        meshlet_buffer = [device newBufferWithBytes: mesh.get_meshlets().data() length: mesh.get_meshlets().size() * sizeof(Mesh::Meshlet)
                                            options: MTLResourceStorageModeShared];
        meshlet_data_buffer = [device newBufferWithBytes: mesh.get_meshlet_data().data() length: mesh.get_meshlet_data().size() * sizeof(uint32_t)
                options: MTLResourceStorageModeShared];
    }
}