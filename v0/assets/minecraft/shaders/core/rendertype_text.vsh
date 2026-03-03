#version 150

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;

#moj_import <minecraft:text_effects_utils.glsl>

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    // ===== v0_fixed2: y-offset via signature color (#RR01F4) =====
// R byte encodes signed offset: off = R - 128 (pixels). Positive = move up.
// Shadow pass darkens colors, so we also accept the shadowed signature (~25%) and recover R by *4.
// Apply without GUI-gate to avoid missing actionbar.
{
    vec3 rgb = Color.rgb;

    bool sigMain =
        abs(rgb.g - (1.0/255.0)) < 0.01 &&
        abs(rgb.b - (244.0/255.0)) < 0.02;

    // approximate shadow signature of (1/255, 244/255) * 0.25
    bool sigShadow =
        abs(rgb.g - (1.0/255.0) * 0.25) < 0.003 &&
        abs(rgb.b - (244.0/255.0) * 0.25) < 0.03;

    if (sigMain || sigShadow) {
        float rRec = sigShadow ? clamp(rgb.r * 4.0, 0.0, 1.0) : rgb.r;
        int off = int(floor(rRec * 255.0 + 0.5)) - 128;
        gl_Position.y += gl_Position.w * (2.0 * float(off) / ScreenSize.y);
    }
}
// ======================================================


sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
    texCoord0 = UV0;

    applyTextEffects();
}