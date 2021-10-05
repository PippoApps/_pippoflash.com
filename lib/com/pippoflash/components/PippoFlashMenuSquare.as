package com.pippoflash.components {
	
	import											com.pippoflash.motion.Animator;
	import											com.pippoflash.visual.Effector;
	import											com.pippoflash.motion.PFMover;
	import											com.pippoflash.utils.*;
// 	import											PippoFlashAS3.net.SuperLoaderObject;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import											flash.net.*;
	import											flash.geom.*;
	
	public dynamic class PippoFlashMenuSquare extends PippoFlashMenu_Base {
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="1.0 - Smooth animation?", type=Boolean, defaultValue=true)]
		public var _smooth								:Boolean = true;
		[Inspectable 									(name="1.1 - Blink on close?", type=Boolean, defaultValue=true)]
		public var _blinkOnClose							:Boolean = true;
		[Inspectable 									(name="1.2 - Class name for SLOT", type=String, defaultValue="PippoFlashMenuSquare_Slot")]
		public var _slotClassName							:String = "PippoFlashMenuSquare_Slot";
// VARIABLES //////////////////////////////////////////////////////////////////////////
		private static const SMOOTH_OPEN_FRAMES				:uint = 8; // Frames used to open the menu
		private static const SMOOTH_CLOSE_FRAMES				:uint = 4; // Frames used to close the menu
		// USER VARIABLES
		// SYSTEM
		public var _openMenuRect							:Rectangle;
		public var _effect								:Effector;
		public var _active								:Boolean = true;
		// REFERENCES
// 		public var _bg									:MovieClip; // Links to embedded _bg, to be used not to trigger error on export
		public var _selectedSlot							:MovieClip; // Links to last selected slot
		public var _lastPressedSlot							:MovieClip;
		private var _slotClass								:Class;
		// FOOL COMPILER FOR COMPONENTS
// 		public var _arrow; 
		// MARKERS
		// DATA HOLDERS
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function PippoFlashMenuSquare					(par:Object=null) {
			super									("PippoFlashMenuSquare", par)
			visible									= false;
		}
		protected override function initAfterVariables				():void {
			renderMain									();
			renderSlots									();
			setToClose									();
			visible									= true;
		}
// RENDER ////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function renderMain							() {
			_effect									= new Effector(_bg);
			_effect.setVisible								(false);
			_slotClass									= UCode.getClassFromString(_slotClassName); 
			UMem.addClass								(_slotClass);
			_menu.addChild								(_bg);
			_menu.addChild								(_arrow);
			UCode.setParameters							(_arrow, {y:_h/2, x:_w});
			addChild									(_menu);
			complete									();
		}
		public function renderSlots							() {
			Buttonizer.removeButtons						(_slots);
			UDisplay.removeClips							(_slots);
			UMem.storeInstances							(_slots);
			UDisplay.removeClip							(_slotsHolder);
			_slotsHolder								= UDisplay.addChild(_menu, new MovieClip());
			_slots									= new Array(_txtList.length);
			for (_i=0; _i<_txtList.length; _i++) {
				_c									= UDisplay.addChild(_slotsHolder, UMem.getInstance(_slotClass));
				UCode.setParameters						(_c._bg, {width:_w, height:_h});
				UCode.setParameters						(_c._tick, {y:_h/2, visible:false});
				UCode.setParameters						(_c._txt, {width:_w-_c._txt.x, y:(_h-_c._txt.height)/2});
				UText.setText							(_c._txt, _txtList[_i]);
				_slots[_i]								= _c;
				_c._id								= _i;
				_c._tick.visible							= false;
				setToNormal							(_c);
				Buttonizer.setupButton					(_c, this, "Slot");
			}
			_selectedSlot								= _lastPressedSlot = _slots[0];
		}
		
// FRAMEWORK ///////////////////////////////////////////////////////////////////////////////////////
		public override function update						(par:Object):void {
			super.update								(par);
			renderSlots									();
			setSelected								(0);
		}
