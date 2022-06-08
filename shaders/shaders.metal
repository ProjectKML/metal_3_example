#include <metal_stdlib>

using namespace metal;

uint murmur_hash_11(uint src) {
    const uint M = 0x5bd1e995;
    uint h = 1190494759;
    src *= M;
    src ^= src >> 24;
    src *= M;
    h *= M;
    h ^= src;
    h ^= h >> 13;
    h *= M;
    h ^= h >> 15;

    return h;
}

float3 murmur_hash_11_color(uint src) {
    const auto hash = murmur_hash_11(src);
    return float3((float)((hash >> 16) & 0xFF), (float)((hash >> 8) & 0xFF), (float)(hash & 0xFF)) / 256.0;
}

struct Vertex {
    float posX, posY, posZ;
    float texX, texY;
    float nx, ny, nz;
};

struct Meshlet {
    uint data_offset;
    uint vertex_count;
    uint triangle_count;
    uint padding;
};

struct VertexOut {
    float4 position [[position]];
    float2 tex_coord;
    float3 normal;
    float3 meshlet_color;
};

struct MeshUniforms {
    float4x4 view_projection_matrix;
};

using mesh_t = mesh<VertexOut, void, 64, 124, topology::triangle>;

[[mesh]] void mesh_function(mesh_t m,
    uint3 giid [[thread_position_in_grid]],
    uint3 liid [[thread_position_in_threadgroup]],
    constant MeshUniforms& uniforms [[buffer(0)]],
    const device Vertex* vertices [[buffer(1)]],
    const device Meshlet* meshlets [[buffer(2)]],
    const device uint* meshlet_data [[buffer(3)]]) {

    VertexOut v;

    const auto meshlet_index = giid.x >> 5;

    const auto meshlet = meshlets[meshlet_index];

    if(liid.x == 0) {
        m.set_primitive_count(meshlet.triangle_count);
    }

    const auto meshlet_color = murmur_hash_11_color(meshlet_index);

    for(auto i = liid.x; i < meshlet.vertex_count; i += 32) {
        const auto vertex_index = meshlet_data[meshlet.data_offset + i];
        const auto current_vertex = vertices[vertex_index];

        v.position = uniforms.view_projection_matrix * float4(current_vertex.posX, current_vertex.posY, current_vertex.posZ, 1.0);
        v.tex_coord = float2(current_vertex.texX, current_vertex.texY);
        v.normal = float3(current_vertex.nx, current_vertex.ny, current_vertex.nz);
        v.meshlet_color = meshlet_color;

        m.set_vertex(i, v);
    }

    const auto num_index_groups = (meshlet.triangle_count * 3 + 3) >> 2;
    for(auto i = liid.x; i < num_index_groups; i += 32) {
        const auto index_group = meshlet_data[meshlet.data_offset + meshlet.vertex_count + i];
        m.set_indices(i << 2, as_type<uchar4>(index_group));
    }
}

struct FSInput {
    float2 tex_coord;
    float3 normal;
    float3 meshlet_color;
};

fragment half4 fragment_function(FSInput input [[stage_in]]) {
    return half4(half3(input.meshlet_color), 1.0);
}
