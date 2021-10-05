/* _cBaseNav - Is a base class for all Navigation interface item menus.
*/
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UText;
	import											com.pippoflash.motion.Animator;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public class _cBaseNav extends _cBase{
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
// 		[Inspectable 									(name="Icon Attachment", type=String, defaultValue="NO ICON")]
// 		public var _iconAttachment							:String = "NO ICON"; // This decides an icon to be attached
// 		[Inspectable 									(name="Icon Frame", type=Number, defaultValue=1)]
// 		public var _iconFrame								:Number = 1; // This decides a frame of the icon to go
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
// 		public var _radioGroup								:String;
		[Inspectable 									(name="Close on Press", type=Boolean, defaultValue=false)]
		public var _closeOnClick							:Boolean = false;
		[Inspectable 									(name="Close on RollOut", type=Boolean, defaultValue=false)]
		public var _closeOnRollOut							:Boolean = false;
// 		[Inspectable 									(name="Text Y Offset", type=Number, defaultValue=0)]
// 		public var _yOff									:Number = 0;
// 		[Inspectable 									(name="Text X Offset", type=Number, defaultValue=0)]
// 		public var _xOff									:Number = 0;
// 		[Inspectable 									(name="Margin", type=Number, defaultValue=4)]
// 		public var _textMargin								:Number = 4;
// 		[Inspectable 									(name="Status Change", type=String, defaultValue="SMOOTH", enumeration="SMOOTH,INSTANT")]
// 		public var _appearStyle							:String = "SMOOTH";
		// VARIABLES //////////////////////////////////////////////////////////////////////////
// 		public static var _radioButtonGroups					:Array = new Array();
// 		public static var _radioGroupsList						:Object = new Object();
// 		public const _instanceList							:Array = ["_up","_over","_down","_sleep"];
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
// 		public static var _horizAlign							:String;
// 		public static var _vertAlign							:String;
		protected static var _c							:MovieClip;
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
// 		private var _alpha_down							:Number;
// 		private var _alpha_over							:Number;
// 		public var _doubleMargin							:Number; // Stores _textMargin*2;
// 		public var _rect									:Rectangle;
// 		public var _appearFunction							:Function;
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
// 		public var _button								:Sprite;
// 		public var _txt									:TextField;
// 		public var _icon									:MovieClip; // Stores the attached icon instance
		// DATA HOILDERS ///////////////////////////////////////////////////////////////////////////////////////
		protected var _tree								:XML;
// 		protected var _treeArray							:Array; // Defines the application according to arrays and levels
		// MARKERS ////////////////////////////////////////////////////////////////////////
		protected var _isOpen								:Boolean = false;
		protected var _selectedMenu						:uint;
// 		public var _active								:Boolean = true;
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function _cBaseNav							(id:String="_cBaseNav", par:Object=true) {
			super									(id, par);
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setup								(tree:XML):void {
			_tree										= tree;
		}
		public function open								():void {
			_isOpen									= true;
		}
		public function close								():void {
			_isOpen									= false;
		}
// GETTERS/SETTERS ///////////////////////////////////////////////////////////////////////////////////////
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}