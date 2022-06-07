#include <metal_stdlib>

using namespace metal;

struct MeshOut {
    float4 position [[position]];
};

struct MeshUniforms {
    float4x4 view_projection_matrix;
};

using mesh_t = mesh<MeshOut, void, 3, 1, topology::triangle>;

[[mesh]] void mesh_function(mesh_t m, constant MeshUniforms& uniforms [[buffer(0)]]) {
    MeshOut v;
    v.position = uniforms.view_projection_matrix * float4(-1.0, -1.0, 0.0, 1.0);

    m.set_primitive_count(1);

    m.set_vertex(0, v);
    v.position = uniforms.view_projection_matrix * float4(0.0, 1.0, 0.0, 1.0);
    m.set_vertex(1, v);
    v.position = uniforms.view_projection_matrix * float4(1.0, -1.0, 0.0, 1.0);
    m.set_vertex(2, v);

    m.set_index(0, 0);
    m.set_index(1, 1);
    m.set_index(2, 2);
}

fragment half4 fragment_function() {
    return half4(0.1, 1.0, 0.1, 1.0);
}
