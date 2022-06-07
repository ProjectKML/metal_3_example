xcrun -sdk macosx metal -c shaders.metal -o ../bin/shaders.air
xcrun -sdk macosx metallib ../bin/shaders.air -o ../bin/shaders.metallib
