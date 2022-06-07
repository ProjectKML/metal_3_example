#include "engine.hpp"

int main() {
    auto* engine = new metal_3_example::Engine(true, 1600, 900);
    engine->run_loop();
    delete engine;
    return 0;
}