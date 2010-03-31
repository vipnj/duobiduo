package com.duobiduo.audio.others
{
	import flash.events.*;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.display.Loader;
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class FastByteArray 
	{
		[Embed(source="FastBytesArray.swf", mimeType="application/octet-stream")] static private const SWF: Class;
		public function FastByteArray()
		{
			var swf:ByteArray = ByteArray(new SWF());
			var ldr:Loader = new Loader();
			//var FBA:Class;
			var onSWFLoaded: Function = function( event: Event ): void
			{
				FBA = ldr.contentLoaderInfo.applicationDomain.getDefinition( "FByteArray" ) as Class;
				trace(ldr.contentLoaderInfo.bytesLoaded,ldr.contentLoaderInfo.applicationDomain,ldr.contentLoaderInfo.frameRate,ldr.contentLoaderInfo.swfVersion,ldr.contentLoaderInfo.contentType);
				domain = ldr.contentLoaderInfo.applicationDomain;
			}
			
			ldr.contentLoaderInfo.addEventListener( Event.COMPLETE, onSWFLoaded );
			//var ctx:LoaderContext = new LoaderContext(false, new ApplicationDomain());
			ldr.loadBytes( swf );// , ctx );
		}
		public var FBA:Class;
		public var domain:ApplicationDomain;
	}
	
}