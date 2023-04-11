package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.Debug;
// 	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.motion.PFMover;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	import com.pippoflash.utils.UDisplay;
	
	public class ContentBox extends _cBase {
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="1.18 - La sorca fracica fracica", type=String)]
		public var _scrollHorizLink3							:String;
		[Inspectable 									(name="1.1 - Link to HORIZONTAL ScrollBar", type=String)]
		public var _scrollHorizLink							:String;
		[Inspectable 									(name="1.0 - Link to VERTICAL ScrollBar", type=String)]
		public var _scrollVertLink							:String;
		[Inspectable 									(name="1.2 - Use mouse wheel", defaultValue=true, type=Boolean)]
		public var _useMouseWheel							:Boolean = true;
		[Inspectable 									(name="1.3 - Mouse-wheel step", defaultValue=10, type=Number)]
		public var _mouseWheelStep							:Number = 10;
		[Inspectable 									(name="1.4 - Smooth Scroll", defaultValue=true, type=Boolean)]
		public var _smoothScrollOn							:Boolean = true;
		[Inspectable 									(name="1.5 - Cover BG (shield so that content doesnt click thru)", defaultValue=true, type=Boolean)]
		public var _coverBg								:Boolean = true;
		[Inspectable 									(name="1.6 - Auto Scroll", defaultValue=false, type=Boolean)]
		public var _autoScroll								:Boolean = false;
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		public static var _scrollSpeed						:uint = 8; // Number of frames for smooth scrolling
		public static var _scrollPow							:uint = 3; // Exponential for smooth scrolling
		private static var _verbose							:Boolean = false;
		// USER VARIABLES
		public var _autoScrollMargin							:uint = 16; // Number of pixels to add to autoscroll when an object has to be set to visible automatically
		public var _mouseScrollMargin						:uint = 8; // The margin from sides to go with mouse to beginning or end of scroll
		// SYSTEM
		private var _rectangle								:Rectangle = new Rectangle();
		private var _realBounds							:Rectangle = new Rectangle(); // This to overcome horrible bug in dimensions with scrollRect set
		// REFERENCES
		private var _content								:*;
		public var _scrollV								:MovieClip; // Reference to a PippoFlashScrollBar
		public var _scrollH								:MovieClip; // Reference to a PippoFlashScrollBar
		private var _scrollVfunc							:Function; // Accordin to the type of scroll, links to the correct function
		private var _scrollHfunc							:Function; // Accordin to the type of scroll, links to the correct function
		private var _bgClip								:DisplayObject; // If activated, this will cover the BG (to block click thru, and listen mousewheel)
		private var _textField								:TextField; // The textfield used for setText();
 		// MARKERS
		private var _boundaries							:Rectangle = new Rectangle();
		public var _scrollVperc								:Number = 0;
		public var _scrollHperc								:Number = 0;
		private var _latestScrollV							:Number = 0; // This one remains memorized and its not reset if I want to re-scroll after an update of content - DOESNT WORK NOW
		private var _latestScrollH							:Number = 0; // This one remains memorized and its not reset if I want to re-scroll after an update of content - DOESNT WORK NOW
		// SMOOTH SCROLL
		private var _targetVperc							:Number;
		private var _targetHperc							:Number;
		private var _targetH								:Number; // Target in pixels
		private var _targetV								:Number; // Target in pixels
