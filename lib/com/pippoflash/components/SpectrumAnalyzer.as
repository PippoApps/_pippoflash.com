/* _cBaseNav - Is a base class for all Navigation interface item menus.
*/
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.USound;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public dynamic class SpectrumAnalyzer extends _cBase {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
// 		[Inspectable 									(name="Attach Main Class", type=String, defaultValue="com.pippoflash.components.NavTopCorner.defaultMainClass")]
// 		public var _classMain								:String = "com.pippoflash.components.NavTopCorner.defaultMainClass"; 
// 		[Inspectable 									(name="Attach Group Class", type=String, defaultValue="com.pippoflash.components.NavTopCorner.defaultGroupClass")]
// 		public var _classGroup								:String = "com.pippoflash.components.NavTopCorner.defaultGroupClass"; 
// 		[Inspectable 									(name="Attach Item Class", type=String, defaultValue="com.pippoflash.components.NavTopCorner.defaultItemClass")]
// 		public var _classItem								:String = "com.pippoflash.components.NavTopCorner.defaultItemClass"; 
		[Inspectable 									(name="Granularity (Higher = slower, more detaild)", defaultValue=16, type=Number, enumeration="256,128,64,32,16,8,4")]
		public var _granularity								:uint = 16;
		[Inspectable 									(name="Scan Interval (msecs)", defaultValue=100, type=Number)]
		public var _interval								:uint = 100; // Milliseconds interval scanning for music
// 		[Inspectable 									(name="Icon positioning", type=String, defaultValue="LEFT", enumeration="LEFT,RIGHT,TOP,BOTTOM,CENTERED (no text)")]
// 		public var _iconPositioning							:String = "LEFT";
// 		[Inspectable 									(name="Icon Y Offset", type=Number, defaultValue=0)]
// 		public var _yIOff									:Number = 0;
// 		[Inspectable 									(name="Icon X Offset", type=Number, defaultValue=0)]
// 		public var _xIOff									:Number = 0;
// 		[Inspectable 									(name="Button Class Name", type=String, defaultValue="PippoFlashAS3_Components_PippoFlashButton_Default")]
// 		public var _buttonLinkage							:String = "PippoFlashAS3_Components_PippoFlashButton_Default";
// 		[Inspectable 									(name="Text", type=String, defaultValue="PippoFlash.com")]
// 		public var _text									:String = "PippoFlash.com";
// 		[Inspectable 									(name="Text Alignment", type=String, defaultValue="CENTER", enumeration="CENTER,JUSTIFY,LEFT,RIGHT")]
// 		public var _textAlign								:String = "CENTER";
// 		[Inspectable 									(name="Is Radio Group (overrides switch)", type=String)]
// 		public var _radioGroup							:String;
// 		[Inspectable 									(name="Groups are Clickable", type=Boolean, defaultValue=false)]
// 		public var _groupsAreClickable						:Boolean = false;
// 		[Inspectable 									(name="Fixed Width", type=Boolean, defaultValue=false)]
// 		public var _fixedWidth								:Boolean = false;
// 		[Inspectable 									(name="Is Selected", type=Boolean, defaultValue=false)]
// 		public var _selected								:Boolean = false;
// 		[Inspectable 									(name="Text Y Offset", type=Number, defaultValue=0)]
// 		public var _yOff									:Number = 0;
		[Inspectable 									(name="Bars color", type=Color, defaultValue=0)]
		public var _color									:uint = 0;
// 		[Inspectable 									(name="Margin", type=Number, defaultValue=4)]
// 		public var _textMargin								:Number = 4;
// 		[Inspectable 									(name="Layout Direction", type=String, defaultValue="HORIZONTAL", enumeration="HORIZONTAL,VERTICAL")]
// 		public var _directionLayout							:String = "HORIZONTAL";
		[Inspectable 									(name="Spectrum Effect", type=String, defaultValue="DEFAULT", enumeration="DEFAULT")]
		public var _effect								:String = "DEFAULT";
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		private static var _sp								:Sprite;
		private static var _n								:Number;
		private static var _i								:uint;
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
		private var _timer								:Timer;
		private var _lines									:uint;
		private var _vector								:Vector.<Number>;
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		private var _mask								:Sprite;
		private var _spectrum								:Sprite = new Sprite();
		private var _clips									:Array = new Array();
		// MARKERS ////////////////////////////////////////////////////////////////////////
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function SpectrumAnalyzer						(par:Object=null) {
			super									("SpectrumAnalyzer", par);
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
// 			_timer									= new Timer(_interval, 0);
// 			_timer.addEventListener						(TimerEvent.TIMER, renderSpectrum);
			renderAnalyzer								();
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		private function renderAnalyzer						():void {
			// Render main
			addChild									(_spectrum);
			_mask									= UDisplay.getSquareSprite(_w, _h);
			addChild									(_mask);
			_spectrum.mask								= _mask;
			_spectrum.scaleY								= -1;
			_spectrum.y								= _h*2;
			// Render lines
			_lines										= _granularity;
			_granularity								= 256 / _lines;
			var ww									:Number = _w/_lines;
			Debug.debug								(_debugPrefix, "Rendering with lines:",_lines,"width:",ww);
			for (_i=0; _i<_lines; _i++) {
				_sp									= UDisplay.getSquareSprite(ww, _h, _color);
				_sp.x									= ww * _i;
				_spectrum.addChild						(_sp);
				_clips.push								(_sp);
			}
			start										();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function start								():void {
// 			_timer.start								();
		}
		public function pause								():void {
// 			_timer.stop									();
		}
// AUTOCLOSE ///////////////////////////////////////////////////////////////////////////////////////
// GETTERS/SETTERS ///////////////////////////////////////////////////////////////////////////////////////
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function renderSpectrum						(e:TimerEvent=null):void {
			_vector									= USound.getSpectrumVector(_granularity);
			for (_i=0; _i<_lines; _i++) {
				_clips[_i].y								= _vector[_i]*_h;
			}
// 			trace(_vector);
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}