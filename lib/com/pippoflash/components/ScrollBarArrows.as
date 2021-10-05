
/* I differentiate this from another scrollbar enclosing the whole graphics into another movieclip
or maybe its already enclosed?

*/

package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.Debug;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
// 	import PippoFlashAS3_Contents_ScrollBarArrows_Cartoon;
// 	import PippoFlashAS3_Components_PippoFlashScrollBar_Minimal;
// 	import PippoFlashAS3_Components_PippoFlashScrollBar_Simple;
// 	import PippoFlashAS3_Contents_ScrollBarArrows_System;
// 	import PippoFlashAS3_Components_PippoFlashScrollBar_Talco;

	public class ScrollBarArrows extends _cBase {
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="0.0 - Link ID for ScrollBar Graphics", type=String, defaultValue="PippoFlashAS3_Contents_ScrollBarArrows_System")]
		public var _graphLinkage							:String = "PippoFlashAS3_Contents_ScrollBarArrows_System";
		[Inspectable 									(name="0.1 - Show Arrows", defaultValue=true, type=Boolean)]
		public var _showArrows							:Boolean = true;
		[Inspectable 									(name="0.2 - Handle fixed Height", defaultValue=false, type=Boolean)]
		public var _handleFixedHeight						:Boolean = false;
		[Inspectable 									(name="0.3 - Link to TextField for autoScroll", type=String)]
		public var _txtLink								:String;
		[Inspectable 									(name="0.4 - Disappear on no scroll", defaultValue=false, type=Boolean)]
		public var _disappearOnNoScroll						:Boolean = false;
		[Inspectable 									(name="0.5 - BG click scroll", type=String, defaultValue="STEP", enumeration="NONE,STEP,MOUSE")]
		public var _bgClickScroll							:String = "STEP";
		[Inspectable 									(name="1.0 - Use Mouse-wheel", defaultValue=true, type=Boolean)]
		public var _useMouseWheel							:Boolean = true;
		[Inspectable 									(name="1.1 - Mouse-wheel step", defaultValue=10, type=Number)]
		public var _mouseWheelStep						:Number = 10;
		[Inspectable 									(name="1.2 - Minimum height", defaultValue=30, type=Number)]
		public var _minHeight								:Number = 30;
		[Inspectable 									(name="1.3 - Maximum height", defaultValue=180, type=Number)]
		public var _maxHeight								:Number = 180;
		
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// USER VARIABLES
		// SYSTEM
		public var _maxScroll								:Number;
		// REFERENCES
		private var _graphicsCont							:*; // Double referencing to avoid compiler errors 
		public var _graphics								:*; // References _graphicsCont
		public var _bg									:*; // Bg bar of the scrollbar
		public var _handle								:*; // Handle button
		// TXT SCROLL VALUES
		public var _txt									:TextField; // The linked TextField
		public var _scrollMult								:Number; // Multiplier between scroll and percent
		public var _isText								:Boolean = false;
		public var _scrollableArea							:Number; // The max scrollable area for handle (this will be useful when putting arrows)
// 		public var _scrollBgSize								;Number; // 
 		// MARKERS
		public var _scroll:Number;
		public var _txtScroll:uint; // The real scroll of text
		public var _enabled:Boolean = true;
		public var _lastScrollPerc:Number = 0; // Marks latest scroll percent for restore
		public var _lastScrollY:Number = 0;
		public var _dragging:Boolean = false; // Marks if we are draging or not