// INIT /////////////////////////////////////////////////////////////////////////////////////////////////		
		public function ContentBox							(par:Object=null) {
			super									("ContentBox", par);
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
			_rectangle									= new Rectangle(0, 0, _w, _h);
			if (UCode.exists(_scrollVertLink))					_scrollV = setupScrollBarLink(_scrollVertLink, "Vertical");
			if (UCode.exists(_scrollHorizLink))					_scrollH = setupScrollBarLink(_scrollHorizLink, "Horizontal");
			if (_useMouseWheel)							addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			if (_coverBg)								renderBgCover();
		}
			private function renderBgCover():void {
				_bgClip = addChild(UDisplay.getSquareSprite(_w, _h, 0));
			}
			private function setupScrollBarLink(link:String, funcPost:String):MovieClip {
				return setupScrollBar(UCode.getPathFromString(this.parent, link), funcPost);
			}
				private function setupScrollBar(sb:MovieClip, funcPost:String):MovieClip {
					sb._cBase_eventPostfix = funcPost;
					sb.addListener(this);
					return sb;
				}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public override function update						(par:Object):void {
			super.update								(par);
			proceedWithUpdate							();
			if (_verbose)								Debug.debug(_debugPrefix, "updated to:",Debug.object(par));
		}
		public override function resize						(w:Number, h:Number):void {
			super.resize								(w, h);
			proceedWithUpdate							();
			if (_verbose)								Debug.debug(_debugPrefix, "Resized to:",_rectangle);
		}
			private function proceedWithUpdate				():void {
				_rectangle								= new Rectangle(0, 0, _w, _h);
				if (hasContent())						setContent(_content);
			}
		public function setContent							(c:*, userBounds:Rectangle=null) {
			if (UCode.exists(_content))						releaseContent();
			_scrollVfunc								= _smoothScrollOn ? smoothScrollV : doScrollV; // I set those here since stopping scroll I could remove them
			_scrollHfunc								= _smoothScrollOn ? smoothScrollH : doScrollH; // I set those here since stopping scroll I could remove them
			_content									= c is Sprite || c is MovieClip ? c : UDisplay.wrapInNewSprite(c);
			_realBounds								= getFullBounds(_content);
			_content.x = 0; _content.y = 0;
			addChild									(_content);
			updateSize									(userBounds);
			resetScroll									();
			setAutoScrollActive							(_autoScroll);
			adjustScrollV								();
			_content.scrollRect							= _rectangle;
			complete									();
		}
// 		public function setText							(txt:String, tf:TextField=null, useHtml:Boolean=true, userBounds:Rectangle=null, format:*=null):TextField {
// 			// format, can be both a TextFormat or an object with properties
// 			_textField									= new TextField();
// 			if (format)									UText.setTextFormat(_textField, format);
// 			if (userBounds)								UDisplay.resizeToRect
// 			return									_textField;
// 		}
		public function setScrollBarV							(sb:MovieClip):void {
			_scrollV 									= setupScrollBar(sb, "Vertical");
		}
		public function setScrollBarH							(sb:MovieClip):void {
			_scrollH 									= setupScrollBar(sb, "Horizontal");
		}
		public override function release						():void {
			stopScroll									();
			resetScroll									();
			if (!UCode.exists(_content))					return; // Prevent errors if content doesnt exist
			_content.scrollRect 							= null;
			UDisplay.removeClip							(_content);
			_content									= null;
			super.release								();
		}
		public var releaseContent							:Function = release;
		public function stopScroll							():void {
			_realBounds								= new Rectangle(0,0,0,0);
			resetScroll									();
			stopSmoothScroll								();
			setAutoScrollActive							(false);
			PFMover.stopStaticMotion						(this);
		}
		public function hasContent							():Boolean {
			return									Boolean(_content);
		}
		public function scrollToPerc							(perc:Number) {
			scrollToPercV								(perc);
		}
		public function scrollSmallStepV						(down:Boolean):void {
			// Here I scroll 1 third of the total
// 			var step									:Number = 
			scrollToV									(down ? _targetV-_rectangle.height/2 : _targetV+_rectangle.height/2);
		}
		public function stepV								(step:Number) {
			_scrollVfunc								(_scrollVperc + step);
		}
		public function scrollToV							(px:Number) {
			scrollToPercV								(UCode.calculatePercent(px, _boundaries.y));
		}
		public function scrollToPercV							(perc:Number) {
			_scrollVfunc								(perc);
			_targetV									= _rectangle.y;
// 			_targetV									= Math.round(UCode.getPercent(_targetVperc, _boundaries.x));
		}
		public function stepH								(ahead:Boolean=true):void { // Steps +1 or -1 - moves the amount of content 1 step
			scrollToH									(_rectangle.x + (ahead ? _w : -_w));
		}
		public function scrollToH							(px:Number) {
			scrollToPercH								(UCode.calculatePercent(px, _boundaries.x));
		}
		public function scrollToPercH							(perc:Number) {
			_scrollHfunc								(perc);
// 			_targetH									= _rectangle.x;
			_targetH									= Math.round(UCode.getPercent(_targetHperc, _boundaries.x));
		}
		public function resetScroll							() {
			UCode.setParameters							(_rectangle, {x:0, y:0});
			_scrollVperc = _scrollHperc = _targetH = _targetV = _targetVperc = _targetHperc = _latestScrollH = 0;
			if (_scrollV)								_scrollV.scrollToTop();
			if (_scrollH)								_scrollH.scrollToTop();
		}
		public function updateSize							(userBounds:Rectangle=null) {
			if (userBounds)								_realBounds = userBounds;
			_boundaries								= new Rectangle(_realBounds.width-_w, _realBounds.height-_h, _w, _h);
			if (UCode.exists(_scrollV)) {
				_scrollV.setScrollSize						(_realBounds.height, _h);
				_scrollV.setEnabled						(_realBounds.height > _h);
			}
			if (UCode.exists(_scrollH)) {
				_scrollH.setScrollSize						(_realBounds.width, _w);
				_scrollH.setEnabled						(_realBounds.width > _w);
			}
		}
		public function getScrollH							():Number {
			return									_targetH;
		}
		public function getScrollV							():Number {
			return									_targetV;
		}
		public function hasVScroll							():Boolean {
			return									_realBounds.height > _h;
		}
		public function hasHScroll							():Boolean {
			return									_realBounds.width > _w;
		}
		public function scrollToTop							() {
			scrollToPerc								(0);
		}
		public function scrollToBottom						() {
			scrollToPerc								(100);
		}
		public function restoreScroll							() { // Scrolls again to the latest position
			if (UCode.exists(_latestScrollV))					scrollToPercV(_latestScrollV);
		}
		public function updateLastScroll						() {
			_latestScrollV								= _targetVperc;
		}
		public function scrollToShowContent					(c:DisplayObject) { // Scrolls to show the specified content
			// MAKE SURE CONTENT IS REALLY INSIDE CONTENT BOX, OR BEHAVIOUR WILL BE HORRIBLE!!!
			if (_rectangle.y > (c.y-_autoScrollMargin))			scrollToV(c.y-_autoScrollMargin); // Scroll up if object is on top of scroll area
			else if (c.y > ((_rectangle.y+_rectangle.height)-(c.height+_autoScrollMargin))) scrollToV((c.y-(_rectangle.height-c.height))+_autoScrollMargin); // Scroll down if object is below visible area
		}
		public function setAutoScrollActive						(a:Boolean):void {
			if (a) {
				addEventListener(MouseEvent.MOUSE_MOVE, scrollOnMousePosition);
			}
			else {
				removeEventListener(MouseEvent.MOUSE_MOVE, scrollOnMousePosition);
			}
		}
		public function blockScrollH							():void {
			_scrollHfunc								= UCode.dummyFunction
		}
		public function blockScrollV							():void {
			_scrollVfunc								= UCode.dummyFunction
		}
		public function stopSmoothScroll						(e:*=null):void {
			stopSmoothScrollH							();
			stopSmoothScrollV							();
		}
