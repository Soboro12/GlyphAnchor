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

const float SIG_G = 1.0 / 255.0;
const float SIG_B = 244.0 / 255.0;

bool decodeControlYOffset(out float yOffsetPx) {
    yOffsetPx = 0.0;

    // Recover from global color modulation first.
    vec3 baseRgb = Color.rgb / max(ColorModulator.rgb, vec3(0.0001));

    // Shadow pass scales RGB, so detect by channel ratio and solve scale.
    float scale = baseRgb.b / SIG_B;
    if (scale < 0.18 || scale > 1.15) {
        return false;
    }

    float expectedG = SIG_G * scale;
    if (abs(baseRgb.g - expectedG) > 0.0025) {
        return false;
    }

    float recoveredR = clamp(baseRgb.r / max(scale, 0.0001), 0.0, 1.0);
    int off = int(floor(recoveredR * 255.0 + 0.5)) - 128;
    yOffsetPx = float(off);
    return true;
}

void main() {
    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
    texCoord0 = UV0;

    applyTextEffects();

    float yOffsetPx;
    if (decodeControlYOffset(yOffsetPx)) {
        gl_Position.y += gl_Position.w * (2.0 * yOffsetPx / ScreenSize.y);
    }
}