// INIT /////////////////////////////////////////////////////////////////////////////////////////////////		
		public function ScrollBarArrows(par:Object=null) {
			super("ScrollBarArrows", par);
		}
		protected override function initialize():void {
			super.initialize();
			renderBar();
			if (_useMouseWheel) addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			_scroll = 0;
		}
		public function renderBar():void {
			if (_maxHeight == 0) _maxHeight = _h;
			setupGraphics();
			setupBgClick();
			checkTxtLink();
			setupScrolling();
			setEnabled(false);
		}
		public override function update(par:Object):void {
			super.update(par);
			renderBar();
			if (_isText)updateTextFieldScrollers();
		}
		public override function resize(w:Number, h:Number):void {
			super.resize(w, h);
			renderBar();
			if (_isText) updateTextFieldScrollers();
		}
		private function checkTxtLink() {
			// this checks if the user just added a txt link in component
			if (UCode.exists(_txtLink)) setTextField(UCode.getPathFromString(parent,_txtLink));
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setTextField							(tf:TextField) {
// 			trace										("SCROLLBAR> "+name+" è settata per un TextField " + tf.name);
			_txt										= tf;
			_isText									= true;
			_txt.addEventListener (Event.CHANGE, onTextFieldChanged);
			_txt.addEventListener							(Event.SCROLL, onTextFieldChanged);
			_txt.addEventListener							(TextEvent.TEXT_INPUT, onTextFieldChanged);
			updateTextFieldScrollers						();
		}
		public function scrollToTop							() {
			setHandlePosition							(0);
		}
		public function scrollToBottom						() {
			setHandlePosition							(_maxScroll);
		}
		public function stepUp							() {
			setHandlePosition							(_handle.y - _handle.height);
		}
		public function stepDown							() {
			setHandlePosition							(_handle.y + _handle.height);
		}
		public function loopDown							():void { // Scrolls down, if it can't scroll goes back up
			if (canStepDown())							stepDown();
			else										scrollToTop();
		}
		public function canStepDown						():Boolean {
			return									_handle.y < _maxScroll;
		}
		public function unitUp								(unit:uint=1):void {
			if (_isText)									_txt.scrollV	-= unit;
			else										stepUp();
		}
		public function unitDown							(unit:uint=1):void {
			if (_isText)									_txt.scrollV	+= unit;
			else										stepDown();
		}
		public function setEnabled							(e:Boolean) {
			try { // All this might be executed before ScrollBar initialized itself
				_handle.visible								= e;
				_graphics._tip.visible = e
			} catch (e) {};
			_enabled									= e;
			if (_disappearOnNoScroll)						visible = e;
		}
		public function setScrollSize							(total:Number, partial:Number) {
			// This resizes handle according to visible and total area
			// Handle size has to be in proportion what visible area is to total
			var perc									:Number = UCode.calculatePercent(partial, total);
			setSizePercent								(perc);
		}
		public function setSizePercent						(n:Number) {
			setHandleHeightInRange						(UCode.getPercent(_scrollableArea, n));
			setupScrolling								();
		}
		public function restoreScroll							() {
			setHandlePosition							(_lastScrollY);
		}
		public function scrollTo							(p:Number, b:Boolean=false):void {
			setScrollPosition								(p, b);
		}
		public function setScrollPosition						(perc:Number, broadcast:Boolean=true) {
			// Sets position of scrollbar in percent
			perc										= UCode.setRange(perc);
			_handle.y									= UCode.getPercent(_maxScroll, perc);
			_scroll									= perc;
			positionTip									();
			if (broadcast)								calculateAndBroadcastScroll();
		}
		public function checkVisibility						():void {
			if (_disappearOnNoScroll) {
// 				visible								= 
			}
		}
		public function getPercent							():Number {
			return									_lastScrollPerc;
		}
// RENDER ////////////////////////////////////////////////////////////////////////////////////////////////
		private function setupGraphics						() {
			if (!_graphics) { // Since this can be re-triggered, only if it doesn't exist
				_graphicsCont = UCode.getClassInstanceByName(_graphLinkage);
				_graphics = _graphicsCont;
				addChild (_graphics);
				_bg = _graphics._bg;
				_handle = _graphics._handle;
			}
			if (!_graphics || !_bg || !_handle) {
				Debug.error(_debugPrefix, "ATTENTION - ScrollBarGraphics instantiation error!!! Interrupting scrollbar rendering.  _graphics", _graphics, "_bg", _bg, "_handle", _handle);
				return;
			}
			_graphicsCont = null;
			_bg.width = _w;
			_handle.width = _w;
			_scrollableArea = _h;
			Buttonizer.setupButton(_handle, this, "Handle", "onPress,onRelease,onReleaseOutside");
			try { // Arrow clips may not be there
			_graphics._arrowUp.visible = _graphics._arrowDown.visible = _showArrows;
			if (_showArrows) {
				_scrollableArea = _h - (_w*2);
				_graphics.y = _w;
				UCode.setParameters(_graphics._arrowUp, {width:_w, height:_w, y:-_w});
				UCode.setParameters(_graphics._arrowDown, {width:_w, height:_w, y:_h-_w*2});
				Buttonizer.setupButton(_graphics._arrowUp, this, "ArrowUp", "onPress");
				Buttonizer.setupButton(_graphics._arrowDown, this, "ArrowDown", "onPress");
			}
			} catch (e) {}
			_bg.height									= _scrollableArea;
			try { // Tip clip may not be there
				_graphics._tip.x							= _w/2;
				Buttonizer.setClickThrough					(_graphics._tip);
			} catch (e) {}
		}
		private function setupBgClick						() {
			if (_bgClickScroll == "NONE")						return;
			Buttonizer.setupButton						(_bg, this, "BG"," onPress");
		}
		private function setupScrolling						() {
			_maxScroll									= _bg.height - _handle.height;
		}
		private function setScrollingActive						(a:Boolean) {
			if (a) {
				addEventListener							(Event.ENTER_FRAME, onMouseMoved);
			}
			else {
				removeEventListener						(Event.ENTER_FRAME, onMouseMoved);
			}
		}
		public function onMouseMoved						(e) {
			positionTip									();
			setTimeout									(calculateAndBroadcastScroll, 1);
		}
		public function calculateAndBroadcastScroll				(e=0) {
			_lastScrollY									= _handle.y;
			var s										:Number = UCode.calculatePercent(_handle.y, _maxScroll);
			if (_scroll == s)								return;
			if (s > 100)								s = 100;							
			_scroll									= s;
			_lastScrollPerc								= s;
			if (_isText) 								broadcastTxtScroll();
			else										broadcastScroll();
			positionTip									();
		}
		private function broadcastTxtScroll					() {
			_txtScroll									= Math.round(_scroll/_scrollMult) + 1;
			_txt.scrollV									= _txtScroll;
		}
		private function broadcastScroll						() {
			broadcastEvent								("onScroll", _scroll);
		}
// SCROLL FOR TEXTFIELD ////////////////////////////////////////////////////////////////////////////////
		private function updateTextFieldScrollers					() {
			setEnabled 									(_txt.maxScrollV > 1);
			//trace										("SCROLLBAR> Provo a sparire se non c'è scroll " + _disappearOnNoScroll + " : " + _txt.maxScrollV);
			if (_disappearOnNoScroll)						visible = _txt.maxScrollV > 1;
			positionTip									();
			if (_txt.maxScrollV == 1)						return; // Useless to calculate all if scroll is impossible
			updateTxtScrolling							();
		}
		private function updateTxtScrolling					() {
			var invLines								:uint = _txt.maxScrollV-1;
			var visLines								:uint = _txt.numLines - invLines;
// 			_handle.height								= Math.round((_bg.height / _txt.numLines) * visLines);
			setHandleHeightInRange						(Math.round((_bg.height / _txt.numLines) * visLines));
			setupScrolling								();
			_scrollMult									= 100 / invLines;
			_handle.y									= _maxScroll/invLines *  (_txt.scrollV-1);
			positionTip									();
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function setHandlePosition						(n:Number):void {
			_handle.y									= UCode.setRange(n, 0, _maxScroll);
			positionTip									();
			calculateAndBroadcastScroll						();
		}
		private function setHandleHeightInRange				(handleHeight:Number) {
			_handle.height								= UCode.setRange(handleHeight, _minHeight, _maxHeight);
			positionTip									();
		}
		private function positionTip							():void {
			try {
				_graphics._tip.y							= Math.round(_handle.y + _handle.height/2);
			} catch (e) {}
		}
// LISTENERS ////////////////////////////////////////////////////////////////////////////////////////////
		public function onTextFieldChanged					(e=null) {
			if (_dragging)								return;
			updateTextFieldScrollers						();
		}
		public function onPressHandle						(h:*) {
			_handle.startDrag							(false, new Rectangle(0,0,0,_maxScroll+0.5));
			_dragging									= true;
			setScrollingActive							(true);
			broadcastEvent								("onScrollHandlePress");
		}
		public var onReleaseOutsideHandle					:Function = onReleaseHandle;
		public function onReleaseHandle						(h:*) {
			_handle.stopDrag							();
			_dragging									= false;
			setScrollingActive							(false);
			broadcastEvent								("onScrollHandleRelease");
		}
		public function onPressBG							(c:MovieClip) {
			if (!_enabled)								return;
			if (_bgClickScroll == "STEP")						this[_graphics.mouseY > _handle.y ? "stepDown" : "stepUp"]();
			else {
				_handle.y 								= mouseY;
				if (_handle.y < 0)						_handle.y = 0;
				else if (_handle.y > _maxScroll)				_handle.y = _maxScroll;	
				calculateAndBroadcastScroll					();
			}
		}
		public function onReleaseBG							(c:MovieClip) {
			// I dont't know why Buttonizer doesn't get the parameter to use only onPress
		}
		public function onMouseWheel						(e) {
			if (_isText)									this[Number(e.delta)>0 ? "unitUp" : "unitDown"]();
			else										setScrollPosition(Number(e.delta)>0 ? _scroll-_mouseWheelStep : _scroll+_mouseWheelStep);
		}
		public function onPressArrowUp						(c:MovieClip=null) {
			unitUp									();
		}
		public function onPressArrowDown						(c:MovieClip=null) {
			unitDown									();
		}
	}
}