#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct MeshletData
{
    uint meshlet_data[1];
};

struct Meshlet
{
    uint data_offset;
    uint vertex_count;
    uint triangle_count;
};

struct Meshlet_1
{
    uint data_offset;
    uint vertex_count;
    uint triangle_count;
};

struct Meshlets
{
    Meshlet_1 meshlets[1];
};

struct Vertex
{
    float position_x;
    float position_y;
    float position_z;
    float tex_coord_x;
    float tex_coord_y;
    float normal_x;
    float normal_y;
    float normal_z;
};

struct Vertex_1
{
    float position_x;
    float position_y;
    float position_z;
    float tex_coord_x;
    float tex_coord_y;
    float normal_x;
    float normal_y;
    float normal_z;
};

struct Vertices
{
    Vertex_1 vertices[1];
};

struct gl_MeshPerVertexEXT
{
    float4 gl_Position [[position]];
};

struct PushConstants
{
    float4x4 view_projection_matrix;
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(32u, 1u, 1u);

struct spvPerVertex
{
    float4 gl_Position [[position]];
    float2 out_tex_coords [[user(locn0)]];
    float3 out_normals [[user(locn1)]];
    float3 out_colors [[user(locn2)]];
};

using spvMesh_t = mesh<spvPerVertex, void, 64, 126, topology::triangle>;

static inline __attribute__((always_inline))
uint murmur_hash_11(thread uint& src)
{
    uint h = 1190494759u;
    src *= 1540483477u;
    src ^= (src >> uint(24));
    src *= 1540483477u;
    h *= 1540483477u;
    h ^= src;
    h ^= (h >> uint(13));
    h *= 1540483477u;
    h ^= (h >> uint(15));
    return h;
}

static inline __attribute__((always_inline))
float3 murmur_hash_11_color(thread const uint& src)
{
    uint param = src;
    uint _59 = murmur_hash_11(param);
    uint hash = _59;
    return float3(float((hash >> uint(16)) & 255u), float((hash >> uint(8)) & 255u), float(hash & 255u)) / float3(256.0);
}

static inline __attribute__((always_inline))
uint get_index(thread const uint& index_offset, thread const uint& index, const device MeshletData& v_90)
{
    uint byte_offset = (3u - (index & 3u)) << uint(3);
    return (v_90.meshlet_data[index_offset + (index >> uint(2))] & uint(255 << int(byte_offset))) >> byte_offset;
}

static inline __attribute__((always_inline))
void _4(const device MeshletData& v_90, thread uint& gl_LocalInvocationIndex, thread uint3& gl_WorkGroupID, const device Meshlets& v_127, const device Vertices& v_169, threadgroup gl_MeshPerVertexEXT (&gl_MeshVerticesEXT)[64], constant PushConstants& push_constants, threadgroup float2 (&out_tex_coords)[64], threadgroup float3 (&out_normals)[64], threadgroup float3 (&out_colors)[64], spvMesh_t spvMesh, threadgroup uint& spv_primitive_count)
{
    uint liid = gl_LocalInvocationIndex;
    uint meshlet_idx = gl_WorkGroupID.x;
    Meshlet _132;
    _132.data_offset = v_127.meshlets[meshlet_idx].data_offset;
    _132.vertex_count = v_127.meshlets[meshlet_idx].vertex_count;
    _132.triangle_count = v_127.meshlets[meshlet_idx].triangle_count;
    Meshlet meshlet = _132;
    if (gl_LocalInvocationIndex == 0)
    {
        spv_primitive_count = meshlet.triangle_count;
    }
    uint param = meshlet_idx;
    float3 meshlet_color = murmur_hash_11_color(param);
    for (uint i = liid; i < meshlet.vertex_count; i += 32u)
    {
        uint vertex_idx = v_90.meshlet_data[meshlet.data_offset + i];
        Vertex _174;
        _174.position_x = v_169.vertices[vertex_idx].position_x;
        _174.position_y = v_169.vertices[vertex_idx].position_y;
        _174.position_z = v_169.vertices[vertex_idx].position_z;
        _174.tex_coord_x = v_169.vertices[vertex_idx].tex_coord_x;
        _174.tex_coord_y = v_169.vertices[vertex_idx].tex_coord_y;
        _174.normal_x = v_169.vertices[vertex_idx].normal_x;
        _174.normal_y = v_169.vertices[vertex_idx].normal_y;
        _174.normal_z = v_169.vertices[vertex_idx].normal_z;
        Vertex vertex0 = _174;
        gl_MeshVerticesEXT[i].gl_Position = push_constants.view_projection_matrix * float4(vertex0.position_x, vertex0.position_y, vertex0.position_z, 1.0);
        out_tex_coords[i] = float2(vertex0.tex_coord_x, vertex0.tex_coord_y);
        out_normals[i] = float3(vertex0.normal_x, vertex0.normal_y, vertex0.normal_z);
        out_colors[i] = meshlet_color;
    }
    uint index_offset = meshlet.data_offset + meshlet.vertex_count;
    for (uint i_1 = liid; i_1 < meshlet.triangle_count; i_1 += 32u)
    {
        uint triangle_idx = 3u * i_1;
        uint param_1 = index_offset;
        uint param_2 = triangle_idx;
        uint param_3 = index_offset;
        uint param_4 = triangle_idx + 1u;
        uint param_5 = index_offset;
        uint param_6 = triangle_idx + 2u;
        uint3 _282 = uint3(get_index(param_1, param_2, v_90), get_index(param_3, param_4, v_90), get_index(param_5, param_6, v_90));
        spvMesh.set_index((i_1) * 3u + 0u, _282[0]);
        spvMesh.set_index((i_1) * 3u + 1u, _282[1]);
        spvMesh.set_index((i_1) * 3u + 2u, _282[2]);
    }
}

[[mesh]] void mesh_function(const device MeshletData& v_90 [[buffer(3)]], const device Meshlets& v_127 [[buffer(2)]], const device Vertices& v_169 [[buffer(1)]], constant PushConstants& push_constants [[buffer(0)]], uint gl_LocalInvocationIndex [[thread_index_in_threadgroup]], uint3 gl_WorkGroupID [[threadgroup_position_in_grid]], spvMesh_t spvMesh)
{
    threadgroup uint spv_primitive_count;
    threadgroup gl_MeshPerVertexEXT gl_MeshVerticesEXT[64];
    threadgroup float2 out_tex_coords[64];
    threadgroup float3 out_normals[64];
    threadgroup float3 out_colors[64];
    _4(v_90, gl_LocalInvocationIndex, gl_WorkGroupID, v_127, v_169, gl_MeshVerticesEXT, push_constants, out_tex_coords, out_normals, out_colors, spvMesh, spv_primitive_count);
    threadgroup_barrier(mem_flags::mem_threadgroup);
    if (spv_primitive_count == 0)
    {
        return;
    }
    spvMesh.set_primitive_count(spv_primitive_count);
    for (uint spvI = gl_LocalInvocationIndex, spvThreadCount = (gl_WorkGroupSize.x*gl_WorkGroupSize.y*gl_WorkGroupSize.z); spvI < 64; spvI += spvThreadCount)
    {
        spvPerVertex spvV = {};
        spvV.gl_Position = gl_MeshVerticesEXT[spvI].gl_Position;
        spvV.out_tex_coords = out_tex_coords[spvI];
        spvV.out_normals = out_normals[spvI];
        spvV.out_colors = out_colors[spvI];
        spvMesh.set_vertex(spvI, spvV);
    }
}

struct main0_out
{
    float4 out_color [[color(0)]];
};

struct main0_in
{
    float3 color [[user(locn2)]];
};

fragment main0_out fragment_function(main0_in in [[stage_in]])
{
    main0_out out = {};
    out.out_color = float4(in.color, 1.0);
    return out;
}
