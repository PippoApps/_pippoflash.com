/* _LoaderBase - (c) Filippo Gregoretti - PippoFlash.com */
/* This is the base class for all Loaders */

package com.pippoflash.movieclips.loaders {
	import									com.pippoflash.utils.*;
	import com.pippoflash.framework._PippoFlashBase;
	import									flash.geom.*;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import 									flash.utils.*;
	import									com.pippoflash.net.SimpleQueueLoaderObject;
	import com.pippoflash.motion.Animator;
	import com.pippoflash.motion.PFMover;
	import com.pippoflash.utils.UDisplay;
	import com.pippoflash.utils.UGlobal;
	
	
	public dynamic class _LoaderBase extends _PippoFlashBase {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		public static var _fadeInFrames:uint = 30;
		public static var _fadeOutFrames:uint = 30;
		// SYSTEM
		public var _id							:uint;
		// USER VARIABLES
		// REFERENCES
		// MARKERS
		protected var _active:Boolean = false;
		protected var _hasStageShield:Boolean=false;
		// DATA HOLDERS
		protected var _percent					:Number;
		protected var _text						:String;
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function _LoaderBase(id:String="_LoaderBase", cl:Class=null) {
			super(id, cl ? cl : _LoaderBase);
		}
		public function harakiri():void {
			
		}
		public function cleanup():void {
			
		}
		public function recycle():void {
			
		}
// RENDER //////////////////////////////////////////////////////////////////////////////////////////
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function reset(t:String=""):void {
			setText(t);
			setPercent(0);
		}
		public function show(instant:Boolean=false, txt:String="", onArrived:Function=null):void {
			reset(txt);
			setActive(true);
			startAnim();
			appear(instant, onArrived);
		}
			protected function appear(instant:Boolean=true, onArrived:Function=null):void {
				visible = true;
				if (instant) onAppeared(onArrived);
				else {
					alpha = 0;
					Animator.fadeIn(this, _fadeInFrames, onAppeared, onArrived ? onArrived : UCode.dummyFunction);
				}
			}
			protected function onAppeared(onArrived:Function=null):void {
				if (onArrived) onArrived();
			}
		public function hide(instant:Boolean = true, onHidden:Function=null):void {
			//trace("CAZZO HIDE");
			stopAnim();
			disappear(instant, onHidden);
		}
			protected function disappear(instant:Boolean = true, onHidden:Function = null):void {
				if (instant) onDisappeared(onHidden);
				else Animator.fadeOutAndKill(this, _fadeOutFrames, onDisappeared, onHidden ? onHidden : UCode.dummyFunction);
			}
			protected function onDisappeared(onHidden:Function = null):void {
					visible = false;
					setActive(false);
					UDisplay.removeClip(this);
					if (onHidden) UExec.next(onHidden);
			}
		public function shieldStage					(shield:Boolean):void {
			
		}
		public function startAnim					():void {
		}
		public function stopAnim					():void {
		}
		public function setActive					(a:Boolean):void {
			_active							= a;
		}
		public function isActive					():Boolean {
			return							_active;
		}
		public function setText					(t:String):void {
			_text								= t;
		}
		public function setTextInTextField(textFieldName:String, txt:String):void {
			trace(this[textFieldName], textFieldName)
			if (this[textFieldName]) this[textFieldName].text = txt;
		}
		public function setPercent					(n:Number):void {
			_percent							= n;
		}
		public function setAmounts					(total:Number, loaded:Number):void {
			setPercent							(UCode.calculatePercent(loaded, total));
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		public function connectToLoader(loader:SimpleQueueLoaderObject):void {
			loader.connectWithMe(this);
		}
		public function setStageShield(shield:Boolean=true):void {
			if (shield && this["_shield"]) {
				this["_shield"].update();
				this["_shield"].visible = shield;
				this["_shield"].alpha = 1;
			}
			_hasStageShield = shield;
		}
		public function resizeToStage():void { // Makes sure that loader screen fits into stage
			UDisplay.resizeTo(this, UGlobal.getStageRect());
			UDisplay.centerToStage(this);
			setStageShield(_hasStageShield);
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onLoadStart					(o:SimpleQueueLoaderObject):void {
		}
		public function onLoadInit					(o:SimpleQueueLoaderObject):void {
			
		}
		public function onLoadComplete				(o:SimpleQueueLoaderObject):void {
			hide();
		}
		public function onLoadError					(o:SimpleQueueLoaderObject):void {
			hide();
		}
		public function onLoadProgress				(o:SimpleQueueLoaderObject):void {
			setPercent							(o._percent);
		}
	}
}