// 		protected override function release							():void {
// 			UDisplay.removeClips								
// 			super.release								();
// 		}
// UTY //////////////////////////////////////////////////////////////////////////////////////////////////
		public function setToNormal							(c:MovieClip) {
			UText.setTextFormat							(c._txt, {color:_colorNorm});
		}
		public function setToRoll							(c:MovieClip) {
			UText.setTextFormat							(c._txt, {color:_colorRoll});
		}
		public function setToPress							(c:MovieClip) {
			UText.setTextFormat							(c._txt, {color:_colorPress});
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function close								() {
			if (_smooth)								smoothToClose();
			else										setToClose();
		}
		public function open								() {
			if (_smooth)								smoothToOpen();
			else										setToOpen();
		}
		public function setTexts							(a:Array) {
			for (_i=0; _i<a.length; _i++) {
				setSlotText								(_i, a[_i]);
			}
		}
		public function setSlotText							(n:uint, s:String) {
			UText.setText								(_slots[n]._txt, s);
		}
		public function setSelected							(n:uint) {
			if (_selectedSlot) { // There was already a selected slot to deselect
				_selectedSlot._tick.visible					= false;
			}
			_selectedSlot								= _lastPressedSlot = _slots[n]; // Selecting both, I do not trigger event
			setToClose									();
		}
		public function getSelectedText						():String {
			return									_txtList[_selectedNum];
		}
		public function setActive							(a:Boolean):void {
			_active									= a;
			if (!_active) {
				close									();
				alpha									= 0.4;
			}
			else {
				alpha									= 1;
			}
		}
// OPEN/CLOSE ////////////////////////////////////////////////////////////////////////////////////////////////////////
		private function setToClose							() {
			for each (_c in _slots)							_c.visible = false;
			_selectedSlot._tick.visible						= true;
			checkForChanged								();
			UCode.setParameters						(_selectedSlot, {x:0, y:0, visible:true});
			setToNormal								(_selectedSlot);
			UCode.setParameters						(_bg, {x:0, y:0, width:_w, height:_h});
			_isOpen									= false;
			_arrow.visible								= true;
		}
		private function checkForChanged						() {
			if (_lastPressedSlot != _selectedSlot) {
				_lastPressedSlot._tick.visible					= false;
				_selectedSlot							= _lastPressedSlot;
				_selectedSlot._tick.visible					= true;
				_selectedNum							= _selectedSlot._id;
				broadcastEvent							("onMenuChange", this);
			}
		}
		private function setToOpen							() {
			for each (_c in _slots) {
				trace(_c);
				_c.visible 								= true;
				_c.y									= _h*_c._id;
				_c._tick.visible							= false;
			}
			_selectedSlot._tick.visible						= true;
			_bg.height									= _slotsHolder.height;
			_isOpen									= true;
			_arrow.visible								= false;
		}
		private function smoothToOpen						() {
			_effect.setVisible								(true);
			PFMover.slideIn							(_bg, {steps:SMOOTH_OPEN_FRAMES, pow:3, endPos:{height:_h*_slots.length}});
			PFMover.slideIn							(_selectedSlot, {steps:SMOOTH_OPEN_FRAMES, pow:3, endPos:{y:_h*_selectedSlot._id}, onComplete:appearOpenSlots});
			for each (_c in _slots) {
				if (_c != _selectedSlot) {
					_c.y								= _h*_c._id;
				}
			}
			Animator.fadeOutAndInvisible					(_arrow);
		}
		public function appearOpenSlots						(c:MovieClip=null) {
			for each (_c in _slots) {
				if (_c != _selectedSlot) {
					Animator.fadeInTotal					(_c);
				}
			}
			_isOpen									= true;
		}
		private function smoothToClose						() {
			_effect.setVisible								(false);
			PFMover.slideIn							(_bg, {steps:SMOOTH_CLOSE_FRAMES, pow:3, endPos:{height:_h}});
			PFMover.slideIn							(_lastPressedSlot, {steps:SMOOTH_CLOSE_FRAMES, pow:3, endPos:{y:0}, onComplete:onMenuClosed});
			for each (_c in _slots) {
				if (_c != _lastPressedSlot) {
					_c.visible							= false;
				}
			}
			_selectedSlot._tick.visible						= false;
			_lastPressedSlot._tick.visible						= true;
			Animator.fadeInTotal							(_arrow, 15);
		}
		private function onMenuClosed						(c:MovieClip=null) {
			_isOpen									= false;
			checkForChanged								();
		}
// LOADING ///////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onRollOverSlot						(c:MovieClip) {
// 			if (!_isOpen && c == _selectedSlot)				return;
			setToRoll									(c);
		}
		public function onRollOutSlot							(c:MovieClip) {
			setToNormal								(c);
		}
		public function onPressSlot							(c:MovieClip) {
			if (!_active)								return;
			_lastPressedSlot								= c;
			if (!_isOpen && c == _selectedSlot) { // Menu is closed, and I am pressing the menu to open
				open									();
			}
			else if (_isOpen && c == _selectedSlot) { // I am pressing the same selected slot
				close									();
			}
			else { // I am selecting another slot
				close									();
			}
		}
	}
	
	
	
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