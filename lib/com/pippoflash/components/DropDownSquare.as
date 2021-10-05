/* DropDownSquare - (c) Filippo Gregoretti - www.pippoflash.com*/package com.pippoflash.components {	import com.pippoflash.utils.*; import com.pippoflash.motion.PFMover; 	import flash.display.*; import flash.text.*; import flash.events.*; import flash.utils.*; import flash.net.*; import flash.geom.*;
	import com.pippoflash.gui.elements.AutoShield;	public dynamic class DropDownSquare extends _cBase {	// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
	// CONSTANTS
		public static const EVT_SELECTED						:String = "onMenuSlotSelected"; // When 1 is selected
		public static const EVT_DESELECTED					:String = "onMenuSlotDeselected"; // When 1 is deselected
		public static const EVT_SELECTIONUPDATE				:String = "onMenuSelection"; // When selection is modified
		public static const EVT_OPEN						:String = "onMenuOpen"; 
		public static const EVT_CLOSE						:String = "onMenuClose"; 
		private static const ANIM_TIME						:Number = 0.2;
		private static const INACTIVE_ALPHA					:Number = 0.5;
	// STATIC
		private static var _pfMover							:PFMover = new PFMover("DropDownSquare");
	// CONTENT AND TEXT		[Inspectable 									(name="Content - Slots Names", type=Array, defaultValue="Header 1,Header 2,Header 3, Header 4, Header 5")]		public var _slotsNames							:Array = ["Header 1","Header 2","Header 3","Header 4","Header 5"];		[Inspectable 									(name="Content - Slots Data", type=Array, defaultValue="30,20,20,15,15")]		public var _slotsDatas								:Array = [30,20,20,15,15];
		[Inspectable 									(name="Content - Main Slot Text", type=String, defaultValue="Options Menu")]		public var _menuTitle								:String = "Options Menu";
		[Inspectable 									(name="UX - Open onRollOver", type=Boolean, defaultValue=false)]		public var _openOnRollOver							:Boolean = false;		[Inspectable 									(name="UX - Open Smooth Animation", type=Boolean, defaultValue=true)]		public var _useSmoothAnimation						:Boolean = true;		/* TO BE IMPLEMENTED */		[Inspectable 									(name="UX - Main Slot - Replace Title with selection (not valid for multiple)", type=Boolean, defaultValue=true)]		public var _replaceTitleWithSelection					:Boolean = true; // This is switched off if multiple selection is selected. Overrides Use Title When Closed.		[Inspectable 									(name="UX - Allow Multiple Selection - overrides all", type=Boolean, defaultValue=false)]		public var _allowMultipleSelection						:Boolean = false;		[Inspectable 									(name="UX - Close On Selection", type=Boolean, defaultValue=false)]		public var _closeOnSelection							:Boolean = false;

		[Inspectable 									(name="UI - Class Square Clip", type=String, defaultValue="DropDownSquare_DefaultBg")]		public var _bgClassName							:String = "DropDownSquare_DefaultBg";		[Inspectable 									(name="UI - Class Arrow (centered, when opened flipped)", type=String, defaultValue="DropDownSquare_DefaultArrow")]		public var _arrowClassName							:String = "DropDownSquare_DefaultArrow";		[Inspectable 									(name="UI - Class Main Slot (_bg & _txt)", type=String, defaultValue="DropDownSquare_DefaultMainSlot")]		public var _mainSlotClassName						:String = "DropDownSquare_DefaultMainSlot";		[Inspectable 									(name="UI - Class Slot (_bg & _txt)", type=String, defaultValue="DropDownSquare_DefaultSlot")]		public var _slotClassName							:String = "DropDownSquare_DefaultSlot";		[Inspectable 									(name="UI - Class Marker (top left)", type=String, defaultValue="DropDownSquare_DefaultMarker")]		public var _markerClassName						:String = "DropDownSquare_DefaultMarker";		[Inspectable 									(name="UI - Slot Text Color", type=Color, defaultValue="#000000")]		public var _txtColorNorm							:uint = 0x000000;		[Inspectable 									(name="UI - Slot Text Color Selected", type=Color, defaultValue="#ff0000")]		public var _txtColorSel								:uint = 0xff0000;		[Inspectable 									(name="UI - Slot Text Color RollOver", type=Color, defaultValue="#00ff00")]		public var _txtColorRoll							:uint = 0x00ff00;		[Inspectable 									(name="UI - Slots Text position", type=Number, defaultValue=24)]		public var _slotsTxtPos								:Number = 24;		[Inspectable 									(name="UI - Slots distance from main (positive or negative)", type=Number, defaultValue=0)]		public var _slotsDistance							:Number = 0;		[Inspectable 									(name="UI - Slots Spacing (positive or negative)", type=Number, defaultValue=0)]		public var _slotsSpacing							:Number = 0;		[Inspectable 									(name="UI - Slots Height (0 for main height)", type=Number, defaultValue=0)]		public var _slotsHeight								:uint = 0;		[Inspectable 									(name="UI - BG Bottom margin (positive or negative)", type=Number, defaultValue=0)]		public var _bgMargin								:uint = 0;

		[Inspectable 									(name="System - Render In", type=String, defaultValue="stage", enumeration="stage,parent,this")]
		public var _renderTargetName						:String = "stage";		// STATIC ////////////////////////////////////////////////////////////////////////////////		// UTY		// VARIABLES //////////////////////////////////////////////////////////////////////////		// USER VARIABLES		// SYSTEM
		private var _internalMarker							:DisplayObject;
		private var _slotsNum								:int; // Total number of slots
		private var _localPosition							:Point; // Stores local position of closed menu
		private var _localParent							:DisplayObjectContainer; // Stores which clip is the local position container
		private var _slots								:Array; // The complete list of slots
		private var _renderTarget							:DisplayObjectContainer; // Where I should render my menu
		private var _slotHeight								:int;
		private var _slotsContainer							:Sprite = new Sprite();
		private var _openBgHeight							:uint;
		private var _shield								:com.pippoflash.gui.elements.AutoShield = new com.pippoflash.gui.elements.AutoShield();
		private var _active								:Boolean = true; // Active by default. Marks if menu is set to active or not. If menu is disactivated, even if re-rendered it will not be activated until setActive(true);		// REFERENCES
		private var _bg									:Sprite;
		private var _arrow								:Sprite;
		private var _markers								:Array = []; // Stores the markers, one for slot		// MARKERS
		private var _selectedSlots							:Array = []; // Stores the selected slots. If single selection, only the first one is returned
		private var _isOpen								:Boolean; // If menu is open or close - check with isOpen();
		private var _mainSlot								:MovieClip; // Can be a main slot, or a linkage to selected slot		// DATA HOLDERS
		private var _tooltip								:String; // If this is defined, a tooltip will appear rolling over		// SYSTEM - RENDERING UTY// INIT ///////////////////////////////////////////////////////////////////////////////////////		public function DropDownSquare						(par:Object=null) {			super									("DropDownSquare", par);
		}// RECURRENT INIT ///////////////////////////////////////////////////////////////////////////////////////		protected override function initialize					():void { 			// This is called EVERY TIME the component is initialized. It suppose a full re-rendering. Its called automatically in recycle().			initializeGraphics								();			initializeProperties							();			super.initialize								();
			if (_cBase_doNotInit)							return;
			renderContent								();		}			private function initializeGraphics					():void {				UMem.addClassString					(_bgClassName);				UMem.addClassString					(_slotClassName);
				UMem.addClassString					(_arrowClassName);				UMem.addClassString					(_markerClassName);
				UMem.addClassString					(_mainSlotClassName);
				
			}			private function initializeProperties				():void {
				// Adjust consistency of variables
				if (_allowMultipleSelection) {
					_replaceTitleWithSelection					= false;
					_closeOnSelection						= false;
				}
				// Proceed creating properties
				_internalMarker							= UMem.getInstanceId(_markerClassName);
				_bg									= UMem.getInstanceId(_bgClassName);
				_bg.width									= _w;
				_bg.height									= _h;	
				_arrow								= UMem.getInstanceId(_arrowClassName);
				_mainSlot								= UMem.getInstanceId(_mainSlotClassName);
				_localParent							= parent;
				_localPosition							= new Point(x, y);
				_renderTarget							= this[_renderTargetName];
				_slotHeight								= _slotsHeight ? _slotsHeight : _h;
				Buttonizer.setClickThrough					(_arrow);
				Buttonizer.setupButton					(_mainSlot, this, "Main", "onPress,onRollOver,onRollOut");
				_arrow.y								= _h/2;
				_arrow.x								= _w - _arrow.y;
				_mainSlot._bg.height						= _h;
				_mainSlot._bg.width						= _w;
				_mainSlot._txt.x							= 10;
				_mainSlot._txt.width						= _w - 10;
				_mainSlot._bg.alpha						= 0;
				_mainSlot._txt.y							= Math.round((_h - _mainSlot._txt.height) / 2);
			}// FRAMEWORK METHODS ///////////////////////////////////////////////////////////////////////////////////////				public override function cleanup						():void {			release									();
			super.cleanup								();
			// I remove the internal marker
			UMem.storeInstance							(_internalMarker);
			_internalMarker								= null;			// I also have to remove all the fucking rest
			if (_bg)									UMem.storeInstance(_bg);
			_bg										= null;
		}		public override function release						():void {			if (isOpen())								setClosed();			UMem.storeInstances							(_slots);			UDisplay.removeClips							(_slots);
			Buttonizer.removeButtons						(_slots);
			UMem.storeInstances							(_markers);			UDisplay.removeClips							(_markers);
			_markers									= null;
			_slots									= null;
		}		public override function resize						(w:Number, h:Number):void {			// This one only resizes component. Rendered or not, this has to work to resize it.
			// If this is not overridden, it will only change the values in memoryt, but nothing happens.
			cleanup									();
			super.resize								(w, h);
			initialize									();		}// METHODS //////////////////////////////////////////////////////////////////////////////////////
	// CHHECKS
		public function isOpen								():Boolean {
			return									_isOpen;
		}
		public function isSelected							(index:uint):Boolean {
			return									_selectedSlots.indexOf(index) != -1;
		}
		public function isActive							():Boolean {
			return									_active;
		}
	// USAGE
		public function setActive							(a:Boolean):void {
			// If activation operations are done when menu is open, it will close itself first.
			if (isOpen()) {
				close									();
			}
			_active									= a;
			alpha										= a ? 1 : INACTIVE_ALPHA;
		}
		public function open								():void {
			// (c:*, time:Number, vars:Object, ease:String="Quart.easeOut", emd:String=null, dir:String="to"):TweenNano {
			if (_useSmoothAnimation) {
				prepareToOpen							();
				_slotsContainer.visible						= false;
				_pfMover.stopMotions						();
				_pfMover.move							(_arrow, ANIM_TIME, {scaleY:-1});
				_pfMover.move							(_bg, ANIM_TIME, {height:_openBgHeight, onComplete:fadeInSlots});
				return;
			}
			setOpened									();
		}
				private function fadeInSlots					():void {
					updateSelectionColors					();
					showMarkers						();
					_slotsContainer.visible					= true;
					_slotsContainer.alpha					= 0;
					_pfMover.move						(_slotsContainer, ANIM_TIME, {alpha:1}, "Linear");
				}
		public function close								():void {
			if (_useSmoothAnimation) {
				prepareForClose							();
				_pfMover.stopMotions						();
				_pfMover.move							(_arrow, ANIM_TIME, {scaleY:1});
				_pfMover.move							(_bg, ANIM_TIME, {height:_h, onComplete:resetParent});
				return;
			}
			setClosed									();
		}		public function setClosed							():void { // Sets to closed without animation
			_bg.height									= _h;	
			_arrow.scaleY								= 1;
			prepareForClose								();
			resetParent									();
		}
				private function prepareForClose				():void {
					_slotsContainer.visible					= false;
					// Below here only has to happen when menu is effectively closed
					if (!_isOpen)						return;
					Buttonizer.removeButton				(_shield);
					UDisplay.removeClip					(_shield);
					UGlobal.removeResizeListener			(onStageResize);
					_isOpen							= false;
				}
				private function resetParent					():void {
					_localParent.addChild					(this);
					x								= _localPosition.x;
					y								= _localPosition.y;
				}
		public function setOpened							():void {
			prepareToOpen								();
			_bg.height									= _openBgHeight;
			_arrow.scaleY								= -1;
			showMarkers								();
		}
				private function prepareToOpen				():void {
					for each (var c:DisplayObject in _markers) {
						c.visible						= false;
					}
					_slotsContainer.visible					= true;
					_isOpen							= true;
					var stagePoint						:Point = this.localToGlobal(new Point(0, 0));
					_renderTarget.addChild				(this);
					x								= stagePoint.x;
					y								= stagePoint.y;
					addChildAt							(_shield, 0);
					_shield.update						();
					_shield.alpha						= 0;
					Buttonizer.setupButton				(_shield, this, "Shield", "onPress");
					_shield.useHandCursor					= false;
					UGlobal.addResizeListener				(onStageResize);
				}
					private function onStageResize			():void {
						if (isOpen()) {
							prepareToOpen				();
						}
						else {
							UGlobal.removeResizeListener	(onStageResize);
						}
					}
				private function updateSelectionColors			():void {
					for (var i:uint=0; i<_slotsNum; i++) {
						UText.setTextColor				(_slots[i]._txt, _selectedSlots.indexOf(i) != -1 ? _txtColorSel : _txtColorNorm);
					}
				}
				private function showMarkers				():void {
					for (var i:uint=0; i<_slotsNum; i++) {
						_markers[i].visible				= _selectedSlots.indexOf(i) != -1;
					}
				}
	// RENDER		// Renders a complete data list		public function render								(names:Array, data:Array=null, preselect:uint=0):void { // Renders new content
			_slotsNames								= names;
			_slotsDatas									= data;
			renderContent								();
			setSelected									(preselect);		}
		public function setTitle							(t:String, replaceDefault:Boolean=false):void {
			if (replaceDefault)							_menuTitle = t;
			_mainSlot._txt.text							= t;
		}
		public function resetTitle							():void { // Sets default title
			_mainSlot._txt.text							= _menuTitle;
		}
		public function setTooltip							(t:String):void {
			_tooltip									= t;									
		}
	// Retrieves FIRST selected element (good for single selection)
		public function getSelectedName						():String { // Returns the FIRST selected name
			return									_slotsNames[_selectedSlots[0]];
		}
		public function getSelectedData						():* { // Returns the FIRST selected data
			return									_slotsDatas[_selectedSlots[0]];
		}
	// Managements
		public function setSelected							(index:uint, broadcast:Boolean=false):void { // Selects a slot. If multiple is allowed, adds a selections.
			if (_selectedSlots.indexOf(index) != -1 || index >= _slotsNum) {
				Debug.error						(_debugPrefix, "Slot N."+index+" is already selected or out of range");
				return;
			}
			if (_allowMultipleSelection) {
				_selectedSlots.push						(index);
				_selectedSlots.sort						();
				setGroupSelected						(_selectedSlots, broadcast);
			}
			else setGroupSelected							([index], broadcast);
			if (broadcast)								broadcastEvent(EVT_SELECTED, index);
		}
		public function setDeselected						(index:uint, broadcast:Boolean=false):void { // Deselects a slot (only works in multiple selection active)
			if (_allowMultipleSelection) {
				UCode.removeArrayItem					(_selectedSlots, index);
				setGroupSelected						(_selectedSlots);
				if (broadcast)							broadcastEvent(EVT_DESELECTED, index);
			}
			else {
				Debug.error						(_debugPrefix, "Cannot setDeselected() when multiple selection is active.");
			}
		}
		public function setGroupSelected						(indexes:Array, broadcast:Boolean=false):void {
			_selectedSlots								= indexes;
			// Proceed updating selection
			updateSelectionColors							();
			showMarkers								();
			// Proceed with title selection
			if (_replaceTitleWithSelection)					setTitle(getSelectedName());
			// Broadcast general event
			if (broadcast)								broadcastEvent(EVT_SELECTIONUPDATE, _selectedSlots);
		}
		private function renderContent						():void { // Renders content already stored in variables
			resetTitle									(); // Sets in main slot the default stored value
			_slotsNum									= _slotsNames.length;
			addChild									(_bg);
			addChild									(_arrow);
			addChild									(_mainSlot);
			addChild									(_slotsContainer);
			_slots									= [];
			_markers									= [];
			var slot									:MovieClip;
			var marker									:Sprite;
			var halfH									:uint = Math.round(_h/2);
			var tempSlot								= UMem.getInstanceId(_slotClassName);
			var slotTxtY								:uint = Math.round((_slotHeight-tempSlot._txt.height)/2);
			_slotsContainer.y								= _h + _slotsDistance;
			var bgBleed								:uint = 10;
			var slotY									:uint = 0;
			UMem.storeInstance							(tempSlot);
			for (var i:uint=0; i<_slotsNum; i++) {
				slot									= UMem.getInstanceId(_slotClassName);
				marker								= UMem.getInstanceId(_markerClassName);
				slot._bg.height							= _slotHeight;
				slot._bg.width							= _w;
				slot._bg.alpha							= 0;
				slot.y									= slotY;
				slot._txt.x								= _slotsTxtPos;
				slot._txt.width							= _w-40;
				slot._txt.y								= slotTxtY;
				slot._txt.text							= _slotsNames[i];
				marker.y								= slot.y + halfH;
				marker.x								= _slotsTxtPos/2;
				slotY									= slotY + _slotHeight + _slotsSpacing;
				_slotsContainer.addChild					(slot);
				_slotsContainer.addChild					(marker);
				_slots.push								(slot);
				_markers.push							(marker);
			}
			Buttonizer.setupButtons						(_slots, this, "Slot", "onPress,onRollOver,onRollOut");
			_openBgHeight								= _h + slotY + _slotsDistance + _bgMargin;
			setClosed									();
		}
