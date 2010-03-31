package com.duobiduo.audio.analyzers 
{
	/**
	 * Fast Fourier Transformer. Ported from Java version of Karl Helgason
	 *
	 * @author Efishocean
	 * @version 1.09.0422
	 */
	public final class FFT 
	{

		private var _w:Vector.<Number>;
		private var _fftFrameSize:int;
		private var _sign:int;
		private var _bitm_array:Vector.<int>;
		private var _fftFrameSize2:int;

		// Sign = -1 is FFT, 1 is IFFT (inverse FFT)
		// Data = Interlaced double array to be transformed.
		// The order is: real (sin), complex (cos)
		// Framesize must be power of 2
		public function FFT(fftFrameSize:int, sign:int=-1)
		{
			_w = computeTwiddleFactors(fftFrameSize, sign);

			_fftFrameSize = fftFrameSize;
			_sign = sign; //make -1 as fft, 1 as inverse clearly
			_fftFrameSize2 = fftFrameSize << 1;

			// Pre-process Bit-Reversal
			_bitm_array = new Vector.<int>(_fftFrameSize2);
			for (var i:int = 2; i < _fftFrameSize2; i += 2) 
			{
				var k:int;
				var bitm:int;
				for (bitm = 2, k = 0; bitm < _fftFrameSize2; bitm <<= 1) 
				{
					if ((i & bitm) != 0)
						k++;
					k <<= 1;
				}
				_bitm_array[i] = k;
			}

		}

		public function transform( data:Vector.<Number>):void 
		{
			bitreversal(data);
			calc(_fftFrameSize, data, _sign, _w);
		}

		private  function computeTwiddleFactors(fftFrameSize:int, sign:int):Vector.<Number> 
		{ 

			var imax:int = int (Math.log(fftFrameSize) / Math.LN2);// .log(2.));

			var warray:Vector.<Number>= new Vector.<Number>((fftFrameSize - 1) * 4);
			var w_index:int = 0;

			for (var i:int = 0,  nstep:int = 2; i < imax; i++) 
			{
				var kmax:int = nstep;
				nstep <<= 1;

				var wr:Number = 1.0;
				var wi:Number = 0.0;

				var arg:Number = Math.PI / (kmax >> 1);
				var wfr:Number = Math.cos(arg);
				var wfi:Number = sign * Math.sin(arg);

				for (var k:Number = 0; k < kmax; k += 2) 
				{
					warray[w_index++] = wr;
					warray[w_index++] = wi;

					var tempr:Number = wr;
					wr = tempr * wfr - wi * wfi;
					wi = tempr * wfi + wi * wfr;
				}
			}

			// PRECOMPUTATION of wwr1, wwi1 for factor 4 Decomposition (3 * complex
			// operators and 8 +/- complex operators)
			
			w_index = 0;
			var w_index2:int = warray.length >> 1;
			for (i = 0,  nstep = 2; i < (imax - 1); i++) 
			{
				kmax = nstep;
				nstep *= 2;

				var ii:int = w_index + kmax;
				for (k = 0; k < kmax; k += 2) 
				{
					wr = warray[w_index++];
					wi = warray[w_index++];
					var wr1:Number = warray[ii++];
					var wi1:Number = warray[ii++];
					warray[w_index2++] = wr * wr1 - wi * wi1;
					warray[w_index2++] = wr * wi1 + wi * wr1;
				}
			}

			

			return warray;
		}

		private  function  calc( fftFrameSize:int,  data:Vector.<Number>,  sign:int, w:Vector.<Number>):void 
		{

			const fftFrameSize2:int = fftFrameSize << 1;

			var nstep:int = 2;

			if (nstep >= fftFrameSize2)
				return;
			var i:int = nstep - 2;
			if (sign == -1)
				calcF4F(fftFrameSize, data, i, nstep, w);
			else
				calcF4I(fftFrameSize, data, i, nstep, w);

		}

		private  function calcF2E( fftFrameSize:int, data:Vector.<Number>,  i:int, nstep:int, w:Vector.<Number>):void 
		{
			var kmax:int = nstep;
			for (var n:int = 0; n < kmax; n += 2) 
			{
				var wr:Number = w[i++];
				var wi:Number = w[i++];
				var m:int = n + kmax;
				var datam_r:Number = data[m];
				var datam_i:Number = data[m + 1];
				var datan_r:Number = data[n];
				var datan_i:Number = data[n + 1];
				var tempr:Number = datam_r * wr - datam_i * wi;
				var tempi:Number = datam_r * wi + datam_i * wr;
				data[m] = datan_r - tempr;
				data[m + 1] = datan_i - tempi;
				data[n] = datan_r + tempr;
				data[n + 1] = datan_i + tempi;
			}
	

		}

		// Perform Factor-4 Decomposition with 3 * complex operators and 8 +/-
		// complex operators
		private  function calcF4F( fftFrameSize:int,  data:Vector.<Number>,  i:int, nstep:int,  w:Vector.<Number>):void
		{
			const fftFrameSize2:int = fftFrameSize << 1; // 2*fftFrameSize;
			// Factor-4 Decomposition

			var w_len:int = w.length >> 1;
			while (nstep < fftFrameSize2) 
			{

				if (nstep << 2 == fftFrameSize2) 
				{
					// Goto Factor-4 Final Decomposition
					// calcF4E(data, i, nstep, -1, w);
					calcF4FE(fftFrameSize, data, i, nstep, w);
					return;
				}
				var kmax:int = nstep;
				var nnstep:int = nstep << 1;
				if (nnstep == fftFrameSize2) 
				{
					// Factor-4 Decomposition not possible
					calcF2E(fftFrameSize, data, i, nstep, w);
					return;
				}
				nstep <<= 2;
				var ii:int = i + kmax;
				var iii:int = i + w_len;

				
				i += 2;
				ii += 2;
				iii += 2;

				for (var n:int = 0; n < fftFrameSize2; n += nstep) 
				{
					var m:int = n + kmax;

					var datam1_r:Number = data[m];
					var datam1_i:Number = data[m + 1];
					var datan1_r:Number = data[n];
					var datan1_i:Number = data[n + 1];

					n += nnstep;
					m += nnstep;
					var datam2_r:Number = data[m];
					var datam2_i:Number = data[m + 1];
					var datan2_r:Number = data[n];
					var datan2_i:Number = data[n + 1];

					var tempr:Number = datam1_r;
					var tempi:Number = datam1_i;

					datam1_r = datan1_r - tempr;
					datam1_i = datan1_i - tempi;
					datan1_r = datan1_r + tempr;
					datan1_i = datan1_i + tempi;

					var n2w1r:Number = datan2_r;
					var n2w1i:Number = datan2_i;
					var m2ww1r:Number = datam2_r;
					var m2ww1i:Number = datam2_i;

					tempr = m2ww1r - n2w1r;
					tempi = m2ww1i - n2w1i;

					datam2_r = datam1_r + tempi;
					datam2_i = datam1_i - tempr;
					datam1_r = datam1_r - tempi;
					datam1_i = datam1_i + tempr;

					tempr = n2w1r + m2ww1r;
					tempi = n2w1i + m2ww1i;

					datan2_r = datan1_r - tempr;
					datan2_i = datan1_i - tempi;
					datan1_r = datan1_r + tempr;
					datan1_i = datan1_i + tempi;

					data[m] = datam2_r;
					data[m + 1] = datam2_i;
					data[n] = datan2_r;
					data[n + 1] = datan2_i;

					n -= nnstep;
					m -= nnstep;
					data[m] = datam1_r;
					data[m + 1] = datam1_i;
					data[n] = datan1_r;
					data[n + 1] = datan1_i;

				}
				

				for (var k:int = 2; k < kmax; k += 2) 
				{
					var wr:Number = w[i++];
					var wi:Number = w[i++];
					var wr1:Number = w[ii++];
					var wi1:Number = w[ii++];
					var wwr1:Number = w[iii++];
					var wwi1:Number = w[iii++];
					// double wwr1 = wr * wr1 - wi * wi1; // these numbers can be
					// precomputed!!!
					// double wwi1 = wr * wi1 + wi * wr1;

					for (n = k; n < fftFrameSize2; n += nstep) {
						m = n + kmax;
						

						datam1_r = data[m];
						datam1_i = data[m + 1];
						datan1_r = data[n];
						datan1_i = data[n + 1];

						n += nnstep;
						m += nnstep;
						datam2_r = data[m];
						datam2_i = data[m + 1];
						datan2_r = data[n];
						datan2_i = data[n + 1];

						tempr = datam1_r * wr - datam1_i * wi;
						tempi = datam1_r * wi + datam1_i * wr;

						datam1_r = datan1_r - tempr;
						datam1_i = datan1_i - tempi;
						datan1_r = datan1_r + tempr;
						datan1_i = datan1_i + tempi;

						n2w1r = datan2_r * wr1 - datan2_i * wi1;
						n2w1i = datan2_r * wi1 + datan2_i * wr1;
						m2ww1r = datam2_r * wwr1 - datam2_i * wwi1;
						m2ww1i = datam2_r * wwi1 + datam2_i * wwr1;

						tempr = m2ww1r - n2w1r;
						tempi = m2ww1i - n2w1i;

						datam2_r = datam1_r + tempi;
						datam2_i = datam1_i - tempr;
						datam1_r = datam1_r - tempi;
						datam1_i = datam1_i + tempr;

						tempr = n2w1r + m2ww1r;
						tempi = n2w1i + m2ww1i;

						datan2_r = datan1_r - tempr;
						datan2_i = datan1_i - tempi;
						datan1_r = datan1_r + tempr;
						datan1_i = datan1_i + tempi;

						data[m] = datam2_r;
						data[m + 1] = datam2_i;
						data[n] = datan2_r;
						data[n + 1] = datan2_i;

						n -= nnstep;
						m -= nnstep;
						data[m] = datam1_r;
						data[m + 1] = datam1_i;
						data[n] = datan1_r;
						data[n + 1] = datan1_i;
					}
				}

				i += kmax << 1;

			}

			calcF2E(fftFrameSize, data, i, nstep, w);

		}

		// Perform Factor-4 Decomposition with 3 * complex operators and 8 +/-
		// complex operators
		private  function calcF4I( fftFrameSize:int,  data:Vector.<Number>,  i:int, nstep:int,  w:Vector.<Number>):void
		{
			const fftFrameSize2:int = fftFrameSize << 1; // 2*fftFrameSize;
			// Factor-4 Decomposition

			var w_len:int = w.length >> 1;
			while (nstep < fftFrameSize2) 
			{

				if (nstep << 2 == fftFrameSize2) 
				{
					// Goto Factor-4 Final Decomposition
					// calcF4E(data, i, nstep, 1, w);
					calcF4IE(fftFrameSize, data, i, nstep, w);
					return;
				}
				var kmax:int = nstep;
				var nnstep:int = nstep << 1;
				if (nnstep == fftFrameSize2) 
				{
					// Factor-4 Decomposition not possible
					calcF2E(fftFrameSize, data, i, nstep, w);
					return;
				}
				nstep <<= 2;
				var ii:int = i + kmax;
				var iii:int = i + w_len;
				
				i += 2;
				ii += 2;
				iii += 2;

				for (var n:int = 0; n < fftFrameSize2; n += nstep) 
				{
					var m:int = n + kmax;

					var datam1_r:Number = data[m];
					var datam1_i:Number = data[m + 1];
					var datan1_r:Number = data[n];
					var datan1_i:Number = data[n + 1];

					n += nnstep;
					m += nnstep;
					var datam2_r:Number = data[m];
					var datam2_i:Number = data[m + 1];
					var datan2_r:Number = data[n];
					var datan2_i:Number = data[n + 1];

					var tempr:Number = datam1_r;
					var tempi:Number = datam1_i;

					datam1_r = datan1_r - tempr;
					datam1_i = datan1_i - tempi;
					datan1_r = datan1_r + tempr;
					datan1_i = datan1_i + tempi;

					var n2w1r:Number = datan2_r;
					var n2w1i:Number = datan2_i;
					var m2ww1r:Number = datam2_r;
					var m2ww1i:Number = datam2_i;

					tempr = n2w1r - m2ww1r;
					tempi = n2w1i - m2ww1i;

					datam2_r = datam1_r + tempi;
					datam2_i = datam1_i - tempr;
					datam1_r = datam1_r - tempi;
					datam1_i = datam1_i + tempr;

					tempr = n2w1r + m2ww1r;
					tempi = n2w1i + m2ww1i;

					datan2_r = datan1_r - tempr;
					datan2_i = datan1_i - tempi;
					datan1_r = datan1_r + tempr;
					datan1_i = datan1_i + tempi;

					data[m] = datam2_r;
					data[m + 1] = datam2_i;
					data[n] = datan2_r;
					data[n + 1] = datan2_i;

					n -= nnstep;
					m -= nnstep;
					data[m] = datam1_r;
					data[m + 1] = datam1_i;
					data[n] = datan1_r;
					data[n + 1] = datan1_i;

				}

				
				for (var k:int = 2; k < kmax; k += 2) 
				{
					var wr:Number = w[i++];
					var wi:Number = w[i++];
					var wr1:Number = w[ii++];
					var wi1:Number = w[ii++];
					var wwr1:Number = w[iii++];
					var wwi1:Number = w[iii++];
					// double wwr1 = wr * wr1 - wi * wi1; // these numbers can be
					// precomputed!!!
					// double wwi1 = wr * wi1 + wi * wr1;

					for (n = k; n < fftFrameSize2; n += nstep) 
					{
						m = n + kmax;

						datam1_r = data[m];
						datam1_i = data[m + 1];
						datan1_r = data[n];
						datan1_i = data[n + 1];

						n += nnstep;
						m += nnstep;
						datam2_r = data[m];
						datam2_i = data[m + 1];
						datan2_r = data[n];
						datan2_i = data[n + 1];

						tempr = datam1_r * wr - datam1_i * wi;
						tempi = datam1_r * wi + datam1_i * wr;

						datam1_r = datan1_r - tempr;
						datam1_i = datan1_i - tempi;
						datan1_r = datan1_r + tempr;
						datan1_i = datan1_i + tempi;

						n2w1r = datan2_r * wr1 - datan2_i * wi1;
						n2w1i = datan2_r * wi1 + datan2_i * wr1;
						m2ww1r = datam2_r * wwr1 - datam2_i * wwi1;
						m2ww1i = datam2_r * wwi1 + datam2_i * wwr1;

						tempr = n2w1r - m2ww1r;
						tempi = n2w1i - m2ww1i;

						datam2_r = datam1_r + tempi;
						datam2_i = datam1_i - tempr;
						datam1_r = datam1_r - tempi;
						datam1_i = datam1_i + tempr;

						tempr = n2w1r + m2ww1r;
						tempi = n2w1i + m2ww1i;

						datan2_r = datan1_r - tempr;
						datan2_i = datan1_i - tempi;
						datan1_r = datan1_r + tempr;
						datan1_i = datan1_i + tempi;

						data[m] = datam2_r;
						data[m + 1] = datam2_i;
						data[n] = datan2_r;
						data[n + 1] = datan2_i;

						n -= nnstep;
						m -= nnstep;
						data[m] = datam1_r;
						data[m + 1] = datam1_i;
						data[n] = datan1_r;
						data[n + 1] = datan1_i;

					}
				}

				i += kmax << 1;

			}

			calcF2E(fftFrameSize, data, i, nstep, w);

		}

		// Perform Factor-4 Decomposition with 3 * complex operators and 8 +/-
		// complex operators
		private  function calcF4FE( fftFrameSize:int,  data:Vector.<Number>,  i:int, nstep:int,  w:Vector.<Number>):void 
		{
			const fftFrameSize2:int = fftFrameSize << 1; // 2*fftFrameSize;
			// Factor-4 Decomposition

			var w_len:int = w.length >> 1;
			while (nstep < fftFrameSize2) 
			{

				var kmax:int = nstep;
				var nnstep:int = nstep << 1;
				if (nnstep == fftFrameSize2) 
				{
					// Factor-4 Decomposition not possible
					calcF2E(fftFrameSize, data, i, nstep, w);
					return;
				}
				nstep <<= 2;
				var ii:int = i + kmax;
				var iii:int = i + w_len;
				for (var n:int = 0; n < kmax; n += 2) 
				{
					var wr:Number = w[i++];
					var wi:Number = w[i++];
					var wr1:Number = w[ii++];
					var wi1:Number = w[ii++];
					var wwr1:Number = w[iii++];
					var wwi1:Number = w[iii++];
					// double wwr1 = wr * wr1 - wi * wi1; // these numbers can be
					// precomputed!!!
					// double wwi1 = wr * wi1 + wi * wr1;

					var m:int = n + kmax;

					var datam1_r:Number = data[m];
					var datam1_i:Number = data[m + 1];
					var datan1_r:Number = data[n];
					var datan1_i:Number = data[n + 1];

					n += nnstep;
					m += nnstep;
					var datam2_r:Number = data[m];
					var datam2_i:Number = data[m + 1];
					var datan2_r:Number = data[n];
					var datan2_i:Number = data[n + 1];

					var tempr:Number = datam1_r * wr - datam1_i * wi;
					var tempi:Number = datam1_r * wi + datam1_i * wr;

					datam1_r = datan1_r - tempr;
					datam1_i = datan1_i - tempi;
					datan1_r = datan1_r + tempr;
					datan1_i = datan1_i + tempi;

					var n2w1r:Number = datan2_r * wr1 - datan2_i * wi1;
					var n2w1i:Number = datan2_r * wi1 + datan2_i * wr1;
					var m2ww1r:Number = datam2_r * wwr1 - datam2_i * wwi1;
					var m2ww1i:Number = datam2_r * wwi1 + datam2_i * wwr1;

					tempr = m2ww1r - n2w1r;
					tempi = m2ww1i - n2w1i;

					datam2_r = datam1_r + tempi;
					datam2_i = datam1_i - tempr;
					datam1_r = datam1_r - tempi;
					datam1_i = datam1_i + tempr;

					tempr = n2w1r + m2ww1r;
					tempi = n2w1i + m2ww1i;

					datan2_r = datan1_r - tempr;
					datan2_i = datan1_i - tempi;
					datan1_r = datan1_r + tempr;
					datan1_i = datan1_i + tempi;

					data[m] = datam2_r;
					data[m + 1] = datam2_i;
					data[n] = datan2_r;
					data[n + 1] = datan2_i;

					n -= nnstep;
					m -= nnstep;
					data[m] = datam1_r;
					data[m + 1] = datam1_i;
					data[n] = datan1_r;
					data[n + 1] = datan1_i;

				}

				i += kmax << 1;

			}

		}

		// Perform Factor-4 Decomposition with 3 * complex operators and 8 +/-
		// complex operators
		private  function calcF4IE( fftFrameSize:int,  data:Vector.<Number>,  i:int, nstep:int,  w:Vector.<Number>):void 
		{
			const fftFrameSize2:int = fftFrameSize << 1; // 2*fftFrameSize;
			// Factor-4 Decomposition

			var w_len:int = w.length >> 1;
			while (nstep < fftFrameSize2) 
			{

				var kmax:int = nstep;
				var nnstep:int = nstep << 1;
				if (nnstep == fftFrameSize2) 
				{
					// Factor-4 Decomposition not possible
					calcF2E(fftFrameSize, data, i, nstep, w);
					return;
				}
				nstep <<= 2;
				var ii:int = i + kmax;
				var iii:int = i + w_len;
				for (var n:int = 0; n < kmax; n += 2) 
				{
					var wr:Number = w[i++];
					var wi:Number = w[i++];
					var wr1:Number = w[ii++];
					var wi1:Number = w[ii++];
					var wwr1:Number = w[iii++];
					var wwi1:Number = w[iii++];
					// double wwr1 = wr * wr1 - wi * wi1; // these numbers can be
					// precomputed!!!
					// double wwi1 = wr * wi1 + wi * wr1;

					var m:int = n + kmax;

					var datam1_r:Number = data[m];
					var datam1_i:Number = data[m + 1];
					var datan1_r:Number = data[n];
					var datan1_i:Number = data[n + 1];

					n += nnstep;
					m += nnstep;
					var datam2_r:Number = data[m];
					var datam2_i:Number = data[m + 1];
					var datan2_r:Number = data[n];
					var datan2_i:Number = data[n + 1];

					var tempr:Number = datam1_r * wr - datam1_i * wi;
					var tempi:Number = datam1_r * wi + datam1_i * wr;

					datam1_r = datan1_r - tempr;
					datam1_i = datan1_i - tempi;
					datan1_r = datan1_r + tempr;
					datan1_i = datan1_i + tempi;

					var n2w1r:Number = datan2_r * wr1 - datan2_i * wi1;
					var n2w1i:Number = datan2_r * wi1 + datan2_i * wr1;
					var m2ww1r:Number = datam2_r * wwr1 - datam2_i * wwi1;
					var m2ww1i:Number = datam2_r * wwi1 + datam2_i * wwr1;

					tempr = n2w1r - m2ww1r;
					tempi = n2w1i - m2ww1i;

					datam2_r = datam1_r + tempi;
					datam2_i = datam1_i - tempr;
					datam1_r = datam1_r - tempi;
					datam1_i = datam1_i + tempr;

					tempr = n2w1r + m2ww1r;
					tempi = n2w1i + m2ww1i;

					datan2_r = datan1_r - tempr;
					datan2_i = datan1_i - tempi;
					datan1_r = datan1_r + tempr;
					datan1_i = datan1_i + tempi;

					data[m] = datam2_r;
					data[m + 1] = datam2_i;
					data[n] = datan2_r;
					data[n + 1] = datan2_i;

					n -= nnstep;
					m -= nnstep;
					data[m] = datam1_r;
					data[m + 1] = datam1_i;
					data[n] = datan1_r;
					data[n + 1] = datan1_i;

				}

				i += kmax << 1;

			}

		}

		private function bitreversal(data:Vector.<Number>):void 
		{
			if (_fftFrameSize < 4)
				return;

			var inverse:int = _fftFrameSize2 - 2;
			for (var i:int = 0; i < _fftFrameSize; i += 4) 
			{
				var k:int = _bitm_array[i];

				// Performing Bit-Reversal, even v.s. even, O(2N)
				if (i < k) 
				{

					var n:int = i;
					var m:int = k;

					// COMPLEX: SWAP(data[n], data[m])
					// Real Part
					var tempr:Number = data[n];
					data[n] = data[m];
					data[m] = tempr;
					// Imagery Part
					n++;
					m++;
					var tempi:Number = data[n];
					data[n] = data[m];
					data[m] = tempi;

					n = inverse - i;
					m = inverse - k;

					// COMPLEX: SWAP(data[n], data[m])
					// Real Part
					tempr = data[n];
					data[n] = data[m];
					data[m] = tempr;
					// Imagery Part
					n++;
					m++;
					tempi = data[n];
					data[n] = data[m];
					data[m] = tempi;
				}

				// Performing Bit-Reversal, odd v.s. even, O(N)

				m = k + _fftFrameSize; // _bitm_array[i+2];
				// COMPLEX: SWAP(data[n], data[m])
				// Real Part
				n = i + 2;
				tempr = data[n];
				data[n] = data[m];
				data[m] = tempr;
				// Imagery Part
				n++;
				m++;
				tempi = data[n];
				data[n] = data[m];
				data[m] = tempi;
			}

		}
	}	
}

