#include "camera.hpp"
#include "util.hpp"

#include <glm/gtc/constants.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include <SDL2/SDL.h>

namespace metal_3_example {
    static const float _SPEED = 12.5f;
    static const float _SENSITIVITY_X = 0.165f;
    static const float _SENSITIVITY_Y = 0.165f;

    Camera::Camera(const glm::vec3& position, const glm::vec3& rotation) noexcept
            : _position(position), _rotation(rotation) {}

    void Camera::update(float delta_time, uint32_t width, uint32_t height) noexcept {
        const auto projection_matrix = util::reverse_depth_projection_matrix_lh(90.0f, static_cast<float>(width) / static_cast<float>(height), 0.1f, 1000.0f);

        const auto sin_pitch = glm::sin(_rotation.x);
        const auto cos_pitch = glm::cos(_rotation.x);

        const auto* keyboard_state = SDL_GetKeyboardState(nullptr);

        if(keyboard_state[SDL_SCANCODE_W]) {
            _position.x += sin_pitch * _SPEED * delta_time;
            _position.z += cos_pitch * _SPEED * delta_time;
        }

        if(keyboard_state[SDL_SCANCODE_A]) {
            _position.x += cos_pitch * _SPEED * delta_time;
            _position.z -= sin_pitch * _SPEED * delta_time;
        }

        if(keyboard_state[SDL_SCANCODE_S]) {
            _position.x -= sin_pitch * _SPEED * delta_time;
            _position.z -= cos_pitch * _SPEED * delta_time;
        }

        if(keyboard_state[SDL_SCANCODE_D]) {
            _position.x -= cos_pitch * _SPEED * delta_time;
            _position.z += sin_pitch * _SPEED * delta_time;
        }

        if(keyboard_state[SDL_SCANCODE_SPACE]) {
            _position.y += _SPEED * delta_time;
        }

        if(keyboard_state[SDL_SCANCODE_LSHIFT]) {
            _position.y -= _SPEED * delta_time;
        }

        const auto look_at = _position + util::direction_from_rotation(_rotation);
        _view_projection_matrix = projection_matrix * glm::lookAt(_position, look_at, glm::vec3(0.0f, 1.0f, 0.0f));
    }

    void Camera::move_mouse(int delta_x, int delta_y) noexcept {
        const auto delta_position = glm::vec2(static_cast<float>(delta_x), static_cast<float>(delta_y));

        const auto move_position = delta_position * glm::vec2(_SENSITIVITY_X, _SENSITIVITY_Y) * 0.0073f;

        _rotation.x -= move_position.x;
        if(_rotation.x > glm::two_pi<float>()) _rotation.x = 0.0f;
        else if(_rotation.x < 0.0f) _rotation.x = glm::two_pi<float>();

        _rotation.y -= move_position.y;
        if(_rotation.y > glm::half_pi<float>() - 0.15f) _rotation.y = glm::half_pi<float>() - 0.15f;
        else if(_rotation.y < 0.15f - glm::half_pi<float>()) _rotation.y = 0.15f - glm::half_pi<float>();
    }
}