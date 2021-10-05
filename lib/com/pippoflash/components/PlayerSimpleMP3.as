/* PlayerSimpleMP3 - Very simple MP3 player with spectrum analyzer
*/
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.USound;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public dynamic class PlayerSimpleMP3 extends _cBase {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
// 		[Inspectable 									(name="Attach Main Class", type=String, defaultValue="com.pippoflash.components.NavTopCorner.defaultMainClass")]
// 		public var _classMain								:String = "com.pippoflash.components.NavTopCorner.defaultMainClass"; 
// 		[Inspectable 									(name="Attach Group Class", type=String, defaultValue="com.pippoflash.components.NavTopCorner.defaultGroupClass")]
// 		public var _classGroup								:String = "com.pippoflash.components.NavTopCorner.defaultGroupClass"; 
// 		[Inspectable 									(name="Attach Item Class", type=String, defaultValue="com.pippoflash.components.NavTopCorner.defaultItemClass")]
// 		public var _classItem								:String = "com.pippoflash.components.NavTopCorner.defaultItemClass"; 
// 		[Inspectable 									(name="Granularity (Higher = slower, more detaild)", defaultValue=16, type=Number, enumeration="256,128,64,32,16,8,4")]
// 		public var _granularity								:uint = 16;
// 		[Inspectable 									(name="Scan Interval (msecs)", defaultValue=100, type=Number)]
// 		public var _interval								:uint = 100; // Milliseconds interval scanning for music
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
// 		[Inspectable 									(name="Bars color", type=Color, defaultValue=0)]
// 		public var _color									:uint = 0;
// 		[Inspectable 									(name="Margin", type=Number, defaultValue=4)]
// 		public var _textMargin								:Number = 4;
// 		[Inspectable 									(name="Layout Direction", type=String, defaultValue="HORIZONTAL", enumeration="HORIZONTAL,VERTICAL")]
// 		public var _directionLayout							:String = "HORIZONTAL";
// 		[Inspectable 									(name="Open Menu On", type=String, defaultValue="DEFAULT", enumeration="DEFAULT")]
// 		public var _effect								:String = "DEFAULT";
		// FOOL COMPONENT DEFINITION COMPILER ///////////////////////////////////////////////////////////////////////////////////////
		private static var _buttPlay; private static var _buttMute; private static var _spectrum;
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		private static const _debugPrefix						:String = "PlayerSimpleMP3";
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		private static var _sp								:Sprite;
		private static var _n								:Number;
		private static var _i								:uint;
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		// MARKERS ////////////////////////////////////////////////////////////////////////
		public var _playing								:Boolean = false;
		public var _muted								:Boolean = false;
		public var _fileUrl									:String;
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function PlayerSimpleMP3						() {
			super									(_debugPrefix);
		}
		protected override function init						():void {
			// I have to override this because buttons and spectrum ruin the calculation of height/width, so I remove them before getting sizes and then I put it back
			_buttPlay = this["_buttPlay"]; _buttMute = this["_buttMute"]; _spectrum = this["_spectrum"]; 
			UDisplay.removeClip							(_buttPlay);
			UDisplay.removeClip							(_buttMute);
			UDisplay.removeClip							(_spectrum);
			super.init									();
			addChild(_buttPlay); addChild(_buttMute); addChild(_spectrum); 
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
			Buttonizer.autoButtons						([_buttPlay, _buttMute], this);
			Buttonizer.setToSwitch						(_buttPlay, true);
			Buttonizer.setToSwitch						(_buttMute, true);
			setMute									(false);
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function playFile								(s:String):void {
			setPlay									(false);
			_fileUrl									= s;
			setPlay									(true);
		}
		public function playIfElse							(s:String):void { // Plays the file only if its not already playing
			if (_fileUrl == s && _playing)						return; // Do nothing if I am already playing the same file
			playFile									(s);
		}
		public function reset								():void {
			setMute									(false);
			setPlay									(false);
			_fileUrl									= null;
		}
		public function setMute							(b:Boolean):void {
			_muted									= b;
			setMuteButton								(!b);
// 			Buttonizer.setSelected						(_buttMute, !b);
			USound.fadeGeneralVolumeTo						(b ? 0 : 1);
			broadcastEvent								("onMute", _muted);
		}
		public function setPlay								(b:Boolean):void {
			if (b && !_fileUrl)							return;
			_playing									= b;
			setPlayButton								(b);
// 			Buttonizer.setSelected						(_buttPlay, b);
			if (b && _fileUrl)								USound.loadSound(_fileUrl);
			else if (!b && _fileUrl)							USound.stopSound(_fileUrl);
			broadcastEvent								("onPlay", _playing);
		}
		public function disposeSound							():void {
			setPlay									(false);
			_fileUrl									= null;
		}
		public function setPlayButton						(b:Boolean):void {
			Buttonizer.setSelected						(_buttPlay, b);
		}
		public function setMuteButton						(b:Boolean):void {
			Buttonizer.setSelected						(_buttMute, b);
		}
		public function togglePlay							():void {
			setPlay									(!_playing);
		}
		public function toggleMute							():void {
			setMute									(!_muted);
		}
// AUTOCLOSE ///////////////////////////////////////////////////////////////////////////////////////
// GETTERS/SETTERS ///////////////////////////////////////////////////////////////////////////////////////
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onPressMute							(c:MovieClip=null) {
			toggleMute									();
			broadcastEvent								("onPressMute", _muted);
		}
		public function onPressPlay							(c:MovieClip=null) {
			togglePlay									();
			broadcastEvent								("onPressPlay", Buttonizer.isSelected(_buttPlay));
		}
	}
}