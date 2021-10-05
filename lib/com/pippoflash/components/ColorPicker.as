/* ColorPicker - (c) Filippo Gregoretti - www.pippoflash.com*/package com.pippoflash.components {	import com.pippoflash.utils.*; import com.pippoflash.motion.Animator; com.pippoflash.components.ScrollBarArrows; com.pippoflash.components.PippoFlashButton; com.pippoflash.components.ContentBox; 
	import com.pippoflash.gui.elements.AutoShield; com.pippoflash.components.SuperTextField;
		import flash.display.*; import flash.text.*; import flash.events.*; import flash.utils.*; import flash.net.*; import flash.geom.*;// 	import PippoFlashAS3_UTY_SquareClip; import DataListDefaultTile; import DataListDefaultBackground; import DataListDefaultSorter; import PippoFlashButton_DataListDefaultHeader;	public dynamic class ColorPicker extends _cBase {	// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
	/* NOT ALL INSPECTABLE VARIABLES ARE IMPLEMENTED */	// INSPECTABLE		[Inspectable 									(name="Color - Default", type=Color, defaultValue="#000000")]		public var _defaultColor							:uint = 0x000000;		[Inspectable 									(name="Picker - Type", type=String, defaultValue="SQUARE", enumeration="SQUARE,LARGE")]
		public var _colorPickerType							:String = "SQUARE";
		[Inspectable 									(name="Picker - Position", type=String, defaultValue="REL_VERTICAL", enumeration="REL_VERTICAL,REL_HORIZONTAL,CENTERED")]
		public var _colorPickerPosition						:String = "REL_VERTICAL";
		[Inspectable 									(name="Picker - Scale", type=Number, defaultValue=100)]
		public var _colorPickerScale							:Number = 100;
		[Inspectable 									(name="Picker - Auto Scale (if smaller than stage)", type=Boolean, defaultValue=true)]
		public var _colorPickerAutoScale						:Boolean = true;
		[Inspectable 									(name="SYSTEM - Icon Class ID (must contain _color)", type=String, defaultValue="ColorPicker_PF_DefaultIcon")]		public var _iconClassId								:String = "ColorPicker_PF_DefaultIcon";		[Inspectable 									(name="SYSTEM - Target Render Color Picker", type=String, defaultValue="stage", enumeration="stage,root,parent")]
		public var _targetRenderColorPicker					:String = "SQUARE";
		// STATIC ////////////////////////////////////////////////////////////////////////////////
// 		private static const PICKER_SIZE						:Point = new Point(408, 438);
		private static const BROADCAST_COLOR_SELECT			:String = "onColorSelect"; // Only if selected color is different from stored color
		private static const ICON_PICKER_MARGIN				:uint = 10;		// UTY		// VARIABLES //////////////////////////////////////////////////////////////////////////		// USER VARIABLES		// SYSTEM		// REFERENCES
		private var _icon									:Sprite;
		private static var _pickerInitialized						:Boolean; // If static picker is initialized. It will be done at first click.
		private static var _picker							:Sprite;
		private static var _shield							:AutoShield;
		private static var _txtHex							:SuperTextField;
		private static var _pickerColor						:DisplayObject;
		private static var _pickerArea						:DisplayObject;
		private static var _pickerAreaBitmap					:BitmapData;
		private static var _previousColor						:uint; // Stores previous color
		private static var _pickerSize						:Point;
		private static var _selectedPicker						:ColorPicker;
		private static var _pickerActive						:Boolean; // If main color picker is active and visible		// MARKERS		// DATA HOLDERS
		private var _colorHex								:String;
		private var _color								:uint;		// SYSTEM - RENDERING UTY		// SYSTEM - DOUBLE CLICK// INIT ///////////////////////////////////////////////////////////////////////////////////////		public function ColorPicker							(par:Object=null) {			super									("ColorPicker", par);		}
		protected override function initAfterVariables				():void {			setAutoPost								("_col");			super.initAfterVariables						();		}// RECURRENT INIT ///////////////////////////////////////////////////////////////////////////////////////		protected override function initialize					():void { 			// This is called EVERY TIME the component is initialized. It suppose a full re-rendering. Its called automatically in recycle().			initializeGraphics								();			initializeProperties							();			super.initialize								();		}			private function initializeGraphics					():void {
				_icon									= UCode.getInstance(_iconClassId);
				addChild								(_icon);
				_icon.width								= _w;
				_icon.height							= _h;
// 				_shield								= new AutoShield();
				Buttonizer.setupButton					(_icon, this, "Icon", "onPress");			}			private function initializeProperties				():void {
				setColor								(_defaultColor);			}
