package easiest.utils
{
    import easiest.core.EasiestCore;
    import easiest.managers.FrameManager;

    import flash.geom.Point;

    public final class MathUtil
    {
        /**
         * 获取一个在min和max之间的随机数，包括min，不包括max
         */
        public static function getNumberRandom(min:Number, max:Number):Number
        {
            var random:Number = Math.random();     
            return min + (max - min) * random;
        }
        
        /**
         * 获取一个在min和max之间的随机数，包括min和max
         */
        public static function getIntRandom(min:Number, max:Number):int
        {
            return Math.floor(Math.random() * (max - min + 1)) + min;
        }
        
        /**
         * 获取倾斜的角度，上为0度，右为90度
         */
        public static function getAngle(beginX:int, beginY:int, endX:int, endY:int):Number
        {
            var k:Number = -(endY - beginY) / (endX - beginX);
            var radian:Number;
            
            if (k < 0)
                radian = Math.atan(-k);
            else
                radian = Math.atan(k);
            
            var rotation:Number;
            if (k < 0)
            {
                if (beginX <= endX)
                    rotation = -(90 - radian * 180 / Math.PI - 180);
                else
                    rotation = -(90 - radian * 180 / Math.PI);
            }
            else
            {   
                if (beginX <= endX)                 
                    rotation = 90 - radian * 180 / Math.PI;
                else
                    rotation = 90 - radian * 180 / Math.PI + 180;
            }
            if (isNaN(rotation))
                return 0;
            return rotation;
        }
        

        /**
         * 人物移动的16方向判断
         */
        public static  function get16Direction(startX:int, startY:int, targetX:int, targetY:int):int
        {
            var ratio:int = 57;                   // Atan2的比值
            
            //偏移坐标系
            var unitPosX:int = targetX - startX;
            var unitPosY:int = targetY - startY;
            
            var _angle:Number = Math.atan2(-unitPosY, unitPosX) * ratio;    
            
            if(_angle < 0)
                _angle = 360 + _angle;
            
            if(_angle > 337.5 || _angle <= 22.5)
                return 4;
            
            if(_angle > 22.5 && _angle <= 67.5)
                return 2;  
            
            if(_angle > 67.5 && _angle <= 112.5)   
                return 0;
            
            if(_angle > 112.5 && _angle <= 157.5)   
                return 14;    
            
            if(_angle > 157.5 && _angle <= 202.5)   
                return 12;   
            
            if(_angle > 202.5 && _angle <= 247.5)   
                return 10;   
            
            if(_angle > 247.5 && _angle <= 292.5)   
                return 8;        
            
            return 6; 
        }
        /**
         * 计算两点之间距离
         */
        public static function getDistance(beginX:Number, beginY:Number, endX:Number, endY:Number):Number
        {
            var distance:Number = (beginX - endX) * (beginX - endX) + (beginY - endY) * (beginY - endY);
            return Math.sqrt(distance);
        }
        
        /**
         * 从（beginX，beginY）到（endX，endY）的连线中，获取离（endX，endY）距离为distance的点
         * 用于寻路到离目标点最远的点
         */
        public static function getNearestPoint(beginX:Number, beginY:Number, endX:Number, endY:Number, distance:Number):Point
        {
            var q:Number = getDistance(beginX, beginY, endX, endY);
            var param:Number = ((q - distance) / q);
            var rx:Number = beginX - (beginX - endX) * param;
            var ry:Number = beginY - (beginY - endY) * param;
            var r:Point = new Point(rx, ry);
            return r;
        }
        
        /**
         * 以（beginX，beginY）为原点，根据指定角度、指定距离，算出点（endX，endY）
         * 用于角色施法，以角色为中心，向某个方向施放一个指定距离的技能
         */
        public static function getAnglePoint(beginX:Number, beginY:Number, angle:Number, distance:Number):Point
        {
            var radian:Number = angle * Math.PI / 180;
            var rx:Number = beginX + Math.sin(radian) * distance;
            var ry:Number = beginY - Math.cos(radian) * distance;
            var r:Point = new Point(rx, ry);
            return r;
        }        
        

        /**
         * 根据角度和X轴长度，计算Y轴长度
         */
        public static function getYByAngle(angle:int, x:int):int
        {
            var angleRadians:Number = angle * Math.PI / 180;
            
            return x * Math.tan(angleRadians);
        }
        
        /**
         * 获取延迟一定帧数后的时间
         */
        public static function getDelayFrameTime(frame:int, fps:int):Number
        {
            var serverTime:Number = FrameManager.serverTime;
            var time:Number = serverTime + frame * EasiestCore.spf / (fps / EasiestCore.frameRate);
            return time;
        }
		
		/**
		 * 将以10000为单位的百分比转化成小数
		 * **/
		public static function transValToRatio(val:Number):Number
		{
			var ratio:Number = val / 10000;
			return ratio;
		}
		
		/**
		 * 将以10000为单位的百分比转化成百分数
		 * **/
		public static function transValToPercent(val:Number):Number
		{
			var percent:Number = val / 100;
			return percent;
		}
		
		/**
		 * 装换为几位数
		 * **/
		public static function formatIntPlaces(val:int, places:int):String
		{
			var valStr:String = val.toString();
			while (valStr.length < places)
			{
				valStr = "0" + valStr;
			}
			return valStr;
		}
		
    }
}