package com.duobiduo.audio.filters.sampleFilters.methods  
{
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class LinerIIR  implements IMethod
	{
		
		public function LinerIIR() 
		{
			
		}
		//The filter parameter is f or g, and the state variable that needs to be kept around between interations is s.

			//101 Leaky Integrator

			a0 = 1
			b1 = 1 - f
			out = s += input - f * s;

			//102 Basic Lowpass (all-pole)
			//A first order lowpass filter, by finite difference appoximation (differentials --> differences).

			a0 = f
			b1 = 1 - f
			out = s += f * ( input - s );

			//103 Lowpass with inverted control
			//Same as above, except for different filter parameter is now inverted.
			//input this case, g equals the location of the pole.

			a0 = g - 1
			b1 = g
			out = s = input + g * ( s - input );


			//104 Lowpass with zero at Nyquist
			//A first order lowpass filter, by via the conformal map of the z-plane (0..infinity --> 0..Nyquist).

			a0 = f
			a1 = f
			b1 = 1 - 2 * f
			s = temp + ( out = s + ( temp = f * ( input - s ) ) );

			
			//105 Basic Highpass (DC-blocker)
			//Input complement to basic lowpass, yields a finite difference highpass filter.

			a0 = 1 - f
			a1 = f - 1
			b1 = 1 - f
			out = input - ( s += f * ( input - s ) );


			//106 Highpass with forced unity gain at Nyquist
			//Input complement to filter 104, yields a conformal map highpass filter.

			a0 = 1 - f
			a1 = f - 1
			b1 = 1 - 2 * f
			out = input + temp - ( s += 2 * ( temp = f * ( input - s ) ) );


			//107 Basic Allpass
			//This corresponds to a first order allpass filter,
			//where g is the location of the pole input the range -1..1.

			a0 = -g
			a1 = 1
			b1 = g
			s = input + g * ( out = s - g * input );

	}
	
}