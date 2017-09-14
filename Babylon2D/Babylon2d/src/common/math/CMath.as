package common.math
{
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.display.DisplayObject;
   import flash.geom.Matrix;
   
   public class CMath
   {
      
	   public static function get AxisX() : Point
	   {
		   return new Point(1,0);
	   }
	   
	   public static function get AxisY() : Point
	   {
		   return new Point(0,1);
	   }
	   
      public static const ORIGIN:Point = new Point(0,0);
      
      private static var _cosLock:Array;
      
      private static var _sinLock:Array;
      
      public static var CanUseRawSizeTexture:Boolean = false;
       
      public function CMath()
      {
         super();
      }
      
      public static function clamp(param1:Number, param2:Number, param3:Number) : Number
      {
         var _loc4_:* = NaN;
         if(param2 > param3)
         {
            _loc4_ = param2;
            param2 = param3;
         }
         return param1 < param2?param2:param1 > param3?param3:param1;
      }
      
      public static function clampi(param1:int, param2:int, param3:int) : int
      {
         var _loc4_:* = 0;
         if(param2 > param3)
         {
            _loc4_ = param2;
            param2 = param3;
			param3 = _loc4_;
         }
         return param1 < param2?param2:param1 > param3?param3:param1;
      }
      
      public static function getRatio(param1:Number, param2:Number, param3:Number) : Number
      {
         return param1 + (param2 - param1) * param3;
      }
      
      public static function random(param1:Number, param2:Number) : Number
      {
         return Math.random() * (param2 - param1) + param1;
      }
      
      public static function randomi(param1:int, param2:int) : int
      {
         return Math.round(random(param1,param2));
      }
      
      public static function shakeRandom(param1:Number, param2:Number, param3:Number) : Number
      {
         return param1 + param1 * random(param2,param3);
      }
      
      public static function abs(param1:Number) : Number
      {
         return Math.abs(param1);
      }
      
      public static function max(param1:Number, param2:Number) : Number
      {
         return param1 > param2?param1:param2;
      }
      
      public static function maxi(param1:int, param2:int) : int
      {
         return param1 > param2?param1:param2;
      }
      
      public static function min(param1:Number, param2:Number) : Number
      {
         return param1 < param2?param1:param2;
      }
      
      public static function mini(param1:int, param2:int) : int
      {
         return param1 < param2?param1:param2;
      }
      
      public static function atan2D(param1:Number, param2:Number) : Number
      {
         return toDegree(Math.atan2(param1,param2));
      }
      
      public static function toDegree(param1:Number) : Number
      {
         return param1 / Math.PI * 180;
      }
      
      public static function toRadian(param1:int) : Number
      {
         return param1 * Math.PI / 180;
      }
      
      public static function ceilPositiveOnly(param1:Number) : uint
      {
         return param1 == int(param1)?param1:int(param1 + 1);
      }
      
      public static function ceil(param1:Number) : Number
      {
         return param1 == int(param1)?param1:param1 >= 0?int(param1 + 1):int(param1);
      }
      
      public static function exp(param1:Number) : int
      {
         var _loc2_:int = int(param1);
         var _loc3_:Number = param1 - _loc2_;
         if(_loc3_ > 0)
         {
            _loc2_ = _loc2_ + (CMath.random(0,1) <= _loc3_?1:0);
         }
         else
         {
            _loc2_ = _loc2_ + (CMath.random(0,1) <= -_loc3_?-1:0);
         }
         return _loc2_;
      }
      
      public static function angleToRadian(param1:int) : Number
      {
         return param1 * Math.PI / 180;
      }
      
      public static function toUAngle(param1:int) : int
      {
         if(param1 > -1 && param1 < 360)
         {
            return param1;
         }
         param1 = param1 % 360;
         if(param1 < 0)
         {
            param1 = param1 + 360;
         }
         return param1;
      }
      
      public static function cos(param1:int) : Number
      {
         var _loc2_:* = 0;
         if(_cosLock == null)
         {
            _cosLock = new Array(360);
            _loc2_ = 0;
            while(_loc2_ < 360)
            {
               _cosLock[_loc2_] = Math.cos(_loc2_ * Math.PI / 180);
               _loc2_++;
            }
         }
         return _cosLock[toUAngle(param1)];
      }
      
      public static function sin(param1:int) : Number
      {
         var _loc2_:* = 0;
         if(_sinLock == null)
         {
            _sinLock = new Array(360);
            _loc2_ = 0;
            while(_loc2_ < 360)
            {
               _sinLock[_loc2_] = Math.sin(_loc2_ * Math.PI / 180);
               _loc2_++;
            }
         }
         return _sinLock[toUAngle(param1)];
      }
      
      public static function toIntRect(param1:Rectangle) : Rectangle
      {
         param1.x = Math.round(param1.x);
         param1.y = Math.round(param1.y);
         param1.width = Math.round(param1.width);
         param1.height = Math.round(param1.height);
         return param1;
      }
      
      public static function getAngle(param1:int, param2:int, param3:int, param4:int) : int
      {
         var _loc5_:Number = param3 - param1;
         var _loc6_:Number = param4 - param2;
         return Math.round(Math.atan2(_loc6_,_loc5_) / Math.PI * 180);
      }
      
      public static function getTwoPointAngle(param1:Point, param2:Point) : int
      {
         var _loc3_:Number = param2.x - param1.x;
         var _loc4_:Number = param2.y - param1.y;
         return Math.round(Math.atan2(_loc4_,_loc3_) / Math.PI * 180);
      }
      
      public static function randomList(param1:int) : Array
      {
         var _loc2_:Array = new Array();
         var _loc3_:* = 0;
         while(_loc3_ < param1)
         {
            _loc2_.push(_loc3_);
            _loc3_++;
         }
         var _loc4_:Array = new Array();
         while(_loc2_.length > 0)
         {
            _loc4_.push(_loc2_.splice(randomi(0,_loc2_.length - 1),1));
         }
         return _loc4_;
      }
      
      public static function randomBoolean() : Boolean
      {
         var _loc1_:int = randomi(0,1);
         return _loc1_ == 0;
      }
      
      public static function getDistance(param1:Number, param2:Number, param3:Number, param4:Number) : Number
      {
         var _loc5_:Number = param3 - param1;
         var _loc6_:Number = param4 - param2;
         return Math.sqrt(_loc5_ * _loc5_ + _loc6_ * _loc6_);
      }
      
      public static function getTwoPointDistance(param1:Point, param2:Point) : Number
      {
         if(param1 == null || param2 == null)
         {
            return 0;
         }
         var _loc3_:Number = param2.x - param1.x;
         var _loc4_:Number = param2.y - param1.y;
         return Math.sqrt(_loc3_ * _loc3_ + _loc4_ * _loc4_);
      }
      
      public static function rotate(param1:int, param2:int, param3:int, param4:int = 0, param5:int = 0) : Point
      {
         var _loc6_:int = Math.round(param1 * cos(param3)) - Math.round(param2 * sin(param3)) + param4;
         var _loc7_:int = Math.round(param1 * sin(param3)) + Math.round(param2 * cos(param3)) + param5;
         return new Point(_loc6_,_loc7_);
      }
      
      public static function getRotateMatrix(param1:DisplayObject, param2:int) : void
      {
         var _loc3_:Matrix = new Matrix();
         _loc3_.rotate(param2 * Math.PI / 180);
         var _loc4_:Point = _loc3_.transformPoint(new Point(0,0));
         var _loc5_:Point = _loc3_.transformPoint(new Point(param1.width,0));
         var _loc6_:Point = _loc3_.transformPoint(new Point(param1.width,param1.height));
         var _loc7_:Point = _loc3_.transformPoint(new Point(0,param1.height));
         var _loc8_:Number = Math.min(_loc4_.x,_loc5_.x,_loc6_.x,_loc7_.x);
         var _loc9_:Number = Math.min(_loc4_.y,_loc5_.y,_loc6_.y,_loc7_.y);
         _loc3_.tx = _loc3_.tx + -_loc8_;
         _loc3_.ty = _loc3_.ty + -_loc9_;
      }
      
      public static function getPointInLine(param1:Number, param2:Number, param3:Number, param4:Number, param5:Number) : Point
      {
         var _loc6_:Number = param1;
         var _loc7_:Number = param2;
         var _loc8_:Number = Math.atan2(param4 - param2,param3 - param1);
         if(param1 != param3)
         {
            _loc6_ = _loc6_ + param5 * Math.cos(_loc8_);
            _loc7_ = _loc7_ + param5 * Math.sin(_loc8_);
         }
         else if(param2 != param4)
         {
            _loc7_ = _loc7_ + param5 * Math.sin(_loc8_);
         }
         return new Point(_loc6_,_loc7_);
      }
      
      public static function getPointInCircle(param1:Number, param2:Number, param3:Number, param4:Number) : Point
      {
         var _loc5_:Number = param1;
         var _loc6_:Number = param2;
         _loc5_ = _loc5_ + param3 * Math.cos(param4);
         _loc6_ = _loc6_ + param3 * Math.sin(param4);
         return new Point(_loc5_,_loc6_);
      }
      
      public static function transformRect(param1:Point, param2:Point, param3:Point, param4:Point, param5:int, param6:int) : void
      {
         param1.x = param1.x + param5;
         param1.y = param1.y + param6;
         param2.x = param2.x + param5;
         param2.y = param2.y + param6;
         param3.x = param3.x + param5;
         param3.y = param3.y + param6;
         param4.x = param4.x + param5;
         param4.y = param4.y + param6;
      }
      
      public static function cutTwoPoint(param1:Point, param2:Point, param3:int) : Array
      {
         var _loc7_:* = 0;
         var _loc8_:* = 0;
         var _loc9_:Array = null;
         var _loc10_:Point = null;
         var _loc11_:* = 0;
         var _loc4_:Number = getTwoPointDistance(param1,param2);
         var _loc5_:* = param3 << 1;
         var _loc6_:Point = new Point();
         if(_loc4_ > _loc5_)
         {
            _loc7_ = Math.ceil(_loc4_ / _loc5_);
            _loc8_ = getTwoPointAngle(param1,param2);
            _loc6_.x = Math.round(_loc5_ * cos(_loc8_));
            _loc6_.y = Math.round(_loc5_ * sin(_loc8_));
            _loc9_ = new Array();
            _loc10_ = param1.clone();
            _loc11_ = 0;
            while(_loc11_ < _loc7_)
            {
               _loc9_[_loc11_] = _loc10_;
               _loc10_ = _loc10_.add(_loc6_);
               _loc11_++;
            }
            return _loc9_;
         }
         return [param1];
      }
      
      public static function getLastInsertPoint(param1:Point, param2:Point, param3:int) : Point
      {
         var _loc7_:* = 0;
         var _loc8_:* = 0;
         var _loc4_:Number = getTwoPointDistance(param1,param2);
         var _loc5_:int = param3 * 2;
         var _loc6_:Point = new Point();
         if(_loc4_ > _loc5_)
         {
            _loc7_ = Math.ceil(_loc4_ / _loc5_) - 1;
            _loc8_ = getTwoPointAngle(param1,param2);
            _loc6_.x = _loc7_ * _loc5_ * cos(_loc8_);
            _loc6_.y = _loc7_ * _loc5_ * sin(_loc8_);
            return param1.add(_loc6_);
         }
         return param1;
      }
      
      public static function getCrossAngle(param1:int, param2:int) : int
      {
         var _loc3_:* = 0;
         if(param1 == param2)
         {
            return 0;
         }
         if(param1 >= 360)
         {
            param1 = param1 - 360;
         }
         else if(param1 < 0)
         {
            param1 = param1 + 360;
         }
         if(param2 >= 360)
         {
            param2 = param2 - 360;
         }
         else if(param2 < 0)
         {
            param2 = param2 + 360;
         }
         if(param1 < param2)
         {
            _loc3_ = param2 - param1;
            if(_loc3_ > 180)
            {
               _loc3_ = 360 - _loc3_;
               return -_loc3_;
            }
            return _loc3_;
         }
         _loc3_ = param1 - param2;
         if(_loc3_ > 180)
         {
            _loc3_ = 360 - _loc3_;
            return _loc3_;
         }
         return -_loc3_;
      }
      
      public static function distance(param1:*, param2:*) : Number
      {
         return Math.sqrt(Math.pow(param1.x - param2.x,2) + Math.pow(param1.y - param2.y,2));
      }
      
      public static function arabicToChinese(param1:uint) : String
      {
         var _loc2_:Array = ["〇","一","二","三","四","五","六","七","八","九","十"];
         return _loc2_[param1];
      }
      
      public static function toMoneyText(param1:Number, param2:Boolean = false) : String
      {
         var _loc3_:uint = 0;
         if(param1 == 0)
         {
            return "0";
         }
         var _loc4_:* = "";
         var _loc5_:int = param2?10000:100000;
         if(int(param1 / 100000000) > 0)
         {
            _loc3_ = param1 / 100000000;
            _loc4_ = _loc3_ + "亿";
         }
         else if(int(param1 / _loc5_) > 0)
         {
            _loc3_ = param1 / 10000;
            _loc4_ = _loc3_ + "万";
         }
         else
         {
            _loc4_ = param1 + "";
         }
         return _loc4_;
      }
      
      public static function digital2Str(param1:Number, param2:int = 3) : String
      {
         var _loc3_:int = param1;
         var _loc4_:Number = param1 - _loc3_;
         param2 = CMath.clampi(param2,0,5);
         if(param2 == 0)
         {
            return _loc3_.toString();
         }
         var _loc5_:int = Math.pow(10,param2);
         var _loc6_:int = _loc4_ * _loc5_;
         if(_loc6_ == 0)
         {
            return _loc3_.toString();
         }
         var _loc7_:* = 10;
         var _loc8_:* = 0;
         while(_loc8_ < param2)
         {
            if(_loc6_ % _loc7_ > 0)
            {
               return param1.toFixed(param2 - _loc8_);
            }
            _loc7_ = _loc7_ * 10;
            _loc8_++;
         }
         return param1.toFixed(0);
      }
      
      public static function digital2FixStr(param1:Number, param2:int, param3:int = 3) : String
      {
         var _loc4_:String = digital2Str(param1,param3);
         while(_loc4_.length < param2)
         {
            _loc4_ = _loc4_ + " ";
         }
         return _loc4_;
      }
      
      public static function toNumList(param1:uint) : Array
      {
         var _loc2_:Array = [];
         while(param1 > 10)
         {
            _loc2_.unshift(param1 % 10);
            param1 = Math.floor(param1 / 10);
         }
         _loc2_.unshift(param1);
         return _loc2_;
      }
      
      public static function getNextPowerOfTwo(param1:uint, param2:Boolean = true) : uint
      {
         if(param2 && CanUseRawSizeTexture)
         {
            return param1;
         }
         param1--;
         param1 = param1 | param1 >> 1;
         param1 = param1 | param1 >> 2;
         param1 = param1 | param1 >> 4;
         param1 = param1 | param1 >> 8;
         param1 = param1 | param1 >> 16;
         param1++;
         return param1;
      }
   }
}
