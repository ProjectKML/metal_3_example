#define NS_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#include "engine.hpp"

int main() {
    auto* engine = new metal_3_example::Engine(true, 1600, 900);
    engine->run_loop();
    delete engine;
    return 0;
}