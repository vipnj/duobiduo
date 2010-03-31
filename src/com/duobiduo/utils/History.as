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


package com.duobiduo.utils 
{
	
	/**
	* Histroy holds a stack.
	* All local item operations will be recorded into this global stack.
	* Thus, undo and redo features are performed based on it.
	* @author Efishocean
	* @version 2.0.0
	*/
	public class History {

		private var _size:uint;

		private var _pointer:uint;
		
		private var _stack:Array;

		private static var singleton:History;
		
		public function get tail():uint{
			return _stack.length-1;
		}
		
		public function set size(size:uint):void{
			_size = size;
		}
		public function get size():uint{
			return _size;
		}		
		public function get data():*{
			return _stack[_pointer];
		}
		
		public function get pointer():uint{
			return _pointer;
		}

		public static function getGlobalHistory():History
		{
			if( singleton==null ){
				singleton = new History();
				return singleton;
			}
			else
				return singleton;
		}
		
		public function History(size:uint=128):void{

			_size = size;
			_stack = new Array();
			// head of _stack should always be empty Object.
			_stack.push( null );
			_pointer = 0;
			
		}
		
		public function execute(states:*):void
		{
			//push the operations of current changed-session on the top of undo stack
			if (_pointer < _size)
			{
				//pointer points the tail. acts like a stack
				++_pointer;
				_stack[_pointer] = operations;
				//cut the stack at current point, next states are abondoned
				_stack.length = _pointer + 1;
			}
			else
			{
				//stack is full, shift the bottom
				_stack.shift();
				_stack[0] = null;
				_stack.push( operations );
			}
		}
		
		public function undo():void
		{
			if (_pointer > 0)
			{
				_pointer--;
			}
		}
		
		public function redo():void
		{
			if (_pointer < this.tail)
			{
				_pointer++;
			}
		}
	}
	
}
