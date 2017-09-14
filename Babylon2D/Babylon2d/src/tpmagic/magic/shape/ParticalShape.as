package tpmagic.magic.shape
{
	import flash.geom.Point;
	
	import starling.animation.Juggler;
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.starling_internal;
	
	import tempest.utils.Geom;
	
	import tpmagic.magic.core.IEmitter;
	import tpmagic.magic.enum.ShapeType;
	import tpmagic.magic.partail.TPartical;

	use namespace starling_internal;

	/**
	 * 粒子矢量对象
	 * @author zhangyong
	 *
	 */
	public class ParticalShape implements IEmitter
	{
		/**是否已释放*/
		private var disposed:Boolean;
		/**缓动对象*/
		private var tween:Tween;
		/**是否交换值*/
		protected var swapValue:Boolean=false;
		/**过程时间*/
		protected var duration:Number=NaN;
		/**添加位置*/
		protected var place:int;
		/**发射完毕是否清除粒子*/
		public var isKill:Boolean=true;


		public function ParticalShape(swapValue:Boolean)
		{
			reset(swapValue);
		}

		/**
		 *发射粒子
		 *
		 */
		public function emitter(tp:TPartical, duration:Number):void
		{
			if (!tp.partical) //粒子被释放了
			{
				onComplete(tp);
				return;
			}
			place=tp.partical.config ? tp.partical.config.body_place : 0;
			if (duration != 0)
			{
				this.duration=duration;
			}
			if (this.swapValue)
			{
				var tempPoint:Point=null;
				tempPoint=tp.targetPoint.clone();
				tp.targetPoint=tp.position.clone();
				tp.position=tempPoint;
			}
			switch (tp.magicInfo.elementType)
			{
				case ShapeType.SHAPE_POINT:
					emitterPoint(tp);
					break;
				case ShapeType.SHAPE_LINE:
					emitterLine(tp);
					break;
				case ShapeType.SHAPE_LINK:
					emitterLink(tp);
					break;
				case ShapeType.SHAPE_TRACK_LINE:
					emitterTrackLine(tp);
					break;
			}
		}

		/**
		 * 发射点粒子
		 * @param tPartical
		 *
		 */
		private function emitterPoint(tPartical:TPartical):void
		{
			var lifeSpan:Number=tPartical.magicInfo.lifeSpan;
			if (lifeSpan != 0)
			{
				App.timer.doOnce(lifeSpan * 1000, onComplete, [tPartical]);
			}
			else
			{
				onComplete(tPartical);
			}
		}

		////////////////////////////////////////////////////////////////
		/**
		 *发射链粒子
		 * @param object
		 * @param rednerPoint
		 *
		 */
		protected function emitterLink(tPartical:TPartical):void
		{
			var lifeSpan:Number=tPartical.magicInfo.lifeSpan;
			var distance:Number=NaN;
			var scaleX:Number=NaN;
			if (tPartical.distance > 0)
			{
				distance=tPartical.distance;
			}
			else
			{
				distance=Geom.getDistance(tPartical.position, tPartical.targetPoint);
			}
			var _width:int=tPartical.partical.config.width; //取特效真实宽度拉伸
			if (_width == 0)
			{
				_width=440;
			}
			scaleX=distance / _width;
			if (scaleX > 0)
			{
				tPartical.partical.scaleX=scaleX; //_scale为其实体宽度 
				tPartical.partical.scaleY=1;
			}
			if (lifeSpan != 0)
			{
				App.timer.doOnce(lifeSpan * 1000, onComplete, [tPartical], false);
			}
			else
			{
				onComplete(tPartical);
			}
		}

		///////////////////////////////////////////////////////////////
		/**
		 *发射直线运动粒子
		 * @param speed
		 *
		 */
		protected function emitterLine(tPartical:TPartical):void
		{
			if (tPartical == null)
				return;
			var targetPoint:Point=tPartical.targetPoint;
			var _duration:Number;
			if (targetPoint == null)
			{
				onComplete(tPartical);
				return;
			}
			var distance:Number=NaN;
			if (this.duration > 0) //外部传入时间
			{
				_duration=this.duration;
			}
			else //根据魔法点计算时间
			{
				if (tPartical.distance > 0)
				{
					distance=tPartical.distance;
				}
				else
				{
					distance=Geom.getDistance(tPartical.position, tPartical.targetPoint);
				}
				var tempSpeed:int=tPartical.magicInfo.effect_movespeed;
				if (tempSpeed > 0)
				{
					_duration=(distance / tempSpeed);
				}
				else
				{
					_duration=(distance / 1000);
				}
			}
			if (distance != 0 && tPartical.partical && _duration > 0)
			{
				var ease:String=Transitions.LINEAR;
				if (tPartical.magicInfo.teaseIn != 0)
				{
					ease=Transitions.EASE_IN;
				}
				else if (tPartical.magicInfo.tweaseOut != 0)
				{
					ease=Transitions.EASE_IN_OUT;
				}
				tween=Juggler.instance.tween(tPartical, _duration, {pos_x: tPartical.targetPoint.x, pos_y: tPartical.targetPoint.y}) as Tween;
				tween.transition=ease;
				tween.onComplete=onComplete;
				tween.onCompleteArgs=[tPartical];
			}
			else
			{
				onComplete(tPartical);
			}
		}

		////////////////////////////////////////////////////////////////
		/**
		 *发射直线运动追踪粒子
		 * @param magicPoint
		 * @param speed
		 *
		 */
		protected function emitterTrackLine(tPartical:TPartical):void
		{
			var distance:Number=NaN;
			if (tPartical.targetPoint == null)
			{
				distance=0;
			}
			else
			{
				distance=Geom.getDistance(tPartical.position, tPartical.targetPoint);
			}
			var speed:Number=(distance / tPartical.magicInfo.effect_movespeed);
			if (distance != 0)
			{
				var ease:String=Transitions.LINEAR;
				if (tPartical.magicInfo.teaseIn != 0)
				{
					ease=Transitions.EASE_IN;
						//Sine.easeIn
				}
				else if (tPartical.magicInfo.tweaseOut != 0)
				{
					ease=Transitions.EASE_IN_OUT;
						//Sine.easeOut
				}
				var targetOffset:int=tPartical.targetPoint.y;
				if (place & 2)
				{ //身体位置
					targetOffset=tPartical.targetPoint.y - tPartical.body_offset;
				}
				tPartical.partical.rotation=Geom.GetRotation(tPartical.position, new Point(tPartical.targetPoint.x, targetOffset));
				tween=Juggler.instance.tween(tPartical, speed, {pos_x: tPartical.targetPoint.x, pos_y: tPartical.targetPoint.y}) as Tween;
				tween.transition=ease;
				tween.onComplete=onComplete;
				tween.onCompleteArgs=[tPartical];
				tween.onUpdate=onChange;
				tween.onUpdateArgs=[tPartical];
			}
			else
			{
				onComplete(tPartical);
			}
		}

		/**
		 * 运动完毕
		 * @param tPartical
		 *
		 */
		public function onComplete(tPartical:TPartical):void
		{
			if (tween)
			{
				tween=null;
			}
			tPartical.onHit();
		}

		/**
		 *追踪
		 * @param gt
		 * @param targetPoint
		 *
		 */
		private function onChange(tpartical:TPartical):void
		{
			if (tween && tpartical && tpartical.targetPoint)
			{
				var speed:int=tpartical.magicInfo.effect_movespeed;
				var targetOffset:int=tpartical.targetPoint.y;
				if (place & 2)
				{ //身体位置
					targetOffset=tpartical.targetPoint.y - tpartical.body_offset;
				}
				var tempPoint:Point=new Point(tpartical.targetPoint.x, targetOffset);
				tween.animate("pos_x", tempPoint.x);
				tween.animate("pos_y", tempPoint.y);
				tpartical.rotation=Geom.GetRotation(tpartical.position, tempPoint);
			}
		}

		/**粒子矢量池*/
		private static var _pool:Vector.<ParticalShape>=new Vector.<ParticalShape>();

		/**
		 * 获取
		 * @param swapValue
		 * @return
		 *
		 */
		public static function Get(swapValue:Boolean):ParticalShape
		{
			var ps:ParticalShape;
			if (_pool.length > 0)
			{
				ps=_pool.shift();
				ps.reset(swapValue);
			}
			else
			{
				ps=new ParticalShape(swapValue);
			}
			return ps;
		}

		/**
		 * 释放
		 * @param ps
		 *
		 */
		public static function free(ps:ParticalShape):void
		{
			if (!ps || ps.disposed)
			{
				return;
			}
			ps.dispose();
			_pool.push(ps);
		}


		/**
		 * 重置对象
		 * @param swapValue
		 *
		 */
		public function reset(swapValue:Boolean):void
		{
			duration=0;
			disposed=false;
			this.swapValue=swapValue;
		}

		/**
		 *释放粒子
		 *
		 */
		public function dispose():void
		{
			disposed=true;
			this.swapValue=false;
			this.tween=null;
			duration=0;
			place=0
			isKill=true;
		}
	}
}
