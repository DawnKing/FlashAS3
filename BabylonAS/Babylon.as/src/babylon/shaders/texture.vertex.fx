// Attributes
attribute vec3 position;
attribute vec2 uv;

// Uniforms
uniform mat4 world;
uniform mat4 viewProjection;

varying vec2 vDiffuseUV;
uniform mat4 diffuseMatrix;

uniform float vertexConst0;
uniform float vertexConst1;

void main(void) {
	mat4 finalWorld = world;

	// position * finalWorld * viewProjection
	m44 finalWorld[0], finalWorld[0], viewProjection;
	m44 finalWorld[1], finalWorld[1], viewProjection;
	m44 finalWorld[2], finalWorld[2], viewProjection;
	m44 finalWorld[3], finalWorld[3], viewProjection;

	Transpose(finalWorld);
	m44 op, position, finalWorld;

	vec4 temp;
	mov temp, uv;
	mov temp.z, vertexConst1;
	mov temp.w, vertexConst0;
	m44 vDiffuseUV, temp, diffuseMatrix;
}

//// Attributes
//attribute vec3 position;
//attribute vec2 uv;
//
//// Uniforms
//uniform mat4 world;
//
//varying vec2 vDiffuseUV;
//
//void main(void) {
//	m44 op, position, world;
//
//	mov vDiffuseUV, uv;
//}
