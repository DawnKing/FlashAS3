/**
 * Created by caijingxiao on 2016/10/13.
 */
package Tutorials {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.cameras.ArcRotateCamera;
    import babylon.lights.Light;
    import babylon.lights.PointLight;
    import babylon.math.Color3;
    import babylon.math.Vector3;
    import babylon.mesh.Mesh;

    import easiest.events.Stage3DEvent;

    import flash.display.Sprite;
    import flash.events.Event;

    [SWF(frameRate="60")]
    public class BasicLight extends Sprite {
        private var _engine: Engine;

        public function BasicLight() {
            _engine = new Engine(stage);
            _engine.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DCreated);
            _engine.init();
        }

        private function onContext3DCreated(event: Stage3DEvent):void {
            var scene: Scene = createScene();

            _engine.runRenderLoop(function():void {
                scene.render();
            });

            stage.addEventListener(Event.RESIZE, function(event: Event): void {
                _engine.resize();
            });
        }

        private function createScene(): Scene {
            var scene: Scene = new Scene(_engine);

            var camera: ArcRotateCamera = new ArcRotateCamera("camera1",  0, 0, 0, new Vector3(0, 0, 0), scene);
            camera.setPosition(new Vector3(0, 10, -10));
            camera.attachControl(this.stage, true);

            var light: Light = new PointLight('light1', new Vector3(0, 1, 0),scene);
//            var light: HemisphericLight = new HemisphericLight('light1', new Vector3(0,1,0), scene);
//            light.specular = new Color3(0, 0, 0);

            var sphere: Mesh = Mesh.CreateSphere('sphere1', 16, 2, scene);
            sphere.position.y = 1;
            var ground: Mesh = Mesh.CreateGround('ground1', 6, 6, 2, scene);

//            var material: ShaderMaterial = new ShaderMaterial("color material", scene, "color", {});
//            material.setColor4("color", new Color4(1, 0, 0, 1));
//            sphere.material = material;

            return scene;
        }
    }
}

/**
 uniform vec3 vEyePosition;     // _effect.setVector3("vEyePosition", scene._mirroredCameraPosition ? scene._mirroredCameraPosition : scene.activeCamera.position);
 uniform vec3 vAmbientColor;    // _effect.setColor3("vAmbientColor", this._globalAmbientColor);    (0, 0, 0)
 uniform vec4 vDiffuseColor;    // _effect.setColor4("vDiffuseColor", this.diffuseColor, this.alpha * mesh.visibility); (1, 1, 1) 1
 uniform vec3 vEmissiveColor;   // _effect.setColor3("vEmissiveColor", this.emissiveColor); (0, 0, 0)

 varying vec3 vPositionW;   // finalWorld*vec4(position,1.0);
 #ifdef NORMAL
 varying vec3 vNormalW; // vNormalW=normalize(vec3(finalWorld*vec4(normal,0.0)));
 #endif


 #ifdef LIGHT0
 uniform vec4 vLightData0;  MaterialHelper.BindLightProperties();   (this.position.x, this.position.y, this.position.z
 uniform vec4 vLightDiffuse0;   MaterialHelper.BindLights().effect.setColor4("vLightDiffuse" + lightIndex, Tmp.Color3[0], light.range); (1, 1, 1)
 #endif

 struct lightingInfo
 {
     vec3 diffuse;
 };

 // viewDirectionW = normalize(vEyePosition - vPositionW);
 // vNormal
 // lightData = vLightData0
 // diffuseColor = vLightDiffuse0.rgb
 // specularColor = vLightSpecular0
 // range = vLightDiffuse0.a
 // glossiness
 lightingInfo computeLighting(vec3 viewDirectionW,vec3 vNormal,vec4 lightData,vec3 diffuseColor,vec3 specularColor,float range,float glossiness) {
	lightingInfo result;
	vec3 lightVectorW;
	float attenuation=1.0;
	if (lightData.w == 0.)
	{
		vec3 direction=lightData.xyz-vPositionW;
		attenuation=max(0.,1.0-length(direction)/range);
		lightVectorW=normalize(direction);
	}
	else
	{
		lightVectorW=normalize(-lightData.xyz);
	}

	float ndl=max(0.,dot(vNormal,lightVectorW));
	result.diffuse=ndl*diffuseColor*attenuation;
	return result;
}




 void main(void) {
	vec3 viewDirectionW=normalize(vEyePosition-vPositionW);

	vec4 baseColor=vec4(1.,1.,1.,1.);
	vec3 diffuseColor=vDiffuseColor.rgb;

	float alpha=vDiffuseColor.a;

#ifdef NORMAL
    vec3 normalW=normalize(vNormalW);
#else
    vec3 normalW=vec3(1.0,1.0,1.0);
#endif
	vec2 uvOffset=vec2(0.0,0.0);

	vec3 baseAmbientColor=vec3(1.,1.,1.);

	float glossiness=0.;

	vec3 diffuseBase=vec3(0.,0.,0.);
	lightingInfo info;
	float shadow=1.;

#ifdef LIGHT0
#if defined(POINTLIGHT0) || defined(DIRLIGHT0)
	info=computeLighting(viewDirectionW,normalW,vLightData0,vLightDiffuse0.rgb,vLightSpecular0,vLightDiffuse0.a,glossiness);
#endif

	shadow=1.;
	diffuseBase+=info.diffuse*shadow;
#endif

	vec3 refractionColor=vec3(0.,0.,0.);

	vec3 emissiveColor=vEmissiveColor;

	vec3 finalDiffuse=clamp(diffuseBase*diffuseColor+emissiveColor+vAmbientColor,0.0,1.0)*baseColor.rgb;    // finalDiffuse = clamp(diffuseBase,0.0,1.0)

	vec3 finalSpecular=vec3(0.0);
	vec4 color=vec4(finalDiffuse*baseAmbientColor+finalSpecular+reflectionColor+refractionColor,alpha);     // color = vec4(finalDiffuse, 1)

	gl_FragColor=color;
}
 */

