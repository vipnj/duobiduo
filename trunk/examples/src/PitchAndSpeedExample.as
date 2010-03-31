package 
{
	import com.duobiduo.audio.filters.TDSI.PitchFilter;
	import flash.display.Sprite;
	import flash.events.Event;
	import com.duobiduo.audio.*;
	import com.bit101.components.*;
	import com.duobiduo.audio.stream.*;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import flash.net.*;
	/**
	 * ...
	 * @author efishocean, www.duobiduo.com
	 */
	[SWF(width=320,height=240)]
	public class PitchAndSpeedExample extends Sprite 
	{
		private var _label:Label;
		private var _progBar:ProgressBar;
		private var _input:InputText;
		private var _infoText:Text;
		private var _playButton:PushButton;
		private var _playProg:HSlider;
		//private var _pauseButton:PushButton;
		private var _stopButton:PushButton;
		private var _openButton:PushButton;
		private var _pitchControl:HSlider;
		private var _speedControl:HSlider;
		private var _pitchLabel:Label;
		private var _speedLabel:Label;
		
		private var _loadButton:PushButton;
		
		private var _audio:AudioXStream;
		private var _channel:AudioChannelX;
		private var _length:Number = 0;
		private var _pitchFilter:PitchFilter;
		private var _enableCursur:Boolean = false;
		public function PitchAndSpeedExample():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			buildUI();
			
		}
		
		private function initAudioInfo():void
		{
			_channel = _audio.createChannel();
			_length = _channel.length;
			_pitchFilter = new PitchFilter();
			_channel.bufferFilters.push(_pitchFilter);
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);

		}
		private	function onEnterFrame(e:Event):void
		{
			_infoText.text = int(_channel.position / 60000) + " m " + int(_channel.position % 60000 / 1000) + " s " + int(_channel.position % 1000) + " / " + 
			int(_channel.length/60000)+" m "+int(_channel.length%60000/1000)+" s "+int(_channel.length%1000);
			_playProg.value = _channel.position / _channel.length * _playProg.maximum;
		}
		private function buildUI():void
		{
			_label = new Label(this, 0, 0, "control speed and pitch");
			
			this.graphics.beginFill(0x123abc);
			this.graphics.drawRoundRect(0, 20, 320, 55, 10, 10);
			this.graphics.endFill();
			
			_openButton = new PushButton(this,20,25,"open local mp3 file",onChange);
			
			_input = new InputText(this, 20, 50, "paste mp3 url here, don't work with vbr mp3s.");
			_input.setSize(240, 20);
			
			_loadButton = new PushButton(this, 260, 50, "LOAD", onChange);
			_loadButton.setSize(40, 20);
			
			this.graphics.beginFill(0xcd12d);
			this.graphics.drawRoundRect(0, 75, 320, 85, 10, 10);
			this.graphics.endFill();
			
			_progBar = new ProgressBar(this,20,80);
			_progBar.setSize(280, 5);
			_progBar.maximum = 100;
			
			
			_infoText = new Text(this, 20, 85, "waiting audio");
			_infoText.setSize(280, 20);
			
			_playProg = new HSlider(this, 20, 105, onChange);
			_playProg.setSize(280, 15);
			_playProg.enabled = false;
			_playProg.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { _enableCursur = true; } );
			_playProg.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void { _enableCursur = false; } );
			_playButton = new PushButton(this,20,130,"PLAY",onChange);
			_playButton.setSize(60, 20);
						
			//_pauseButton = new PushButton(this, 100, 130, "PAUSE", onChange);
			//_pauseButton.setSize(60, 20);
			
			_stopButton = new PushButton(this, 180, 130, "STOP", onChange);
			_stopButton.setSize(60, 20);
			
			this.graphics.beginFill(0xdef456);
			this.graphics.drawRoundRect(0, 160, 320, 70, 10, 10);
			this.graphics.endFill();
			
			_pitchControl = new HSlider(this, 20, 170, onChange);
			_pitchControl.setSize(200, 20);
			_pitchControl.minimum = -100;
			_pitchControl.maximum = 100;
			_pitchControl.value = 0;
			
			_pitchLabel = new Label(this, 220, 170, "pitch ");
			
			_speedControl = new HSlider(this, 20, 190, onChange);
			_speedControl.setSize(200, 20);
			_speedControl.minimum = -200;
			_speedControl.maximum = 200;
			_speedControl.value = 0;
			
			_speedLabel = new Label(this, 220, 190, "speed ");
			
		}
		
		private function onChange(e:Event):void
		{
			switch(e.currentTarget)
			{
				case _openButton:
				{
					if (_channel)
					{
						_channel.stop();
					}
					var file:FileReference = new FileReference();
					file.addEventListener(Event.COMPLETE, onFileComp);
					file.addEventListener(Event.SELECT, onSel );
					file.addEventListener(ProgressEvent.PROGRESS, onFileProg);
					file.browse([new FileFilter("CBR MP3", "*.mp3;*.MP3;")]);
					
					function onFileComp(event:Event):void
					{
						_audio = new AudioXStream();
						_audio.addEventListener(Event.COMPLETE, function(ee:Event):void { initAudioInfo();} );
						_audio.loadBytes(file.data);
						_playProg.enabled = true;
						_pitchControl.value = 0;
						_speedControl.value = 0;
					}
					function onSel(event:Event):void
					{
						file.load();
					}
					function onFileProg(event:ProgressEvent):void
					{
						_progBar.value = event.bytesLoaded / event.bytesTotal * 100;
					}
					break;
				}
				case _loadButton:
				{
					if (_channel)
					{
						_channel.stop();
					}
					_audio = new AudioXStream();
					_audio.addEventListener(Event.COMPLETE, onComp);
					_audio.addEventListener(ProgressEvent.PROGRESS, onProg);
					_audio.addEventListener(IOErrorEvent.IO_ERROR, onIOErr);
					_audio.load(new URLRequest(_input.text));
					_loadButton.enabled = false;
					function onComp(event:Event):void
					{
						_loadButton.enabled = true;
						initAudioInfo();
						_playProg.enabled = true;
						_pitchControl.value = 0;
						_speedControl.value = 0;
					}
					function onProg(event:ProgressEvent):void
					{
						_progBar.value = event.bytesLoaded / event.bytesTotal * 100;
					}
					function onIOErr(event:IOErrorEvent):void
					{
						_infoText.text = "Can't load file: "+_input.text;
						_loadButton.enabled = true;
					}
					break;
				}
				case _playProg:
				{
					if (!_channel)
					{
						break;
					}
					if (_enableCursur)
					{
						if (_channel.status==0 || _channel.status==1 )
						{
							_channel.stop();
							_channel.play(_channel.length * _playProg.value / _playProg.maximum);
							_channel.pause();
							_playButton.label = "PLAY";
						}
						else
						{
							_channel.stop();
							_channel.play(_channel.length * _playProg.value / _playProg.maximum);
							_playButton.label = "PAUSE";
						}
					}
					break;
				}
				case _playButton:
				{
					if (!_channel)
					{
						break;
					}
					if (_channel.status==0)
					{
						_channel.play();
						_playButton.label = "PAUSE";
					}
					else if(_channel.status==1)
					{
						_channel.resume();
						_playButton.label = "PAUSE";
					}
					else
					{
						_channel.pause();
						_playButton.label = "PLAY";
					}
					break;
				}

				case _stopButton:
				{
					if (!_channel)
					{
						break;
					}
					_channel.stop();
					_playButton.label = "PLAY";
					_playProg.value = 0;
					break;
				}
				case _pitchControl:
				{
					if ( _channel)
					{
						_pitchFilter.pitch = Math.pow(2, _pitchControl.value / 100);
						_pitchLabel.text = "pitch " + int(Math.pow(2, _pitchControl.value / 100) * 100) / 100 ;
					}
					break;
				}
				case _speedControl:
				{
					if ( _channel)
					{
						_channel.speed = Math.pow(2, _speedControl.value / 100);
						_speedLabel.text = "speed "+int(Math.pow(2, _speedControl.value / 100) * 100) / 100 ;
					}
					break;
				}
				default:break;
			}
		}
	}
	
}