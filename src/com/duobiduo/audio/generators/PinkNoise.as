package com.duobiduo.audio.generators
{
	public class PinkNoise implements IGenerator
	{
		protected var state:Array = new Array( PINK_NOISE_NUM_STAGES );
		protected static const A:Array =  [0.02109238, 0.07113478, 0.68873558];
		protected static const P:Array = [ 0.3190,  0.7756,  0.9613 ];		
		private const PINK_NOISE_NUM_STAGES:int = 3;
		
		private static const RMI2:Number = 1.5;//2.0 /0x7ffff; //float(RAND_MAX); // + 1.0; // change for range [0,1)
		private static const offset:Number = A[0] + A[1] + A[2];
		
		public function PinkNoise()
		{
			restart();
		}

		public function restart():void 
		{
			for( var i:int=0; i< PINK_NOISE_NUM_STAGES; i++ )
			{
					state[ i ] = 0.0;
			}
		}
		
		public function tick():Number
		{
			// unrolled loop
			var temp:Number = Math.random();
			state[0] = P[0] * (state[0] - temp) + temp;
			temp = Math.random();
			state[1] = P[1] * (state[1] - temp) + temp;
			temp = Math.random();
			state[2] = P[2] * (state[2] - temp) + temp;
			
			return ( A[0] * state[0] + A[1] * state[1] + A[2] * state[2] ) * RMI2 - offset;
		}

	}
}