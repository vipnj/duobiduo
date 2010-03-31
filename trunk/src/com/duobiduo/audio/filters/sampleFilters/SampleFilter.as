package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.filters.ISampleFilter;
	import com.duobiduo.audio.utils.Sample;
	import com.duobiduo.audio.filters.sampleFilters.methods.IMethod;
	import com.duobiduo.audio.filters.sampleFilters.methods.Method;
	import flash.utils.*;
	/**
	 * ...
	 * @author efishocean
	 */
	public class SampleFilter implements ISampleFilter
	{
		internal var _leftFilter:IMethod;
		internal var _rightFilter:IMethod;
		public var bypass:Boolean;
		public function SampleFilter() 
		{
			_leftFilter = new Method();
			_rightFilter = new Method();
			bypass = false;
		}
		public function clone():ISampleFilter
		{
			var className:String = getQualifiedClassName(this);
			var ClassReference:Class = getDefinitionByName(className) as Class;
			var sf:ISampleFilter = new ClassReference();
			(sf as ClassReference)._leftFilter = _leftFilter.clone();
			(sf as ClassReference)._rightFilter = _rightFilter.clone();
			return sf;
		}
		public function toString():String
		{
			return getQualifiedClassName(this)+": bypass=" + bypass + ", "+_leftFilter.toString();
		}
		public function process(sample:Sample):void
		{
			sample.left = _leftFilter.process(sample.left);
			sample.right = _rightFilter.process(sample.right);
		}
		public function reset():void
		{
			_leftFilter.reset();
			_rightFilter.reset();
		}
	}

}