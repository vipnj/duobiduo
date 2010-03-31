package com.duobiduo.audio.filters.TDSI
{
   
	import com.joa_ebert.apparat.memory.*;
	import flash.utils.ByteArray;
	import com.joa_ebert.apparat.memory.Memory;
	import com.duobiduo.audio.filters.TDSI.MemoryAgent;
    public class PitchFilter 
    {
		private var _pitchValue:Number;					//变调值
		
		//以下全部静态变量。因为flash没有多线程，因此线程安全。可供多个实例共享。
        private static var $stretchSamples:uint;		//伸长采样数
        private static var $endIndex:uint;				
        private static var $startIndex:uint;

        private static var $leftMonoBuffer:MemoryAgent;
        private static var $rightMonoBuffer:MemoryAgent;
		
		private static var $leftTempBuffer:MemoryAgent;
        private static var $rightTempBuffer:MemoryAgent;
		
		private static var $stretchBuffer:MemoryAgent;
        private static var $spareBuffer:MemoryAgent;
		private static var $input:MemoryAgent;
		private static var $xfwin:MemoryAgent;
		
		private static var $inited:Boolean = false;
		
		private static const MAX_SAMPLES:uint = 8192;
        private static const OVERLAP:uint = 1024;
        private static const MAX_STRETCH:Number = 1.75;
        private static const NUM_INTERPOLATION_POINTS:uint = 4;
        private static const TWO_PI:Number = 6.28319;
        private static const channels:uint = 2;

        private var _processSize:uint;
		private var _outSize:uint;
        private var _bufSize:uint;
        private var _spareSize:uint;
		private var _monoSamples:uint;
        private var _spareSamples:uint;
		private var _input:MemoryAgent;
		private var _zeroMemAgent:MemoryAgent;
		private static var $address:int;
		private static var $value:Number;
		
		private static const WOV_LAST:int = 100;
		private static const WOV_NEW:int = WOV_LAST * 2;
		private var _currentKm:int;
		private var _newL:MemoryAgent;
		private var _newR:MemoryAgent;
		private var _lastL:MemoryAgent;
		private var _lastR:MemoryAgent;
		
		/**
		 * Nonoverlap Psola Filter
		 * 非叠加PSola算法。滤镜
		 * @param	pitch	initialized pitch value.
		 * 					初始音调值。
		 * @param	processSize	Number of samples should be processed each time.	
		 * 					一次处理采样长度。
		 */
        public function PitchFilter(pitch:Number = 1,outSize:uint=4096)
        {
            this.pitch = pitch;
			init(outSize);
        }

		/**
		 * current pitch scaled value.
		 */
		public function get pitch():Number
		{
			return _pitchValue;
		}
		public function set pitch(value:Number):void
		{
			_pitchValue = value;
		}

		/**
		 * reset pitch to normal
		 */
        public function reset() : void
        {
            this.pitch=1;
        }

		/**
		 * global initialization method. Can't be called multi-times. First constructor calls this.
		 * 全局初始化变调算法，不能多次调用。由第一次构造函数默认调用。
		 * @param	processSize	Number of samples should be processed each time.
		 */
        private function init(outSize:uint) : void
        {
			if ( !$inited )
			{
				_processSize = MAX_SAMPLES + WOV_NEW;
				_bufSize = 2*_processSize;
				_spareSize = MAX_STRETCH * _processSize;
				
				_monoSamples = _processSize;
				_spareSamples = uint(_monoSamples * MAX_STRETCH);

				$stretchBuffer = new MemoryAgent(_bufSize);

				$spareBuffer = new MemoryAgent(_spareSize);

				$leftMonoBuffer = new MemoryAgent(_processSize);

				$rightMonoBuffer = new MemoryAgent(_processSize);
				
				$leftTempBuffer = new MemoryAgent(_processSize);

				$rightTempBuffer = new MemoryAgent(_processSize);

				$input = new MemoryAgent(_bufSize);
				
				$xfwin = new MemoryAgent(WOV_LAST);
				
				for (var i:uint = 0; i < WOV_LAST;++i)
				{
					Memory.writeFloat((i + 1) / (WOV_LAST + 1), $xfwin.pos + (i << 2));
				}
				
				$inited = true;
			}
			
			//实例变量
			_outSize = outSize;
			_processSize = _outSize + WOV_NEW;
			_bufSize = 2*_processSize;
			_spareSize = MAX_STRETCH * _processSize;
			_monoSamples = _processSize;
			_spareSamples = uint(_monoSamples * MAX_STRETCH);
			_input = $input;
			_zeroMemAgent = new MemoryAgent(0);
			
			_newL = new MemoryAgent(WOV_NEW);
			_newR = new MemoryAgent(WOV_NEW);
			_lastL = new MemoryAgent(WOV_LAST);
			_lastR = new MemoryAgent(WOV_LAST);
			
			_currentKm = 0;
        }
		
		public function dispose():void
		{
			_zeroMemAgent.dispose();			
			_newL.dispose();
			_newR.dispose();
			_lastL.dispose();
			_lastR.dispose();
		}
		/**
		 * Process samples of the applied Filter.
		 * 滤镜处理采样
		 * @param	bytes input samples. If bytes set to null, Filter will process the 
		 * 			internal input cache after you fill datas into the position which 
		 * 			can be retrieved by getMemEntry().
		 * 			输入采样，如果使用空值，你需要先调用getMemEntry()获得内部缓存地址，
		 * 			并填充数据。然后滤镜就处理内部输入缓存。
		 * @return	index of the output bytes if the input bytes is set to null. 
		 * 			If the input bytes is specified, the output will rewrite into bytes, 
		 * 			and the return value will be -1.
		 * 			如果输入为空，则返回滤镜处理过的采样的内部缓存地址。
		 * 			如果输入不为空，则返回-1，处理过的采样被回写到输入bytes。
		 * 			
		 */
		public function process(bytes:ByteArray=null):int
		{

			if (null == bytes)
			{
				//执行变调处理
				processMain(0, _processSize);
			}
			else
			{
				var pos:uint = bytes.position;
				
				var i:int;
				//填充新采样
				for ( i = 0; i < _outSize; i++)
				{
					
					$value = bytes.readFloat();
					Memory.writeFloat($value, _input.pos + ((2 * i) << 2));

					$value = bytes.readFloat();
					Memory.writeFloat($value, _input.pos + ((2 * i + 1) <<2));
				}
				
				//执行变调处理
				processMain(0, _processSize);
				
				//内存归位，写入变调处理过的采样
				bytes.position = pos;
				for (i = 0; i < _outSize; i++)
				{
					bytes.writeFloat(Memory.readFloat(_input.pos + ((2 * i)<<2)));
					bytes.writeFloat(Memory.readFloat(_input.pos + ((2 * i + 1)<<2)));
				}
				//内存归位
				bytes.position = pos;
				
			}
			return _input.pos;
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
		
        //override public function clone() : AbstractEffect
        //{
            //var _loc_1:* = new PitchEffect(automationEnabled);
            //_loc_1.pitch.initFromClone(this.pitch);
            //return _loc_1;
        //}
		
        //override public function toString() : String
        //{
            //var _loc_1:* = super.toString();
            //_loc_1 = _loc_1 + "\n";
            //_loc_1 = _loc_1 + "[Pitch]";
            //return _loc_1;
        //}
		
        private function processMain(start:int, length:int) : void
        {
            //if (bypass)
            //{
                //return;
            //}
			var procLen:uint;
            if (_pitchValue == 1)
            {
                return;
            }
            $startIndex = start * channels;
            $endIndex = $startIndex + length * channels;
            if ($endIndex > _bufSize)
            {
                $endIndex = _bufSize;
            }
            length = $endIndex - $startIndex;
            procLen = length / channels;
            if (procLen < _processSize)
            {
                this.clearBuffers(procLen);
            }
            this.zipOpen(procLen < _processSize ? (length) : (_processSize * 2));
			
			/*缓存新数据*/
			this.cacheNew();
			
            
			$stretchSamples = uint(_monoSamples * _pitchValue);
            if (_pitchValue > MAX_STRETCH)
            {
                this.stretch($leftMonoBuffer, $spareBuffer, _monoSamples, _spareSamples);
                this.stretch($spareBuffer, $stretchBuffer, _spareSamples, $stretchSamples);
                this.interpolate($stretchBuffer, $leftMonoBuffer, $stretchSamples, _monoSamples);
                this.stretch($rightMonoBuffer, $spareBuffer, _monoSamples, _spareSamples);
                this.stretch($spareBuffer, $stretchBuffer, _spareSamples, $stretchSamples);
                this.interpolate($stretchBuffer, $rightMonoBuffer, $stretchSamples, _monoSamples);
            }
            else
            {
                this.stretch($leftMonoBuffer, $stretchBuffer, _monoSamples, $stretchSamples);
                this.interpolate($stretchBuffer, $leftMonoBuffer, $stretchSamples, _monoSamples);
                this.stretch($rightMonoBuffer, $stretchBuffer, _monoSamples, $stretchSamples);
                this.interpolate($stretchBuffer, $rightMonoBuffer, $stretchSamples, _monoSamples);
            }
			if (procLen <= _processSize)
            {
				/*间隙重叠处理*/
				this.eraseGap();
			}
            this.zipClose(procLen < _processSize ? (length) : (_processSize * 2));
            if (procLen <= _processSize)
            {
                return;
            }
            $startIndex = $startIndex + _processSize * 2;
            length = $endIndex - $startIndex;
            if (length / channels < _processSize)
            {
                this.clearBuffers(length / channels);
            }
            this.zipOpen(length);
            $stretchSamples = uint(_monoSamples * _pitchValue);
            if (_pitchValue > MAX_STRETCH)
            {
                this.stretch($leftMonoBuffer, $spareBuffer, _monoSamples, _spareSamples);
                this.stretch($spareBuffer, $stretchBuffer, _spareSamples, $stretchSamples);
                this.interpolate($stretchBuffer, $leftMonoBuffer, $stretchSamples, _monoSamples);
                this.stretch($rightMonoBuffer, $spareBuffer, _monoSamples, _spareSamples);
                this.stretch($spareBuffer, $stretchBuffer, _spareSamples, $stretchSamples);
                this.interpolate($stretchBuffer, $rightMonoBuffer, $stretchSamples, _monoSamples);
            }
            else
            {
                this.stretch($leftMonoBuffer, $stretchBuffer, _monoSamples, $stretchSamples);
                this.interpolate($stretchBuffer, $leftMonoBuffer, $stretchSamples, _monoSamples);
                this.stretch($rightMonoBuffer, $stretchBuffer, _monoSamples, $stretchSamples);
                this.interpolate($stretchBuffer, $rightMonoBuffer, $stretchSamples, _monoSamples);
            }
			
			/*间隙重叠处理*/
			this.eraseGap();
			
            this.zipClose(length);
			
			return;
        }

		private function cacheNew():void
		{
			var i:int;
			//移位，前面让出位置
			for ( i = _processSize-1; i >= WOV_NEW; i--)
			{
				Memory.writeFloat(Memory.readFloat($leftMonoBuffer.pos + ((i - WOV_NEW) << 2)), $leftMonoBuffer.pos + (i << 2));
				Memory.writeFloat(Memory.readFloat($rightMonoBuffer.pos + ((i - WOV_NEW) << 2)), $rightMonoBuffer.pos + (i << 2));
			}
			//放置上次未处理的新数据
			for ( i = 0; i < WOV_NEW; i++)
			{
				Memory.writeFloat(Memory.readFloat(_newL.pos + (i << 2)), $leftMonoBuffer.pos + (i << 2));
				Memory.writeFloat(Memory.readFloat(_newR.pos + (i << 2)), $rightMonoBuffer.pos + (i << 2));	
			}
			//缓存本次新数据
			for (i = 0; i < WOV_NEW; i++)
			{
				Memory.writeFloat(Memory.readFloat($leftMonoBuffer.pos + ((_processSize-WOV_NEW + i) << 2)), _newL.pos + (i << 2) );
				Memory.writeFloat(Memory.readFloat($rightMonoBuffer.pos + ((_processSize-WOV_NEW + i) << 2)), _newR.pos + (i << 2) );
			}
		}
		
		private function cacheLast():void
		{
			var i:int;
			
			for (i = 0; i<WOV_LAST; i++)
			{
				Memory.writeFloat(Memory.readFloat($leftMonoBuffer.pos + ((_outSize + i) << 2)), _lastL.pos + (i << 2));
				Memory.writeFloat(Memory.readFloat($rightMonoBuffer.pos + ((_outSize + i) << 2)), _lastR.pos + (i << 2));
			}
		}
		
		private function eraseGap():void
		{
			
			_currentKm = Math.random() * 100;
			//trace("erase Gap, _currentKm=",_currentKm);
			var i:int;
			var res:Number;
			
			// 交叉部分点
            for (i = 0; i < WOV_LAST; i++)
            {
                //左声道
				res = (1 - Memory.readFloat($xfwin.pos + (i << 2))) * Memory.readFloat(_lastL.pos + (i << 2));
                res += Memory.readFloat($xfwin.pos + (i << 2)) * Memory.readFloat($leftMonoBuffer.pos + ((_currentKm+i) << 2));
				Memory.writeFloat(res, _lastL.pos + (i << 2));
				
                //右声道
				res = (1 - Memory.readFloat($xfwin.pos + (i << 2))) * Memory.readFloat(_lastR.pos + (i << 2));
                res += Memory.readFloat($xfwin.pos + (i << 2)) * Memory.readFloat($rightMonoBuffer.pos + ((_currentKm+i) << 2));
				Memory.writeFloat(res, _lastR.pos + (i << 2));
			}
			// 加入剩余点
			for (i = WOV_LAST; i < _processSize; i++)
            {
                Memory.writeFloat(Memory.readFloat($leftMonoBuffer.pos + (( _currentKm + i) << 2)), $leftTempBuffer.pos + (i << 2));
				Memory.writeFloat(Memory.readFloat($rightMonoBuffer.pos + (( _currentKm + i) << 2)), $rightTempBuffer.pos + (i << 2));
            }
			
			//补充前面，更新叠加
			for (i = 0; i < WOV_LAST; i++)
            {
				//上次的保留的叠加部分写入本次输出的前面
				Memory.writeFloat( Memory.readFloat(_lastL.pos+(i<<2)), $leftTempBuffer.pos + (i << 2)); 
				//更新上次叠加部分
                Memory.writeFloat(Memory.readFloat( $leftMonoBuffer.pos + ( (_currentKm + _outSize + i) << 2)), _lastL.pos + (i << 2));
				
				//上次的保留的叠加部分写入本次输出的前面
				Memory.writeFloat( Memory.readFloat(_lastR.pos+(i<<2)), $rightTempBuffer.pos + (i << 2)); 
				//更新上次叠加部分
                Memory.writeFloat(Memory.readFloat( $rightMonoBuffer.pos + ( (_currentKm + _outSize + i) << 2)), _lastR.pos + (i << 2));
            }
			//复制到mono
			for (i = 0; i < _processSize; i++)
			{
				Memory.writeFloat(Memory.readFloat($leftTempBuffer.pos + (i << 2)), $leftMonoBuffer.pos + (i << 2));
				Memory.writeFloat(Memory.readFloat($rightTempBuffer.pos + (i << 2)), $rightMonoBuffer.pos + (i << 2));
			}
		}
		
        private function interpolate(bufOne:MemoryAgent, bufTwo:MemoryAgent, sizeOne:uint, sizeTwo:uint) : void
        {
            var k:Number = 0;
            var odds:Number = 0;
            var i:uint = 0;

            var j:uint = 0;

            var fix:int = 0;
            var step:Number = Number(sizeOne) / Number(sizeTwo);
            j = sizeOne - 1;
			
			Memory.writeFloat(Memory.readFloat(bufOne.pos),bufTwo.pos);
            k = step;
            i = 1;
            while (i < sizeTwo)
            {
                
                fix = uint(k);
                odds = k - fix;
                if (fix < 0)
                {
                    odds = odds - 1;
                    fix = 0;
                }
                else if (fix + NUM_INTERPOLATION_POINTS > j)
                {
                    odds = odds + 1;
                    fix = j - (NUM_INTERPOLATION_POINTS - 1);
                }

                Memory.writeFloat(this.CubicInterpolate(bufOne, fix, odds),bufTwo.pos + (i <<2));
                k = k + step;
                i = i + 1;
            }
        }

        private function clearBuffers(buf:int) : void
        {
            var i:int;
            i = buf;
            while (i < _processSize)
            {
               
                Memory.writeFloat(0, $leftMonoBuffer.pos + (i <<2) );
				
                Memory.writeFloat(0,$rightMonoBuffer.pos + (i <<2));
                i++;
            }
        }

		/**
		 * 三次插值
		 * @param	param1
		 * @param	param2
		 * @param	param3
		 * @return
		 */
        private function CubicInterpolate(buf:MemoryAgent, fix:uint, odds:Number) : Number
        {
            var a:Number = 0;
            var b:Number = 0;
            var c:Number = 0;
            var d:Number = 0;
            var e:Number = 0;
            e = odds * odds;
			var f3:int = (fix + 3) << 2;
			var f2:int = (fix + 2) << 2;
			var f1:int = (fix + 1) << 2;
			var f0:int = fix << 2;
            a = Memory.readFloat(buf.pos + f3) - Memory.readFloat(buf.pos + f2) - Memory.readFloat(buf.pos + f0) + Memory.readFloat(buf.pos + f1);
            b = Memory.readFloat(buf.pos + f0) - Memory.readFloat(buf.pos + f1) - a;
            c = Memory.readFloat(buf.pos + f2) - Memory.readFloat(buf.pos + f0);
            d = Memory.readFloat(buf.pos + f1);
            return a * odds * e + b * e + c * odds + d;
        }



        private function overlap(bufOne:MemoryAgent, bufTwo:MemoryAgent, posOne:uint, posTwo:uint, overLap:uint) : void
        {
            var i:uint = 0;
            var win:Number = 0;
            var overLap2:uint = overLap * 2;
            while (i < overLap)
            {
                
                win = 0.5 * (1 - Math.cos(TWO_PI * (i + overLap) / Number(overLap2)));
                Memory.writeFloat(Memory.readFloat(bufTwo.pos + (posTwo<<2)) * win + Memory.readFloat(bufOne.pos + (posOne<<2)) * (1 - win), bufOne.pos + (posOne<<2));
                posOne = posOne + 1;
                posTwo = posTwo + 1;
                i = i + 1;
            }
            return;
        }
        
		private function stretch(sourceBuffer:MemoryAgent, workBuffer:MemoryAgent, sourceLen:uint, workLen:uint) : void
        {
            var pos:uint;
            var srcIndex:uint;
            var fix:uint;
            var overLap:uint;
            var skip:uint;
            if (workLen > sourceLen)
            {
                skip = workLen - sourceLen;
                overLap = sourceLen - skip;
                srcIndex = 0;
            }
            else if (workLen < sourceLen)
            {
                skip = sourceLen / 2 - (sourceLen - workLen);
                srcIndex = sourceLen / 2;
                overLap = sourceLen - workLen;
                if (overLap < OVERLAP)
                {
                    fix = (OVERLAP - overLap) / 2;
                    srcIndex = srcIndex - fix;
                    skip = skip - fix;
                    overLap = OVERLAP;
                }
            }
            pos = skip;
            while (srcIndex < sourceLen)
            {
                Memory.writeFloat(Memory.readFloat(sourceBuffer.pos + (srcIndex<<2)), workBuffer.pos + (pos<<2));
				pos++;
				srcIndex++;
            }

            srcIndex = 0;
            pos = 0;
            while (pos < skip)
            {
                Memory.writeFloat(Memory.readFloat(sourceBuffer.pos + (srcIndex<<2)), workBuffer.pos + (pos<<2));
				pos++;
				srcIndex++;
            }
            this.overlap(workBuffer, sourceBuffer, pos, srcIndex, overLap);
        }


		/**
		 * 将左右独立buffer里的采样合并到交错采样vector里
		 * @param	sampleVector
		 * @param	vectorLength
		 */
        private function zipClose(vectorLength:int) : void
        {
            var sampleLength:int;
            var sampleIdx:int;
            var idx:uint = $startIndex;
            sampleLength = vectorLength / channels;
            sampleIdx = 0;
            while (sampleIdx < sampleLength)
            {
                
                Memory.writeFloat(Memory.readFloat($leftMonoBuffer.pos + (sampleIdx<<2)), _input.pos + (idx<<2));
                Memory.writeFloat(Memory.readFloat($rightMonoBuffer.pos + (sampleIdx<<2)), _input.pos + ((idx + 1)<<2));
                idx = idx + 2;
                sampleIdx++;
            }   
        }

		/**
		 * 将交错采样vector左右分离切分到独立buffer里
		 * @param	sampleVector
		 * @param	vectorLength
		 */
        private function zipOpen(vectorLength:int) : void
        {
            var sampleLength:int;
            var sampleIdx:int;
            var idx:uint = $startIndex;
            sampleLength = vectorLength / channels;
            sampleIdx = 0;
            while (sampleIdx < sampleLength)
            {
                
                Memory.writeFloat(Memory.readFloat(_input.pos + (idx<<2)), $leftMonoBuffer.pos + (sampleIdx<<2));
                Memory.writeFloat(Memory.readFloat(_input.pos + ((idx + 1)<<2)), $rightMonoBuffer.pos + (sampleIdx<<2));
                idx = idx + 2;
                sampleIdx++;
            }
        }

    }
}
