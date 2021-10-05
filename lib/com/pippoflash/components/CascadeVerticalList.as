/* _cBaseNav - Is a base class for all Navigation interface item menus.
*/
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UMem;
	import											com.pippoflash.utils.UXml;
	import											com.pippoflash.motion.Animator;
	import											com.pippoflash.motion.PFMover;
	import											com.pippoflash.gui.button._AutoButtonClips;	
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public class CascadeVerticalList extends _cBase{
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
// 		[Inspectable 									(name="Icon Attachment", type=String, defaultValue="NO ICON")]
// 		public var _iconAttachment							:String = "NO ICON"; // This decides an icon to be attached
		[Inspectable 									(name="Link - LISTITEM Class (_AutoButtonClips compliant)", type=String, defaultValue="PippoFlash_CasVerList_ITEM")]
		public var _linkListItem								:String = "PippoFlash_CasVerList_ITEM";
		[Inspectable 									(name="Link - LISTGROUP Class (_AutoButtonClips compliant)", type=String, defaultValue="PippoFlash_CasVerList_GROUP")]
		public var _linkListGroup							:String = "PippoFlash_CasVerList_GROUP";
		[Inspectable 									(name="Link to BG Class", type=String, defaultValue="PippoFlash_CascadeVerticalListBG")]
		public var _linkBg									:String = "PippoFlash_CascadeVerticalListBG";
		[Inspectable 									(name="IMG - Link Image Loading Anim", type=String, defaultValue="PippoFlash_ImageLoaderAdv_LoaderAnimClass")]
		public var _linkImageLoaderanim						:String = "PippoFlash_ImageLoaderAdv_LoaderAnimClass";
		[Inspectable 									(name="IMG - Cover Image URL", type=String, defaultValue="http://www.pippoflash.com/_img/0.swf")]
		public var _imgUrl								:String = "http://www.pippoflash.com/_img/0.swf";
// 		[Inspectable 									(name="Margin - Internal", type=Number, defaultValue=2)]
// 		public var _intMargin								:uint = 2; // This decides a frame of the icon to go
// 		[Inspectable 									(name="Margin - External", type=Number, defaultValue=4)]
// 		public var _extMargin								:uint = 4; // This decides a frame of the icon to go
		[Inspectable 									(name="UX - ScrollBar", type=Boolean, defaultValue=true)]
		public var _useScrollBar							:Boolean = true; // This decides a frame of the icon to go
		[Inspectable 									(name="UX - ScrollBar Class", type=String, defaultValue="PippoFlashAS3_Components_PippoFlashScrollBar_Minimal")]
		public var _linkScrollBar							:String = "PippoFlashAS3_Components_PippoFlashScrollBar_Minimal";
		[Inspectable 									(name="UX - Auto Scroll", type=Boolean, defaultValue=true)]
		public var _autoScroll								:Boolean = true; // This decides a frame of the icon to go
// 		[Inspectable 									(name="Icon positioning", type=String, defaultValue="LEFT", enumeration="LEFT,RIGHT,TOP,BOTTOM,CENTERED (no text)")]
// 		public var _iconPositioning							:String = "LEFT";
// 		[Inspectable 									(name="Icon Y Offset", type=Number, defaultValue=0)]
// 		public var _yIOff									:Number = 0;
		[Inspectable 									(name="IMG - Width of image", type=Number, defaultValue=120)]
		public var _imgWidth								:Number = 120;
		[Inspectable 									(name="COLUMN - Width of column", type=Number, defaultValue=180)]
		public var _colWidth								:Number = 180;
// 		[Inspectable 									(name="Button Class Name", type=String, defaultValue="PippoFlashAS3_Components_PippoFlashButton_Default")]
// 		public var _buttonLinkage							:String = "PippoFlashAS3_Components_PippoFlashButton_Default";
// 		[Inspectable 									(name="Text Alignment", type=String, defaultValue="CENTER", enumeration="CENTER,JUSTIFY,LEFT,RIGHT")]
// 		public var _textAlign								:String = "CENTER";
// 		[Inspectable 									(name="Is Radio Group (overrides switch)", type=String)]
// 		public var _radioGroup								:String;
		[Inspectable 									(name="IMG - Use Left Image", type=Boolean, defaultValue=true)]
		public var _useImg								:Boolean = true;
		[Inspectable 									(name="XML - DIspose on new render", type=Boolean, defaultValue=false)]
		public var _disposeOnNewRender						:Boolean = false;
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
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
// 		protected var _lastHeight							:Number = 0; // Last height of clips
// 		protected var _setupProperty						:String; // x or y, property to modify according to direction
// 		protected var _sizeProperty							:String; // width or height, property to modify according to direction
// 		protected var _isVertical							:Boolean;
// 		public var _doubleMargin							:Number; // Stores _textMargin*2;
// 		public var _rect									:Rectangle;
// 		public var _appearFunction							:Function;
		private static var _containerDefaultValues				:Object = {_extMargin:0, _intMargin:0, width:200, height:100, _alignH:"LEFT", _alignV:"TOP", _direction:"VERTICAL", _useAreaBg:false};
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
// 		protected var _container							:Sprite = new Sprite();
// 		protected var _positionClip							:Function; // This changes according to direction
// 		protected var _bgArea								:Sprite; // Sprite for the whole area of component 
// 		protected var _bgContent							:Sprite; // sprite for the area of content
// 		public var _txt									:TextField;
// 		public var _icon									:MovieClip; // Stores the attached icon instance
		private var _listItemClass							:Class;
		private var _listGroupClass							:Class;
		private var _listBgClass								:Class;
		private var _imgClip								:ImageLoaderAdv;
		private var _tempButtonList							:Array; // Stores the temp list for a button and sets radio button
		private var _imgBg								:*;
		// DATA HOILDERS ///////////////////////////////////////////////////////////////////////////////////////
		private var _xml									:XML;
// 		private var _nodeNameToClass						:Object;
// 		public var _clips								:Array = [];
// 		protected var _tree								:XML;
// 		protected var _treeArray							:Array; // Defines the application according to arrays and levels
		// MARKERS ////////////////////////////////////////////////////////////////////////
		private var _depth								:uint; // Depth of the list
		// private var _rendered								:Boolean;
		private var _startX								:Number = 0;
		private var _selectedClip							:_AutoButtonClips; // The selected clip
		private var _selectedDepth							:uint = 0;
		private var _targetDepth							:uint = 0;
		private var _lastListNum							:uint; // The last list closed, this is needed to destroy all its subclips
		private var _renderingListNum						:uint; // Marks the rendering list, so that all clips can be added to the disposable list
// 		protected var _isOpen								:Boolean = false;
// 		protected var _selectedMenu						:uint;
// 		public var _active								:Boolean = true;
		// STATIC UTY ///////////////////////////////////////////////////////////////////////////////////////
		private static var _node							:XML;
		private static var _list								:Sprite;
		private static var _scrollBar							:ScrollBarArrows;
		private static var _cont							:Container;
		private static var _cb								:ContentBox;
		private static var _bg								:*;
		private static var _item							:*;
		private static var _group							:*;
		private static var _a								:Array;
		private static var _j								:*;
		private static var _c								:*;
		private static var _o								:Object;
// INIT ///////////////////////////////////////////////////////////////////////////////////////

		public function CascadeVerticalList						(par:Object=null) {
			super									("CascadeVerticalList", par);
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
			_listItemClass								= UCode.getClassFromString(_linkListItem);
			_listGroupClass								= UCode.getClassFromString(_linkListGroup);
			_listBgClass									= UCode.getClassFromString(_linkBg);
			_startX									= _imgWidth;
			UMem.addClass								(_AutoButtonClips);
			UMem.addClass								(_listItemClass);
			UMem.addClass								(_listGroupClass);
			UMem.addClass								(_listBgClass);
			UMem.addClass								(ContentBox);
			UMem.addClass								(Container);
			UMem.addClass								(ScrollBarArrows);
			UMem.addClass								(PippoFlash_TransparentSquareClip);
			UMem.addClass								(ImageLoaderAdv);
			_containerDefaultValues.width					= _colWidth;
			_containerDefaultValues.height					= _h;
		}
		public override function update						(par:Object):void {
			super.update								(par);
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function renderXml							(n:XML):void {
			if (_disposeOnNewRender && isRendered())	{
				UXml.dispose							(_xml);
				disposeAll								();
				_xml									= null;
				
			}
			_xml										= n;
			UXml.setIdRecursiveAndStore					(_xml);
			renderList									();
			complete									();
		}
		public function getWidth							():Number { // Returns the width for target position
			return									_startX + (_colWidth * (_targetDepth+1));
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		private var _containers								:Array = [];
		private var _contentBoxes							:Array = [];
		private var _lists									:Array = []; // Lists of main clips containing BG and content box
		private var _bgs									:Array = [];
// 		private var _disposableClips							:Array = []; // List of all clips that can be disposed by UMem
		private var _clipsLists								:Array = []; // Bi-dimensional list with all clips relevant to a list
		private var _scrollBars								:Array = [];
		private var _mainList								:Sprite; // Links to the list 0, or root list
		// STARTUP RENDERING
		private function renderList							():void {
			if (isRendered())								disposeAll();
			_depth									= UXml.getXmlDepth(_xml);
			renderImage								();
			renderMainContents							();
		}
			private function disposeAll						():void {
				for each (_a in _clipsLists) for each (_c in _a)	UMem.storeInstance(_c);
				for each (_cont in _containers)				UMem.storeInstance(_cont);
				for each (_cb in _contentBoxes)				UMem.storeInstance(_cb);
				for each (_scrollBar in _scrollBars)				UMem.storeInstance(_scrollBar);
				for each (_bg in _bgs)						UMem.storeInstance(_bg);
				_containers								= [];
				_contentBoxes							= [];
				_lists									= [];
				_bgs									= [];
				_clipsLists								= [];
				_scrollBars								= [];
				_targetDepth							= 0;
				if (_imgBg) {
					UDisplay.removeClip					(_imgBg);
					_imgBg							= null;
				}
				_selectedDepth							= 0;
				// Dispose img
				if (_imgClip)							UMem.storeInstance(_imgClip);
			}
			private function renderImage						():void {
				_startX								= 0;
				if (_useImg) {
					_imgBg = new _listBgClass(); _imgBg.height = _h; _imgBg.width = _imgWidth; addChild(_imgBg);
					_imgClip							= UMem.getInstance(ImageLoaderAdv, {_resizeMode:"CROP-RESIZE", x:0, y:0, height:_h, width:_imgWidth, _w:_imgWidth, _h:_h});
					addChild							(_imgClip);
					if (UCode.exists(_xml.@image))			_imgUrl = _xml.@image;
					_imgClip.loadImage					(_imgUrl);
					_startX							= _imgWidth;
				}
			}
			private function renderMainContents				():void { // This renders the correct amount of containers to handle enough depth for the list
				for (_i=0; _i<_depth; _i++) {
					// Create main content holder
					_list								= new Sprite();
					_lists.push							(_list);
					// Create content box
					_cb								= UMem.getInstance(ContentBox, {height:_h, width:_colWidth, _autoScroll:_autoScroll});
					_contentBoxes.push					(_cb);
					// Create containers
					_cont							= UMem.getInstance(Container, _containerDefaultValues);
					_containers.push						(_cont);
					// Create BG
					_bg								= UMem.getInstance(_listBgClass);
					_bg.visible							= false;
					_bgs.push							(_bg);
					// Add childs in list clip
					_list.addChild(_bg); _list.addChild(_cb);
					// Crate scrollbars if they are needed
					if (_useScrollBar) {
// 						_scrollBar						= new ScrollBarArrows({_graphLinkage:_linkScrollBar, _showArrows:false, _disappearOnNoScroll:true, _bgClickScroll:"NONE", _maxHeight:Math.round(_h*0.60), _w:8, _h:Math.round(_h*0.60), x:_colWidth-12, y:Math.round(_h*20)});
						var margin						:uint = 5;
						_scrollBar						= UMem.getInstance(ScrollBarArrows, {_graphLinkage:_linkScrollBar, _showArrows:false, _disappearOnNoScroll:true, _bgClickScroll:"NONE", _maxHeight:Math.round(_h*0.60), width:8, height:(_h-margin*2), x:_colWidth-(8+margin), y:margin});
						_scrollBars.push					(_scrollBar);
						_cb.setScrollBarV					(_scrollBar);
						_list.addChild					(_scrollBar);
					}
					// Add list clip (to lower level)
					addChildAt(_list, 0);
				}
				// Add all lists to stage
				// Add to disposable
				// _disposableClips							= _disposableClips.concat(_bgs, _contentBoxes);
				// Render main list
				renderMainList							();
			}
			private function renderMainList					():void {
				_mainList								= _lists[0];
				renderNodeInLevel						(0, _xml);
				_mainList.x								= _startX;
				broadcastEvent							("onListUpdate", this);
			}
		// RENDER ONE LIST
		private function renderNodeInLevel						(l:uint, n:XML):void {
			_renderingListNum							= l;
			_clipsLists[_renderingListNum]					= [];
			_AutoButtonClips.setToHtml						(true);
			_list										= _lists[_renderingListNum];
			var 										clips:Array = getClipsArray(n, _renderingListNum);
			_containers[l].setup							(clips);
			_contentBoxes[l].releaseContent					();
			_contentBoxes[l].setContent						(_containers[_renderingListNum]);
			_contentBoxes[l].blockScrollH						();
			_bgs[l].width								= _colWidth;
			_bgs[l].height								= _h;
			_bgs[l].visible								= true;
			_lists[l].addChild								(_contentBoxes[_renderingListNum]);
			_lists[l].addChild								(_scrollBars[_renderingListNum]);
		} 
			private function getClipsArray					(n:XML, depth:uint):Array {
				_tempButtonList							= [];
				var noText								:String = "DISTANCE";
				_a									= new Array();
				for each (_node in n.children()) {
					var c								:*;
					c								= getSingleClip(_node);
					c._xmlId							= UXml.getId(_node);
					c._depth							= depth;
					_a.push							(_j);
				}
				Buttonizer.makeList						(_tempButtonList, -1);
				return								_a;
			}
			private function getSingleClip					(n:XML):* { // I need to set columns also here not to break the function proxy
				return								this["getClipFor"+n.name()](n);
			}
			private function getClipForLISTITEM				(n:XML):* {
// 				trace("CREO LISTA PER",n.toXMLStriqng());
				_c									= UMem.getInstance(_listItemClass);
				_j									= UMem.getInstance(_AutoButtonClips, _c);
				_clipsLists[_renderingListNum].push				(_c);
				_clipsLists[_renderingListNum].push				(_j);
				_j.setTextVert							(UXml.formatNode(n));
				return								_j;
			}
			private function getClipForLISTGROUP				(n:XML):* {
// 				trace("CREO LISTA PER",n.toXMLString());
				_c									= UMem.getInstance(_listGroupClass);
				_j									= UMem.getInstance(_AutoButtonClips, _c, this, "Group");
				_clipsLists[_renderingListNum].push				(_c);
				_clipsLists[_renderingListNum].push				(_j);
// 				Buttonizer.setupButton					(_j, this, "Group", "onPress");
				_tempButtonList.push						(_c);
				_j.setTextVert							(UXml.formatNode(n));
				return								_j;
			}
			private function getClipForDISTANCE				(n:XML):* {
				_j									= UMem.getInstance(PippoFlash_TransparentSquareClip);
				_j.height								= Number(n.@px);
				return								_j;
			}
			
			
// SELECTION ///////////////////////////////////////////////////////////////////////////////////////
		private function selectGroup							(c:_AutoButtonClips):void {
			_selectedClip								= c;
			_targetDepth								= c._depth + 1;
			checkForOpen								();
// 			trace("is open",isOpen());
			broadcastEvent								("onListResize", this);
		}
// 			private function getTargetDepthWidth				():Number {
// 				
// 			}
			private function checkForOpen					():void {
				if (isOpen())							closeLastList();
				else									openSelected();
			}
			private function isOpen						():Boolean {
				return								_selectedDepth >= _targetDepth;
			}
			private function closeLastList					():void {
				// Closes last list and opens the newly selected one
				PFMover.slideOut						(_lists[_selectedDepth], {steps:8, pow:2, endPos:{x:0}, onComplete:onLastListClosed});
				_lastListNum							= _selectedDepth;
				_selectedDepth							--;
// 				broadcastEvent							("onListUpdate", this);
			}
			public function onLastListClosed					():void {
				// I have to clean and recycle all objects for the last closed list
				// TODOOOOOOOOOOOOOOOOOOOOOOOO
				_containers[_lastListNum].harakiri				();
				_a									= _clipsLists[_lastListNum];
				for each (_c in _a) {
					_c.harakiri							();
					UDisplay.removeClip					(_c);
					UMem.storeInstance					(_c);
				}
// 				UMem.storeInstance						(_containers[_lastListNum]);
				
				_clipsLists[_lastListNum]					= [];
				checkForOpen							();
			}
		private function openSelected						():void {
// 			_b										= _selectedDepth != _targetDepth;
			_selectedDepth								= _targetDepth;
			renderNodeInLevel							(_selectedDepth, UXml.getNode(_selectedClip._xmlId));
			_list										= _lists[_selectedDepth-1];
			PFMover.slideIn							(_lists[_selectedDepth], {steps:20, pow:3, endPos:{x:_selectedDepth*_colWidth}});
// 			if (_b)									broadcastEvent("onListUpdate", this);
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// 		private function addToDisposableList					(a:Array):void {
// 			_disposableClips								= _disposableClips.concat(a);
// 		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onPressGroup							(c:*) {
			selectGroup								(c.parent);
		}
	}
}