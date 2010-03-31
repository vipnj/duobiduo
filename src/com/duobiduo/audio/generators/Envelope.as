package com.duobiduo.audio.generators 
{
	import flash.utils.ByteArray;
	
	/**
	 * Envelope generator 1.0 generates amplitude scale each tick.
	 * @author efishocean (Tools -> Custom Arguments...)
	 * @version 1.0
	 */
	public class Envelope implements IGenerator
	{
		private var _attack:uint = 0;
		/**
		 * 上冲时间
		 */
		public function get attackTime():uint { return _attack / SAMPLE_RATE; }
		public function set attackTime(value:uint):void { _attack = value * SAMPLE_RATE; _attackStep = 1.0 / (_attack == 0?1:_attack); }		
		
		private var _decay:uint = 0;
		/**
		 * 衰减时间
		 */
		public function get decayTime():uint { return _decay / SAMPLE_RATE;; }
		public function set decayTime(value:uint):void { _decay = value * SAMPLE_RATE; _decayStep = (1.0 - _sustainLevel) / (_decay==0?1:_decay); }	
		
		private var _sustain:uint = 0;
		/**
		 * 维持延音时间
		 */
		public function get sustainTime():uint { return _sustain / SAMPLE_RATE; }
		public function set sustainTime(value:uint):void { _sustain = value * SAMPLE_RATE; }	
		
		private var _release:uint = 0;
		/**
		 * 释放时间
		 */
		public function get releaseTime():uint { return _release / SAMPLE_RATE; }
		public function set releaseTime(value:uint):void { _release = value * SAMPLE_RATE; _releaseStep = _sustainLevel / (_release == 0?1:_release); }
		
		private var _sustainLevel:Number = 0;
		/**
		 * 维持延音的级别
		 */
		public function get sustainLevel():Number { return _sustainLevel; }
		public function set sustainLevel(value:Number):void { _sustainLevel = value; _decayStep = (1.0 - _sustainLevel) / (_decay==0?1:_decay); _releaseStep = _sustainLevel / (_release == 0?1:_release); }

		
		private var _attackStep:Number = 0;//冲击梯度
		
		private var _decayStep:Number = 0;//衰减梯度
		
		private var _releaseStep:Number = 0;//释放梯度

		
		private var _scale:Number = 0;//增益缩放
		
		private var _ticks:uint=0;//计次，采样数
		
		private var _totalTicks:uint = 0;//包络总采样数
		
		private var _releasing:Boolean = false;//是否释放
		
		/**
		 * 包络总采样数
		 */
		public function get totalTicks():uint { return _totalTicks = _attack + _decay + _sustain + _release ; }
		
		/**
		 * 包络总时间
		 */
		public function get totalTime():uint { return _totalTicks / SAMPLE_RATE; }
		
		private var _playing:Boolean = false;
		/**
		 * 包络是否在播放
		 */
		public function get playing():Boolean { return _playing; }
		
		private const SAMPLE_RATE:Number = 44.1;
		
		
		/**
		 *  set envelope generator包络发生器
		 * @param	attack	attack time in ms. 上冲时间
		 * @param	decay	decay time in ms.	衰减时间
		 * @param	sustainLevel	level of sustain. 维持延音级别
		 * @param	release	sustain time in ms.	释放时间
		 * @param	sustain	sustain time in ms.	维持延音时间
		 */
		public function setEnvelope(attack:uint, decay:uint, sustainLevel:Number, release:uint, sustain:uint=4294967295):void
		{
			this.attackTime = attack;
			this.decayTime = decay;
			this.sustainTime = sustain;
			this.releaseTime = release;
			this.sustainLevel = sustainLevel;
			this.totalTicks;
			init();
		}
		
		private function init():void
		{
			_scale = 0.0;
			_releasing = false;
			this.totalTicks;
			_ticks = this.totalTicks + 1;
			_playing = false;
		}
		
		/**
		 * 包络回到初始启动状态
		 */
		public function restart():void
		{
			_ticks = 0;
			_scale = 0.0;
			_releasing = false;
			this.totalTicks;
			_playing = true;
		}

		/**
		 * 使包络进入释放阶段
		 */
		public function release():void
		{
			_releasing = true;
			_totalTicks = _ticks + _release;
		}
		
		/**
		 * 提取包络输出的一个单声道采样
		 * @return
		 */
		public function tick():Number
		{
			if (_ticks>_totalTicks)
			{
				
				init();
				return 0.0;
			}
			if ( _releasing ) 
			{
				_scale -= _releaseStep;
			}
			else
			{
				if (_ticks < _attack)
				{
					_scale += _attackStep;
				}
				else if (_ticks < (_attack + _decay))
				{
					_scale -= _decayStep;
				}
				else if (_ticks < (_attack + _decay + _sustain)  )
				{
					_scale = _sustainLevel;
				}
				else
				{
					_releasing = true;
					_scale -= _releaseStep;
				}
			}
			
			_ticks++;
			if ( _scale < 0.0 )
			{
				_scale = 0.0;
			}
			else if ( _scale > 1.0 )
			{
				_scale = 1.0;
			}
			return _scale;
		}
	}
	
}