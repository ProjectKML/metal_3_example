#include "metal_util.hpp"
#include <iostream>

namespace metal_3_example::metal_util {
    void panic_if_failed(NSError* error, const std::string_view& message) noexcept {
        if(error) {
            NSLog(@"%@ failed: %@", @(message.data()), error);
            std::exit(1);
        }
    }
}