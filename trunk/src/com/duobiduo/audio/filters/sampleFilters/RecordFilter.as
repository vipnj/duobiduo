package com.duobiduo.audio.filters.sampleFilters 
{
	import com.duobiduo.audio.filters.sampleFilters.SampleFilter;
	import com.duobiduo.audio.formats.WaveEncoder;
	import com.duobiduo.audio.utils.Sample;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class RecordFilter extends SampleFilter
	{
		private var _samples:Array;
		private var _length:Number=0;
		private var _paused:Boolean=true;
		public function RecordFilter(length:Number=0,recordNow:Boolean=true) 
		{
			super();
			setLength(length);
			_samples = new Array()
			recordNow ? record():1;
		}
		
		override public function process(sample:Sample):void
		{
			var sp:Sample = sample.clone();
			if (!_paused)
			{
				_samples.push(sp);
			}
			if (_length > 0 && _samples.length >= _length )
			{
				_paused = true;
				save();
			}
		}
		
		override public function reset():void
		{
			;
		}
		
		public function pause():void
		{
			_paused = true;
		}
		
		public function save():void
		{
			_paused = true;
			var data:ByteArray = new ByteArray();
			trace("record to file");
			data = WaveEncoder.encode(_samples, 2, 16, 44100);
			var file:FileReference = new FileReference();
			file.save(data);
			_samples = new Array();
		}
		
		public function record():void
		{
			_paused = false;
		}
		
		public function setLength(length:Number):void
		{
			_length = length * 44.1;
		}
	}
	
}