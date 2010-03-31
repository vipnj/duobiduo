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

package com.duobiduo.midi.model 
{
	import flash.utils.ByteArray;
	
	import com.duobiduo.midi.MidiEnum;
	
	/**
	 * 
	 */
	public class MetaItem extends MessageItem{
		public var text:ByteArray;
		private var _type:uint;
		
		public function MetaItem():void{
			super();
			//defaulte meta item is a end of track
			text = new ByteArray();
			_type = MidiEnum.M_END_OF_TRK;
			this.kind = MidiEnum.META;
		}
		
		public function get type():uint{
			return _type;
		}
		
		public function set type(t:uint):void{
			_type = t;
		}
		public function get metaName():String{
			return MidiEnum.getMessageName(type);
		}
		public function get size():uint{
			if( text )
				return text.length;
			else
				return 0;
		}
		
		override public function clone():MessageItem{
			var item:MetaItem = new MetaItem();
			item.kind = this.kind;
			item.timeline = this.timeline;
			item.text = this.text;
			item.type = this.type;
			return item;
		}
	}
	
}
