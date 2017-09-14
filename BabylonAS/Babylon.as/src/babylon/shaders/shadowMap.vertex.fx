// Attribute
attribute vec3 position;

#include<bonesDeclaration>

// Uniforms
#include<instancesDeclaration>

uniform mat4 viewProjection;

varying vec4 vPosition;

#ifdef ALPHATEST
varying vec2 vUV;
uniform mat4 diffuseMatrix;
#ifdef UV1
attribute vec2 uv;
#endif
#ifdef UV2
attribute vec2 uv2;
#endif
#endif

uniform float vertexConst0;
uniform float vertexConst1;

void main(void) {
#include<instancesVertex>
#include<bonesVertex>

#ifdef CUBEMAP
	// vPosition = finalWorld * vec4(position, 1.0);
	Transpose(finalWorld);
	vec4 temp;
	mov temp.xyz, position;
	mov temp.w, vertexConst1;
	m44 vPosition, temp, finalWorld;
	Transpose(finalWorld);

	// gl_Position = viewProjection * finalWorld * vec4(position, 1.0);
	m44 finalWorld[0], finalWorld[0], viewProjection;
	m44 finalWorld[1], finalWorld[1], viewProjection;
	m44 finalWorld[2], finalWorld[2], viewProjection;
	m44 finalWorld[3], finalWorld[3], viewProjection;

	Transpose(finalWorld);
	vec4 temp;
	mov temp.xyz, position;
	mov temp.w, vertexConst1;
	m44 op, temp, finalWorld;
#else
	// vPosition = viewProjection * finalWorld * vec4(position, 1.0);
	m44 finalWorld[0], finalWorld[0], viewProjection;
	m44 finalWorld[1], finalWorld[1], viewProjection;
	m44 finalWorld[2], finalWorld[2], viewProjection;
	m44 finalWorld[3], finalWorld[3], viewProjection;

	Transpose(finalWorld);
	vec4 temp;
	mov temp.xyz, position;
	mov temp.w, vertexConst1;
	m44 vPosition, temp, finalWorld;

	// gl_Position = vPosition;
	mov op, vPosition;
#endif

#ifdef ALPHATEST
#ifdef UV1
	// vUV = vec2(diffuseMatrix * vec4(uv, 1.0, 0.0));
	vec4 temp;
	mov temp, uv;
	mov temp.z, vertexConst1;
	mov temp.w, vertexConst0;
	m44 vUV, temp, diffuseMatrix;
#endif
#ifdef UV2
	// vUV = vec2(diffuseMatrix * vec4(uv2, 1.0, 0.0));
	vec4 temp;
	mov temp, uv2;
	mov temp.z, vertexConst1;
	mov temp.w, vertexConst0;
	m44 vUV, temp, diffuseMatrix;
#endif
#endif
}