/**
 varying vec3 vPositionW;   // finalWorld*vec4(position,1.0);
 #ifdef NORMAL
 varying vec3 vNormalW; // vNormalW=normalize(vec3(finalWorld*vec4(normal,0.0)));
 #endif


 #ifdef LIGHT0
 uniform vec4 vLightData0;  MaterialHelper.BindLightProperties();   (this.position.x, this.position.y, this.position.z
 uniform vec4 vLightDiffuse0;   MaterialHelper.BindLights().effect.setColor4("vLightDiffuse" + lightIndex, Tmp.Color3[0], light.range); (1, 1, 1)
 #endif

 struct lightingInfo
 {
     vec3 diffuse;
 };

 // vNormal
 // lightData = vLightData0
 // diffuseColor = vLightDiffuse0.rgb
 // range = vLightDiffuse0.a
 lightingInfo computeLighting(vec3 vNormal,vec4 lightData,vec3 diffuseColor,float range) {
	lightingInfo result;
	vec3 lightVectorW;
	float attenuation=1.0;
	if (lightData.w == 0.)
	{
		vec3 direction=lightData.xyz-vPositionW;
		attenuation=max(0.,1.0-length(direction)/range);
		lightVectorW=normalize(direction);
	}
	else
	{
		lightVectorW=normalize(-lightData.xyz);
	}

	float ndl=max(0.,dot(vNormal,lightVectorW));
	result.diffuse=ndl*diffuseColor*attenuation;
	return result;
}


 void main(void) {
    vec3 normalW=normalize(vNormalW);

	vec3 diffuseBase=vec3(0.,0.,0.);
	lightingInfo info;

#ifdef LIGHT0
#if defined(POINTLIGHT0) || defined(DIRLIGHT0)
	info=computeLighting(normalW,vLightData0,vLightDiffuse0.rgb,vLightDiffuse0.a);
#endif

	diffuseBase+=info.diffuse;
#endif

	vec3 finalDiffuse=clamp(diffuseBase,0.0,1.0);
	vec4 color=vec4(finalDiffuse,1);

	gl_FragColor=color;
}
 */