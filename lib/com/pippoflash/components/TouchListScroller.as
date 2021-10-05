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
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	
	
	import com.pippoflash.utils.*;
	
	public class TouchListScroller extends _cBaseMasked {
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="1.0 - Slots Content", type=Array, defaultValue="Sun,Mon,Tue,Wed,Thu,Fri,Sat")]		public var _defaultContent							:Array = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]; // Default comntent array to be copied into a vector
		[Inspectable 									(name="1.2 - Slots distance step", defaultValue=100, type=Number)]
		public var _slotsStep								:Number = 100; // Howmany extra slots of content are visible on top and below
		[Inspectable 									(name="1.3 - Extra visible slots (on top and below)", defaultValue=1, type=Number)]
		public var _visibleSlotsNum							:uint = 1; // Howmany extra slots of content are visible on top and below
		[Inspectable 									(name="1.4 - Render at startup", defaultValue=false, type=Boolean)]
		public var _renderAtStartup							:Boolean = false;
		[Inspectable 									(name="1.5 - Slots Pos offset", defaultValue=0, type=Number)]
		public var _slotVerticalOffset							:Number = 0; // Positioning of slot, this will be added for visual coherence (some fonts are superscript or subscipt)
		[Inspectable 									(name="1.6 - Slots Size offset", defaultValue=0, type=Number)]
		public var _slotSizeOffset							:Number = 0; // Influences slot dimensions, but not positioning
		[Inspectable 									(name="2.0 - Broadcast on stop", defaultValue=true, type=Boolean)]
		public var _broadcastOnStop						:Boolean = true; // Howmany extra slots of content are visible on top and below
		[Inspectable 									(name="2.1 - Speed modifier", defaultValue=10, type=Number)]
		public var _speedModifier							:Number = 10; // Howmany extra slots of content are visible on top and below
		[Inspectable 									(name="2.2 - Time modifier", defaultValue=4, type=Number)]
		public var _timeModifier							:Number = 4; // Howmany extra slots of content are visible on top and below
		[Inspectable 									(name="2.3 - Min. time for Launch", defaultValue=50, type=Number)]
		public var _minTimeForLaunch						:Number = 50; // Howmany extra slots of content are visible on top and below
		[Inspectable 									(name="2.4' - Minimum pixel motion", defaultValue=5, type=Number)]
		public var _minMotion								:Number = 5; // Howmany extra slots of content are visible on top and below
		[Inspectable 									(name="3.1 - Horizontal (not active)", defaultValue=false, type=Boolean)]
		public var _isHorizontal							:Boolean = false;
		[Inspectable 									(name="DEBUG - Show TextField border", defaultValue=false, type=Boolean)]
		public var _showTFBorder							:Boolean = false;
		[Inspectable 									(name="DEBUG - BG Alpha", defaultValue=0, type=Number)]
		public var _bgBoxAlpha							:Number = 0;
		[Inspectable 									(name="DEBUG - Do not mask", defaultValue=false, type=Boolean)]
		public var _doNotMask								:Boolean = false;
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		private static var _pfMover							:PFMover;
		private static const _textFieldDefaultProps				:Object = {condenseWhite:true, autoSize:"none", mouseWheelEnabled:false, multiline:false, selectable:false, wordWrap:false};
		private static const EV_ON_STOP						:String = "onScrollerStop"; // [ID:uint] This is called with the last selected number when scroller stops
		private static const EV_ON_RUNNING					:String = "onScrollerSelect"; // [ID:uint] This is the event that is called as soon as a number is centered, also when moving
		private static const VERBOSE						:Boolean = true;
		private static const MIN_TIME_LAUNCH					:Number = 0.5; // Launch sometimes gives time 0, if 0 this is the minimum
		// USER VARIABLES
		// SYSTEM
		private var _myContent							:Vector.<String>; // to speed up, I convert array to vector
		private var _visibleSlots							:Vector.<TextField>;
		private var _allSlots								:Vector.<TextField>; 
		private var _slotsWholeSize							:uint; // Size of total slots rendered
		private var _maxVisibleSlots							:uint; // the max number of visible slots. When I am in the middle of whole slots;
		private var _slotsNum								:uint; // total number of slots
		private var _textFieldProps							:Object;
		private var _content								:Sprite;
		private var _bg									:MovieClip;
		
		// LAUNCH AND SCROLL
		private var _pressPos								:int; // The position where I pressed the mouse (doesn't change)
		private var _lastPos								:int; // The last position where I start calculating motion
		private var _lastLaunchPos							:int; // Tha last position where I memorized a launch start pos
		private var _pressTime							:uint; // The moment I start counting for a press and a launch time (gets updated while scrolling with no force)
		private var _hasForce								:Boolean; // If the motion has been fast and long enough to have a launch force
		private var _adding								:Boolean; // the direction in which is scrolling, needed to find the closest slot
		// MOTION
		private var _destinationPos							:int; // The destination position when I am sliding into place
		public var _actualPos								:int; // PUBLIC because controlled by PFMover. The absolute position of wheel, while is scrolling or movig. when motion is over, it gets same like _realPos;
		private var _realPos								:int; // The real position of playhead, % of total position
		private var _displayStep							:int; // Sets the step of display, if it didn't change, then I do not have to re-render the slots
		private var _displayStepOffset						:int; // The amount of slots I need to display BEFOIRE and AFTER the selected slot
		private var _displayPosOffset						:int; // The amount of pixels I have to detract to position in order to center selected slot
		private var _selectedSlotPos							:int; // Marks the central positioning for selected slot
		private var _selectedId							:int; // ID of selected slot. It can happen on stop or while running. (it can be set as negative initially, so its a int)
			// ["alwaysShowSelection", "antiAliasType", "background", "backgroundColor", "border", "borderColor", "condenseWhite", "defaultTextFormat", "displayAsPassword", "embedFonts", "gridFitType", "maxChars", "mouseWheelEnabled", "multiline", "restrict", "scrollH", "scrollV", "selectable", "sharpness", "styleSheet", "textColor", "thickness", "type", "useRichTextClipboard", "wordWrap"];