// LISTENERS /////////////////////////////////////////////////////////////////////////////////////
		public function onScrollVertical						(perc:Number) {
			_scrollVfunc								(perc);
		}
		public function onScrollHorizontal						(perc:Number) {
			_scrollHfunc								(perc);
		}
		private function onMouseWheel						(e) {
			if (!hasVScroll())								return; // Inhibit scroll wheel if there is nothing to scroll
			scrollSmallStepV								(Boolean(Number(e.delta)>0));
// 			adjustScrollV								();
		}
		private function scrollOnMousePosition					(e:MouseEvent):void {
			if (hasVScroll())								onScrollVertical(UCode.calculatePercent(mouseY-_mouseScrollMargin, _h-_mouseScrollMargin*2));
			if (hasHScroll())								onScrollHorizontal(UCode.calculatePercent(mouseX-_mouseScrollMargin, _w-_mouseScrollMargin*2));
		}
// SCROLL FUNCTIONS ////////////////////////////////////////////////////////////////////////////////
	// NORMAL SCROLL
		private function doScrollV							(perc:Number) {
			if (!hasVScroll())								return;
			_targetVperc = _scrollVperc						= setInRange(perc);
			positionContentV								();
			broadcastV									();
		}
		private function doScrollH							(perc:Number) {
			if (!hasHScroll())								return;
			_targetHperc = _scrollHperc						= setInRange(perc);
			positionContentH								();
			broadcastH									();
		}
	// SMOOTH SCROLL
		private function smoothScrollV						(perc:Number) {
			if (!hasVScroll()) {
				stopSmoothScrollH						();
				return;
			}
			_targetVperc								= setInRange(perc);
			_latestScrollV								= _targetVperc; //UCode.getPercent(_boundaries.y, _targetVperc);
// 			trace(name, "SETTO SCROLLV ", _latestScrollV);
			activateSmoothScrolling						();
			adjustScrollV								();
			addEventListener								(Event.ENTER_FRAME, positionContentV);
			broadcastV									();
		}
		private function stopSmoothScrollV						() {
			removeEventListener							(Event.ENTER_FRAME, positionContentV);
		}
		private function smoothScrollH						(perc:Number) {
			if (!hasHScroll()) {
				stopSmoothScrollH						();
				return;
			}
			_targetHperc								= setInRange(perc);
			_latestScrollH								= _targetHperc; //UCode.getPercent(_boundaries.y, _targetVperc);
			activateSmoothScrolling						();
			adjustScrollH								();
			addEventListener								(Event.ENTER_FRAME, positionContentH);
			broadcastH									();
		}
		private function stopSmoothScrollH					() {
			removeEventListener							(Event.ENTER_FRAME, positionContentH);
		}
		private function activateSmoothScrolling					():void {
			PFMover.slideIn								(this, {steps:_scrollSpeed, pow:_scrollPow, endPos:{_scrollVperc:_targetVperc, _scrollHperc:_targetHperc}, onComplete:stopSmoothScroll});
		}
	// UTY - Check Range
		private function setInRange							(n:Number):Number {
			if (n > 100)								return 100;
			else if (n < 0)								return 0;
			else										return n;
		}
		private function checkRangeH						() {
			if (_scrollHperc < 0)							_scrollHperc = 0;
			else if (_scrollHperc > 100)						_scrollHperc = 100;
		}
	// UTY - Position Content
		private function positionContentV						(e=0) {
			_rectangle.y								= UCode.getPercent(_boundaries.y, _scrollVperc);
			if (_content != null)
				_content.scrollRect						= _rectangle;
		}
		private function positionContentH						(e=0) {
// 			trace(name,_rectangle,_rectangle.x,_scrollHperc,_boundaries.x,_content);
			_rectangle.x								= UCode.getPercent(_boundaries.x, _scrollHperc);
			_content.scrollRect							= _rectangle;
		}
	// UTY - Ajust ScrollBar Position
		private function adjustScrollV						() {
			if (UCode.exists(_scrollV))						_scrollV.setScrollPosition(_targetVperc, false);
		}
		private function adjustScrollH						() {
			if (UCode.exists(_scrollH))						_scrollH.setScrollPosition(_targetHperc, false);
		}
