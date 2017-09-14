// Attributes
attribute vec3 position;
#ifdef NORMAL
attribute vec3 normal;
#endif

#ifdef UV1
attribute vec2 uv;
#endif

#include<bonesDeclaration>

// Uniforms
#include<instancesDeclaration>

uniform mat4 viewProjection;

#ifdef DIFFUSE
varying vec2 vDiffuseUV;
uniform mat4 diffuseMatrix;
#endif

// Output
varying vec3 vPositionW;
#ifdef NORMAL
varying vec3 vNormalW;
#endif

uniform float vertexConst0;
uniform float vertexConst1;

void main(void) {

#include<instancesVertex>
#include<bonesVertex>

	// vec4 worldPos = finalWorld * vec4(position, 1.0);
    // vPositionW = vec3(worldPos);
	Transpose(finalWorld);
	vec4 temp;
	mov temp.xyz, position;
	mov temp.w, vertexConst1;
	m44 vPositionW, temp, finalWorld;

#ifdef NORMAL
	// vNormalW = normalize(vec3(finalWorld * vec4(normal, 0.0)));
	vec4 temp;
	mov temp.xyz, normal;
	mov temp.w, vertexConst0;
	m44 temp, temp, finalWorld;
	nrm temp.xyz, temp.xyz;
	mov vNormalW, temp.xyz;
#endif
	Transpose(finalWorld);

	// gl_Position = viewProjection * finalWorld * vec4(position, 1.0);
	// position * finalWorld * viewProjection
	m44 finalWorld[0], finalWorld[0], viewProjection;
	m44 finalWorld[1], finalWorld[1], viewProjection;
	m44 finalWorld[2], finalWorld[2], viewProjection;
	m44 finalWorld[3], finalWorld[3], viewProjection;

	Transpose(finalWorld);
	vec4 temp;
	mov temp.xyz, position;
	mov temp.w, vertexConst1;
	m44 op, temp, finalWorld;

#ifdef DIFFUSE
	vec4 temp;
	mov temp, uv;
	mov temp.z, vertexConst1;
	mov temp.w, vertexConst0;
	m44 vDiffuseUV, temp, diffuseMatrix;
#endif
}