#pragma once

#include <string_view>

namespace metal_3_example::util {
    void panic(const std::string_view& message) noexcept;
}