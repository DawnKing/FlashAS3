package easiest.utils
{
	import flash.globalization.DateTimeFormatter;
	
	
	/**
	 * 时间工具
	 * @author caijingxiao
	 * 
	 */
	public final class TimeUtil
	{
		/**
		 * 确定日期或时间格式时使用的首选区域设置 ID 名称。
		 */
		public static var localIDName:String = "zh-CN";
		
		public static const HH_MM_SS:String = "HH:mm:ss";
		public static const HH_MM:String = "HH:mm";
		public static const MM_SS:String = "mm:ss";
        public static const dd_HH_MM:String = "dd:HH:mm";
		
		/**
		 * 格式化时间戳
         * 用于服务器发来的时间，格式化成本地时间
         * 
		 * @param timestamp 时间戳，单位毫秒
		 * @param pattern 设置日期和时间格式所用的模式字符串。 
		 * @return 表示日期或时间值的设置了格式的字符串。 
		 */
		public static function formatTimestamp(timestamp:Number, pattern:String=HH_MM_SS, isUTC:Boolean=true):String
		{
			var date:Date = new Date(timestamp);
			var timeFormatter:DateTimeFormatter = new DateTimeFormatter(localIDName);
			timeFormatter.setDateTimePattern(pattern);
            if (isUTC)
                var timeStr:String = timeFormatter.formatUTC(date);
            else
                timeStr = timeFormatter.format(date);
			return timeStr;
		}
        
		/**
		 * 格式化秒
         * 用于格式化剩余时间，如剩余30秒，格式化成30：00
         * 
		 * @param second 秒
		 * @param pattern 设置日期和时间格式所用的模式字符串。 
		 * @return 表示日期或时间值的设置了格式的字符串。 
		 */
		public static function formatSecond(second:Number, pattern:String=HH_MM_SS, isUTC:Boolean=true):String
		{
			return formatTimestamp(second*1000, pattern, isUTC);
		}
        
        public static const SECOND_A_YEAR:int = 31536000;    //一年的秒数
        public static const DAY_SECOND:int = 86400;       //一天的秒数
        public static const HOUR_SECOND:int = 3600;        //一小时的秒数
        public static const MINUTE_SECOND:int = 60;          //一分钟的秒数
        
        public static const HOUR_MINUTE:int = 60;      //一小时的分钟数
        public static const DAY_MINUTE:int = 1440;    //一天的分钟数
        
        public static const YEAR_DAY:int =  365;      //一年的天数

		public static function formatSecond2YYMMDD(second:Number):String
		{
			var date:Date = new Date(second * 1000);
			var timeText:String = "";
			timeText = date.fullYear.toString() + "年" + int(date.month + 1).toString() + "月" + date.date.toString() + "日";
			return timeText;
		}
		
        public static function formatSecond2HHMMSS(second:Number):String
        {
            var timeText:String = "";
            var leftSecond:int = second;
            
            var hour:int = leftSecond / HOUR_SECOND;
            timeText += hour.toString() + ":";
            
            leftSecond %= HOUR_SECOND;
            
            var minute:int = leftSecond / MINUTE_SECOND;
            timeText += getTwoTimeText(minute) + ":";
            
            leftSecond %= MINUTE_SECOND;
            
            timeText += getTwoTimeText(leftSecond);
                
            return timeText;
        }
        
        public static function formatSecond2DDHHMM(second:Number, useTwoTime:Boolean=false):String
        {
			var textArr:Array = [];
            var leftSecond:int = second;
            var day:int = leftSecond / DAY_SECOND;
            var dayText:String = (useTwoTime) ? getTwoTimeText(day) : day.toString();
			dayText += "天";
            leftSecond %= DAY_SECOND;
            var hour:int = leftSecond / HOUR_SECOND;
			var hourText:String = (useTwoTime) ? getTwoTimeText(hour) : hour.toString();
			hourText += "小时";
			leftSecond %= HOUR_SECOND;
			var min:int = leftSecond / MINUTE_SECOND;
			var minText:String = (useTwoTime) ? getTwoTimeText(min) : min.toString();
			minText += "分钟";
			leftSecond %= MINUTE_SECOND;
			var secondText:String = (useTwoTime) ? getTwoTimeText(leftSecond) : leftSecond.toString();
			secondText += "秒";
			
			if(second >= DAY_SECOND)
			{
				textArr.push(dayText);
				textArr.push(hourText);
			}
			else if(second >= HOUR_SECOND)
			{
				textArr.push(hourText);
				textArr.push(minText);
			}
			else if(second >= MINUTE_SECOND)
			{
				textArr.push(minText);
				textArr.push(secondText);
			}
			else
			{
				textArr.push(secondText);
			}
            return textArr.join("");
        }
		
		public static function formartDesc(timeDesc:String):Number
		{
			var timeArr:Array = timeDesc.split(" ");
			var leftPart:Array = timeArr[0].split("-");
			var rightPart:Array = timeArr[1].split(":");
			var year:int = leftPart[0];
			var month:int = int(leftPart[1]) - 1;
			var day:int = leftPart[2];
			var hour:int = rightPart[0];
			var min:int = rightPart[1];
			var second:int = rightPart[2];
			var date:Date = new Date(year, month, day, hour, min, second);
			return (date.time / 1000);
		}
		
		public static function formartSecondDesc(second:Number):String
		{
			var result:String = "";
			if(second < MINUTE_SECOND)
			{
				result = second.toString() + "秒";
			}
			else if(second < HOUR_SECOND)
			{
				var min:int = second / MINUTE_SECOND;
				result = min.toString() + "分钟";
			}
			else if(second < DAY_SECOND)
			{
				var hour:int = second / HOUR_SECOND;
				result = hour.toString() + "小时";
			}
			else
			{
				var day:int = second / DAY_SECOND;
				result = day.toString() + "天";
			}
			return result;
		}
        
        public static function getTwoTimeText(time:int):String
        {
            if (time < 10)
                return "0" + time;
            return time.toString();
        }
        
	}
}