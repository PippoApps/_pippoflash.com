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
		public var _resetAtLine							:uint = 1000;
		[Inspectable 									(name="0.2 - Key Combination", type=Array, defaultValue="C,O,N")]
		public var _keyCombination							:Array = ["C","O", "N"];
		[Inspectable 									(name="0.3 - Auto Full Screen", type=Boolean, defaultValue=true)]
		public var _autoFullScreen							:Boolean = true;
// VARIABLES //////////////////////////////////////////////////////////////////////////
		public static var _minSize							:Point = new Point(380, 320);
		// USER VARIABLES
		// SYSTEM
		// REFERENCES
		// REFERENCES - to fool component definition export
		public var _bg									:MovieClip;
// 		public var _buttClose								:MovieClip;
// 		public var _buttClear								:MovieClip;
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
			stop										();
			visible									= false;
			Debug.setupConsole							(this);
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
			UGlobal.callOnStage							(initOnStage);
		}
		public function initOnStage							():void {
			UKey.addSequenceListener						(this, _keyCombination, "DebugConsole");
			Buttonizer.autoButtons						([_buttClose, _buttClear], this);
// 			if (Buttonizer.isTouchDevice())					Buttonizer.setupButton(_bg, this, "BG", "onPress");
// 			Buttonizer.autoTextContainer					(this, {_buttClose:"X", _buttClear:"CLEAR"});
			onResize									();
			_buttClose._txt.text							= "X";
			_buttClear._txt.text							= "CLEAR";
			if (_showAtStartup)							show();
			UGlobal.addResizeListener(onResize);
		}
		public function onResize							():void {
			//if (_autoFullScreen) {
				//_w = UGlobal._sw; _h = UGlobal._sh;
			//}
			//update									({});
			resize(UGlobal._sw, UGlobal._sh);
		}
		override public function resize(w:Number, h:Number):void 
		{
			update({_w:w, _h:h});
			//_w = w;
			//_h = h;
			//super.resize(w, h);
		}
		public override function update						(par:Object):void {
			super.update								(par);
			positionGraphics								();
		}
		private function positionGraphics						():void {
			_bg.width = _w; _bg.height = _h;
			_txt.height = (_bg.height - (_txt.y + 10)); _txt.width = _w - 30;
			_scrollBar.x = _txt.x + _txt.width; _scrollBar.resize		(_scrollBar._w, _txt.height-20);
			addChild									(_txt);
		}
		public function setTextFormat						(tf:TextFormat, start, end):void {
			try {
				_txt.setTextFormat(tf, start, end);
			}
			catch (e:Error) {
					// Her eI can't use a Debug.error or will trigger an infinite loop
					//trace(_debugPrefix + " ERROR SETTING TEXTFORMAT");
			}
		}
		public function getTextFormat						():TextFormat {
			return									_txt.getTextFormat();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function set text							(t:String) {
			_txt.text									= t;
		}
		public function appendText							(t:String) {
			_txt.appendText								(t);
			setTimeout									(scrollToBottom, 1);
		}
		public function scrollToBottom						(e=null) {
			_txt.scrollV									= _txt.maxScrollV;
		}
		public function show								() {
			x = y = 0;
			_open									= true;
			UGlobal.stage.addChild						(this);
			visible									= true;
		}
		public function hide								() {
			_open									= false;
			visible									= false;
		}
	// GETTERS
		public function get text							():String {
			return									_txt.text;
		}
		public function get length							():uint {
			return									_txt.text.length;
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
		public function onKeyPressDebugConsole				() {
			if (_open)									hide();
			else										show();
		}
		public function onPressClose						(c:MovieClip=null) {
			hide										();
		}
		public function onPressClear						(c:MovieClip=null) {
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
		public function onPressMinus						(c:MovieClip=null) {
			UText.setTextFormat							(_txt, {size:Number(_txt.getTextFormat().size) - 1});
		}
		public function onPressFullscreen						(c:MovieClip=null):void {
			UGlobal.toggleFullScreen						();
		}
	}
}