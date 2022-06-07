#include "util.hpp"

#include <iostream>

namespace metal_3_example::util {
    void panic(const std::string_view& message) noexcept {
        std::cerr << message << std::endl;
        std::exit(1);
    }
}