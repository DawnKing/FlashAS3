/**
 * Created by caijingxiao on 2016/10/26.
 */
package babylon.materials {
    public dynamic class StandardMaterialDefines extends MaterialDefines {
        public var DIFFUSE: Boolean = false;
//        public var AMBIENT: Boolean = false;
//        public var OPACITY: Boolean = false;
//        public var OPACITYRGB: Boolean = false;
//        public var REFLECTION: Boolean = false;
//        public var EMISSIVE: Boolean = false;
//        public var SPECULAR: Boolean = false;
//        public var BUMP: Boolean = false;
//        public var PARALLAX: Boolean = false;
//        public var PARALLAXOCCLUSION: Boolean = false;
//        public var SPECULAROVERALPHA: Boolean = false;
//        public var CLIPPLANE: Boolean = false;
        public var ALPHATEST: Boolean = false;
//        public var ALPHAFROMDIFFUSE: Boolean = false;
//        public var POINTSIZE: Boolean = false;
//        public var FOG: Boolean = false;
        public var SPECULARTERM: Boolean = false;
//        public var DIFFUSEFRESNEL: Boolean = false;
//        public var OPACITYFRESNEL: Boolean = false;
//        public var REFLECTIONFRESNEL: Boolean = false;
//        public var REFRACTIONFRESNEL: Boolean = false;
//        public var EMISSIVEFRESNEL: Boolean = false;
//        public var FRESNEL: Boolean = false;
        public var NORMAL: Boolean = false;
        public var UV1: Boolean = false;
//        public var UV2: Boolean = false;
        public var VERTEXCOLOR: Boolean = false;
        public var VERTEXALPHA: Boolean = false;
        public var NUM_BONE_INFLUENCERS: int;
        public var BonesPerMesh: int;
        public var INSTANCES: Boolean = false;
//        public var GLOSSINESS: Boolean = false;
//        public var ROUGHNESS: Boolean = false;
//        public var EMISSIVEASILLUMINATION: Boolean = false;
//        public var LINKEMISSIVEWITHDIFFUSE: Boolean = false;
//        public var REFLECTIONFRESNELFROMSPECULAR: Boolean = false;
//        public var LIGHTMAP: Boolean = false;
//        public var USELIGHTMAPASSHADOWMAP: Boolean = false;
//        public var REFLECTIONMAP_3D: Boolean = false;
//        public var REFLECTIONMAP_SPHERICAL: Boolean = false;
//        public var REFLECTIONMAP_PLANAR: Boolean = false;
//        public var REFLECTIONMAP_CUBIC: Boolean = false;
//        public var REFLECTIONMAP_PROJECTION: Boolean = false;
//        public var REFLECTIONMAP_SKYBOX: Boolean = false;
//        public var REFLECTIONMAP_EXPLICIT: Boolean = false;
//        public var REFLECTIONMAP_EQUIRECTANGULAR: Boolean = false;
//        public var REFLECTIONMAP_EQUIRECTANGULAR_FIXED: Boolean = false;
//        public var INVERTCUBICMAP: Boolean = false;
//        public var LOGARITHMICDEPTH: Boolean = false;
//        public var REFRACTION: Boolean = false;
//        public var REFRACTIONMAP_3D: Boolean = false;
//        public var REFLECTIONOVERALPHA: Boolean = false;
//        public var INVERTNORMALMAPX: Boolean = false;
//        public var INVERTNORMALMAPY: Boolean = false;
//        public var SHADOWFULLFLOAT: Boolean = false;
//        public var CAMERACOLORGRADING: Boolean = false;
//        public var CAMERACOLORCURVES: Boolean = false;

        public function StandardMaterialDefines() {
            super();
            this.rebuild();
        }
    }
}
