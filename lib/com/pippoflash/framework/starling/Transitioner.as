package com.pippoflash.framework.starling 
{
	import com.pippoflash.motion.PFMover;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import com.pippoflash.utils.*;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class Transitioner extends _StarlingBase 
	{
		// DEFAULTS
		private static const TRANSITION_IN_TIME:Number = 2;
		private static const TRANSITION_OUT_TIME:Number = 2;
		// System
		private var _mover:PFMover;
		private var _transitioning:Vector.<DisplayObject>;
		private var _masks:Dictionary;
		private var _methods:Dictionary;
		// Variables
		private var _timeIn:Number;
		private var _timeOut:Number;
		// STATIC UTYS
		private static var _unusedMasks:Vector.<DisplayObject>;
		private static var _m:Quad;
		
		
		/**
		 * Instantiate with unique id.
		 * @param	id
		 */
		public function Transitioner(id:String) {
			super("Transitioner_" + id, Transitioner, false);
			// Static init
			if (!_unusedMasks) {
				_unusedMasks = new Vector.<starling.display.DisplayObject>();
			}
			// Instance init
			_mover = new PFMover(_debugPrefix);
			_transitioning = new Vector.<starling.display.DisplayObject>();
			_masks = new Dictionary(true);
			_methods = new Dictionary(true);
			_timeIn = TRANSITION_IN_TIME;
			_timeOut = TRANSITION_OUT_TIME;
		}
		/**
		 * Has a mask arrive from a direction.
		 * @param	c Item to add
		 * @param	rect Rectangle for dimensions of mask
		 * @param	dir Direction. Random on Top Bottom Left Right
		 * @param	useContainer Put the object inside a container and mask it, or mask the object directly
		 */
		public function maskIn(c:DisplayObject, rect:Rectangle, dir:String = "RANDOM or (TBRL)", onComplete:Function = null, useParent:Boolean = false):void {
			Debug.debug(_debugPrefix, "Fade IN " + c);
			var m:Quad = setupMask(c, rect, onComplete, useParent);
			var d:String = dir.indexOf("RANDOM") == 0 ? ("TBRL").charAt(Math.floor(Math.random() * 4)) : dir;
			var pos:Object = {onComplete:onFadeComplete, onCompleteParams:c};
			if (d == "T") {
				m.height = 0;
				m.y = rect.height;
				pos.y = rect.y;
				pos.height = rect.height;
			}
			else if (d == "B") {
				m.height = 0;
				m.y = rect.y;
				pos.height = rect.height;
			}
			else if (d == "L") {
				m.width = 0;
				m.x = rect.width;
				pos.x = rect.x;
				pos.width = rect.width;
			}
			else if (d == "R") {
				m.width = 0;
				m.x = rect.x;
				pos.width = rect.width;
			}
			Debug.debug(_debugPrefix, "Transitioning in ", c, d, Debug.object(pos));
			_mover.move(m, _timeIn, pos);
		}
		public function maskOut(c:DisplayObject, rect:Rectangle, dir:String = "RANDOM or (TBRL)", onComplete:Function = null, useParent:Boolean = false):void {
			Debug.debug(_debugPrefix, "Fade OUT " + c);
			var m:Quad = setupMask(c, rect, onComplete, useParent);
			var d:String = dir.indexOf("RANDOM") == 0 ? ("TBRL").charAt(Math.floor(Math.random() * 4)) : dir;
			var pos:Object = {onComplete:onFadeComplete, onCompleteParams:c};
			if (d == "T") {
				pos.height = 1;
			}
			else if (d == "B") {
				pos.height = 1;
				pos.y = rect.y + rect.height;
			}
			else if (d == "L") {
				pos.width = 1;
			}
			else if (d == "R") {
				pos.width = 1;
				pos.x = rect.y + rect.width;
			}
			Debug.debug(_debugPrefix, "Transitioning in ", c, d, Debug.object(pos));
			_mover.move(m, _timeOut, pos);
		}
		private function onFadeComplete(c:DisplayObject):void {
			Debug.debug(_debugPrefix, "Completed fade: " + c);
			if (_methods[c.mask]) _methods[c.mask]();
			_methods[c.mask] = null;
			//stop(c);
		}
		
		private function setupMask(c:DisplayObject, rect:Rectangle, onComplete:Function = null, useParent:Boolean = false):Quad {
			// Get previous mask or create a new one
			var m:Quad;
			//if (c.mask == _masks[c]) {
				//m = c.mask as Quad;
				//trace("Usng the same quad as mask");
			//}
			//else m = new Quad(rect.width, rect.height);
			m = _masks[c] ? _masks[c] : new Quad(rect.width, rect.height);
			m.width = rect.width; m.height = rect.height;
			m.x = rect.x; m.y = rect.y;
			c.mask = m;
			//useParent ? c.parent.addChild(m) : (c as DisplayObjectContainer).addChild(m);
			_masks[c] = m;
			if (onComplete) _methods[m] = onComplete;
			Debug.debug(_debugPrefix, "Masking " + c, rect);
			return m;
		}
		public function stop(c:DisplayObject):void {
			/* TO BE IMPLEMENTED MASK STOP AND REMOVAL */
			//if (c.mask) {
				//if (c.mask != _masks[c]) {
					//Debug.warning(_debugPrefix, "DisplayObject " + c + " is already masked, but not with masks from me.");
				//} else {
					//
				//}
				//c.mask.dispose();
			//}
			//if (_masks[c]) { // This guy is masked with me but mask has to be removed
				//if (c.mask != _masks[c]) {
					//Debug.warning(_debugPrefix, "DisplayObject " + c + " is already masked, but not with masks from me.");
					//trace("TOLGOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",c);
				//}
				//c.mask = null;
				//_m = _masks[c];
				//_mover.stopMotion(_m);
				//_methods[_m] = null;
				//_unusedMasks.push(_m);
				//_m = _masks[c] = null;
			//}
		}
		
		static private function getQuad(w:Number, h:Number):Quad {
			
			if (_unusedMasks.length) {
				_m = _unusedMasks.pop();
				_m.width = w;
				_m.height = h;
				_m.x = _m.y = 0;  
				return _m;
			}
			return new Quad(w, h);
		}
		
		public function set timeIn(value:Number):void {
			_timeIn = value;
		}
		
		public function set timeOut(value:Number):void {
			_timeOut = value;
		}
		
		
		
		
		
		
	}

}