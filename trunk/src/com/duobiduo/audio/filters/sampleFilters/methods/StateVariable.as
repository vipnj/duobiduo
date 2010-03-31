package com.duobiduo.audio.filters.sampleFilters.methods 
{
	/**
	 * ...
	 * @author efishocean
	 */
	public class StateVariable implements IMethod
	{
		
		public function StateVariable() 
		{
			
		}
		
	}

}
//Input/Output
    I - input sample
    L - lowpass output sample
    B - bandpass output sample
    H - highpass output sample
    N - notch output sample
    F1 - Frequency control parameter
    Q1 - Q control parameter
    D1 - delay associated with bandpass output
    D2 - delay associated with low-pass output
    
// parameters:
    Q1 = 1/Q 
    // where Q1 goes from 2 to 0, ie Q goes from .5 to infinity
    
    // simple frequency tuning with error towards nyquist
    // F is the filter's center frequency, and Fs is the sampling rate
    F1 = 2*pi*F/Fs

    // ideal tuning:
    F1 = 2 * sin( pi * F / Fs )

// algorithm
    // loop
    L = D2 + F1 * D1
    H = I - L - Q1*D1
    B = F1 * H + D1
    N = H + L
    
    // store delays
    D1 = B
    D2 = L

    // outputs
    L,H,B,N