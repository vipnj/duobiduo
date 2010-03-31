package com.duobiduo.audio.filters.sampleFilters.methods 
{
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class BiQuad implements IMethod
	{
		public static const filterType:Object = { LPF:"lowPassFilter", HPF:"HighPassFilter", BPF:"BandPassFilter", NOTCH:"NotchFilter", PEQ:"PEQ", LSH:"LSH", HSH:"HSH" };		

		private static const M_LN2:Number = Math.LN2;// 0.69314718055994530942;
		private var ca0:Number,  ca1:Number,  ca2:Number,  ca3:Number,  ca4:Number; // coefficients (faster than array)
		private var x1:Number, x2:Number, y1:Number, y2:Number;//state registers
		private var _type:String;
		private var _frequence:Number;
		private var _quality:Number;
		private var _bandwidth:Number;
		
		public function BiQuad()
		{

		}
		

		public function configure(type:String,frequence:Number,quality:Number,bandwidth:Number):void
		{
			_type = type;
			_frequence = frequence;
			_quality = quality;
			_bandwidth = bandwidth;
			
			var A:Number, omega:Number, sn:Number, cs:Number, alpha:Number, beta:Number;
			var a0:Number, a1:Number, a2:Number, b0:Number, b1:Number, b2:Number;	
			
			A = Math.pow(10, quality / 40);
			omega = 2 * Math.PI * frequence / 44100;
			sn = Math.sin(omega);
			cs = Math.cos(omega);
			alpha = sn * MathX.sinh(M_LN2 / 2 * bandwidth * omega / sn);
			beta = Math.sqrt(A + A);
			
			switch(type)
			{
			case filterType.LPF:
                b0 = (1 - cs) / 2;
                b1 = 1 - cs;
                b2 = (1 - cs) / 2;
                a0 = 1 + alpha;
                a1 = -2 * cs;
                a2 = 1 - alpha;
                break;
            case filterType.HPF:
                b0 = (1 + cs) / 2;
                b1 = -(1 + cs);
                b2 = (1 + cs) / 2;
                a0 = 1 + alpha;
                a1 = -2 * cs;
                a2 = 1 - alpha;
                break;
            case filterType.BPF:
                b0 = alpha;
                b1 = 0;
                b2 = -alpha;
                a0 = 1 + alpha;
                a1 = -2 * cs;
                a2 = 1 - alpha;
                break;
            case filterType.NOTCH:
                b0 = 1;
                b1 = -2 * cs;
                b2 = 1;
                a0 = 1 + alpha;
                a1 = -2 * cs;
                a2 = 1 - alpha;
                break;
            case filterType.PEQ:
                b0 = 1 + (alpha * A);
                b1 = -2 * cs;
                b2 = 1 - (alpha * A);
                a0 = 1 + (alpha / A);
                a1 = -2 * cs;
                a2 = 1 - (alpha / A);
                break;
            case filterType.LSH:
                b0 = A * ((A + 1) - (A - 1) * cs + beta * sn);
                b1 = 2 * A * ((A - 1) - (A + 1) * cs);
                b2 = A * ((A + 1) - (A - 1) * cs - beta * sn);
                a0 = (A + 1) + (A - 1) * cs + beta * sn;
                a1 = -2 * ((A - 1) + (A + 1) * cs);
                a2 = (A + 1) + (A - 1) * cs - beta * sn;
                break;
            case filterType.HSH:
                b0 = A * ((A + 1) + (A - 1) * cs + beta * sn);
                b1 = -2 * A * ((A - 1) + (A + 1) * cs);
                b2 = A * ((A + 1) + (A - 1) * cs - beta * sn);
                a0 = (A + 1) - (A - 1) * cs + beta * sn;
                a1 = 2 * ((A - 1) - (A + 1) * cs);
                a2 = (A + 1) - (A - 1) * cs - beta * sn;
                break;
            default:
				break;
			}

			ca0 = b0 / a0;
			ca1 = b1 / a0;
			ca2 = b2 / a0;
			ca3 = a1 / a0;
			ca4 = a2 / a0;
			
			reset();
		}
		
		public function process(sample:Number):Number
		{
			
			var out:Number;
				
			out = ca0 * sample + ca1 * x1 + ca2 * x2 - ca3 * y1 - ca4 * y2;
			
			//if ( isDenormal(y) ) y = 0f; // anti-denormal helps

			/* shift x1 to x2, sample to x1 */
			x2 = x1;
			x1 = sample;

			/* shift y1 to y2, result to y1 */
			y2 = y1;
			y1 = out;

			//if (!doMix) {
				//mixBuffer[index] = y;
			//} else {
				//mixBuffer[index] += (amplitudeAdj * y);
			//}
			return out;
		}
		
		public function reset():void
		{
			x1 = x2 = y1 = y2 = 0;
		}
		
		public function clone():IMethod
		{
			return new BiQuad(_type, _frequence, _quality, _bandwidth);
		}
		public function toString():String
		{
			return String("type~" + _type
							+", frequence~" + _frequence
							+"hz, quality~" + _quality
							+", bandwidth~"+_bandwidth+"hz");
		}
	}
	
}