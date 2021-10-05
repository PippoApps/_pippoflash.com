/* ContainerMenuBar - Is a base class for all Navigation interface item menus.
*/

package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UMem;
	import											com.pippoflash.motion.PFMover;
	import											com.pippoflash.visual.Effector;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;

	// FRAMEWORK 0.44
	public class ContainerSmooth extends _cBaseContainer {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		private static var _zenoSteps					:uint = 15; // Steps to half differences with zeno's paradox
		private static var _zenoDivider					:Number = 1.2; // Zeno divides by
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		private static var _decreaseStepBefore				:Number; // Step to decrease for other clips BEFORE
		private static var _decreaseStepAfter				:Number; // Step to decrease for other clips BEFORE
		private static var _i							:uint;
		private static var _c							:_cBase;
		private static var _p							:Point;
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		// DATA HOILDERS ///////////////////////////////////////////////////////////////////////////////////////
		private var _originalSizes						:Vector.<Object>;
		// MARKERS ////////////////////////////////////////////////////////////////////////
		private var _enlargeClip						:*;
		private var _enlargeNum						:uint; // Index of the clip to enlarge
		private var _enlargeClipOrigRect					:Object; // Original size and position
		private var _enlarging							:Boolean;
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function ContainerSmooth					(par:Object=null) {
			super								("ContainerSmooth", par);
		}
// SMOOTH MOTION OF JUST ONE CLIP ///////////////////////////////////////////////////////////////////////////////////////
		public function highlightClip						(c:*, scale:Number=0.2, frames:uint=4, glowTime:Number=0.2):void {
			if (_enlargeClip == c)						return;
			PFMover.removeMotion					(c);
			_enlarging								= true;
			_enlargeClip							= c;
			_enlargeNum							= _clips.indexOf(_enlargeClip);
			_enlargeClipOrigRect						= _originalSizes[_enlargeNum];
			var xDiff								:Number = _enlargeClipOrigRect.x-(((_enlargeClipOrigRect.width*(1+scale))-_enlargeClipOrigRect.width)/2);
			var yDiff								:Number = _enlargeClipOrigRect.y-(((_enlargeClipOrigRect.height*(1+scale))-_enlargeClipOrigRect.height)/2);
			UDisplay.moveToTop						(c);
			PFMover.slideIn						(_enlargeClip, {steps:frames, pow:3, endPos:{x:xDiff, y:yDiff, scaleX:_enlargeClipOrigRect.scale+scale, scaleY:_enlargeClipOrigRect.scale+scale}});
// 			Effector.setGlow							(c, glowTime);
		}
		public function resetHighlightClip					(frames:uint=16, glowTime:Number=0.2):void {
			PFMover.slideIn						(_enlargeClip, {steps:frames, pow:3, endPos:{x:_enlargeClipOrigRect.x, y:_enlargeClipOrigRect.y, scaleX:_enlargeClipOrigRect.scale, scaleY:_enlargeClipOrigRect.scale}});
			Effector.stopGlow						(_enlargeClip, glowTime);
			_enlargeClip							= null;
		}
// COMMON METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public override function release					():void {
			var c:*;
			for each (c in _clips)						PFMover.removeMotion(c);
			super.release							();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
			public override function setup				(a:Array):void {
				super.setup						(a);
				_originalSizes						= new Vector.<Object>();
				for (var i:uint=0; i<_clips.length; i++) {
					_clip							= _clips[i];
					_originalSizes[i] = {x:_clip.x, y:_clip.y, width:UCode.getWidth(_clip), height:UCode.getHeight(_clip), scale:_clip.scaleX};
				}
				_w = _bgContent.width; _h = _bgContent.height;
			}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}