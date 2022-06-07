#pragma once

#import <Foundation/Foundation.h>

#include <string_view>

namespace metal_3_example::metal_util {
    void panic(const std::string_view& message) noexcept;
    void panic_if_failed(NSError* error, const std::string_view& message) noexcept;
}