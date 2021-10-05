/* TABLeft - Quick Description.
*/

package com.pippoflash.components {
	
	import com.pippoflash.components._cBase;
	import com.pippoflash.components.assets.common.BgSquare;
	import com.pippoflash.utils.*;
	import com.pippoflash.motion.PFMover;
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	import flash.filters.DropShadowFilter;
	import flash.filters.BevelFilter;
	
	public class TABLeft extends _cBase{
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
// 		[Inspectable 									(name="Icon Attachment", type=String, defaultValue="NO ICON")]
// 		public var _iconAttachment							:String = "NO ICON"; // This decides an icon to be attached
// 		[Inspectable 									(name="GUI - Link Image Loading Anim", type=String, defaultValue="PippoFlash_ImageLoaderAdv_LoaderAnimClass")]
// 		public var _linkImageLoaderAnim						:String = "PippoFlash_ImageLoaderAdv_LoaderAnimClass";
		[Inspectable 									(name="UI - Link for ICON", type=String, defaultValue="PippoFlash_ICON_Facebook_Square_65")]
		public var _linkIcon								:String = "PippoFlash_ICON_Facebook_Square_65";
		[Inspectable 									(name="UI - Link for BG", type=String, defaultValue="PippoFlash_Component_TabLeft_Tab_BG_75")]
		public var _linkBg									:String = "PippoFlash_Component_TabLeft_Tab_BG_75";
		[Inspectable 									(name="UI - Size of tab thumb", type=Number, defaultValue=75)]
		public var _widthIcon								:uint =75; // This decides a frame of the icon to go
		[Inspectable 									(name="Margin - External", type=Number, defaultValue=10)]
		public var _extMargin								:uint = 10; // This decides a frame of the icon to go
		[Inspectable 									(name="UX - Auto position on stage resize", type=Boolean, defaultValue=true)]
		public var _autoPosition							:Boolean = true; // This decides a frame of the icon to go
		[Inspectable 									(name="UI - Positioning", type=String, defaultValue="LEFT", enumeration="LEFT,RIGHT,TOP,BOTTOM,CUSTOM")]
		public var _positioning								:String = "LEFT";
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
		// CONSTANTS ///////////////////////////////////////////////////////////////////////////////////////
		private static const BEVEL_FILTER_PARAMS				:Object = {knockout:false, type:"inner", quality:3, strength:0.84765625, blurY:2, blurX:2, shadowAlpha:1, shadowColor:0, highlightAlpha:1, highlightColor:16777215, angle:44.999253346524966, distance:1};
		private static const SHADOW_FILTER_PARAMS				:Object = {hideObject:false, knockout:false, inner:false, quality:3, strength:0.5390625, blurY:5, blurX:5, alpha:1, color:0, angle:44.999253346524966, distance:2};
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		private var _bg									:*; // Holds the BG
		private var _buttIcon								:BgSquare; // Holds the button icon
		private var _content								:*; // Holds the content
		private var _icon									:MovieClip;
		// DATA HOILDERS ///////////////////////////////////////////////////////////////////////////////////////
		// MARKERS ////////////////////////////////////////////////////////////////////////
		private var _hasContent							:Boolean;
		private var _isOpen								:Boolean;
		private var _isHidden								:Boolean;
// INIT ONCE ///////////////////////////////////////////////////////////////////////////////////////
		public function TABLeft							(par:Object=null) {
			super									("TABLeft", par);
		}
		protected override function init						():void {
			// First initialization goes here
			super.init									();
		}
		protected override function initAfterVariables				():void { // This can be overridden. No need to be called. It gets called automatically depending on how I have been instantiated.
			// Setup BG and Icon Button
			_bg = UCode.getInstance(_linkBg); addChild(_bg);
			_buttIcon = new BgSquare(); addChild(_buttIcon); _buttIcon.name = "_buttIcon"; Buttonizer.autoButton(_buttIcon, this, "onPress,onRollOver,onRollOut");
			_buttIcon.width = _widthIcon; _buttIcon.height = _widthIcon; _buttIcon.alpha = 0; 
			_icon = UCode.getInstance(_linkIcon); addChild(_icon); addChild(_buttIcon);
			UGlobal.addResizeListener						(onResize);
			// Add filter to bg
			var bf									:BevelFilter = new BevelFilter();
			UCode.setParameters							(bf, BEVEL_FILTER_PARAMS);
			var sf									:DropShadowFilter = new DropShadowFilter();
			UCode.setParameters							(sf, SHADOW_FILTER_PARAMS);
// 			_bg.filters									= [bf, sf];
			//  Initialization after receioved variables goes here
			super.initAfterVariables						();
		}
// INIT ANY TIME ///////////////////////////////////////////////////////////////////////////////////////
		protected override function initialize					():void {
			super.initialize								();
			// This is called each time the component is started. Parameters have already been set or updated. Whatever renders and happens here needs to be able to re-happen.
			positionItems								();
			onResize									();
		}
		public override function recycle						(par:Object=null):void {
			// This is called as re-initialization after a cleanup
			super.recycle								(par);
		}
			private function positionItems					():void {
				_bg.width = _w + _widthIcon; _bg.height = _h;
				_buttIcon.x = _w; UDisplay.alignSpriteTo(_icon, _buttIcon); 
			}
// KILL AND RECYCLE ///////////////////////////////////////////////////////////////////////////////////////
// 		public function override release						():void {
// 			super.release								();
// 			// This is called to undo a render operation, and make the component ready again to render content - IT DOESN'T RESET THE OCMPINENT OR ELIG IT FOR RECYCLE
// 			// Call this if you want to render again a component after usage. It undos render, and removes content if applicable.
// 		}
// 		public function override cleanup						():void {
// 			super.cleanup								();
// 			UDisplay.removeClip							(_content);
// 			_content									= null;
// 			// This is used by UMeme to store the ocmponent. After this, no render() is possible, but the ocmponent must be used with recycle. This stops all components activities, but leaves it redy for a recycle.
// 		}
// 		public function override recycle						():void {
// 			super.recycle								();
// 			// This has to be called after a cleanup() to re-initialize the ocmponent. Parameters take all of part of initialization parameters. After this, an initialize() is called.
// 		}
// DISPOSE ///////////////////////////////////////////////////////////////////////////////////////
		public override function harakiri						():void {
			// This tries to make the component aligible for garbage collection. This method KILLS the component, it will not be possible ot use it again in the future.
			super.harakiri								();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setContent							(c:*, resize:Boolean=false):void {
			if (_hasContent)								cleanup();
			// Resizes background according to content and margin
			if (resize) {
				_w = UCode.getWidth(c) + _extMargin * 2; _h = UCode.getHeight(c) + _extMargin * 2;
				initialize								();
			}
			// This sets the content in the tab
			_content = c; _content.x = _content.y = _extMargin; addChild(_content);
		}
		public function open								():void {
			// Opens to open position
			_isOpen = true; _isHidden = false;
			PFMover.slideIn							(this, {steps:10, pow:3, endPos:{x:0}});
		}
		public function close								():void {
			// Closes leaving tab visible
			_isOpen = false; _isHidden = false;
			PFMover.slideIn							(this, {steps:10, pow:3, endPos:{x:-_w}});
		}
		public function toggleOpen							():void {
			this[_isOpen ? "close" : "open"]					();
			broadcastEvent								(_isOpen ? "onTabOpen" : "onTabClose", this);
		}
		public function hide								():void {
			// Hides totally
			_isOpen = false; _isHidden = true;
			PFMover.slideIn							(this, {steps:6, pow:3, endPos:{x:-(_w+_widthIcon)}});
		}
		public function show								():void {
			// Shows tab
			if (_isOpen)								return;
			close										();
		}
		public function onResize							(e:Event=null):void {
			if (!_autoPosition)							return;
			this["position_"+_positioning]						();
		}
		public function isOpen								():Boolean {
			return									_isOpen;
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function position_LEFT						():void {
			x = -_w;
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onPressIcon							(c:BgSquare=null) {
			toggleOpen									();
			broadcastEvent								("onTabPress", this);
		}
		public function onRollOverIcon						(c:BgSquare=null) {
			broadcastEvent								("onTabRollOver", this);
		}
		public function onRollOutIcon						(c:BgSquare=null) {
			broadcastEvent								("onTabRollOut", this);
		}
	}
}