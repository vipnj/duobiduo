package com.duobiduo.audio.filters.bufferFilters
{
   
	import flash.utils.ByteArray;
public class PitchFilter //extends AbstractEffect
    {
        //private var _pitch:Number;				//音调调整值
        private var _stretchSamples:uint;		//
        private var _endIndex:uint;
        private var _startIndex:uint;
        private var _pitchValue:Number;				//音调调整值
        private var _procLen:uint;

        private var _leftMonoBuffer:Vector.<Number>;
        private var _rightMonoBuffer:Vector.<Number>;
  
		private var _stretchBuffer:Vector.<Number>;
        private var _spareBuffer:Vector.<Number>;

		private var _monoSamples:uint;
        private var _spareSamples:uint;

        private static const OVERLAP:uint = 1024;
        private static const MAX_STRETCH:Number = 1.75;
        private static const NUM_INTERPOLATION_POINTS:uint = 4;
        private static const TWO_PI:Number = 6.28319;
        private static const channels:uint = 2;

        private var _processSize:uint = 4096;
        private var _bufSize:uint = 2*_processSize;
        private var _spareSize:uint = MAX_STRETCH*_processSize;


		/**
		 * 
		 * @param	param1
		 */
        public function PitchFilter(pitch:Number = 1,processSize:uint=4096)
        {
            this.pitch = pitch;
			_processSize = processSize;
			_bufSize = 2*_processSize;
			_spareSize = MAX_STRETCH*_processSize;
            init();
        }

		public function get pitch():Number
		{
			return _pitchValue;
		}
		public function set pitch(value:Number):void
		{
			_pitchValue = value;
		}
		
        private function interpolate(bufOne:Vector.<Number>, bufTwo:Vector.<Number>, sizeOne:uint, sizeTwo:uint) : void
        {
            var k:Number = 0;
            var odds:Number = 0;
            var i:uint = 0;

            var j:uint = 0;

            var fix:int = 0;
            var step:Number = Number(sizeOne) / Number(sizeTwo);
            j = sizeOne - 1;
            bufTwo[0] = bufOne[0];
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
                bufTwo[i] = this.CubicInterpolate(bufOne, fix, odds);
                k = k + step;
                i = i + 1;
            }
        }

        private function clearMonoBuffers(buf:int) : void
        {
            var i:int;
            i = buf;
            while (i < _processSize)
            {
                
                _leftMonoBuffer[i] = 0;
                _rightMonoBuffer[i] = 0;
                i++;
            }
        }

        public function reset() : void
        {
            this.pitch=1;
        }

        private function init() : void
        {
            _monoSamples = _processSize;
            _spareSamples = uint(_monoSamples * MAX_STRETCH);
            _stretchBuffer = new Vector.<Number>(_bufSize, true);
            _spareBuffer = new Vector.<Number>(_spareSize, true);
            _leftMonoBuffer = new Vector.<Number>(_processSize, true);
            _rightMonoBuffer = new Vector.<Number>(_processSize, true);
        }


		/**
		 * 三次插值
		 * @param	param1
		 * @param	param2
		 * @param	param3
		 * @return
		 */
        private function CubicInterpolate(buf:Vector.<Number>, fix:uint, odds:Number) : Number
        {
            var a:Number = 0;
            var b:Number = 0;
            var c:Number = 0;
            var d:Number = 0;
            var e:Number = 0;
            e = odds * odds;
            a = buf[fix + 3] - buf[fix + 2] - buf[fix] + buf[(fix + 1)];
            b = buf[fix] - buf[(fix + 1)] - a;
            c = buf[fix + 2] - buf[fix];
            d = buf[(fix + 1)];
            return a * odds * e + b * e + c * odds + d;
        }
		
		public function process(bytes:ByteArray):void
		{
			var pos:uint = bytes.position;
			var input:Vector.<Number> = new Vector.<Number>(_bufSize, true);
			var i:int;
			//填充新采样
			for ( i = 0; i < _processSize; i++)
			{
				input[2 * i] = bytes.readFloat();
				input[2 * i + 1] = bytes.readFloat();
			}
			
			//执行变调处理
			processSamples(input, 0, _processSize);
			
			//内存归位，写入变调处理过的采样
			bytes.position = pos;
			for (i = 0; i < _processSize; i++)
			{
				bytes.writeFloat(input[2 * i]);
				bytes.writeFloat(input[2 * i + 1]);
			}
			//内存归位
			bytes.position = pos;
		}
		
        public function processSamples(source:Vector.<Number>, start:int, length:int) : void
        {
            //if (bypass)
            //{
                //return;
            //}
            if (_pitchValue == 1)
            {
                return;
            }
            _startIndex = start * channels;
            _endIndex = _startIndex + length * channels;
            if (_endIndex > source.length)
            {
                _endIndex = source.length;
            }
            length = _endIndex - _startIndex;
            _procLen = length / channels;
            if (_procLen < _processSize)
            {
                this.clearMonoBuffers(_procLen);
            }
            this.interleaved2Mono(source, _procLen < _processSize ? (length) : (_processSize * 2));
            _stretchSamples = uint(_monoSamples * _pitchValue);
            if (_pitchValue > MAX_STRETCH)
            {
                this.stretch(_leftMonoBuffer, _spareBuffer, _monoSamples, _spareSamples);
                this.stretch(_spareBuffer, _stretchBuffer, _spareSamples, _stretchSamples);
                this.interpolate(_stretchBuffer, _leftMonoBuffer, _stretchSamples, _monoSamples);
                this.stretch(_rightMonoBuffer, _spareBuffer, _monoSamples, _spareSamples);
                this.stretch(_spareBuffer, _stretchBuffer, _spareSamples, _stretchSamples);
                this.interpolate(_stretchBuffer, _rightMonoBuffer, _stretchSamples, _monoSamples);
            }
            else
            {
                this.stretch(_leftMonoBuffer, _stretchBuffer, _monoSamples, _stretchSamples);
                this.interpolate(_stretchBuffer, _leftMonoBuffer, _stretchSamples, _monoSamples);
                this.stretch(_rightMonoBuffer, _stretchBuffer, _monoSamples, _stretchSamples);
                this.interpolate(_stretchBuffer, _rightMonoBuffer, _stretchSamples, _monoSamples);
            }
            this.mono2Interleaved(source, _procLen < _processSize ? (length) : (_processSize * 2));
            if (_procLen <= _processSize)
            {
                return;
            }
            _startIndex = _startIndex + _processSize * 2;
            length = _endIndex - _startIndex;
            if (length / channels < _processSize)
            {
                this.clearMonoBuffers(length / channels);
            }
            this.interleaved2Mono(source, length);
            _stretchSamples = uint(_monoSamples * _pitchValue);
            if (_pitchValue > MAX_STRETCH)
            {
                this.stretch(_leftMonoBuffer, _spareBuffer, _monoSamples, _spareSamples);
                this.stretch(_spareBuffer, _stretchBuffer, _spareSamples, _stretchSamples);
                this.interpolate(_stretchBuffer, _leftMonoBuffer, _stretchSamples, _monoSamples);
                this.stretch(_rightMonoBuffer, _spareBuffer, _monoSamples, _spareSamples);
                this.stretch(_spareBuffer, _stretchBuffer, _spareSamples, _stretchSamples);
                this.interpolate(_stretchBuffer, _rightMonoBuffer, _stretchSamples, _monoSamples);
            }
            else
            {
                this.stretch(_leftMonoBuffer, _stretchBuffer, _monoSamples, _stretchSamples);
                this.interpolate(_stretchBuffer, _leftMonoBuffer, _stretchSamples, _monoSamples);
                this.stretch(_rightMonoBuffer, _stretchBuffer, _monoSamples, _stretchSamples);
                this.interpolate(_stretchBuffer, _rightMonoBuffer, _stretchSamples, _monoSamples);
            }
            this.mono2Interleaved(source, length);
            return;
        }

        //override public function clone() : AbstractEffect
        //{
            //var _loc_1:* = new PitchEffect(automationEnabled);
            //_loc_1.pitch.initFromClone(this.pitch);
            //return _loc_1;
        //}

        private function overlapSegements(bufOne:Vector.<Number>, bufTwo:Vector.<Number>, posOne:uint, posTwo:uint, overLap:uint) : void
        {
            var i:uint = 0;
            var win:Number = 0;
            var overLap2:uint = overLap * 2;
            while (i < overLap)
            {
                
                win = 0.5 * (1 - Math.cos(TWO_PI * (i + overLap) / Number(overLap2)));
                bufOne[posOne] = bufTwo[posTwo] * win + bufOne[posOne] * (1 - win);
                posOne = posOne + 1;
                posTwo = posTwo + 1;
                i = i + 1;
            }
            return;
        }
        
		private function stretch(sourceBuffer:Vector.<Number>, workBuffer:Vector.<Number>, sourceLen:uint, workLen:uint) : void
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
                workBuffer[pos] = sourceBuffer[srcIndex];
				pos++;
				srcIndex++;
            }

            srcIndex = 0;
            pos = 0;
            while (pos < skip)
            {
                workBuffer[pos] = sourceBuffer[srcIndex];
				pos++;
				srcIndex++;
            }
            this.overlapSegements(workBuffer, sourceBuffer, pos, srcIndex, overLap);
        }

        //override public function toString() : String
        //{
            //var _loc_1:* = super.toString();
            //_loc_1 = _loc_1 + "\n";
            //_loc_1 = _loc_1 + "[Pitch]";
            //return _loc_1;
        //}

		/**
		 * 将左右独立buffer里的采样合并到交错采样vector里
		 * @param	sampleVector
		 * @param	vectorLength
		 */
        private function mono2Interleaved(sampleVector:Vector.<Number>, vectorLength:int) : void
        {
            var sampleLength:int;
            var sampleIdx:int;
            var idx:uint = _startIndex;
            sampleLength = vectorLength / channels;
            sampleIdx = 0;
            while (sampleIdx < sampleLength)
            {
                
                sampleVector[idx] = _leftMonoBuffer[sampleIdx];
                sampleVector[idx + 1] = _rightMonoBuffer[sampleIdx];
                idx = idx + 2;
                sampleIdx++;
            }   
        }

		/**
		 * 将交错采样vector左右分离切分到独立buffer里
		 * @param	sampleVector
		 * @param	vectorLength
		 */
        private function interleaved2Mono(sampleVector:Vector.<Number>, vectorLength:int) : void
        {
            var sampleLength:int;
            var sampleIdx:int;
            var idx:uint = _startIndex;
            sampleLength = vectorLength / channels;
            sampleIdx = 0;
            while (sampleIdx < sampleLength)
            {
                
                _leftMonoBuffer[sampleIdx] = sampleVector[idx];
                _rightMonoBuffer[sampleIdx] = sampleVector[idx + 1];
                idx = idx + 2;
                sampleIdx++;
            }
        }

    }
}
