package com.duobiduo.audio.filters.sampleFilters.methods 
{
	/**
	 * ...
	 * @author efishocean
	 */
	public class Resonant implements IMethod
	{
		
		public function Resonant() 
		{
			
		}
		
	}

}
////////////////第一种//////////////////
//set feedback amount given f and q between 0 and 1
fb = q + q/(1.0 - f);

//for each sample...
buf0 = buf0 + f * (in - buf0 + fb * (buf0 - buf1));
buf1 = buf1 + f * (buf0 - buf1);
out = buf1;


////////////////第二种//////////////////
resofreq = pole frequency
amp = magnitude at pole frequency (approx)

double pi = 3.141592654;

/* Parameters. Change these! */
double resofreq = 5000;
double amp = 1.0;

DOUBLEWORD streamofs;
double w = 2.0*pi*resofreq/samplerate; // Pole angle
double q = 1.0-w/(2.0*(amp+0.5/(1.0+w))+w-2.0); // Pole magnitude
double r = q*q;
double c = r+1.0-2.0*cos(w)*q;
double vibrapos = 0;
double vibraspeed = 0;

/* Main loop */
for (streamofs = 0; streamofs < streamsize; streamofs++) {

  /* Accelerate vibra by signal-vibra, multiplied by lowpasscutoff */
  vibraspeed += (fromstream[streamofs] - vibrapos) * c;

  /* Add velocity to vibra's position */
  vibrapos += vibraspeed;

  /* Attenuate/amplify vibra's velocity by resonance */
  vibraspeed *= r;

  /* Check clipping */
  temp = vibrapos;
  if (temp > 32767) {
    temp = 32767;
  } else if (temp < -32768) temp = -32768;

  /* Store new value */
  tostream[streamofs] = temp;
}