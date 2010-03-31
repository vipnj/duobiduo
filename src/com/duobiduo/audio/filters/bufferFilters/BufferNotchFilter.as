package com.duobiduo.audio.filters.bufferFilters 
{
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class BufferNotchFilter 
	{
		//notch filter
		//Parameters:
		//0 =< freq =< samplerate/2
		//0 =< q < 1 (The higher, the narrower)		
		public function BufferNotchFilter(frequency:Number,quality:Number) 
		{
			configure(frequency, quality);
		}

		public function configure(frequency:Number,quality:Number):void
		{
			freq = frequency;
			q = quality;
			z1x = Math.cos(2*pi*freq/samplerate);
			a0a2 = (1-q)*(1-q)/(2*(Math.abs(z1x)+1)) + q;
			a1 = -2*z1x*a0a2;
			b1 = -2*z1x*q;
			b2 = q * q;
			reset();
		}
		
		public function reset():void
		{
			leftReg0 = 0;
			leftReg1 = 0;
			leftReg2 = 0;
			rightReg0 = 0;
			rightReg1 = 0;
			rightReg2 = 0;
		}
		
		public function process(buffer:ByteArray):void
		{
			num_samples = buffer.length >> 3;
			//reset buffer position
			buffer.position = 0;
			/* Main loop */
			
			for (n = 0; n < num_samples-2; n++)
			{
				left0 = buffer.readInt();
				right0 = buffer.readInt();

				left1 = buffer.readInt();
				right1 = buffer.readInt();

				left2 = buffer.readInt();
				right2 = buffer.readInt();
				
				leftReg0 = a0a2 * (left0 + left2) + a1 * left1 - b1 * leftReg1 - b2 * leftReg2;
				rightReg0 = a0a2 * (right0 + right2) + a1 * right1 - b1 * rightReg1 - b2 * rightReg2;

				leftReg2 = leftReg1;
				leftReg1 = leftReg0;

				rightReg2 = rightReg1;
				rightReg1 = rightReg0;

				//var tempLeft:Number = leftReg0;
				 // var tempRight:Number = rightReg0;
				/* Check clipping */
				//if (temp > 32767) {
				//  temp = 32767;
				//} else if (temp < -32768) temp = -32768;
				buffer.position -= 24;
				/* Store new value */
				buffer.writeInt(leftReg0);
				buffer.writeInt(rightReg0);
			}
		}
		
		//
		private const pi:Number = Math.PI;
		private const sqrt2:Number = Math.sqrt(2.0);
		private const samplerate:Number = 44100;
		
		private var freq:Number; // Change! (zero & pole angle)
		private var q:Number;    // Change! (pole magnitude)

		private var z1x:Number;	// = cos(2 * pi * freq / samplerate);
		private var a0a2:Number;// = (1 - q) * (1 - q) / (2 * (Math.abs(z1x) + 1)) + q;
		private var a1:Number;	// = -2 * z1x * a0a2;
		private var b1:Number;	// = -2 * z1x * q;
		private var b2:Number;	// = q * q;
		
		private var leftReg0:Number, leftReg1:Number,leftReg2:Number,rightReg0:Number, rightReg1:Number, rightReg2:Number;
		private var left0:Number,left1:Number,left2:Number,right0:Number,right1:Number,right2:Number;
		private var num_samples:uint;



	}
	
}