// UTILITIES ///////////////////////////////////////////////////////////////////////////////////////
	// PICKER ACTIVATION - DEACTIVATION
		protected function activatePicker						():void { // Can be called by static class
			_previousColor								= _color;
			if (!_pickerInitialized)							initializePicker();
			_txtHex.setText								(_colorHex.toUpperCase());
			UExec.next								(_txtHex.focusAndSelectAll);
// 			_txtHex.focusAndSelectAll						();
			UDisplay.setClipColor							(_pickerColor, _previousColor);
			setColor									(_previousColor);
			// Position picker
			var margin									:uint = 12;
			// Rendering SOLO su stage
			_targetRenderColorPicker						= "stage";
			this[_targetRenderColorPicker].addChild			(_picker);
			var centerPicker								:Boolean = false;
			if (_colorPickerPosition.indexOf("REL") != -1) { // Positions it on top or bottom
// 				_targetRenderColorPicker					= "parent"; // Per adesso devo fare cosi... Non posso riposizionare il pixel du palle...
				UDisplay.positionRelativeTo					(_picker, this, new Point(0,0));
				var stagePoint							:Point = this.localToGlobal(new Point(0, 0));
				// Find a rectangle
				var r									:Rectangle = new Rectangle(stagePoint.x - margin, stagePoint.x + _w + margin, stagePoint.y - margin, stagePoint.y + _w + margin);
				// controllo sotto a dx
				var canLeft							:Boolean = (r.x - _pickerSize.x) >= 0; // Can be positioned at the left of picker
				var canLeftDown							:Boolean = canLeft && (stagePoint.y + _pickerSize.y) <= UGlobal._sh;
				var canLeftUp							:Boolean = canLeft && ((stagePoint.y + _h) - _pickerSize.y) >= 0;
// 				var canDown							:Boolean = (r.height + _pickerSize.y) - UGlobal._sh; // Can go below
// 				var canRight							:Boolean = (r.x + _pickerSize.x) - UGlobal._sw;
				if (canLeftDown) {
					_picker.x							= r.x - _pickerSize.x;
					_picker.y							= stagePoint.y;
				}
				else if (canLeftUp) {
					_picker.x							= r.x - _pickerSize.x;
					_picker.y							= (stagePoint.y + _h) - _pickerSize.y;
				}
				else {
					centerPicker						= true;
				}
				
				// Controllare se il picker va fuori lo schermo mettendolo prima sotto!
				
			}
			if (centerPicker) { // Position centered
// 				_targetRenderColorPicker					= "stage";
				_picker.x									= (UGlobal._sw - _pickerSize.x) / 2;
				_picker.y									= (UGlobal._sh - _pickerSize.y) / 2;
			}
			_shield.update								();
			_selectedPicker								= this;
			_pickerActive								= true;
			startPickerChecks							();
		}
				private function initializePicker():void {
					if (_pickerInitialized)					return; // Just to make sure this doesn't happen twice
					_picker							= UCode.getInstance("ColorPicker_PF_Picker"+_colorPickerType); // SQUARE or LARGE
					_shield							= _picker["_shield"];
					_picker.removeChild					(_shield);
					_pickerSize							= new Point(_picker.width, _picker.height);
					_picker.addChildAt					( _shield, 0);
					_txtHex							= _picker["_txtHex"];
					_pickerColor						= _picker["_color"];
					_pickerArea						= _picker["_pickerArea"];
					_pickerAreaBitmap					= new BitmapData(_pickerArea.width, _pickerArea.height);
					_pickerAreaBitmap.draw				(_pickerArea);
					_txtHex.addListener					(ColorPicker);
					_txtHex.setDefaultText					("");
					Buttonizer.setupButton				(_shield, ColorPicker, "Shield", "onPress");
					Buttonizer.setupButton				(_pickerArea as InteractiveObject, ColorPicker, "Area", "onPress");
					_shield["useHandCursor"]				= false;
					_pickerArea["useHandCursor"]			= false;
					_pickerInitialized						= true;
					UGlobal.addResizeListener				(onMainAppResize);
				}
			private function startPickerChecks				():void {
				_picker.addEventListener					(MouseEvent.MOUSE_MOVE, onMouseMovePicker);
				UGlobal.addResizeListener					(onMainAppResize);
			}
			private static function onMouseMovePicker				(e:Event):void {
				if (_pickerArea.mouseX >= 0 && _pickerArea.mouseY >= 0 && _pickerArea.mouseX <= _pickerArea.width && _pickerArea.mouseY <= _pickerArea.height) {
					_selectedPicker.setColor							(_pickerAreaBitmap.getPixel(_pickerArea.mouseX, _pickerArea.mouseY));
				}
				else {
					_selectedPicker.setColor							(_previousColor);
				}
			}
		private function deactivatePicker						():void {
			UDisplay.removeClip							(_picker);
			_txtHex.clearFocus							();
			_pickerActive								= false;
		}
		private function abortPicker							():void {
			restorePreviousColor							();
			deactivatePicker								();
		}
		private function restorePreviousColor					():void {
			setColor									(_previousColor);
		}		private function confirmAreaColor						():void {
			deactivatePicker								();
			if (_color != _previousColor)					broadcastColorSelect();
		}
		private function broadcastColorSelect					():void {
			_previousColor								= null;
			broadcastEvent								(BROADCAST_COLOR_SELECT, _color);
		}
