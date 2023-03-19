xcrun -sdk macosx metal -c shaders.metal -o ../bin/shaders.air
xcrun -sdk macosx metallib ../bin/shaders.air -o ../bin/shaders.metallib

xcrun -sdk macosx metal -c shaders_spv.metal -o ../bin/shaders_spv.air
xcrun -sdk macosx metallib ../bin/shaders_spv.air -o ../bin/shaders_spv.metallib