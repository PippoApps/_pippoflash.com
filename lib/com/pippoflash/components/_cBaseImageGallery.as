/* _cBaseImageGallery - Is a base class for all Navigation interface item menus.
*/
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
	import 											com.pippoflash.components.ImageLoaderAdv;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.UXml;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UMem;
	import											com.pippoflash.motion.Animator;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public class _cBaseImageGallery extends _cBase{
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
// 		[Inspectable 									(name="Icon Attachment", type=String, defaultValue="NO ICON")]
// 		public var _iconAttachment							:String = "NO ICON"; // This decides an icon to be attached
		[Inspectable 									(name="GUI - Link Image Loading Anim", type=String, defaultValue="PippoFlash_ImageLoaderAdv_LoaderAnimClass")]
		public var _linkImageLoaderAnim						:String = "PippoFlash_ImageLoaderAdv_LoaderAnimClass";
// 		[Inspectable 									(name="Margin - Internal", type=Number, defaultValue=2)]
// 		public var _intMargin								:uint = 2; // This decides a frame of the icon to go
// 		[Inspectable 									(name="Margin - External", type=Number, defaultValue=4)]
// 		public var _extMargin								:uint = 4; // This decides a frame of the icon to go
// 		[Inspectable 									(name="BG - Whole Area", type=Boolean, defaultValue=false)]
// 		public var _useAreaBg								:Boolean = false; // This decides a frame of the icon to go
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
// 		[Inspectable 									(name="Direction", type=String, defaultValue="VERTICAL", enumeration="VERTICAL,HORIZONTAL")]
// 		public var _direction								:String = "VERTICAL";
// 		[Inspectable 									(name="Align - Vertical", type=String, defaultValue="MIDDLE", enumeration="TOP,MIDDLE,BOTTOM")]
// 		public var _alignV									:String = "MIDDLE";
// 		[Inspectable 									(name="Align - Horizontal", type=String, defaultValue="CENTER", enumeration="LEFT,CENTER,RIGHT")]
// 		public var _alignH									:String = "CENTER";
		// VARIABLES //////////////////////////////////////////////////////////////////////////
// 		public static var _radioButtonGroups					:Array = new Array();
// 		public static var _radioGroupsList						:Object = new Object();
// 		public const _instanceList							:Array = ["_up","_over","_down","_sleep"];
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
// 		public static var _horizAlign							:String;
// 		public static var _vertAlign							:String;
// 		protected static var _c							:MovieClip;
		protected static var _node							:XML;
		protected static var _bitmap							:Bitmap;
		protected static var _imageLoader						:ImageLoaderAdv;
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
// 		protected var _lastHeight							:Number = 0; // Last height of clips
// 		protected var _setupProperty						:String; // x or y, property to modify according to direction
// 		protected var _sizeProperty							:String; // width or height, property to modify according to direction
// 		protected var _isVertical							:Boolean;
// 		public var _doubleMargin							:Number; // Stores _textMargin*2;
// 		public var _rect									:Rectangle;
// 		public var _appearFunction							:Function;
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
// 		protected var _container							:Sprite = new Sprite();
// 		protected var _positionClip							:Function; // This changes according to direction
// 		protected var _bgArea								:Sprite; // Sprite for the whole area of component 
// 		protected var _bgContent							:Sprite; // sprite for the area of content
// 		public var _txt									:TextField;
// 		public var _icon									:MovieClip; // Stores the attached icon instance
		protected var _imageLoaders							:Vector.<ImageLoaderAdv> = new Vector.<ImageLoaderAdv>();
		protected var _bitmaps							:Vector.<Bitmap> = new Vector.<Bitmap>();
		protected var _bitmapsHighres						:Vector.<Bitmap> = new Vector.<Bitmap>();
		// DATA HOILDERS ///////////////////////////////////////////////////////////////////////////////////////
// 		public var _clips									:Array = [];
// 		protected var _tree								:XML;
// 		protected var _treeArray							:Array; // Defines the application according to arrays and levels
		protected var _xml								:XML; // Holds gallery data
		// MARKERS ////////////////////////////////////////////////////////////////////////
		protected var _pageNum							:uint; // Stores the number of page if needed
		protected var _imgsPerPage							:uint; // Stores the amount of images per page
// 		protected var _isOpen								:Boolean = false;
// 		protected var _selectedMenu						:uint;
// 		public var _active								:Boolean = true;
// INIT ONCE ///////////////////////////////////////////////////////////////////////////////////////
		public function _cBaseImageGallery					(id:String="_cBaseImageGallery", par:Object=null) {
			super									(id, par);
		}
		protected override function init						():void {
			super.init									();
			UMem.addClass								(ImageLoaderAdv);
		}
// INIT ANY TIME ///////////////////////////////////////////////////////////////////////////////////////
		protected override function initialize					():void {
			super.initialize								();
		}
		public override function recycle						(par:Object=null):void {
			super.recycle								(par);
		}
// COMMON METHODS ///////////////////////////////////////////////////////////////////////////////////////		
		public override function release						():void {
			super.harakiri								();
// 			for each (_bitmap in _bitmaps)					UMem.killBitmap(_bitmap);
// 			for each (_bitmap in _bitmapsHighres)				UMem.killBitmap(_bitmap);
			for each (_imageLoader in _imageLoaders) {
				_imageLoader.harakiri						();
				UDisplay.removeClip						(_imageLoader);
				UMem.storeInstance						(_imageLoader);
			}
			_imageLoaders								= new Vector.<ImageLoaderAdv>();
			_bitmaps									= new Vector.<Bitmap>();
			_bitmapsHighres								= new Vector.<Bitmap>();
			_xml										= null;
		}
		public override function harakiri						():void {
			UXml.dispose								(_xml);
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function renderXml							(xx:XML):void {
// 			if (isRendered() && _xml == xx) { // Re-render only if its a new xml
// 				Debug.debug							(_debugPrefix, "Same XML rendered twice, abort and retain status.");
// 				return;
// 			} 
			renderGallery								(xx);
			complete									();
		}
		public function addImage							():void {
			
		}
		
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		protected function renderGallery						(xx:XML):void { // This is overridable
			if (isRendered())								release();
			_xml										= xx;
			_pageNum									= 0;
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}