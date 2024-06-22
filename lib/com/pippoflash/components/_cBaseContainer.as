/* _cBaseNav - Is a base class for all Navigation interface item menus.
*/
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UMem;
	import											com.pippoflash.motion.Animator;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public class _cBaseContainer extends _cBase{
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
// 		[Inspectable 									(name="Icon Attachment", type=String, defaultValue="NO ICON")]
// 		public var _iconAttachment							:String = "NO ICON"; // This decides an icon to be attached
		[Inspectable 									(name="Margin - Internal", type=Number, defaultValue=2)]
		public var _intMargin								:uint = 2; // This decides a frame of the icon to go
		[Inspectable 									(name="Margin - External", type=Number, defaultValue=4)]
		public var _extMargin								:uint = 4; // This decides a frame of the icon to go
		[Inspectable 									(name="BG - Whole Area", type=Boolean, defaultValue=false)]
		public var _useAreaBg								:Boolean = false; // This decides a frame of the icon to go
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
// 		[Inspectable 									(name="Close on Press", type=Boolean, defaultValue=false)]
// 		public var _closeOnClick							:Boolean = false;
// 		[Inspectable 									(name="Close on RollOut", type=Boolean, defaultValue=false)]
// 		public var _closeOnRollOut							:Boolean = false;
// 		[Inspectable 									(name="Text Y Offset", type=Number, defaultValue=0)]
// 		public var _yOff									:Number = 0;
// 		[Inspectable 									(name="Text X Offset", type=Number, defaultValue=0)]
// 		public var _xOff									:Number = 0;
// 		[Inspectable 									(name="Margin", type=Number, defaultValue=4)]
// 		public var _textMargin								:Number = 4;
		[Inspectable 									(name="Direction", type=String, defaultValue="VERTICAL", enumeration="VERTICAL,HORIZONTAL")]
		public var _direction								:String = "VERTICAL";
		[Inspectable 									(name="Align - Vertical", type=String, defaultValue="MIDDLE", enumeration="TOP,MIDDLE,BOTTOM")]
		public var _alignV								:String = "MIDDLE";
		[Inspectable 									(name="Align - Horizontal", type=String, defaultValue="CENTER", enumeration="LEFT,CENTER,RIGHT")]
		public var _alignH								:String = "CENTER";
		// VARIABLES //////////////////////////////////////////////////////////////////////////
// 		public static var _radioButtonGroups					:Array = new Array();
// 		public static var _radioGroupsList						:Object = new Object();
// 		public const _instanceList							:Array = ["_up","_over","_down","_sleep"];
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
// 		public static var _horizAlign							:String;
// 		public static var _vertAlign							:String;
// 		protected static var _c							:MovieClip;
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
		protected var _lastHeight							:Number = 0; // Last height of clips
// 		protected var _setupProperty						:String; // x or y, property to modify according to direction
// 		protected var _sizeProperty							:String; // width or height, property to modify according to direction
		protected var _isVertical							:Boolean;
// 		public var _doubleMargin							:Number; // Stores _textMargin*2;
// 		public var _rect									:Rectangle;
// 		public var _appearFunction							:Function;
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		protected var _container							:Sprite = new Sprite();
		protected var _positionClip							:Function; // This changes according to direction
		protected var _bgArea								:Sprite; // Sprite for the whole area of component 
		protected var _bgContent							:Sprite; // sprite for the area of content
// 		public var _txt									:TextField;
// 		public var _icon									:MovieClip; // Stores the attached icon instance
		// DATA HOILDERS ///////////////////////////////////////////////////////////////////////////////////////
		public var _clips									:Array = [];
// 		protected var _tree								:XML;
// 		protected var _treeArray							:Array; // Defines the application according to arrays and levels
		// MARKERS ////////////////////////////////////////////////////////////////////////
// 		protected var _isOpen								:Boolean = false;
// 		protected var _selectedMenu						:uint;
// 		public var _active								:Boolean = true;
// INIT ///////////////////////////////////////////////////////////////////////////////////////

		public function _cBaseContainer						(id:String="_cBaseContainer", par:Object=null) {
			super									(id, par);
		}
		protected override function initialize					():void {
			if (_useAreaBg)								_bgArea = UDisplay.addChild(this, UDisplay.getSquareSprite(_w, _h), {alpha:0});
			_bgContent									= UDisplay.addChild(this, UDisplay.getSquareSprite(10, 10), {alpha:0});
			_lastHeight									= _extMargin; // Starts adding vertical margin
			_isVertical									= _direction == "VERTICAL";
			_positionClip								= _isVertical ? positionClipVertical : positionClipHorizontal;
// 			prepareContainer								();
		}
			private function prepareContainer					():void {
				_container								= new Sprite();
				addChild								(_container);
			}
// COMMON METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public override function release						():void {
			removeAllItems								();
			prepareContainer								();
			super.release								();
		}
		public override function cleanup						():void {
			release									();
			UDisplay.removeClip							(_bgArea);
			UDisplay.removeClip							(_bgContent);
			UDisplay.removeClip							(_container);
			_useAreaBg									= false;
			super.cleanup								();
		}
		public override function harakiri						():void {
			cleanup									();
			super.harakiri								();
		}
// 		public override function recycle						(par:Object=null):void {
// 			trace("RECYCLING CONTAINER!!!!!");
// 			super.recycle								(par);
// 		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setup								(a:Array):void {
			if (isRendered())								release();
			_clips										= [];
			prepareContainer								();
			for each (_c in a)							doAddItem(_c);
			alignContainer								();
			complete									();
		}
		protected override function complete					():void {
			super.complete								();
		}
		public function addItem							(c:DisplayObject):void {
			doAddItem									(c);
			alignContainer								();
		}
		public function getItems							():Array {
			return									_clips;
		}
		public function removeAllItems						():void {
			_lastHeight									= _extMargin;
			for each (_c in _clips)							UDisplay.removeClip(_c);
			_clips										= new Array();
		}
		public function offset								(xx:Number=0, yy:Number=0):void {
			_container.x = xx; _container.y = yy;
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		protected function doAddItem						(c:DisplayObject):void {
			_positionClip								(c);
			_container.addChild							(c);
		}
		protected function alignContainer						():void {
// 			trace("ALLINEO A:",new Rectangle(_extMargin,_extMargin,_w-(_extMargin*2),_h-(_extMargin*2)));
			_bgContent.width							= _container.width + _extMargin*2;
			_bgContent.height							= _container.height + _extMargin*2;
			UDisplay.alignSpriteTo							(_container, new Rectangle(_extMargin,_extMargin,_w-(_extMargin*2),_h-(_extMargin*2)), _alignH, _alignV);
		}
		protected function positionClipHorizontal					(c:*) {
			_clips.push									(c);
			c.x										= _lastHeight;
// 			c.y										= -c.height/2;
			_lastHeight									+= UCode.getWidth(c) + _intMargin;
		}
		protected function positionClipVertical					(c:DisplayObject) {
			_clips.push									(c);
			c.y										= _lastHeight;
// 			c.x										= -c.width/2;
			_lastHeight									+= UCode.getHeight(c) + _intMargin;
		}
		protected function arrangeAllClips 						() {
			_lastHeight									= 0;
			for (_i=0; _i<_clips.length; _i++) {
				_clip									= _clips[_i];
				_clip.x								= _lastHeight;
				_lastHeight								+= _clip.width;
			}
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}