#pragma once

#include <glm/glm.hpp>

#include <string_view>

namespace metal_3_example::util {
    void panic(const std::string_view& message) noexcept;

    [[nodiscard]] inline glm::mat4 reverse_depth_projection_matrix_lh(float field_of_view, float aspect_ratio, float near_plane, float far_plane) noexcept {
        const auto tan_half_fov_y = glm::tan(glm::radians(field_of_view) / 2.0f);
        const auto far_minus_near = far_plane - near_plane;

        glm::mat4 result(0.0f);
        result[0][0] = 1.0f / (aspect_ratio * tan_half_fov_y);
        result[1][1] = 1.0f / (tan_half_fov_y);
        result[2][2] = far_plane / far_minus_near - 1.0f;
        result[2][3] = -1.0f;
        result[3][2] = (far_plane * near_plane) / far_minus_near;

        return result;
    }

    [[nodiscard]] inline glm::vec3 direction_from_rotation(const glm::vec3& rotation) noexcept {
        const auto cos_y = glm::cos(rotation.y);

        glm::vec3 v;
        v.x = glm::sin(rotation.x) * cos_y;
        v.y = glm::sin(rotation.y);
        v.z = glm::cos(rotation.x) * cos_y;
        return v;
    }
}