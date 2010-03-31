/**
* QUI OToolTip class
* @author Efish.Ocean
* @version 0.1 2008
*/

package com.duobiduo.toy
{
	import flash.display.InteractiveObject;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	public class ToolTip {
		//private static var tooltip:OToolTip;
		private static var _text:TextField;			//text field to display tool tip message
		private static var _point:Point;			//point a current cursor
		private static var _target:Object;			//current target calls tooltip
		private static var showTimer:Timer;			//timer for fade in
		private static var offTimer:Timer;			//timer for fade out
		private static var _toolTipLib:Dictionary;	//a dictionary to store registered interactiveObjects that has tooltip
		{
			//initialize static tooltip style
			_text= new TextField();
			showTimer = new Timer(30, 10);
			offTimer = new Timer(30, 10);
			showTimer.addEventListener("timer", fadeIn , false , 0 , true);
			offTimer.addEventListener("timer", fadeOut , false , 0 , true);
			_toolTipLib = new Dictionary(true);
		}
		
		/**
		* Constructor
		* @return
		*/
		public function ToolTip():void{

		}
		
		/**
		* bind a tooltip message to an interactive object
		* @param	interObj
		* @param	tooltip
		* @param	follow
		* @return
		*/
		public static function bind( interObj:InteractiveObject ,  tooltip:String , follow:Boolean=false):void{
			_toolTipLib[interObj] = tooltip;
			interObj.addEventListener( MouseEvent.ROLL_OVER , appear , false , 0 , true);
			interObj.addEventListener( MouseEvent.ROLL_OUT , disappear , false , 0 , true);
			if( follow ){
				interObj.addEventListener( MouseEvent.MOUSE_MOVE , followMouse , false , 0 , true );
			}
			interObj.addEventListener( Event.REMOVED_FROM_STAGE , function(e:Event):void{ remove(e.target as InteractiveObject);} );
		}
		
		/**
		* replace tooltip message of a binded object
		* @param	interObj
		* @param	tooltip
		* @return
		*/
		public static function replace( interObj:InteractiveObject , tooltip:String ):void{
			if( _toolTipLib[interObj] )
			_toolTipLib[interObj] = tooltip;
		}
		
		/**
		* remove a binded object from tooltip
		* @param	interObj
		* @return
		*/
		public static function remove( interObj:InteractiveObject ):void{
			if( _toolTipLib[interObj] ){
				delete _toolTipLib[interObj];
				interObj.removeEventListener( MouseEvent.ROLL_OVER , appear );
				interObj.removeEventListener( MouseEvent.ROLL_OUT , disappear );
				interObj.removeEventListener( MouseEvent.MOUSE_MOVE , followMouse );
			}
		}
		
		/**
		* follow mouse handler
		* @param	e
		* @return
		*/
		protected static function followMouse(e:MouseEvent):void{
			_point = new Point( e.target.mouseX , e.target.mouseY );
			_text.x = e.target.localToGlobal( _point ).x ;
			_text.y = e.target.localToGlobal( _point ).y + 30 ;
			e.updateAfterEvent();
		}
		
		/**
		* tooltip appear handler
		* @param	e
		* @return
		*/
		protected static function appear(e:MouseEvent):void{
			//delete prev tool tip
			if( _text.parent ){
				_text.parent.removeChild(_text);
			}
			
			//new target
			_target = e.target;
			
			_text= new TextField();
			_text.setTextFormat( new TextFormat(  ) );
			_text.background = true;
			_text.backgroundColor = 0xFFFFCA;
			_text.borderColor = 0xA59D0C;
			_text.border = true;
			_text.width =800;
			_text.height= 600;
			_text.autoSize = "left";
			_text.selectable = false;
			_text.multiline = true;
			_text.wordWrap = false;
			_text.filters = [new DropShadowFilter(4,45,0x000000,0.5)];
			_text.alpha = 1;
			
			//new text
			_text.text = _toolTipLib[_target];
			_text.width = _text.textWidth;
			_text.height = _text.textHeight;
			

			//restore alpha
			_text.alpha = 0;
			
			//stop off timer
			offTimer.stop();
			
			//start show timer
			showTimer.reset();
            showTimer.start();
			
		}
		protected static function fadeIn(e:TimerEvent):void{
			
			if( _text.alpha==0 ){

				_point = new Point( _target.mouseX , _target.mouseY );
				_text.x = _target.localToGlobal( _point ).x ;
				_text.y = _target.localToGlobal( _point ).y + 30 ;
				_target.stage.addChild(_text);
			}
			_text.alpha +=0.1;
		}
		
		protected static function disappear(e:MouseEvent):void{
			showTimer.stop();
			offTimer.reset();
			offTimer.start();

		}
		
		protected static function fadeOut(e:TimerEvent):void{
			_text.alpha -= 0.1;
			if( _text.parent && _text.alpha==0 ){
				_text.parent.removeChild(_text);
			}
			
		}
	}
	
}
