package com.duobiduo.audio.analyzers 
{
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author efishocean
	 */
	public class ComputeSpectrum
	{
		private static const fftLeft:FFT = new FFT(512);
		private static const fftRight:FFT = new FFT(512);
		private static const vectorLeft:Vector.<Number> = new Vector.<Number>(1024);
		private static const vectorRight:Vector.<Number> = new Vector.<Number>(1024);
		private static const bytes:ByteArray = new ByteArray();
		public function ComputeSpectrum() 
		{
			
		}
		public static function computeSpectrum(inputArray:ByteArray, outputArray:ByteArray, FFTMode:Boolean = false, stretchFactor:int = 0):void
		{
			var i:uint;
			var j:uint;
			var inpos:uint = inputArray.position;
			var outpos:uint = outputArray.position;
			var dup:uint = Math.pow(2, stretchFactor+1)-1;
			for (i = 0; i < 512;++i)
			{
				vectorLeft[2 * i] = inputArray.readFloat();
				vectorLeft[2 * i + 1] = 0; 
				vectorRight[2 * i] = inputArray.readFloat();
				vectorRight[2 * i + 1] = 0;
				inputArray.position += dup * 8;
			}
			
			if (FFTMode)
			{
				fftLeft.transform(vectorLeft);
				fftRight.transform(vectorRight);
			}

			for (i = 0; i < 256 ;++i)
			{
				if (FFTMode)
				{
					var intensity:Number = Math.sqrt(vectorLeft[2*i] * vectorLeft[2*i] + vectorLeft[2*i+1 ] * vectorLeft[2*i +1]);
					var decibel:Number = ((vectorLeft[2 * i] == 0 && vectorLeft[2 * i + 1] == 0) ? 0.0 : (10.0 * Math.log(intensity)));
					decibel = decibel < 0 ? 0 : decibel/50;
					outputArray.writeFloat(decibel);

				}
				else
				{
					outputArray.writeFloat(vectorLeft[2 * i]);
				}
				
			}
			for (i = 0; i < 256 ;++i)
			{
				if (FFTMode)
				{
					intensity = Math.sqrt(vectorRight[2*i] * vectorRight[2*i] + vectorRight[2*i+1 ] * vectorRight[2*i +1]);
					decibel = ((vectorRight[2 * i] == 0 && vectorRight[2 * i + 1] == 0) ? 0.0 : (10.0 * Math.log(intensity)));
					decibel = decibel < 0 ? 0 : decibel/50;
					outputArray.writeFloat(decibel);
				}
				else
				{
					outputArray.writeFloat(vectorRight[2 * i]);	

				}
				
			}

			inputArray.position = inpos;
			outputArray.position = outpos;

		}
	}

}