#include "mesh.hpp"
#include "util.hpp"

#include <fast_obj/fast_obj.h>
#include <meshoptimizer/meshoptimizer.h>

namespace metal_3_example {
    static const size_t _MAX_VERTICES = 64;
    static const size_t _MAX_TRIANGLES = 124;

    Mesh::Mesh(const std::string_view& path) noexcept {
        auto* obj_mesh = fast_obj_read(path.data());
        if(!obj_mesh) {
            util::panic("fast_obj_read");
        }

        size_t index_count = 0;
        for(auto i = 0; i < obj_mesh->face_count; i++) {
            index_count += 3 * (obj_mesh->face_vertices[i] - 2);
        }

        std::vector<Vertex> vertices(index_count);

        size_t vertex_offset = 0, index_offset = 0;
        for(auto i = 0; i < obj_mesh->face_count; i++) {
            const auto face_vertices = obj_mesh->face_vertices[i];

            for(auto j = 0; j < face_vertices; j++) {
                const auto index = obj_mesh->indices[index_offset + j];

                if(j >= 3) {
                    vertices[vertex_offset] = vertices[vertex_offset - 3];
                    vertices[vertex_offset + 1] = vertices[vertex_offset - 1];
                    vertex_offset += 2;
                }

                auto& vertex = vertices[vertex_offset++];

                const auto position_index = index.p * 3;
                const auto tex_coord_index = index.t * 2;
                const auto normal_index = index.n * 3;

                vertex.position = glm::vec3(obj_mesh->positions[position_index], obj_mesh->positions[position_index + 1], obj_mesh->positions[position_index + 2]);
                vertex.tex_coord = glm::vec2(obj_mesh->texcoords[tex_coord_index], obj_mesh->texcoords[tex_coord_index + 1]);
                vertex.normal = glm::vec3(obj_mesh->normals[normal_index], obj_mesh->normals[normal_index + 1], obj_mesh->normals[normal_index + 2]);
            }

            index_offset += face_vertices;
        }

        fast_obj_destroy(obj_mesh);

        std::vector<uint32_t> remap(vertices.size());
        const auto vertex_count = meshopt_generateVertexRemap(remap.data(), nullptr, index_count, vertices.data(), index_count, sizeof(Vertex));

        _vertices.resize(vertex_count);
        std::vector<uint32_t> indices(index_count);

        meshopt_remapVertexBuffer(_vertices.data(), vertices.data(), index_count, sizeof(Vertex), remap.data());
        meshopt_remapIndexBuffer(indices.data(), nullptr, index_count, remap.data());

        meshopt_optimizeVertexCache(indices.data(), indices.data(), index_count, vertex_count);
        meshopt_optimizeVertexFetch(_vertices.data(), indices.data(), index_count, _vertices.data(), vertex_count, sizeof(Vertex));

        const auto max_meshlets = meshopt_buildMeshletsBound(indices.size(), _MAX_VERTICES, _MAX_TRIANGLES);
        std::vector<meshopt_Meshlet> meshlets(max_meshlets);

        std::vector<uint32_t> meshlet_vertices(max_meshlets * _MAX_VERTICES);
        std::vector<uint8_t> meshlet_triangles(max_meshlets * _MAX_TRIANGLES);

        const auto meshlet_count = meshopt_buildMeshlets(meshlets.data(), meshlet_vertices.data(), meshlet_triangles.data(), indices.data(), indices.size(),
                                                         &_vertices[0].position.x, _vertices.size(), sizeof(Vertex), _MAX_VERTICES, _MAX_TRIANGLES, 0.0f);

        _meshlets.resize((meshlet_count + 31) & ~31);

        size_t num_meshlet_data = 0;
        for(auto i = 0; i < meshlet_count; i++) {
            const auto& meshlet = meshlets[i];

            num_meshlet_data += meshlet.vertex_count;
            num_meshlet_data += (meshlet.triangle_count * 3 + 3) / 4;
        }

        _meshlet_data.resize(num_meshlet_data);

        size_t index = 0;

        for(auto i = 0; i < meshlet_count; i++) {
            const auto& meshlet = meshlets[i];

            const auto data_offset = index;

            for(auto j = 0; j < meshlet.vertex_count; j++) {
                _meshlet_data[index++] = meshlet_vertices[meshlet.vertex_offset + j];
            }

            const auto* packed_indices = reinterpret_cast<const uint32_t*>(meshlet_triangles.data() + meshlet.triangle_offset);
            const auto num_packed_indices = (meshlet.triangle_count * 3 + 3) / 4;

            for(auto j = 0; j < num_packed_indices; j++) {
                _meshlet_data[index++] = packed_indices[j];
            }

            new (_meshlets.data() + i) Mesh::Meshlet(data_offset, meshlet.vertex_count, meshlet.triangle_count);
        }
    }
}