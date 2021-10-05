/* ContainerMenuBar - Is a base class for all Navigation interface item menus.
*/
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UMem;
	import											com.pippoflash.motion.PFMover;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;

	
	public class ContainerMenuBar extends _cBaseContainer {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="BG Class", type=String, defaultValue="com.pippoflash.components.assets.common.BgSquare")]
		public var _bgAttachment							:String = "com.pippoflash.components.assets.common.BgSquare"; // This decides the BG to be attached
		[Inspectable 									(name="Rollover Margin", type=Number, defaultValue=4)]
		public var _rollOverMargin							:uint = 4; // Distance from where a rollover opens up the menu
		[Inspectable 									(name="Hide", type=Boolean, defaultValue=true)]
		public var _hideOnRollout							:Boolean = true; // Hide on rollout
		[Inspectable 									(name="Always on top", type=Boolean, defaultValue=true)]
		public var _alwaysOnTop							:Boolean = true;
		[Inspectable 									(name="Position", type=String, defaultValue="BOTTOM", enumeration="BOTTOM,TOP,LEFT,RIGHT")]
		public var _position								:String = "BOTTOM";
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		private static const DISAPPEAR_AFTER					:uint = 1000; // Milliseconds after which to disappear
		private static const CLOSE_OFFSET					:uint = 2; // Add to offscreen close
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
		private var _checkTimer							:Timer;
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		protected var _rollOutSquare							:MovieClip; // The square to rollour to show the menu
		protected var _bgSprite							:Sprite;
		protected var _endClip								:DisplayObject;
		protected var _startClip							:DisplayObject;
		// DATA HOILDERS ///////////////////////////////////////////////////////////////////////////////////////
		// MARKERS ////////////////////////////////////////////////////////////////////////
		private var _isOpen								:Boolean;
// INIT ///////////////////////////////////////////////////////////////////////////////////////

		public function ContainerMenuBar						(id:String="ContainerMenuBar") {
			super									(id);
			_checkTimer								= new Timer(500, 0);
			_checkTimer.addEventListener					(TimerEvent.TIMER, checkMenuOpen);
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
			setupBg									();
			setupHide									();
			UGlobal.callOnStage							(initOnStage);
		}
		private function initOnStage							():void {
			UGlobal.addResizeListener						(onResize);
			positionMenu								();
		}
		private function setupHide							():void {
// 			if (_hideOnRollout) {
				_rollOutSquare							= UDisplay.getSquareMovieClip();
				_rollOutSquare.alpha						= 0;
				Buttonizer.setupButton					(_rollOutSquare, this, "RollSquare", "onRollOver");
// 			}
		}
		private function setupBg							():void {
			_bgSprite									= UCode.getInstance(_bgAttachment);
			addChildAt									(_bgSprite, 0);
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function open								(autoClose:Boolean=true):void {
			PFMover.slideIn							(this, {steps:6, pow:3, endPos:{y:UGlobal.stage.stageHeight-_h}});
			_isOpen									= true;
			_rollOutSquare.visible							= false;
			if (autoClose)								_checkTimer.start();
		}
		public function close								():void {
			PFMover.slideOut							(this, {steps:6, pow:3, endPos:{y:UGlobal.stage.stageHeight+CLOSE_OFFSET}, onComplete:onMenuDisappeared});
			_checkTimer.stop								();
			_isOpen									= false;
		}
			public function onMenuDisappeared				(o=null):void {
				_rollOutSquare.visible						= true;
			}
		public function onResize							(e:Event=null):void {
			positionMenu								();
		}
		public function setStartClip							(c:DisplayObject):void {
			_startClip									= c;
			addChild									(_startClip);
			alignStartClip								();
		}
		public function setEndClip							(c:DisplayObject):void {
			_endClip									= c;
			addChild									(_endClip);
			alignEndClip									();
		}
// COMMON METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public override function update						(par:Object):void {
			// Unly gets: _hideOnRollout
			super.update								(par);
			if (_hideOnRollout)							close();
			else										open(false);
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		protected function positionMenu						():void {
			y = UGlobal.stage.stageHeight+CLOSE_OFFSET; _w = UGlobal.stage.stageWidth; x = 0;
			if (!_hideOnRollout)							y = UGlobal.stage.stageHeight - _h;
			super.alignContainer							();
			alignStartClip								();
			alignEndClip									();
// 			if (_hideOnRollout) {
				_rollOutSquare.width						= UGlobal.stage.stageWidth;
				_rollOutSquare.y							= -_rollOverMargin;
				addChild								(_rollOutSquare);
// 			}
			UCode.setParameters							(_bgSprite, {width:_w, height:_h});
		}
		protected function alignStartClip						():void {
			if (!_startClip)								return;
			UDisplay.alignSpriteTo							(_startClip, new Rectangle(_extMargin,_extMargin,_w-(_extMargin*2),_h-(_extMargin*2)), "RIGHT", "MIDDLE");
		}
		protected function alignEndClip						():void {
			if (!_endClip)								return;
			UDisplay.alignSpriteTo							(_endClip, new Rectangle(_extMargin,_extMargin,_w-(_extMargin*2),_h-(_extMargin*2)), "RIGHT", "MIDDLE");
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function checkMenuOpen						(e:TimerEvent):void {
			if (mouseY < 0)								close();
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onRollOverRollSquare					(c:MovieClip):void {
			open										();
		}
	}
}