#include "util.hpp"

#include <iostream>

namespace metal_3_example::util {
    void panic(const std::string_view& message) noexcept {
        std::cerr << message << std::endl;
        std::exit(1);
    }

    void panic_if_failed(NSError* error, const std::string_view& message) noexcept {
        if(error) {
            NSLog(@"%@ failed: %@", @(message.data()), error);
            std::exit(1);
        }
    }
}