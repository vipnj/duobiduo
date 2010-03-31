/**
 * Copyright(C) 2008 Efishocean
 * 
 * This file is part of Midias.
 *
 * Midias is an ActionScript3 midi lib developed by Efishocean.
 * Midias was extracted from my project 'ocean' which purpose to 
 * impletement a commen audio formats libray. 
 * More infos might appear on my blog http://www.tan66.cn 
 * 
 * Midias is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Midias is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

package com.duobiduo.midi
{
	import flash.utils.Dictionary;

	/**
	 * MidiEnum class
	 */
	public class MidiEnum {
		/**
		* Channel message
		*/
		public static const C_NOTE_OFF:int  	 			=	0x80;		//	????
		public static const C_NOTE_ON:int   				=	0x90;		//	????
		public static const C_POLY_PRESSURE:int 			=	0xA0;		//	???????(??)
		public static const C_CONTROL_CHANGE:int   		=	0xB0;		//	??????
		public static const C_PROGRAM_CHANGE:int   		=	0xC0;		//	??(??)??
		public static const C_CHANNEL_PRESSURE:int   		=	0xD0;		//	?????
		public static const C_PITCH_BEND:int   			=	0xE0;		//	??
		/**
		* Meta message
		*/
		public static const	META:int   			=	0xFF;		//	Meta tag
		public static const	M_SEQ_NUM:int   		=	0x00;		//  Sequence number
		public static const	M_TEXT:int   			=	0x01;		//  Text
		public static const	M_COPY_RIGHT:int   	=	0x02;		//  Copyright notice
		public static const	M_SEQ_TRK_NAME:int  	= 	0x03;		//  Sequence or track name
		public static const	M_INSTRUMENT_NAME:int =	0x04;		//  Instrument name
		public static const	M_LYRIC_TXT:int   	=	0x05;		//  Lyric text
		public static const	M_MARKER_TXT:int   	=	0x06;		//  Marker text
		public static const	M_CUE_POINT :int   	=	0x07;		//  Cue point
		public static const	M_PROGRAM_NAME:int  	= 	0x08;		//  Program name
		public static const	M_DEVICE_NAME:int  	= 	0x09;		//  Device name
		public static const	M_CHANNEL_PREFIX:int  = 	0x20;		//  MIDI channel prefix assignment
		public static const	M_END_OF_TRK:int   	=	0x2F;		//  End of track
		public static const	M_SET_TEMPO:int   	=	0x51;		//  1/4 Tempo setting
		public static const	M_SMPTE_OFFSET:int  	= 	0x54;		//  SMPTE offset
		public static const	M_TIME_SIGN:int   	=	0x58;		//  Time signature
		public static const	M_KEY_SIGN:int   		=	0x59;		//  Key signature
		public static const	M_SEQ_SPEC:int   		=	0x7F;		//  Sequencer specific event
		/**
		* System Real Time Message----
		*/
		public static const	S_TIMING_CLOCK:int  		= 	0xF8;		//  ????
		public static const	S_RESERVED_0xF9:int  		= 	0xF9;		//	??
		public static const S_SYS_START:int  			=	0xFA;		//	?????????(????????????????)
		public static const	S_SYS_CONTINUE:int  		= 	0xFB;		//	???????????????
		public static const S_SYS_STOP:int  			=	0xFC;		//	??????
		public static const	S_RESERVED_0xFD:int  		= 	0xFD;		//	??
		public static const	S_ACTIVE_SENDING:int  	= 	0xFE;		//	??????
		//public static const	SYS_RESET:int  			=	0xFF;		//	????
		/**
		* System message
		*/
		public static const S_SYSTEM_EXCLUSIVE:int	=	0xF0;		//	???????,????????
		public static const S_MIDI_TIME_CODE:int  	= 	0xF1;		//	midi???
		public static const S_SONG_POSITION:int  		= 	0xF2;		//	????
		public static const S_SONG_SELECT:int  		=	0xF3;		//	??
		public static const	S_RESERVED_0xF4:int  		= 	0xF4;		//	??
		public static const S_RESERVED_0xF5:int  		=	0xF5;		//	??
		public static const S_TUNE_REQUEST:int  		= 	0xF6;		//	??
		public static const	S_END_OF_SYS_EX:int  		= 	0xF7;		//	??????????
		
		public static const NOTE:int				=	0x00;		// zero can be presents the note kind
		
		private static const _message:Dictionary = new Dictionary(true);
		
		//Initialize the static block
		{
			_message[C_NOTE_OFF]="NOTE_OFF";
			_message[C_NOTE_ON]="NOTE_ON";
			_message[C_POLY_PRESSURE]="POLY_PRESSURE";
			_message[C_CONTROL_CHANGE]="CONTROL_CHANGE";
			_message[C_PROGRAM_CHANGE]="PROGRAM_CHANGE";
			_message[C_CHANNEL_PRESSURE]="CHANNEL_PRESSURE";
			_message[C_PITCH_BEND]="PITCH_BEND";
			
			_message[META]="META";
			_message[M_SEQ_NUM]="SEQ_NUM";
			_message[M_TEXT]="TEXT";
			_message[M_COPY_RIGHT]="COPY_RIGHT";
			_message[M_SEQ_TRK_NAME]="SEQ_TRK_NAME";
			_message[M_INSTRUMENT_NAME]="INSTRUMENT_NAME";
			_message[M_LYRIC_TXT]="LYRIC_TXT";
			_message[M_MARKER_TXT]="MARKER_TXT";
			_message[M_CUE_POINT]="CUE_POINT";
			_message[M_PROGRAM_NAME]="PROGRAM_NAME";
			_message[M_DEVICE_NAME]="DEVICE_NAME";
			_message[M_CHANNEL_PREFIX]="CHANNEL_PREFIX";
			_message[M_END_OF_TRK]="END_OF_TRK";
			_message[M_SET_TEMPO]="SET_TEMPO";
			_message[M_SMPTE_OFFSET]="SMPTE_OFFSET";
			_message[M_TIME_SIGN]="TIME_SIGN";
			_message[M_KEY_SIGN]="KEY_SIGN";
			_message[M_SEQ_SPEC]="SEQ_SPEC";
			
			_message[S_TIMING_CLOCK]="TIMING_CLOCK";
			_message[S_RESERVED_0xF9]="RESERVED_0xF9";
			_message[S_SYS_START]="SYS_START";
			_message[S_SYS_CONTINUE]="SYS_CONTINUE";
			_message[S_SYS_STOP]="SYS_STOP";
			_message[S_RESERVED_0xFD]="RESERVED_0xFD";
			_message[S_ACTIVE_SENDING]="ACTIVE_SENDING";
			//_message[SYS_RESET]="SYS_RESET";
			
			_message[S_SYSTEM_EXCLUSIVE]="SYSTEM_EXCLUSIVE";
			_message[S_MIDI_TIME_CODE]="MIDI_TIME_CODE";
			_message[S_SONG_POSITION]="SONG_POSITION";
			_message[S_SONG_SELECT]="SONG_SELECT";
			_message[S_RESERVED_0xF4]="RESERVED_0xF4";
			_message[S_RESERVED_0xF5]="RESERVED_0xF5";
			_message[S_TUNE_REQUEST]="TUNE_REQUEST";
			_message[S_END_OF_SYS_EX]="END_OF_SYS_EX";
			
			_message[NOTE]="NOTE";
			//_message[]="";
			//_message[]="";
			//_message[]="";
			//_message[]="";
			//_message[]="";
		}
		/**
		* Initializes the static dictionary.
		*/
		public function MidiEnum():void{
			undefined;
		}
		
		/**
		 * @param n message value.
		 * @return message name. 
		 */
		public static function getMessageName(n:int):String{
			return _message[n];
		}
		
		
	}
	
}
