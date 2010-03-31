package com.duobiduo.audio.filters.bufferFilters 
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
	public class SolafsProcess
	{
		
		private var SS:uint = 2048;//SAMPLES_LENGTH;
		private const WOV:uint = 100;
		private const KMAX:uint = 200;
		private const WSIM:uint = 100;
		private var XDEC:uint = 8;//8
		private var KDEC:uint = 2;//2
		private var W:uint = SS + WOV;
		public function get ADDMAX():uint //扩展读取窗口以便适应速度小于1.1的搜索窗口
		{
			return SS + KMAX;// 2248;
		}
		
		private var SA:uint=0;
		
		private var xfwin:Vector.<Number>;	//三角形交叉窗口
		
		private var newix:Vector.<Number>;	//非重叠索引
		private var simix:Vector.<Number>;	//相似索引
		private var padX:Vector.<Number>;	//输入缓存
        public var km:uint = 0;
        private var lastOvL:Vector.<Number>;//末次输出缓存
        private var lastOvR:Vector.<Number>;//末次输出缓存
		//输出
        private var outL:Vector.<Number> = new Vector.<Number>(SS);//左声道输出
		private var outR:Vector.<Number> = new Vector.<Number>(SS);//右声道输出利用左声道判断结果
		
		/**
		 * 
		 * @param	Ss
		 * @param	quality 声音处理效果质量，从1-8档，8档最高
		 */
		public function SolafsProcess(Ss:uint=2048,highQuality:Boolean=false)
		{
			SS = Ss;
			W = SS + WOV;
			XDEC = highQuality ? 1 : 8;
			KDEC = highQuality ? 1 : 2;
			
			// Cross-fade win is Wov pts long - it grows
			// 交叉消隐窗口，具有Wov个点的长度
			xfwin = new Vector.<Number>(WOV);
			xfwin.forEach(	function(item:Number, index:int, vector:Vector.<Number>):void { vector[index] = (index + 1) / (WOV + 1); } );
			
			// Index for non-overlapping bit
			// 非重叠区域的索引
			newix = new Vector.<Number>(SS);
			newix.forEach(	function(item:Number, index:int, vector:Vector.<Number>):void { vector[index] = (index + 1); } );
			
			// Index for similarity chunks
			// decimate the cross-correlation
			// 相似区块的索引，由交叉关联抽样取得
			simix = new Vector.<Number>(Math.round( WSIM/ XDEC));
			for (var i:uint = 0; i < Math.round(WSIM / XDEC); i++)
			{
				simix[i] = i * XDEC;
			}
            
            //缓存末次数据用于下次重叠
			lastOvL = new Vector.<Number>(WOV);
            lastOvR = new Vector.<Number>(WOV);

		}

		/**
		 * Solafs算法主体
		 * 
		 * @param	vecInL 输入
		 * @return	输出
		 */
		public function process(vecInL:Vector.<Number>,speed:Number):Vector.<Number>
		{
            var i:uint;
				
				
			var kmpred:uint;
			var len:uint;
			//因为SS固定，所以由输入数据决定SA步长，也就决定了速度SA=SS x speed
            
			SA = vecInL.length;
			if (speed<1.1)
			{
				SA -= ADDMAX;
			}
			
            
            
           
			// Calculate the skew, km
			// 计算斜切和搜索步长
			// .. by first figuring the cross-correlation
			len= simix.length;
			var ysim:Vector.<Number> = new Vector.<Number>(len);
			//上段中抽样检测点
			for (i = 0; i < len; i++ )
			{
				ysim[i] = lastOvL[ simix[i] ];
				
			}
			
			// Clear the Rxy array
			var rxy:Vector.<Number> = new Vector.<Number>(KMAX+1);
			var rxx:Vector.<Number> = new Vector.<Number>(KMAX+1);
			
			// Make sure km doesn't take us backwards
			// 确保搜索不会倒退
			//Kmin = max(0, km-xpos);
			var Kmin:uint = 0;
		
			// actually, this sounds kinda bad.  Allow backwards for now
			// 实际操作，效果有些差，因此允许倒退
			// 从输入中抽样检测点，并计算出rxx rxy
			var xsim:Vector.<Number> = new Vector.<Number>();
			for (var k:uint = Kmin; k <= KMAX; k += KDEC)
			{
				for (i = 0; i < len; i++)
				{
					xsim[i] = vecInL[ k + simix[i] ];
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
	   

            // Cross-fade some points
            // 交叉部分点
            len = WOV
            for (i = 0; i < len; i++)
            {
                //左声道    
                lastOvL[i] *= 1 - xfwin[i];  //Y[ypos + ovix[i]] *= 1 - xfwin[i]; 
                lastOvL[i] += xfwin[i] * vecInL[ km + i ];//Y[ypos + ovix[i]] += xfwin[i] * padX[Wsim + km + ovix[i]];
              
            }
            // Add in remaining points
            // 加入剩余点
            len = SS-WOV;
            
            for (i = 0; i < len; i++)
            {
                outL[i+WOV] = vecInL[ km + WOV + i];
            }
            
			
			
			
            for (i = 0; i < WOV; i++)
            {
				//上次的保留的叠加部分写入本次输出的前面
				outL[i] = lastOvL[i];
				//更新上次叠加部分
                lastOvL[i] = vecInL[ km + SS+ i];
            }
			
            return outL;
        
		}
		
		/**
		 * 快速处理数据，利用的是process计算过后的km位移。
		 * 当音频为差别不大的双声道，使用process处理完第一个声道，
		 * 便可以立刻使用quickProcess处理第二个声道。
		 * @param	vecInR 输入向量
		 * @return	输出向量
		 */
        public function quickProcess(vecInR:Vector.<Number>):Vector.<Number>
		{
			var len:uint;
			var i:uint;
			// Cross-fade some points
            // 交叉部分点
            len = WOV
            for (i = 0; i < len; i++)
            {
                //右声道
                lastOvR[i] *= 1 - xfwin[i];  //Y[ypos + ovix[i]] *= 1 - xfwin[i]; 
                lastOvR[i] += xfwin[i] * vecInR[ km + i ];//Y[ypos + ovix[i]] += xfwin[i] * padX[Wsim + km + ovix[i]];
            }
            // Add in remaining points
            // 加入剩余点
            len = SS-WOV;
            
            for (i = 0; i < len; i++)
            {
                outR[i+WOV] = vecInR[ km + WOV + i];
            }
            
			
           

            for (i = 0; i < WOV; i++)
            {
				outR[i] = lastOvR[i];
                //lastOvR[i] = vecInR[ km + len + i];
                lastOvR[i] = vecInR[ km + SS+ i];
            }
			
            return outR;
		}
    }
	
}