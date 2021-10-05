package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UText;
	import											com.pippoflash.utils.UDisplay;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public class PippoFlashSlider extends _cBase{
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable (name="Link ID for Graphic Asset", type=String, defaultValue="Components_PippoFlash_Slider_DefaultGraphics")]
		public var _graphicsLinkage							:String = "Components_PippoFlash_Slider_DefaultGraphics";
		[Inspectable (name="Is this a video slider?", type=Boolean, defaultValue=false)]
		public var _isVideo								:Boolean = false;
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// USER VARIABLES
		// REFERENCES
		private var _mainGraphics							:DisplayObject;
		private var _handle								:MovieClip;
		// MARKERS
		private var _percent								:Number;
		private var _startX								:Number;
		private var _endX								:Number;
		private var _slideW								:Number;
// INIT ////////////////////////////////////////////////////////////////////////////////////////////
		public function PippoFlashSlider						(par:Object=null) {
			super									("PippoFlashSlider", par);
		}
		protected override function initialize					():void {
			super.initialize								();
			_mainGraphics								= UCode.getClassInstanceByName(_graphicsLinkage);
			_handle									= _mainGraphics["_handle"];
			_handle["ButtonizerId"]						= UText.getRandomString();
			_mainGraphics["_sizer"].y						= -_mainGraphics["_sizer"].height/2;
			Buttonizer.setupButton						(_handle, this, "Handle", "onPress,onRelease,onReleaseOutside");
			addChild									(_mainGraphics);
			render									();
		}
		private function render							() {
// 			UDisplay.removeChild							(this, _mainGraphics);
			if (!_mainGraphics)							return; // This is needed to prevend calling resize() before graphics are actually rendered
			_startX									= _mainGraphics["_sizer"].x;
			_endX									= _w - _startX;
			_slideW									= _w-(_startX*2);
			_handle.x									= _startX;
			_percent									= 0;
			UCode.setParameters							(_mainGraphics, {y:_h/2});
			UCode.setParameters							(_mainGraphics["_bg"], {width:_w, height:_h, y:-_h/2});
			UCode.setGroupParameters						([_mainGraphics["_sizer"],_mainGraphics["_borderProgress"],_mainGraphics["_progress"],_mainGraphics["_bgProgress"]], {x:_startX, width:_slideW});
			setupVideoMode								();
			complete									();
		}
		private function setupVideoMode						() {
			if (_mainGraphics) 							UCode.setGroupParameters([_mainGraphics["_borderProgress"],_mainGraphics["_progress"],_mainGraphics["_bgProgress"]], {visible:_isVideo});
		}
		public override function resize						(w:Number, h:Number):void {
			super.resize								(w, h);
			render									();
// 			if (_isText)									updateTextFieldScrollers();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setPosition							(n:Number) {
			setPercent									(n);
		}
		public function setPercent							(n:Number) {
			_handle.x									= Math.round(_startX + percentToPixels(n));
			checkHandlePosition							();
		}
		public function setProgress							(n:Number) {
			_mainGraphics["_progress"].width					= percentToPixels(n);
			checkHandlePosition							();
		}
		public function getPercent							():Number {
			return									_percent;
		}
		public function stepPlus							() {
			setPercent									(_percent+5);
			broadcastEvent								("onSliderUpdate", _percent);
		}
		public function stepMinus							() {
			setPercent									(_percent-5);
			broadcastEvent								("onSliderUpdate", _percent);
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function percentToPixels						(n:Number):Number {
			return									UCode.getPercent(UCode.checkPercentRange(n), _slideW);
		}
		private function checkHandlePosition					() {
// 			trace("CHECCKO");
			if (_isVideo && (_handle.x-_startX)>_mainGraphics["_progress"].width) _handle.x = _mainGraphics["_progress"].width+_startX;
// 			else if (_handle.x < _startX)					_handle.x = _startX;
			_percent									= getNewPercent();
		}
		private function getNewPercent						():Number {
			var p										:Number = UCode.setRange(UCode.calculatePercent(_handle.x-_startX, _slideW));
			return									p;
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
// 		private static const SLIDE_MIN_OFFSET					:uint = 1;
// 		private static const SLIDE_MAX_OFFSET				:uint = 1;
		public function onPressHandle						(c:DisplayObject=null) {
			broadcastEvent								("onSliderPress");
// 			_handle.startDrag							(false, new Rectangle(_startX-SLIDE_MIN_OFFSET, 0, _endX+SLIDE_MAX_OFFSET, 0));
			UGlobal.stage.addEventListener					(MouseEvent.MOUSE_MOVE, onMouseMoveSlider);
		}
		public function onReleaseHandle						(c:DisplayObject=null) {
			broadcastEvent								("onSliderRelease");
// 			_handle.stopDrag							();
			UGlobal.stage.removeEventListener				(MouseEvent.MOUSE_MOVE, onMouseMoveSlider);
			if (getNewPercent() != _percent) {
				_percent								= getNewPercent();
				broadcastEvent							("onSliderChange", _percent);
			}
		}
		public function onReleaseOutsideHandle					(c:DisplayObject=null):void {
			onReleaseHandle								(c);
		}
		public function onMouseMoveSlider					(e:Event=null) {
// 			_handle.x									= Math.round(_handle.x);
// 			adjustHandlePosition							();
			var xPos									:Number = mouseX;
// 			trace(UCode.setRange(_handle.x, _startX, _endX));
			_handle.x									= UCode.setRange(xPos, _startX, _endX);
// 			trace(xPos, _startX);
// 			if (getNewPercent() != _percent) {
				broadcastEvent							("onSliderUpdate", getNewPercent());
// 			}
		}
// 			private function adjustHandlePosition				():void {
// 				if (_handle.x < _startX)					_handle.x = _startX;
// 			}
	}
	
	
	
}