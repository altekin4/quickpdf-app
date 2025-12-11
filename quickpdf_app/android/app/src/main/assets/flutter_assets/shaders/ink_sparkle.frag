// Dummy shader to bypass Impeller compilation
#version 320 es
precision mediump float;
out vec4 fragColor;
void main() {
    fragColor = vec4(1.0, 1.0, 1.0, 1.0);
}