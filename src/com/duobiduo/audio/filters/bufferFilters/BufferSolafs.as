package com.duobiduo.audio.filters.bufferFilters 
{
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class BufferSolafs 
	{
		
		public function BufferSolafs() 
		{
			
		}
		private function b2v(bytes:ByteArray, vecLeft:Vector.<Number>, vecRight:Vector.<Number>):void
		{
			var len:uint = bytes.length >> 3;
			bytes.position = 0;
			
			vecLeft.length = vecRight.length = len;
			for (var i:uint = 0; i < len; i++)
			{
				vecLeft[i] = bytes.readFloat();
				vecRight[i] = bytes.readFloat();
			}
			
		}
		private function v2b(vecLeft:Vector.<Number>, vecRight:Vector.<Number>, bytes:ByteArray):void
		{
			var len:uint = vecLeft.length;
			bytes.length = len << 3;
			bytes.position = 0;
			
			for (var i:uint = 0; i < len; i++)
			{
				bytes.writeFloat(vecLeft[i]);
				bytes.writeFloat(vecRight[i]);
			}
			
		}
		private function fillAudioBuffer():uint 
		{   
			
			
			var extracted:uint = 0;
			var isEnd:uint = 0;
			var tempSamples:ByteArray = new ByteArray();
			var sample:Sample = new Sample();
			
			//buffer归零
			_audioBuffer.length = 0;
			_audioBuffer.position = 0;
			
			if ( _speed == 1 )
			{
				
				//完整提取
				extracted = _sound.extract(tempSamples, SAMPLES_LENGTH, _samplePos );
				
				//更新采样位置
				_samplePos += extracted;
				
				tempSamples.position = 0;
				while (tempSamples.bytesAvailable>0)
				{
					
					sample.from(tempSamples);
					//写入buffer
					_audioBuffer.writeFloat(sample.left);
					_audioBuffer.writeFloat(sample.right);
				}
				//如果数据不够采样长度，就是结尾
				isEnd = SAMPLES_LENGTH - extracted ;
			}
			else if ( _speed > 1 )
			{
	//-----------------solafs算法-----------------
				const SS:uint = SAMPLES_LENGTH;
				const WOV:uint = 100,  KMAX:uint = 200, WSIM:uint = 100, XDEC:uint = 8, KDEC:uint = 2;
				const W:uint = SS + Wov;
				var Sa:uint = SS * _speed;
				var vecInL:Vector.<Number> = new Vector.<Number>();
				var vecInR:Vector.<Number> = new Vector.<Number>();
				var vecOutL:Vector.<Number> = new Vector.<Number>();
				var vecOutR:Vector.<Number> = new Vector.<Number>();
				
				//提取分析所需数据
				extracted = _sound.extract(tempSamples, Sa, _samplePos );
				
				//字节转向量
				b2v(tempSamples, vecInL, vecInR);
				
				//更新采样位置
				_samplePos += extracted;
				
				//进行solafs处理
				process
				
				//结果向量转字节
				v2b(vecOutL, vecOutR, tempSamples);
				tempSamples.position = 0;
				while (tempSamples.bytesAvailable>0)
				{
					
					sample.from(tempSamples);
					//写入buffer
					_audioBuffer.writeFloat(sample.left);
					_audioBuffer.writeFloat(sample.right);
				}
				
				//如果数据不够采样长度，就是结尾
				isEnd = Sa - extracted;
	//--------------------旧的算法--------------
				//丢弃的采样
				//_samplePos += SAMPLES_LENGTH * (_speed - 1);
				
				//播放的采样
				//extracted = _sound.extract(tempSamples, SAMPLES_LENGTH, _samplePos );
				
				//更新采样位置
				//_samplePos += extracted;
				
				//tempSamples.position = 0;
				//while (tempSamples.bytesAvailable>0)
				//{
					//
					//sample.from(tempSamples);
					//写入buffer
					//_audioBuffer.writeFloat(sample.left);
					//_audioBuffer.writeFloat(sample.right);
				//}
				
				//如果数据不够采样长度，就是结尾
				//isEnd = SAMPLES_LENGTH - extracted;
			}
			else//调慢速度播放
			{
				
				//需填充samlpeData长度，单位是byte
				var remain:uint = SAMPLES_LENGTH << 3;
				//暂时取样长度，单位是sample
				var tempLen:Number = SAMPLES_LENGTH * _speed;
				//抽取采样
				extracted = _sound.extract(tempSamples, tempLen, _samplePos );
				_samplePos += extracted;
				isEnd = uint(tempLen) - extracted;
				
				////////填充采样
				
				while (remain >= tempSamples.length)
				{
					
					remain -= tempSamples.length;
					tempSamples.position = 0 ;
					
					while (tempSamples.bytesAvailable>0)
					{
						
						sample.from(tempSamples);
						//写入buffer
						_audioBuffer.writeFloat(sample.left);
						_audioBuffer.writeFloat(sample.right);
					}
					
				}
				
				if (remain>0)
				{
					tempSamples.position = 0 ;
					while (remain>0)
					{
						
						sample.from(tempSamples);
						//写入buffer
						_audioBuffer.writeFloat(sample.left);
						_audioBuffer.writeFloat(sample.right);
						remain-=8;
					}
				}
				
			}
			
			if (isEnd>0)
			{
				
				if (loops == 1)//只播放一次
				{
					this.stop();
				}
				else if(_loops > 1)
				{
					_loops--;
					//开始循环播放,定位提取位置,需填充sampleData
					tempSamples.length = 0;
					//补齐buffer
					extracted = _sound.extract(tempSamples, isEnd, _startPosition);
					_samplePos = _startPosition + extracted;
					tempSamples.position = 0 ;
					while (isEnd>0)
					{
						
						sample.from(tempSamples);
						//写入buffer
						_audioBuffer.writeFloat(sample.left);
						_audioBuffer.writeFloat(sample.right);
						isEnd--;
					}
				}
				else if (_loops == 0)
				{
					//开始循环播放,定位提取位置,需填充sampleData
					tempSamples.length = 0;
					//补齐buffer
					extracted = _sound.extract(tempSamples, isEnd, _startPosition);
					_samplePos = _startPosition + extracted;
					tempSamples.position = 0 ;
					while (isEnd>0)
					{
						
						sample.from(tempSamples);
						//写入buffer
						_audioBuffer.writeFloat(sample.left);
						_audioBuffer.writeFloat(sample.right);
						isEnd--;
					}	
				}
			}
			tempSamples.clear();
			return _samplePos;
		}
		
	}
	
}