// 		private var _slotsOffset							:uint;
		// REFERENCES
 		// MARKERS
		private var _pressed								:Boolean;
		// INTERFACE MODE MARKERS
		// SMOOTH SCROLL
// INIT /////////////////////////////////////////////////////////////////////////////////////////////////		
		public function TouchListScroller						(par:Object=null) {
			super									("TouchListScroller", par);
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
			if (!_pfMover) {
				_pfMover 								= new PFMover("TouchListScroller", "Quart.easeOut");
			}
			_verbose									= VERBOSE;
			_content									= new Sprite();
			_content.cacheAsBitmap						= true;
			_bg										= new MovieClip();
			_bg.cacheAsBitmap							= true;
			_bg.alpha									= _bgBoxAlpha;
			addChild									(_content);
			Buttonizer.setClickThrough						(_content);
			Buttonizer.setupButton						(_bg, this, "", "onPress,onRelease");
			removeChild								(this["_defaultTextField"]);
			setupSourceTextField							(this["_defaultTextField"]);
			this["_defaultTextField"]						= null;
			renderBg									();
// 			UDisplay.drawSquare							(this, _w, _h, 0);
// 			scrollRect = null;
			if (_renderAtStartup)							renderContent(_defaultContent);
			_defaultContent								= null;
			if (_doNotMask)								scrollRect = null;
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		
		public function setupSourceTextField					(t:TextField):void { // Setup a textfield to be used as source of formatting
			_textFieldProps								= UText.getTextFieldVisualProperties(t);
			for (_s in _textFieldDefaultProps)					_textFieldProps[_s] = _textFieldDefaultProps[_s];
			_s										= null;
			_textFieldProps.border							= _showTFBorder;
		}
		public function renderContent						(c:Array):void {
			_myContent								= new Vector.<String>(c.length);
			for (var i:uint=0; i<c.length; i++)				_myContent[i] = String(c[i]);
			renderSlots									();
		}
		public function setupTextFormatProperties				(o:Object):void { // Gets an object and converts it to textformat properties
			var tf									:TextFormat = UText.makeTextFormat(o);
			for each (_t in _allSlots) {
				_t.defaultTextFormat						= tf;
				_t.setTextFormat							(tf);
			}
			_t										= null;
		}
		public function setToSlot							(i:uint, scrolling:Boolean=false, broadcast:Boolean=false):void { // Sets interface to a precise slot
			// First find the step and scroll position from 0
			// Then find the closest scroll position (using modulo and adding the amount from 0)
			// Then launch the motion, eventually with time 0
// 			trace(name,"SETTTO A ",i);
			stopMotion									();
			var closestScroll								:int = -(i*_slotsStep);
			var largeActualScroll							:int = _actualPos%_slotsWholeSize;
			var actualScroll								:int = _actualPos - largeActualScroll;
			if (closestScroll == _actualPos || closestScroll == actualScroll || closestScroll == largeActualScroll) {
				Debug.debug							(_debugPrefix, "Cannot setToSlot(), scroll is aleady positioned.");
				return;
			}
			// Here, since scrolling is inverted, I need to do the opposite, if scrolling is negative, add +, if it is positive, remove
			var targetScroll								:int = largeActualScroll < 0 ? largeActualScroll-closestScroll : largeActualScroll+closestScroll;
// 			trace(name,"VERBOSE??? " + _verbose, "SETTO AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",i,_actualPos,largeActualScroll,closestScroll,actualScroll,targetScroll);
			moveToPos									(closestScroll, scrolling ? 0.5 : 0, broadcast); 
		}
		
	// FRAMEWORK
		public override function update						(par:Object):void {
			super.update								(par);
			proceedWithUpdate							();
			if (_verbose)								Debug.debug(_debugPrefix, "updated to:",Debug.getObjectString(par));
		}
		public override function resize						(w:Number, h:Number):void {
			super.resize								(w, h);
			proceedWithUpdate							();
			if (_verbose)								Debug.debug(_debugPrefix, "Resized to:",w,h);
		}
			private function proceedWithUpdate				():void {
				renderBg								();
			}
		public function setContent							(c:*, userBounds:Rectangle=null) {
		}
		public override function release						():void {
// 			stopScroll									();
// 			resetScroll									();
// 			if (!UCode.exists(_content))					return; // Prevent errors if content doesnt exist
// 			_content.scrollRect 							= null;
// 			UDisplay.removeClip							(_content);
// 			_content									= null;
			super.release								();
// 			graphics.clear								();
			
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		private function renderBg							():void {
			_bg.graphics.clear							();
			UDisplay.drawSquare							(_bg, _w, _h, 0xffffff);
			addChildAt									(_bg, 0);
		}
		private function renderSlots							():void {
// 			trace("FREGNAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
// 			var total:uint=7;
// 			for (var ii:int=-30; ii<31; ii++) {
// 				trace(ii,ii%total);
// 			}
			if (isRendered())							release();
			_slotsNum									= _myContent.length;
			_allSlots									= new Vector.<TextField>(_slotsNum);
			_maxVisibleSlots								= (_visibleSlotsNum*2)+3; // the maximum number of visible slots. A Central one, plus the 2 visible, and plus other 2.
			_displayStepOffset							= _visibleSlotsNum + 1;
			_displayPosOffset							= ((_visibleSlotsNum*2)*_slotsStep) - ((_h-_slotsStep)/2);
			_visibleSlots								= new Vector.<TextField>(_maxVisibleSlots);
			var slot									:TextField;
			var slotSize								:uint = Math.round(_slotsStep + _slotSizeOffset);
			for (var i:uint=0; i<_slotsNum; i++) {
				// Here I create all slots
				slot									= new TextField();
				for (_s in _textFieldProps)					slot[_s] = _textFieldProps[_s];
				slot.width								= _w;
				slot.height								= slotSize;
				slot.text								= _myContent[i];
// 				slot.border = true;
				_allSlots[i]								= slot;
				slot.y 								= (slot.height*i);
			}
			_slotsWholeSize								= _slotsStep*_slotsNum;
			_actualPos									= 0;
			_destinationPos								= 0;
			_displayStep								= 9999999999;
			renderSlotsPosition							();
		}
// MOVE ///////////////////////////////////////////////////////////////////////////////////////
		private function updateScrollPosition					(p:int):void { 
			// Called during finger scroll
// 			trace("AGGIUNGPO",p);
			if (p) {
				_actualPos								+= p;
				_adding								= p > 0; // If I am scroling down or up
				renderSlotsPosition						();
			}
		}
		private function slideToClosestPosition					():void { // When it is released without launching it, it scrolls to closest slot
// 			_destinationPos								= _adding ? (_slotsStep * Math.ceil(_actualPos/_slotsStep)) : (_slotsStep * Math.floor(_actualPos/_slotsStep)); // Find howmany, round them, and multiply again!!!
			_destinationPos								= _slotsStep * Math.round(_actualPos/_slotsStep);
			moveToPos									(_destinationPos, 0.4);
		}
		private function renderSlotsPosition					():void {
			_realPos									= _actualPos%_slotsWholeSize;
			// Find step and eventually render blocks
			_content.y									= (_realPos%_slotsStep)-_displayPosOffset;
			var step									:int = Math.floor(_realPos)/_slotsStep*-1;
// 			trace("STEP",step);
			if (step < 0) {
				step = _slotsNum + step;
// 			trace("-STEP",step);
			}
			if (step != _displayStep) {
				_displayStep							= step;
				renderSlotsSteps							();
			}
			// Now position the visible items.
// 			_content.y									= -_displayPosOffset;
// 			_content.y									= (_realPos%_slotsStep)-_displayPosOffset;
// 			trace("POSIZIONE ",_actualPos,_realPos,step);
		}
		private function renderSlotsSteps						():void { // Render slots according to _displayStep
			// Remove all slots
			var slot									:TextField;
			var slotId									:uint;
			var mod									:int;
			_selectedId									= _displayStep%_slotsNum;
			if (_selectedId < 0 )							_selectedId = _slotsNum - _selectedId;
			var selectedSlot								:TextField = _allSlots[_selectedId]; // This is the slot which is selected NOW!
			if (!_broadcastOnStop)						broadcastEvent(EV_ON_RUNNING, _selectedId);
// 			trace("SELEZIONATO",_selectedId,_allSlots[_selectedId].text);
			for (_i=0; _i<_slotsNum; _i++) {
				if (_content.contains(_allSlots[_i]))			_content.removeChild(_allSlots[_i]);
			}
			// The real steps is the CENTRAL one, therefore I need to find an offset...
			for (_i=0; _i<_maxVisibleSlots; _i++) {
				mod									= ((_i+_displayStep)%_slotsNum)-_displayStepOffset;
// 				trace("MODULO",mod);
				if (mod < 0) {
					mod = mod%_slotsNum;
// 					trace("E' MINOREEEEEEEEEEEEEEEEEe",mod%_slotsNum);
				}
				slotId									= (mod < 0 ? _slotsNum+mod : mod);		
// 				trace("AGGIUNGO SLOT",_i,_displayStep,slotId,_allSlots[_displayStep].text);
				slot									= _allSlots[slotId];
// 				trace(slot);
				_content.addChild						(slot);
				slot.y									= (_slotsStep*_i) + _slotVerticalOffset;
			}
// 				trace("RENDERO SLOT",_displayStep,_allSlots[_selectedId].text);
			// Now I have to position content according to _actualPos
		}
		private function moveToPos							(p:Number, t:Number, broadcast:Boolean=true):void {
			if (_verbose) 								Debug.debug(_debugPrefix, "Moving to pos " + p + " in time " + t);
			_destinationPos								= p;
			if (_destinationPos == _actualPos) {
				Debug.debug							(_debugPrefix, "Change aborted, destination is already set.");
				completeMotion							(broadcast);
				return;
			}
			addEventListener								(Event.ENTER_FRAME, enterFrameTurning);
			if (t) {
				_pfMover.move							(this, t, {_actualPos:p, onComplete:completeMotion, onCompleteParams:[broadcast]}, "Cubic.easeOut");
			}
			else {
// 				_actualPos								= p;
// 				slideToClosestPosition						();
// 				renderSlotsPosition						();
				completeMotion							(broadcast);
			}
		}
		private function completeMotion						(broadcast:Boolean=true):void {
			_actualPos									= _destinationPos;
			stopMotion									();
			renderSlotsPosition							();
			if (broadcast)								broadcastEvent(EV_ON_STOP, _selectedId);
		}
		private function stopMotion							():void {
			removeEventListener							(Event.ENTER_FRAME, enterFrameTurning);
			_pfMover.stopMotion							(this);
		}
// LISTENERS /////////////////////////////////////////////////////////////////////////////////////
		public function enterFramePressed					(e:Event):void {
			var pos									:int = mouseY;
			_hasForce 									= Math.abs(pos - _lastPos) > _minMotion;
			if (pos != _lastPos) {
				// If there is no force, actual position becomes the start position
				if (!_hasForce) {
					_pressTime							= getTimer();
					_lastLaunchPos						= pos;
				}
// 				trace("STO AD ALTEZZA",pos-_pressPos);
				updateScrollPosition						(pos-_lastPos);
			}
			_lastPos									= pos;
		}
		public function enterFrameTurning					(e:Event):void {
// 			trace("GIRA");
			renderSlotsPosition							();
// 				trace("_actualPos",_actualPos);
		}
		public function onPress							(c:DisplayObject):void {
			stopMotion									();
			_pressed									= true;
			_pressPos = _lastPos = _lastLaunchPos				= mouseY;
			_pressTime									= getTimer();
			_hasForce									= false;
			addEventListener								(Event.ENTER_FRAME, enterFramePressed);
		}
		public function onRelease							(c:DisplayObject):void {
			removeEventListener							(Event.ENTER_FRAME, enterFramePressed);
			if (!_pressed) 								return;
			var releaseTime:uint 							= getTimer();
			var diffTime 								= getTimer() - _pressTime;
			if (!_hasForce || diffTime<_minTimeForLaunch) { // I am not launching, but I just need position where is most fit
				slideToClosestPosition						();
				return;
			}
// 			_lastPos									= pos;
			var releasePos 								= mouseY;
			var diffPos									:int = releasePos - _lastLaunchPos;
			var speed									:Number = diffPos / (diffTime/100);
			_destinationPos 								= Math.round(_actualPos+(_speedModifier*speed));
			// I must find a way to round the destination position to one number
// 			trace(_destinationPos,_slotsStep);
			var time:Number = (_timeModifier * Math.abs(speed))/1000;
			_destinationPos								= (_slotsStep * Math.round(_destinationPos/_slotsStep)); // Find howmany, round them, and multiply again!!!
// 			trace(_destinationPos);
			
			moveToPos									(_destinationPos, time < MIN_TIME_LAUNCH ? MIN_TIME_LAUNCH : time);
// 			trace("LANCIOOOOOOOOOOOOOOOOOOOOOOOOqOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");
// 			trace("da posizione",_actualPos,"a posizione");
// 			_m.move(_ball, time, {x:endPointX}, "Quart.easeOut");
// 			_m.move(_ball, time, {x:endPointX, y:endPointY}, "Quart.easeOut");
			// (c:*, time:Number, vars:Object, ease:String="Quart.easeOut", emd:String=null, dir:String="to"):TweenNano {
			// Now I have to find a speed accoridng to time and space
			// Divide pixels per seconds
// 			addEventListener								(Event.ENTER_FRAME, enterFrameTurning);
			
		}
		
// SCROLL FUNCTIONS ////////////////////////////////////////////////////////////////////////////////
	} // CLOSE CLASS ///////////////////////////////////////////////////////////////////////////////
}