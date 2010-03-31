package com.duobiduo.audio.others 
{
	
	import com.duobiduo.audio.utils.MathX;
	/**
	 *  //   Y is X scaled to run F x faster.  X is added-in in windows
	 *  //   W pts long, overlapping by Wov points with the previous output.  
	 *	//   The similarity is calculated over the last Wsim points of output.
	 *	//   Maximum similarity skew is Kmax pts.
	 *	//   Each xcorr calculation is decimated by xdecim (8)
	 *	//   The skew axis sampling is decimated by kdecim (2)
	 *	//   Defaults (for 22k) W = 200, Wov = W/2, Kmax = 2*W, Wsim=Wov.
	 *	//   Based on "The SOLAFS time-scale modification algorithm", 
	 *	//   Don Hejna & Bruce Musicus, BBN, July 1991.
	 *	//   1997may16 dpwe@icsi.berkeley.edu $Header: /homes/dpwe/matlab/dpwebox/RCS/solafs.m,v 1.3 2006/04/09 20:10:20 dpwe Exp $
	 *	//   2006-04-08: fix to predicted step size, thanks to Andreas Tsiartas
	 ** @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class solafs 
	{
		private var Ss:uint;
		private var xpts:uint;
		private var ypts:uint;
		private var Y:Vector.<Number>;
		private var xfwin:Vector.<Number>;
		private var ovix:Vector.<Number>;
		private var newix:Vector.<Number>;
		private var simix:Vector.<Number>;
		private var padX:Vector.<Number>;
		private var kdecim:uint;
		private var Wsim:uint;
		private var W:uint;
		private var Wov:uint;
		private var Kmax:uint;
		private var xdecim:uint;
		private var F:Number=1;
		public function solafs(X:Vector.<Number>, F__:Number, W__:uint=2048, Wov__:uint=100,  Kmax__:uint=200, Wsim__:uint=100, xdecim__:uint=8, kdecim__:uint=2) 
		{
			F = F__;
			kdecim = kdecim__;
			Wsim = Wsim__;
			W = W__;
			Wov = Wov__;
			Kmax = Kmax__;
			xdecim = xdecim__;
			
			Ss = W - Wov;
			xpts = X.length;
			ypts = Math.round(xpts / F);
			Y = new Vector.<Number>(ypts);
			
			// Cross-fade win is Wov pts long - it grows
			// 交叉消隐窗口，具有Wov个点的长度
			xfwin = new Vector.<Number>(Wov);
			xfwin.forEach(	function(item:Number, index:int, vector:Vector.<Number>):void { vector[index] = (index + 1) / (Wov + 1); } );
			
			// Index to add to ypos to get the overlap region
			// 重叠区域的索引
			ovix = new Vector.<Number>(Wov);
			ovix.forEach(	function(item:Number, index:int, vector:Vector.<Number>):void { vector[index] = (index - Wov + 1); } );
			
			// Index for non-overlapping bit
			// 非重叠区域的索引
			newix = new Vector.<Number>(W - Wov);
			newix.forEach(	function(item:Number, index:int, vector:Vector.<Number>):void { vector[index] = (index + 1); } );
			
			// Index for similarity chunks
			// decimate the cross-correlation
			// 相似区块的索引，由交叉关联抽样取得
			simix = new Vector.<Number>(Math.round(Wsim / xdecim));
			for (var i:uint = 0; i < Math.round(Wsim / xdecim); i++)
			{
				simix[i] = 1 + i * xdecim - Wsim;
			}
			
			// prepad X for extraction
			// 预提取输入数据缓存
			padX = new Vector.<Number>(Wsim + X.length + Kmax + W - Wov);
			for (i = 0; i < X.length; i++) 
			{
				padX[i+Wsim] = X[i];
			}
			
			// Startup - just copy first bit
			// 开始先复制一部分到输出
			for (i = 0; i < Wsim; i++)
			{
				Y[i] = X[i];
			}
			

		}
		
		public function process():Vector.<Number>
		{
			var i:uint;
			var xabs:uint = 0;
			var lastxpos:uint = 0;
			var lastypos:uint = 0;
			var km:uint = 0;
			
			var xpos:uint;
			var kmpred:uint;
			var len:uint;
			for (var ypos:uint = Wsim ; ypos < ypts - W; ypos += Ss)
			{
				// Ideal X position
				// 理想的输入位置
				xpos = F * ypos;
				
				// Overlap prediction - assume all of overlap from last copy
				// 重叠区预测，假设都从上次复制开始重叠
				kmpred = km + ((xpos - lastxpos) - (ypos - lastypos));
				lastxpos = xpos;
				lastypos = ypos;
				
				if (kmpred <= Kmax && kmpred >= 0)
				{ 
					km = kmpred;   // no need to search，不许要搜索了
				}
				else
				{
					// Calculate the skew, km
					// 计算斜切和搜索步长
					// .. by first figuring the cross-correlation
					len= simix.length;
					var ysim:Vector.<Number> = new Vector.<Number>(len);
					
					for (i = 0; i < len; i++ )
					{
						ysim[i] = Y[ypos + simix[i]];
						
					}
					
					// Clear the Rxy array
					var rxy:Vector.<Number> = new Vector.<Number>(Kmax+1);
					var rxx:Vector.<Number> = new Vector.<Number>(Kmax+1);
					
					// Make sure km doesn't take us backwards
					// 确保搜索不会倒退
					//Kmin = max(0, xabs-xpos);
					Kmin = 0;
				
					// actually, this sounds kinda bad.  Allow backwards for now
					// 实际操作，效果有些差，因此允许倒退
					for (var k:uint = Kmin; k <= Kmax; k += kdecim)
					{
						var xsim:Vector.<Number> = new Vector.<Number>();
						for (i = 0; i < len; i++)
						{
							xsim[i] = padX[Wsim + xpos + k + simix[i]];
							rxy[k] += ysim[i] * xsim[i];
						}
						rxx[k] = MathX.norm2(xsim);
					}
					
					// Zero the pts where rxx was zero
					// rxx等于零的地方为零，因为不能做除数
					var Rxy:Vector.<Number> = new Vector.<Number>(len);
					for (i = 0; i < len; i++) 
					{
						Rxy[i] = (rxx[i] != 0) ? (rxy[i] / rxx[i]) : rxy[i];
					}
										
					// Local max gives skew
					// 定位最大切入值
					km = MathX.firstMax(Rxy);
				}
				xabs = xpos+km;
								  
				// Cross-fade some points
				// 交叉部分点
				len = ovix.length;
				for (i = 0; i < len; i++)
				{
					Y[ypos + ovix[i]] *= 1 - xfwin[i]; 
					Y[ypos + ovix[i]] += xfwin[i] * padX[Wsim + xabs + ovix[i]];
				}
				// Add in remaining points
				// 加入剩余点
				len = newix.length;
				for (i = 0; i < len; i++)
				{
					Y[ypos + newix[i]] = padX[Wsim + xabs + newix[i]];
				}
				
			}
			return Y.concat();
		}


	}
	
}
/*
function Y = solafs(X, F, W, Wov,  Kmax, Wsim, xdecim, kdecim)
// Y = solafs(X, F, W, Wov, Kmax, Wsim, xdec, kdec)   Do SOLAFS timescale mod'n
//   Y is X scaled to run F x faster.  X is added-in in windows
//   W pts long, overlapping by Wov points with the previous output.  
//   The similarity is calculated over the last Wsim points of output.
//   Maximum similarity skew is Kmax pts.
//   Each xcorr calculation is decimated by xdecim (8)
//   The skew axis sampling is decimated by kdecim (2)
//   Defaults (for 22k) W = 200, Wov = W/2, Kmax = 2*W, Wsim=Wov.
//   Based on "The SOLAFS time-scale modification algorithm", 
//   Don Hejna & Bruce Musicus, BBN, July 1991.
// 1997may16 dpwe@icsi.berkeley.edu $Header: /homes/dpwe/matlab/dpwebox/RCS/solafs.m,v 1.3 2006/04/09 20:10:20 dpwe Exp $
// 2006-04-08: fix to predicted step size, thanks to Andreas Tsiartas

if (nargin < 3)		W    = 200; end
if (nargin < 4)		Wov  = W/2; end
if (nargin < 5)		Kmax = 2 * W; end
if (nargin < 6)         Wsim = Wov; end
if (nargin < 7)         xdecim = 8; end
if (nargin < 8)         kdecim = 2; end

Ss = W - Wov;

if(size(X,1) ~= 1)   error('X must be a single-row vector');  end;

xpts = size(X,2);
ypts = round(xpts / F);
Y = zeros(1, ypts);

// Cross-fade win is Wov pts long - it grows
xfwin = (1:Wov)/(Wov+1);

// Index to add to ypos to get the overlap region
ovix = (1-Wov):0;
// Index for non-overlapping bit
newix = 1:(W-Wov);
// Index for similarity chunks
// decimate the cross-correlation
simix = (1:xdecim:Wsim) - Wsim;

// prepad X for extraction
padX = [zeros(1, Wsim), X, zeros(1,Kmax+W-Wov)];

// Startup - just copy first bit
Y(1:Wsim) = X(1:Wsim);

xabs = 0;
lastxpos = 0;
lastypos = 0;
km = 0;
for ypos = Wsim:Ss:(ypts-W);
  // Ideal X position
  xpos = F * ypos;
//  disp(['xpos=',num2str(xpos),' ypos=',num2str(ypos)]);
  // Overlap prediction - assume all of overlap from last copy
  kmpred = km + ((xpos - lastxpos) - (ypos - lastypos));
  lastxpos = xpos;
  lastypos = xpos;
  if (kmpred <= Kmax && kmpred >= 0) 
    km = kmpred;   // no need to search
  else
    // Calculate the skew, km
    // .. by first figuring the cross-correlation
    ysim = Y(ypos + simix);
    // Clear the Rxy array
    rxy = zeros(1, Kmax+1);
    rxx = zeros(1, Kmax+1);
    // Make sure km doesn't take us backwards
    //Kmin = max(0, xabs-xpos);
    Kmin = 0;
    // actually, this sounds kinda bad.  Allow backwards for now
    for k = Kmin:kdecim:Kmax
      xsim = padX(floor(Wsim + xpos + k + simix));
      rxx(k+1) = norm(xsim);
      rxy(k+1) = (ysim * xsim');
    end
    // Zero the pts where rxx was zero
    Rxy = (rxx ~= 0).*rxy./(rxx+(rxx==0));
    // Local max gives skew
    km = min(find(Rxy == max(Rxy))-1);
  end
  xabs = xpos+km;
//  disp(['ypos = ', int2str(ypos), ', km = ', int2str(km), '(base = ', int2str(ypos-xabs), ')']);
  
//  subplot(311);
//  plot(ysim);
//  subplot(312);
//  plot(padX(Wsim + xpos + ((1-Wsim):Kmax)))
//  subplot(313);
//  plot(Rxy);
//  pause;
  
  // Cross-fade some points
  Y(ypos+ovix) = ((1-xfwin).*Y(ypos+ovix)) + (xfwin.*padX(floor(Wsim+xabs+ovix)));
  // Add in remaining points
  Y(ypos+newix) = padX(floor(Wsim+xabs+newix));
end
*/