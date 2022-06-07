#pragma once

#include <glm/glm.hpp>

namespace metal_3_example {
    class Camera final {
    private:
        glm::vec3 _position;
        glm::vec3 _rotation;

        glm::mat4 _view_projection_matrix;
    public:
        Camera(const glm::vec3& position, const glm::vec3& rotation) noexcept;

        void update(float delta_time, uint32_t width, uint32_t height) noexcept;
        void move_mouse(int delta_x, int delta_y) noexcept;

        [[nodiscard]] inline const glm::mat4& get_view_projection_matrix() const noexcept {
            return _view_projection_matrix;
        }
    };
}