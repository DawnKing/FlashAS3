package easiest.managers.load
{
    public final class AssetType
    {
        public static const BITMAP:String = "bitmap";
        public static const BITMAP_DATA:String = "bitmapData";
        public static const MOVIE_CLIP:String = "movieClip";
        public static const SPRITE_SHEET:String = "spriteSheet";
        
        public static const XML:String = "xml";
        public static const BINARY:String = "binary";
        public static const TEXT:String = "text";
        public static const VARIABLES:String = "variables";
        
        public static const CACHE_NONE:int = 0;
        public static const CACHE_SOMETIMES:int = 1;
        public static const CACHE_ALWAYS:int = 2;

        public static const SKIP_CHECK:String = "skipCheck";
        
        public static function getExtension(url:String):String
        {
            var extension:String = url.split(".").pop() as String;
            extension = extension.toLowerCase();
            return extension;
        }
        
        public static function isSwf(url:String):Boolean
        {
            return getExtension(url) == "swf";
        }

        // away3d
        public static const ENTITY:String = 'entity';
        public static const SKYBOX:String = 'skybox';
        public static const CAMERA:String = 'camera';
        public static const SEGMENT_SET:String = 'segmentSet';
        public static const MESH:String = 'mesh';
        public static const GEOMETRY:String = 'geometry';
        public static const SKELETON:String = 'skeleton';
        public static const SKELETON_POSE:String = 'skeletonPose';
        public static const CONTAINER:String = 'container';
        public static const TEXTURE:String = 'texture';
        public static const TEXTURE_PROJECTOR:String = 'textureProjector';
        public static const MATERIAL:String = 'material';
        public static const ANIMATION_SET:String = 'animationSet';
        public static const ANIMATION_STATE:String = 'animationState';
        public static const ANIMATION_NODE:String = 'animationNode';
        public static const ANIMATOR:String = 'animator';
        public static const STATE_TRANSITION:String = 'stateTransition';
        public static const LIGHT:String = 'light';
        public static const LIGHT_PICKER:String = 'lightPicker';
        public static const SHADOW_MAP_METHOD:String = 'shadowMapMethod';
        public static const EFFECTS_METHOD:String = 'effectsMethod';
    }
}