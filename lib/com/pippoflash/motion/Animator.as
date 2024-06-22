package com.pippoflash.motion {
	import											com.pippoflash.motion.PFMover;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.Debug;
	import											flash.display.*;
// 	import											flash.text.*;
// 	import											flash.events.*;
	import 											flash.utils.*;
	
	public class Animator {
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		private static var _endMotionList:Object = new Object();
		private static const _showHideMover:PFMover = new PFMover("PippoFlashAnimator", "Cubic.easeInOut");
		private static const _debugPrefix:String = "Animator";
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public static function fadeTo(c:DisplayObject, to:Number=1, frames:uint=5, onComplete:Function=null, par:Object=null):void {
			PFMover.fadeTo(c, to, frames, onComplete, par);
		}
		public static function fadeIn(c:DisplayObject, frames:uint=5, onComplete:Function=null, par:Object=null):void {
			PFMover.fadeIn(c, frames, onComplete, par);
		}
		public static function fadeInTotal(c:DisplayObject, frames:uint=3, onComplete:Function=null, par:Object=null):void {
			PFMover.fadeInTotal(c, frames, onComplete, par);
		}
		public static function fadeOut(c:DisplayObject, frames:uint=3, onComplete:Function=null, par:Object=null):void {
			PFMover.fadeOut(c, frames, onComplete, par);
		}
		public static function fadeOutAndKill(c:DisplayObject=null, frames:uint=5, onComplete:Function=null, par:Object=null):void {
			PFMover.fadeOutAndKill(c, frames, onComplete, par);
		}
		public static function fadeOutAndInvisible(c:DisplayObject=null, frames:uint=5, onComplete:Function=null, par:Object=null):void {
			PFMover.fadeOutAndInvisible(c, frames, onComplete, par);
		}
		public static function stopMotion(c:DisplayObject):void {
			PFMover.stopStaticMotion(c);
		}
// EFFECTS ///////////////////////////////////////////////////////////////////////////////////////
// SHOW and HIDE ///////////////////////////////////////////////////////////////////////////////////////
	// Set show and hid positions for display objects. Any property can be used to set the objects in hide and show.
	// If I call hide and a show position is not defined, or vice-versa, the other position will be taken from properties of object calling the reverse function
		private static const PROPERTY_FOR_HIDESHOW_SPEED	:String = "hideShowSpeed"; // If this property is in the motion object, this will be used, otherwise the default
		private static const DEFAULT_HIDESHOW_SPEED		:Number = 0.5; // Seconds for default hide/show speed
		private static var _hidePositions						:Dictionary = new Dictionary();
		private static var _showPositions					:Dictionary = new Dictionary();
	// Registering one position, if the other is not set, it is generated automatically by the actual position of object
		public static function registerHidePos					(c:DisplayObject, pos:Object, setNow:Boolean=false):void {
			_hidePositions[c]							= pos;
			if (!_showPositions[c])						setupPositionObject(c, _showPositions, pos);
			if (setNow)								hideNow(c);
		}
		public static function registerShowPos				(c:DisplayObject, pos:Object, setNow:Boolean=false):void {
			_showPositions[c]							= pos;
			if (!_hidePositions[c])						setupPositionObject(c, _hidePositions, pos);
			if (setNow)								showNow(c);
		}
		public static function hideNow						(c:DisplayObject):void {
			UCode.setParametersForced					(c, _hidePositions[c]);
			c.visible									= false;
		}
		public static function showNow						(c:DisplayObject):void {
			UCode.setParametersForced					(c, _showPositions[c]);
			c.visible									= true;
		}
		public static function hide							(c:DisplayObject, pos:Object=null, callback:Function=null, instant:Boolean=false, moveId:String="DEFAULT", postDirective:String="INV"):void {
			pos										= pos ? pos : _hidePositions[c];
			if (!pos) {
				Debug.error							(_debugPrefix, "No show positions received for",c,"and no stored.");
				return;
			}
			if (!_showPositions[c])						setupPositionObject(c, _showPositions, pos);
			var par									:Object = UCode.duplicateObject(pos);
			par.onComplete								= callback;
			par.onCompleteParams						= [c];
			var speed									:Number = par[DEFAULT_HIDESHOW_SPEED] ? par[DEFAULT_HIDESHOW_SPEED] : DEFAULT_HIDESHOW_SPEED
			_showHideMover.move						(c, speed, par, null, postDirective);
		}
		public static function show						(c:DisplayObject, pos:Object=null, callback:Function=null, instant:Boolean=false, moveId:String="DEFAULT"):void {
			pos										= pos ? pos : _showPositions[c];
			if (!pos) {
				Debug.error							(_debugPrefix, "No show positions received for",c,"and no stored.");
				return;
			}
			if (!_hidePositions[c])						setupPositionObject(c, _hidePositions, pos);
			var par									:Object = UCode.duplicateObject(pos);
			par.onComplete								= callback;
			par.onCompleteParams						= [c];
			var speed									:Number = par[DEFAULT_HIDESHOW_SPEED] ? par[DEFAULT_HIDESHOW_SPEED] : DEFAULT_HIDESHOW_SPEED
			c.visible									= true;
			_showHideMover.move						(c, speed, par);
		}
				private static function setupPositionObject		(c:DisplayObject, d:Dictionary, pos:Object):void {
					var o							:Object = {};
					for (var i:String in pos)				o[i] = c[i];
					d[c]								= o;
				}
	}
}