// 		private function checkScrollBarsVisible					():void {
// 			if (_scrollV)								_scrollV.setEnabled();
// 			if (_scrollH)								_scrollH.checkVisibility();
// 		}
	// UTY - Fucking solution to scrollrect problem
		private function getFullBounds 						(displayObject:DisplayObject):Rectangle {
			var bounds:Rectangle, transform:Transform, toGlobalMatrix:Matrix, currentMatrix:Matrix;
			transform 									= displayObject.transform;
			currentMatrix 								= transform.matrix;
			toGlobalMatrix 								= transform.concatenatedMatrix;
			toGlobalMatrix.invert							();
			transform.matrix 								= toGlobalMatrix;
			bounds 									= transform.pixelBounds.clone();
			transform.matrix 								= currentMatrix;
			return 									bounds;
		}
	// UTY - Broadcast scroll
		private function broadcastH							() {
			broadcastEvent								("onScrollH", _targetHperc);
		}
		private function broadcastV							() {
			broadcastEvent								("onScrollV", _targetVperc);
		}
		
	// UTY - Get reference to _content
		public function getContent () {
			return _content
		}

		
	} // CLOSE CLASS ///////////////////////////////////////////////////////////////////////////////
}

/* ________________________________________________________
All AS files and libraries included in the domain com.pippoflash.*
Are open.source libraries developed by Filippo Gregoretti, and are therefore not copyrightable.
They can be used in commercial projects but must be left free for re-distribution and usage.
They go with all MovieClips included in the .fla or .xfl document, in the folders:
- PippoFlash.com - Framework

- PippoFlash.com - Components
All movieclips and assets within those folders in the source flash document (fla or xfl) 
are open source anc dan be used in commercial projects, but cannot be copyrighted.
__________________________________________________________ */