// LISTENERS ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function onPressMain							(c:DisplayObject=null):void {
			if (!isActive())								return;
			if (isOpen()) {
				close									();
				broadcastEvent							(EVT_CLOSE);
				return;
			}
			if (_tooltip)								UGlobal.removeToolTip(this);
			open										();
			broadcastEvent								(EVT_OPEN);
		}
		public function onRollOverMain						(c:DisplayObject=null):void {
			if (!isActive())								return;
			if (isOpen())								return;
			if (_tooltip)								UGlobal.setToolTip(true, _tooltip, this);
		}
		public function onRollOutMain						(c:DisplayObject=null):void {
			if (!isActive())								return;
			if (isOpen())								return;
			if (_tooltip)								UGlobal.removeToolTip(this);
		}
		public function onRollOverSlot						(c:DisplayObject=null):void {
			if (!isActive())								return;
			var index									:uint = _slots.indexOf(c);
			if (isSelected(index))							return;
			UText.setTextColor							(_slots[index]._txt, _txtColorRoll);
		}
		public function onRollOutSlot						(c:DisplayObject=null):void {
			if (!isActive())								return;
			var index									:uint = _slots.indexOf(c);
			if (isSelected(index))							return;
			UText.setTextColor							(_slots[index]._txt, _txtColorNorm);
		}
		public function onPressSlot							(c:DisplayObject=null):void {
			if (!isActive())								return;
			var index									:uint = _slots.indexOf(c);
			if (isSelected(index) && _allowMultipleSelection)		setDeselected(index, true);
			else										setSelected(index, true);
			if (_closeOnSelection)							close();
		}
		public function onPressShield						(c:DisplayObject=null):void {
			if (!isOpen())								onPressMain();
		}	}}

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