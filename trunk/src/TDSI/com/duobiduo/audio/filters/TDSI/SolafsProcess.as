package com.duobiduo.audio.filters.TDSI 
{
	import com.duobiduo.audio.filters.TDSI.MemoryAgent;
	import com.joa_ebert.apparat.memory.Memory;
	import flash.utils.ByteArray;
	/**
	 *  //   Y is X scaled to run F x faster.  X is added-in in windows
	 *  //   _winSize pts long, overlapping by Wov points with the previous output.  
	 *	//   The similarity is calculated over the last Wsim points of output.
	 *	//   Maximum similarity skew is Kmax pts.
	 *	//   Each xcorr calculation is decimated by xdecim (8)
	 *	//   The skew axis sampling is decimated by kdecim (2)
	 *	//   Defaults (for 22k) _winSize = 200, Wov = _winSize/2, Kmax = 2*_winSize, Wsim=Wov.
	 *	//   Based on "The SOLAFS time-scale modification algorithm", 
	 *	//   Don Hejna & Bruce Musicus, BBN, July 1991.
	 *	//   1997may16 dpwe@icsi.berkeley.edu $Header: /homes/dpwe/matlab/dpwebox/RCS/solafs.m,v 1.3 2006/04/09 20:10:20 dpwe Exp $
	 *	//   2006-04-08: fix to predicted step size, thanks to Andreas Tsiartas
	 ** @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class SolafsProcess
	{
		
		private static const MAX_SAMPLES:uint = 8192;

		private static const WOV:uint = 100;
		private static const KMAX:uint = 200;
		private static const WSIM:uint = 100;


		
		private var _outSamples:uint;//每次处理后输出采样长度
		
		private static var $inited:Boolean=false;
		private static var $xfwin:MemoryAgent;	//三角形交叉窗口

		private static var $ysim:MemoryAgent;
		private static var $rxy:MemoryAgent;
		private static var $rxx:MemoryAgent;
		private static var $xsim:MemoryAgent;
		private static var $Rxy:MemoryAgent;

		//输入输出
        private static var $outL:MemoryAgent;//左声道输出
		private static var $outR:MemoryAgent;//右声道输出利用左声道判断结果
		
		private static var $inL:MemoryAgent;//左声道输入
		private static var $inR:MemoryAgent;//右声道输入
		
		private static var $input:MemoryAgent;
		private static var $output:MemoryAgent;		
        
		private var _input:MemoryAgent;
		private var _zeroMemAgent:MemoryAgent;
		
		//实例缓存，每个实例需要缓存不同的中间数据
		private var _km:uint = 0;

        private var _lastOvL:MemoryAgent;//末次输出缓存
        private var _lastOvR:MemoryAgent;//末次输出缓存

		
		/** 
		 * 
		 * @param	outSamples
		 * @param	quality 声音处理效果质量，从1-8档，8档最高
		 */
		public function SolafsProcess(outSamples:uint=4096)
		{
			init(outSamples);
			$inited = true;
		}
		private function init(outSamples:uint):void
		{
			if (!$inited)
			{
				// Cross-fade win is Wov pts long - it grows
				// 交叉消隐窗口，具有Wov个点的长度
				$xfwin = new MemoryAgent(WOV);
				for (var i:uint = 0; i < WOV;++i)
				{
					Memory.writeFloat((i + 1) / (WOV + 1), $xfwin.pos + (i << 2));
				}
				
				
				$ysim = new MemoryAgent(WSIM);
				$xsim = new MemoryAgent(WSIM);
				$Rxy = new MemoryAgent(WSIM);	
				$rxy = new MemoryAgent(KMAX);
				$rxx = new MemoryAgent(KMAX);
				
				$outL = new MemoryAgent(MAX_SAMPLES);//左声道输出
				$outR = new MemoryAgent(MAX_SAMPLES);//右声道输出利用左声道判断结果
				
				$inL = new MemoryAgent(MAX_SAMPLES + KMAX);//左声道输入
				$inR = new MemoryAgent(MAX_SAMPLES + KMAX);//右声道输入
				
				$input = new MemoryAgent((MAX_SAMPLES + KMAX) * 2);
				$output = new MemoryAgent(MAX_SAMPLES * 2);		
			
			}
			_outSamples = outSamples;
			_input = $input;
			_zeroMemAgent = new MemoryAgent(0);
			//缓存末次数据用于下次重叠
			_lastOvL = new MemoryAgent(WOV);
			_lastOvR = new MemoryAgent(WOV);
		}
		
		public function dispose():void
		{
			_zeroMemAgent.dispose();
			_lastOvL.dispose();
			_lastOvR.dispose();
		}
		
		/**
		 * Get input memory entry point
		 * @return position of input memory buffer.
		 */
		public function get entryPosition():int
		{
			_input = $input;
			return $input.pos;
		}
		public function set entryPosition(value:int):void
		{
			_input = _zeroMemAgent;
			_input.pos = value;
		}
		/**
		 * 扩展读取窗口以便适应速度小于1.1的搜索窗口
		 * @return 扩展窗口大小
		 */
		public function getAddmax():uint
		{
			return _outSamples + KMAX;// 2248;
		}
		public function process(bytes:ByteArray = null):int
		{
			if (bytes == null)
			{
				processMain();
			}
			else
			{
				var i:int = 0;
				var value:Number;
				var pos:int = bytes.position;
				while (i <getAddmax())
				{
					value = bytes.readDouble();
					Memory.writeDouble( value , _input.pos + (i << 3));
					++i;
				}
				processMain();
				bytes.position = pos;
				
				i = 0;
				while (i < _outSamples)
				{
					value = Memory.readFloat($outL.pos + (i << 2));
					bytes.writeFloat(value);
					value = Memory.readFloat($outR.pos + (i << 2));
					bytes.writeFloat(value);
					++i;
				}
				bytes.position = pos;
			}
			return $output.pos;
		}
		private function processMain():void
		{
			var i:int = 0;
			while (i < getAddmax())
			{
				Memory.writeFloat( Memory.readFloat(_input.pos + ((i*2) << 2)), $inL.pos + (i << 2));
				Memory.writeFloat( Memory.readFloat(_input.pos + ((i*2 + 1) << 2)), $inR.pos + (i << 2));
				++i;
			}
			processLeft($inL);
			processRight($inR);
			
			i = 0;
			while (i < _outSamples)
			{
				
				Memory.writeFloat( Memory.readFloat($outL.pos + (i << 2)), $output.pos + ((i*2) << 2));
				Memory.writeFloat( Memory.readFloat($outR.pos + (i << 2)), $output.pos + ((i*2 + 1) << 2));
				++i;
			}
			
		}
		/**
		 * Solafs算法主体
		 * 
		 * @param	vecInL 输入
		 */
		private function processLeft(vecInL:MemoryAgent):void
		{
            var i:uint;
			var res:Number=0;
			
			// Clear the $Rxy array
			for (i = 0; i < KMAX; i++)
			{
				Memory.writeFloat(0, $rxy.pos + (i << 2));
			}

			// 从输入中抽样检测点，并计算出rxx $rxy
			
			for (var k:uint = 0; k < KMAX; ++k)
			{
				for (i = 0; i < WSIM; i++)
				{
					Memory.writeFloat( Memory.readFloat( vecInL.pos + ((k + i) << 2)), $xsim.pos + (i << 2));
					Memory.writeFloat( Memory.readFloat($rxy.pos + (k << 2)) 
										+ Memory.readFloat(_lastOvL.pos + (i << 2)) * Memory.readFloat($xsim.pos + (i << 2))
										,$rxy.pos + (k << 2));
				}
				// norm2() result
				for (i = 0; i < WSIM; i++)
				{
					res += Memory.readFloat($xsim.pos + (i << 2)) * Memory.readFloat($xsim.pos + (i << 2));
				}
				res = Math.sqrt(res);
				Memory.writeFloat( res , $rxx.pos + (k << 2));
			}
			
			// Zero the pts where $rxx was zero
			// rxx等于零的地方为零，因为不能做除数
			for (i = 0; i < WSIM; i++) 
			{
				res = (Memory.readFloat($rxx.pos + (i << 2)) != 0) 
							? (Memory.readFloat($rxy.pos + (i << 2)) / Memory.readFloat($rxx.pos + (i << 2))) 
							: Memory.readFloat($rxy.pos + (i << 2));
				Memory.writeFloat(res, $Rxy.pos + (i << 2));
			}
								
			// Local max gives skew
			// 定位最大切入值
			var max:Number = -Infinity;
			for (i = 0; i < WSIM; i++)
			{
				if (Memory.readFloat($Rxy.pos+(i<<2)) > max)
				{
					max = Memory.readFloat($Rxy.pos + (i<<2));
					_km = i;
				}
			}
			
			//trace("true km",_km);
			///*哈哈，用模拟的km就不错*/
			//_km = Math.random() * 100;
			//trace("rand km",_km);

            // Cross-fade some points
            // 交叉部分点
            for (i = 0; i < WOV; i++)
            {
                //左声道
				res = (1 - Memory.readFloat($xfwin.pos + (i << 2))) * Memory.readFloat(_lastOvL.pos + (i << 2));
                res += Memory.readFloat($xfwin.pos + (i << 2)) * Memory.readFloat(vecInL.pos + ((_km+i) << 2));
				Memory.writeFloat(res, _lastOvL.pos + (i << 2));
				
			}
            // Add in remaining points
            // 加入剩余点
            var len:int = _outSamples-WOV;
            
            for (i = 0; i < len; i++)
            {
                Memory.writeFloat(Memory.readFloat(vecInL.pos + (( _km + WOV + i) << 2)), $outL.pos + ((i + WOV) << 2));
            }
            
			
			
			
            for (i = 0; i < WOV; i++)
            {
				//上次的保留的叠加部分写入本次输出的前面
				Memory.writeFloat( Memory.readFloat(_lastOvL.pos+(i<<2)), $outL.pos + (i << 2)); 
				//更新上次叠加部分
                Memory.writeFloat(Memory.readFloat( vecInL.pos + ( (_km + _outSamples + i) << 2)), _lastOvL.pos + (i << 2)); 
            }
			  
		}
		
		/**
		 * 快速处理数据，利用的是process计算过后的km位移。
		 * 当音频为差别不大的双声道，使用process处理完第一个声道，
		 * 便可以立刻使用quickProcess处理第二个声道。
		 * @param	vecInR 输入向量
		 * @return	输出向量
		 */
        private function processRight(vecInR:MemoryAgent):void
		{
			var len:uint;
			var i:uint;
			var res:Number=0;
			// Cross-fade some points
            // 交叉部分点
            len = WOV
            for (i = 0; i < len; i++)
            {
                //右声道
                res = (1 - Memory.readFloat($xfwin.pos + (i << 2))) * Memory.readFloat(_lastOvR.pos + (i << 2));
                res += Memory.readFloat($xfwin.pos + (i << 2)) * Memory.readFloat(vecInR.pos + ((_km+i) << 2));
				Memory.writeFloat(res, _lastOvR.pos + (i << 2));
            }
            // Add in remaining points
            // 加入剩余点
            len = _outSamples-WOV;
            
            for (i = 0; i < len; i++)
            {
               Memory.writeFloat(Memory.readFloat(vecInR.pos + (( _km + WOV + i) << 2)), $outR.pos + ((i + WOV) << 2));
            }

            for (i = 0; i < WOV; i++)
            {
				//上次的保留的叠加部分写入本次输出的前面
				Memory.writeFloat( Memory.readFloat(_lastOvR.pos+(i<<2)), $outR.pos + (i << 2)); 
				//更新上次叠加部分
                Memory.writeFloat(Memory.readFloat( vecInR.pos + ( (_km + _outSamples + i) << 2)), _lastOvR.pos + (i << 2)); 
            }
		}
    }
	
}