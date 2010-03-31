package com.duobiduo.audio.filters.sampleFilters.methods 
{
	/**
	 * ...
	 * @author efishocean
	 */


	public class Phaser implements IMethod
	{
		private const SR:Number = 44100;  //sample rate
		private const F_PI:Number = 3.14159;
		private var _dmin:Number, _dmax:Number/*range*/, _fb:Number/*feedback*/, _lfoPhase:Number, _lfoInc:Number, _depth:Number, _zm1:Number;
		private var _alps:Vector.<AllpassDelay>;// [6]
		public function Phaser() //initialise to some usefull defaults...
		{
			this.reset();
			
			_alps = new Vector.<AllpassDelay>(6, true);
			for (var i:int = 0; i < 6; i++)
			{
				_alps[i] = new Allpa   ssDelay();
			}
		}
		public function configure(fmin:Number,fmax:Number,rate:Number,fb:Number,depth:Number):void
		{
			//Hz	
			_dmin = fmin / (SR/2.0);
			_dmax = fmax / (SR/2.0);

			// cps
			_lfoInc = 2.0 * F_PI * (rate / SR);
			
			// 0 -> <1.
			_fb = fb;

			// 0 -> 1.
			_depth = depth;
		}

		public function process( sample:Number ):Number
		{
			//calculate and update phaser sweep lfo...
			var d:Number  = _dmin + (_dmax-_dmin) * ((Math.sin( _lfoPhase ) + 1.0)/2.0);
			_lfoPhase += _lfoInc;
			if( _lfoPhase >= F_PI * 2.0 )
				_lfoPhase -= F_PI * 2.0;

			//update filter coeffs
			for( var i:int =0; i<6; i++ )
				_alps[i].Delay( d );

			//calculate output
			var y:Number = 	_alps[0].Update(
								_alps[1].Update(
									_alps[2].Update(
										_alps[3].Update(
											_alps[4].Update(
												_alps[5].Update( sample + _zm1 * _fb ))))));
			_zm1 = y;

			return sample + y * _depth;
		}
		public function reset():void
		{
			_fb = .7;
			_lfoPhase = 0.0;
			_depth = 1.0;
			_zm1 = 0.0;
		
			_dmin = 440.0;
			_dmax = 1600.0;
			_lfoInc = 2.0 * F_PI * (0.5 / SR);
		}
	}

}
class AllpassDelay{
    public function	AllpassDelay()
    {
    	_a1 = 0.0;
        _zm1 = 0.0;
    }

	public function Delay( delay:Number ):void
	{
		//sample delay time
		_a1 = (1.0 - delay) / (1.0 + delay);
	}

	public function Update( inSamp:Number ):Number
	{
		var y:Number = inSamp * -_a1 + _zm1;
		_zm1 = y * _a1 + inSamp;

		return y;
	}
    private	var _a1:Number, _zm1:Number;
}
/* 
Date: Mon, 24 Aug 1998 07:02:40 -0700
Reply-To: music-dsp
Originator: music-dsp@shoko.calarts.edu
Sender: music-dsp
Precedence: bulk
From: "Ross Bencina" <rbencina@hotmail.com>
To: Multiple recipients of list <music-dsp>
Subject: Re: Phaser revisited [code included]
X-Comment:  Music Hackers Unite! http://shoko.calarts.edu/~glmrboy/musicdsp/music-dsp.html 
Status: RO

Hi again,

Thanks to Chris Towsend and Marc Lindahl for their helpful 
contributions. I now have a working phaser and it sounds great! It seems 
my main error was using a 'sub-sampled' all-pass reverberator instead of 
a single sample all-pass filter [what was I thinking? :)].

I have included a working prototype (C++) below for anyone who is 
interested. My only remaining doubt is whether the conversion from 
frequency to delay time [ _dmin = fMin / (SR/2.f); ] makes any sense 
what-so-ever.

Ross B.
*/
/*
    class: Phaser
    implemented by: Ross Bencina <rossb@kagi.com>
    date: 24/8/98

    Phaser is a six stage phase shifter, intended to reproduce the
    sound of a traditional analogue phaser effect.
    This implementation uses six first order all-pass filters in
    series, with delay time modulated by a sinusoidal.

    This implementation was created to be clear, not efficient.
    Obvious modifications include using a table lookup for the lfo,
    not updating the filter delay times every sample, and not
    tuning all of the filters to the same delay time.

    Thanks to:
    The nice folks on the music-dsp mailing list, including...
    Chris Towsend and Marc Lindahl
    
    ...and Scott Lehman's Phase Shifting page at harmony central:
    http://www.harmony-central.com/Effects/Articles/Phase_Shifting/

*/


