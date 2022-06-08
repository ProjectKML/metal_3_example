#pragma once

#include <glm/glm.hpp>

#include <string_view>
#include <vector>

namespace metal_3_example {
    class Mesh final {
    public:
        struct Vertex final {
            glm::vec3 position;
            glm::vec2 tex_coord;
            glm::vec3 normal;

            Vertex() noexcept = default;
            Vertex(const glm::vec3& position, const glm::vec2& tex_coord, const glm::vec3& normal) noexcept
                    : position(position), tex_coord(tex_coord), normal(normal) {}
        };

        struct Meshlet final {
            uint32_t data_offset;
            uint32_t vertex_count;
            uint32_t triangle_count;
            uint32_t _padding;

            Meshlet() noexcept = default;
            Meshlet(uint32_t data_offset, uint32_t vertex_count, uint32_t triangle_count) noexcept
                    : data_offset(data_offset), vertex_count(vertex_count), triangle_count(triangle_count) {}
        };
    private:
        std::vector<Vertex> _vertices;
        std::vector<Meshlet> _meshlets;
        std::vector<uint32_t> _meshlet_data;

    public:
        Mesh(const std::string_view& path) noexcept;

        [[nodiscard]] inline const std::vector<Vertex>& get_vertices() const noexcept {
            return _vertices;
        }

        [[nodiscard]] inline const std::vector<Meshlet>& get_meshlets() const noexcept {
            return _meshlets;
        }

        [[nodiscard]] inline const std::vector<uint32_t>& get_meshlet_data() const noexcept {
            return _meshlet_data;
        }
    };
}