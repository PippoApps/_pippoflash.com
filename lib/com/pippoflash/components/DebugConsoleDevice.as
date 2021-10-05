package com.pippoflash.components {
	
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.UText;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UKey;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import											flash.net.*;
	import											flash.geom.*;
	
	public dynamic class DebugConsole extends _cBase {
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="0.0 - Show At Startup", type=Boolean, defaultValue=false)]
		public var _showAtStartup							:Boolean = false;
		[Inspectable 									(name="0.1 - Reset at line", type=Number, defaultValue=1000)]
		public var _resetAtLine								:uint = 1000;
// VARIABLES //////////////////////////////////////////////////////////////////////////
		public static var _minSize							:Point = new Point(380, 320);
		// USER VARIABLES
		// SYSTEM
		// REFERENCES
		// REFERENCES - to fool component definition export
		public var _bg									:MovieClip;
		public var _buttClose								:MovieClip;
		public var _txt									:TextField;
		public var _scrollBar								:MovieClip;
		// MARKERS
		public var _open									:Boolean = false;
		public var _resizing								:Boolean = false;
		// DATA HOLDERS
// INIT /////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function DebugConsole						(par:Object=null) {
			// Init super
			super									("DebugConsole", par);
			visible									= false;
			Debug.setupConsole							(this);
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
			UGlobal.callOnStage							(initOnStage);
		}
		public function initOnStage							():void {
			Buttonizer.autoButtons						([_buttFullscreen, _buttPlus, _buttMinus, _buttClose, _buttClear, _buttHandle, _scrollButtons._buttStepUp, _scrollButtons._buttStepDown, _scrollButtons._buttPageUp, _scrollButtons._buttPageDown], this);
			if (Buttonizer.isTouchDevice())					Buttonizer.setupButton(_bg, this, "BG", "onPress");
			Buttonizer.setClickThrough						(_txt);
			Buttonizer.autoTextContainer					(this, {_buttClose:"X", _buttClear:"CLEAR", _buttPlus:"+", _buttMinus:"-", _buttFullscreen:"FULLSCREEN"});
			width = UGlobal._sw; height = UGlobal._sh; update({});
			if (_showAtStartup)							show();
		}
		public override function update						(par:Object):void {
			super.update								(par);
			positionGraphics								();
		}
		private function positionGraphics						():void {
			_bg.width = _w; _bg.height = _h;
			_txt.height = (_bg.height - (_txt.y + 10)); _txt.width = _w - 75;
			_buttHandle.x = _w; _buttHandle.y = _h;
			_scrollButtons.x = _w; _scrollButtons.y = _h;
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function set text							(t:String) {
			_txt.text									= t;
		}
		public function get text							():String {
			return									_txt.text;
		}
		public function appendText							(t:String) {
			_txt.appendText								(t);
			setTimeout									(scrollToBottom, 1);
		}
		public function scrollToBottom						(e=null) {
			_txt.scrollV									= _txt.maxScrollV;
		}
		public function show								() {
			_open									= true;
			UGlobal.stage.addChild							(this);
			visible									= true;
		}
		public function hide								() {
			_open									= false;
			visible									= false;
		}
// RESIZER ////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function onPressHandle						(c:MovieClip=null) {
			
		}
		public function onPressBG							(c:MovieClip=null):void {
			width										= this.mouseX > _minSize.x ? this.mouseX : _minSize.x;
			height									= this.mouseY > _minSize.y ? this.mouseY : _minSize.y;
			update									({});
		}
// UTY //////////////////////////////////////////////////////////////////////////////////////////////////
// BRODACAST ///////////////////////////////////////////////////////////////////////////////////////
// ENTER FRAME ACTIONS  ///////////////////////////////////////////////////////////////////////////////////////
// OPEN/CLOSE ////////////////////////////////////////////////////////////////////////////////////////////////////////
// LOADING ///////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onKeyPress							() {
			if (_open)									hide();
			else										show();
		}
		public function onPressClose							(c:MovieClip=null) {
			hide										();
		}
		public function onPressClear							(c:MovieClip=null) {
			Debug.resetConsole							();
		}
		public function onPressStepDown						(c:MovieClip=null) {
			UText.addToScroll							(_txt, 1);
		}
		public function onPressStepUp						(c:MovieClip=null) {
			UText.addToScroll							(_txt, -1);
		}
		public function onPressPageDown						(c:MovieClip=null) {
			UText.scrollPage								(_txt, 1);
		}
		public function onPressPageUp						(c:MovieClip=null) {
			UText.scrollPage								(_txt, -1);
		}
		public function onPressPlus							(c:MovieClip=null) {
			UText.setTextFormat							(_txt, {size:_txt.getTextFormat().size + 1});
		}
		public function onPressMinus							(c:MovieClip=null) {
			UText.setTextFormat							(_txt, {size:Number(_txt.getTextFormat().size) - 1});
		}
		public function onPressFullscreen						(c:MovieClip=null):void {
			UGlobal.toggleFullScreen						();
		}
	}
}