// FRAMEWORK METHODS ///////////////////////////////////////////////////////////////////////////////////////				public override function cleanup						():void {			super.cleanup								();
		}		public override function release						():void {
			super.release								();		}		public override function resize						(w:Number, h:Number):void {			super.resize								(w, h);
		}// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setHex								(hex:String):void {
			setColor									(uint("0x"+hex));
		}
		public function setColor							(c:uint):void {
			if (_color == c)								return; // Do not do useless calculations
			_color									= c;
			var r										:String = (c >> 16 & 0xff).toString(16);
			var g										:String = (c >> 8 & 0xff).toString(16);
			var b										:String = (c & 0xff).toString(16);
			r 										= r.length > 1 ? r : "0" + r;
			g 										= g.length > 1 ? g : "0" + g;
			b 										= b.length > 1 ? b : "0" + b;
			_colorHex									= r + g + b;
			UDisplay.setClipColor							(_icon["_color"], c);
			if (_pickerInitialized) {
				_txtHex.setText							(_colorHex.toUpperCase());
				UDisplay.setClipColor						(_pickerColor, _color);
			}
		}
		public function getColor							():uint {
			return									_color;
		}
		public function getHex							():String {
			return									_colorHex;
		}// UTY ///////////////////////////////////////////////////////////////////////////////////////// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public function onPressIcon							(c:DisplayObject=null):void {
			activatePicker								();
		}
// STATIC LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public static function onPressShield					(c:DisplayObject=null):void {
			if (_selectedPicker)							_selectedPicker.abortPicker();
			_selectedPicker								= null;
		}		public static function onPressArea						(c:DisplayObject=null):void {
			if (_selectedPicker)							_selectedPicker.confirmAreaColor();
			_selectedPicker								= null;
		}
		public static function onChangedReturnHex 				(t:SuperTextField):void {
			if (_selectedPicker) {
				var c										:uint = uint("0x" + t.text);
				_selectedPicker.setColor									(c);
				if (_previousColor != c)						_selectedPicker.confirmAreaColor();
				_selectedPicker								= null;
			}
		}
		public static function onMainAppResize			(firstResize:Boolean=false):void {
			if (_pickerActive) {
				if (_selectedPicker)				_selectedPicker.activatePicker();
			}
		}
	}}

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