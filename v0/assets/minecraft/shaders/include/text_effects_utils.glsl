#version 150

#moj_import <minecraft:globals.glsl>

precision highp float;
#define TE_STEP_Y 12.0
#define TE_MARK_STRIDE 4096.0

bool teIsActionbarZ(float z) {
    // wide tolerance for 1.21.x; actionbar is around 2200
    return abs(z - 2200.015) < 0.05;
}
int teMarkerIndex(float x) {
    return int(floor((x / TE_MARK_STRIDE) + 0.5));
}


#define hue(v)  ((.6+.6*cos(6.*(v)+vec4(0, 23, 21, 1)))+vec4(0., 0., 0., 1.) )

#define finalize() { \
    sphericalVertexDistance=length((ModelViewMat*vertex).xyz); \
    cylindricalVertexDistance=length((ModelViewMat*vertex).xyz); \
}

void applyProjection(inout vec4 vertex) {
    gl_Position = ProjMat * ModelViewMat * vertex;
}

void applyColorTexture() {
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
}

void applyHueColor() {
    vertexColor = hue(gl_Position.x + GameTime * 1000.) * texelFetch(Sampler2, UV2 / 16, 0);
}

void applyWaveEffect() {
    gl_Position.y += sin(GameTime * 12000. + (gl_Position.x * 6)) / 150.;
}

void processRainbowEffect(inout vec4 vertex) {
    applyProjection(vertex);
    applyHueColor();
    finalize();
}

void processWavyEffect(inout vec4 vertex) {
    applyProjection(vertex);
    applyColorTexture();
    applyWaveEffect();
    finalize();
}

void processWavyRainbowEffect(inout vec4 vertex) {
    applyProjection(vertex);
    applyWaveEffect();
    applyHueColor();
    finalize();
}

void processBouncyEffect(inout vec4 vertex) {
    applyColorTexture();
    float vertexId = mod(gl_VertexID, 4.);
    if (vertex.z <= 0.) {
        if (vertexId == 3. || vertexId == 0.) {
            vertex.y += cos(GameTime * 12000. / 4) * .1;
            vertex.y += max(cos(GameTime * 12000. / 4) * .1, 0.);
        }
    } else {
        if (vertexId == 3. || vertexId == 0.) {
            vertex.y -= cos(GameTime * 12000. / 4) * 3;
            vertex.y -= max(cos(GameTime * 12000. / 4) * 4, 0.);
        }
    }
    applyProjection(vertex);
    finalize();
}

void processBouncyRainbowEffect(inout vec4 vertex) {
    float vertexId = mod(gl_VertexID, 4.);
    if (vertex.z <= 0.) {
        if (vertexId == 3. || vertexId == 0.) {
            vertex.y += cos(GameTime * 12000. / 4) * .1;
            vertex.y += max(cos(GameTime * 12000. / 4) * .1, 0.);
        }
    } else {
        if (vertexId == 3. || vertexId == 0.) {
            vertex.y -= cos(GameTime * 12000. / 4) * 3;
            vertex.y -= max(cos(GameTime * 12000. / 4) * 4, 0.);
        }
    }
    applyHueColor();
    applyProjection(vertex);
    finalize();
}

void processBlinkingEffect(inout vec4 vertex, float speed) {
    applyProjection(vertex);
    float blink = abs(sin(GameTime * 12000. * speed));
    vertexColor = Color * blink * texelFetch(Sampler2, UV2 / 16, 0);
    finalize();
}

void processNoShadow(inout vec4 vertex) {
    applyProjection(vertex);
    applyColorTexture();
    vertexColor = vec4(1, 1, 1, vertexColor.a); 
    finalize();
}

void applyTextEffects() {
    vec4 vertex = vec4(Position, 1.);
    // === Custom: actionbar marker UP/DOWN (color-independent) ===
    // Use space-advance marker characters (±4096) placed before the moving segment.
    // NOTE: This cannot read fine bit-space (±1..±2048) because space glyphs don't emit vertices.
    if (teIsActionbarZ(Position.z)) {
        int m = teMarkerIndex(Position.x);
        if (m != 0) {
            vertex.x -= float(m) * TE_MARK_STRIDE; // undo X marker so it doesn't "stretch"
            vertex.y += float(m) * TE_STEP_Y;      // move up/down
        }
    }

    ivec3 iColor = ivec3(Color.xyz * 255 + vec3(.5));

    if(fract(Position.z) < .1) {
        if(iColor==ivec3(19, 23, 9)) {
            gl_Position=vec4(2, 2, 2, 1);
            applyColorTexture();
            finalize();
            return;
        }
        if(iColor==ivec3(57, 63, 63)) {
            applyProjection(vertex);
            applyColorTexture();
            finalize();
            return;
        }
        if(iColor==ivec3(57, 63, 62)) {
            processWavyEffect(vertex);
            return;
        }
        if(iColor==ivec3(57, 62, 63)) {
            processWavyEffect(vertex);
            return;
        }
        if(iColor==ivec3(57, 62, 62)) {
            processBouncyEffect(vertex);
            return;
        }
        if(iColor==ivec3(57, 61, 63)) {
            processBouncyEffect(vertex);
            return;
        }
        if(iColor==ivec3(57, 61, 62)) {
            processBlinkingEffect(vertex, .5);
            return;
        }
    }

    if (iColor == ivec3(78, 92, 36)) {
        processNoShadow(vertex);
        return;
    }
    if (iColor == ivec3(230, 255, 254)) {
        processRainbowEffect(vertex);
        return;
    }
    if (iColor == ivec3(230, 255, 250)) {
        processWavyEffect(vertex);
        return;
    }
    if (iColor == ivec3(230, 251, 254)) {
        processWavyRainbowEffect(vertex);
        return;
    }
    if (iColor == ivec3(230, 251, 250)) {
        processBouncyEffect(vertex);
        return;
    }
    if (iColor == ivec3(230, 247, 254)) {
        processBouncyRainbowEffect(vertex);
        return;
    }
    if (iColor == ivec3(230, 247, 250)) {
        processBlinkingEffect(vertex, .5);
        return;
    }

    applyProjection(vertex);
    applyColorTexture();
    finalize();
}
