/* _cBaseNav - Is a base class for all Navigation interface item menus.
*/
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBaseNav;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UXml;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UText;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.motion.Animator;
	import											com.pippoflash.motion.AnimatorSequence;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public dynamic class NavTopCorner extends _cBaseNav {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="Attach Main Class", type=String, defaultValue="com.pippoflash.components.NavTopCorner.defaultMainClass")]
		public var _classMain								:String = "com.pippoflash.components.NavTopCorner.defaultMainClass"; 
		[Inspectable 									(name="Attach Group Class", type=String, defaultValue="com.pippoflash.components.NavTopCorner.defaultGroupClass")]
		public var _classGroup								:String = "com.pippoflash.components.NavTopCorner.defaultGroupClass"; 
		[Inspectable 									(name="Attach Item Class", type=String, defaultValue="com.pippoflash.components.NavTopCorner.defaultItemClass")]
		public var _classItem								:String = "com.pippoflash.components.NavTopCorner.defaultItemClass"; 
		[Inspectable 									(name="Menu Slots Height", type=Number, defaultValue=24)]
		public var _slotsMenuHeight							:Number = 24;
// 		[Inspectable 									(name="Icon positioning", type=String, defaultValue="LEFT", enumeration="LEFT,RIGHT,TOP,BOTTOM,CENTERED (no text)")]
// 		public var _iconPositioning							:String = "LEFT";
		[Inspectable 									(name="GUI - Space between boxes", type=Number, defaultValue=0)]
		public var _spaceBetweenBoxes						:Number = 0;
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
		[Inspectable 									(name="Hide", type=Boolean, defaultValue=true)]
		public var _hideOnRollout							:Boolean = true; // Hide on rollout
		[Inspectable 									(name="Groups are Clickable", type=Boolean, defaultValue=false)]
		public var _groupsAreClickable						:Boolean = false;
		[Inspectable 									(name="Fixed Width", type=Boolean, defaultValue=false)]
		public var _fixedWidth								:Boolean = false;
		[Inspectable 									(name="UX - Select parent group", type=Boolean, defaultValue=true)]
		public var _selectParentGroup						:Boolean = true;
// 		[Inspectable 									(name="Text Y Offset", type=Number, defaultValue=0)]
// 		public var _yOff									:Number = 0;
		[Inspectable 									(name="Color of main bg", type=Color, defaultValue=0)]
		public var _mainSlotBgColor							:uint = 0;
// 		[Inspectable 									(name="Margin", type=Number, defaultValue=4)]
// 		public var _textMargin								:Number = 4;
		[Inspectable 									(name="Layout Direction", type=String, defaultValue="HORIZONTAL", enumeration="HORIZONTAL,VERTICAL")]
		public var _directionLayout							:String = "HORIZONTAL";
		[Inspectable 									(name="Open Menu On", type=String, defaultValue="ROLLOVER", enumeration="ROLLOVER,PRESS,NEVER")]
		public var _openMenuAction							:String = "ROLLOVER";
		// VARIABLES //////////////////////////////////////////////////////////////////////////
// 		public static var _radioButtonGroups					:Array = new Array();
// 		public static var _radioGroupsList						:Object = new Object();
// 		public const _instanceList							:Array = ["_up","_over","_down","_sleep"];
// 		private static var _debugPrefix						:String = "NavTopCorner"; // Duplicate to be used in 
		private static var _motionFrames						:uint = 10;
		private static var _motionInterval						:uint = 80;
		public var _formatTop								:String = "<font color='#0000ff'>[text]</font>";
		public var _formatContent							:String = "<font color='#00ff00'>[text]</font>";
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
// 		public static var _horizAlign							:String;
// 		public static var _vertAlign							:String;
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
// 		private var _animSequences							:Array;
		private var _mainAnimOpen							:AnimatorSequence;
		private var _mainAnimClose							:AnimatorSequence;
// 		private var _alpha_down							:Number;
// 		private var _alpha_over							:Number;
// 		public var _doubleMargin							:Number; // Stores _textMargin*2;
// 		public var _rect									:Rectangle;
// 		public var _appearFunction							:Function;
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
// 		public var _button								:Sprite;
// 		public var _txt									:TextField;
// 		public var _icon									:MovieClip; // Stores the attached icon instance
		private var _mainSlot								:MovieClip; // Imported main slot clip
// 		private var _content								:Array; // Multidimensional array of content
		private var _clickBg								:MovieClip; // Clickable BG for main slot
// 		private var _contentSlots							:Array; // Complete list of ALL content slots
// 		private var _contentGroups							:Array; // Complete list of all content groups
		private var _slots								:Array; // All slots NOT GROUP
		private var _groups								:Array; // All groups
		private var _headers								:Array; // All items in header (group or slot)
// 		private var _headerSlots							:Array; // List of main header slots
		private var _headerGroup							:MovieClip = new MovieClip(); // Group containing the header slots
		private var _nodesDictionary							:Object = new Object(); // This doesnt work with XML elements, so I will add a random ID as parameter to the XML
		private var _preselectedNode						:XML; // Stores the preselected node as set in XML
		private var _bg									:Sprite;
		// MARKERS ////////////////////////////////////////////////////////////////////////
		private var _lastSelectedGroup						:XML;
		private var _lastSelectedNode						:XML;
// 		public var _isRadio								:Boolean = false;
// 		public var _active								:Boolean = true;
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function NavTopCorner						(par:Object=null) {
			super									("NavTopCorner", par);
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
			initMainSlot									();
		}
		private function initMainSlot							():void {
			_clickBg									= UDisplay.addChild(this, UCode.getInstance(_classItem));
			_clickBg.setText(""); _clickBg.setSize(_w, _h);
			Buttonizer.setupButton						(_clickBg, this, "Main", "onPress,onRollOver,onRollOut");
			_mainSlot									= UDisplay.addChild(this, UCode.getInstance(_classMain));
			UDisplay.centerToArea(_mainSlot, _w, _h);
			Buttonizer.setClickThrough						(_mainSlot);
		}
			private function putMainSlotToTop					():void {
				addChild(_clickBg); addChild(_mainSlot);
			}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		private function renderSlots							():void {
			_headers									= new Array();
			_groups									= new Array();
			_slots									= new Array();
			prepareGroup								(_tree, true); // I first prepare clips for ALL items
			renderHeaderSlots							();
			renderContentSlots							();
			resetSelection								();
		}
		private function prepareGroup						(group:XML, top:Boolean=false):void {
			for each (var xx:XML in group.children()) 			prepareNode(xx, top);
		}
		private function prepareNode						(xx:XML, top:Boolean=false):void {
			setPropertyForNode							(xx, "_clip", createItemClip(xx, top));
			if (UXml.hasAttribute(xx, "preselect") && UCode.isTrue(xx.@preselect)) {
				_preselectedNode = xx;
			}
			if (isGroup(xx))								prepareGroup(xx);
		}
		private function renderHeaderSlots						():void {
			var prevX									:Number = _w + _spaceBetweenBoxes;
			_mainAnimOpen								= new AnimatorSequence(_motionInterval);
			_mainAnimClose								= new AnimatorSequence(_motionInterval);
			for (var i:uint=0; i<_tree.children().length(); i++) {
				_c									= getPropertyForNode(_tree.children()[i], "_clip");
				_headerGroup.addChild						(_c);
				_c.alpha = 0;
				_mainAnimOpen.addStep					(_c, {steps:12, pow:1, endPos:{alpha:1}}, _c.fadeIn);
				_mainAnimClose.addStep					(_c, {steps:12, pow:3, endPos:{alpha:0}}, _c.fadeOut);
				if (_fixedWidth)							_c.setSize(_w, _h);
				else									_c.setAutoSize(_h);
				_c.x 									= prevX;
				prevX								+= _c.width + _spaceBetweenBoxes;
				_headers.push							(_c);
			}
			Buttonizer.setClickThrough						(_headerGroup);
			_mainAnimClose.reverse						();
			addChild									(_headerGroup);
			putMainSlotToTop							();
		}
		private function renderContentSlots					():void {
			for (_i=0; _i<_tree.GROUP.length(); _i++) {
				renderGroup							(_tree.GROUP[_i]);
			}
		}
		private function renderGroup							(gx:XML):void {
			var gc									:MovieClip = new MovieClip();
			var gso									:AnimatorSequence = new AnimatorSequence(_motionInterval);
			var gsc									:AnimatorSequence = new AnimatorSequence(_motionInterval);
			setPropertyForNode							(gx, "_groupClip", gc);				
			setPropertyForNode							(gx, "_animOpen", gso);				
			setPropertyForNode							(gx, "_animClose", gsc);				
			var prevY									:Number = _spaceBetweenBoxes;
			for (var i:uint=0; i<gx.children().length(); i++) {
				_c									= getPropertyForNode(gx.children()[i], "_clip");
				_c.alpha								= 0;
				_c.y									= prevY;
				prevY								+= _slotsMenuHeight + _spaceBetweenBoxes;
				gso.addStep							(_c, "fadeIn", _c.fadeIn, {alpha:0});
				gsc.addStep							(_c, "fadeOut", _c.fadeOut);
				gc.addChild								(_c);
			}
			gsc.reverse									();
		}
			private function createItemClip					(xx:XML, top:Boolean=false):MovieClip {
				if (isGroup(xx)) {
					_c								= UCode.getInstance(_classGroup);
					_c._isGroup							= true;
					_groups.push						(_c);
				}
				else {
					_c								= UCode.getInstance(_classItem);
					_slots.push							(_c);
				}
				_c._node								= xx;
				_c.setText								(top ? _formatTop.split("[text]").join(xx.@name) : _formatContent.split("[text]").join(xx.@name));
				if (_fixedWidth)							_c.setSize(_w, _slotsMenuHeight);
				else									_c.setAutoSize(_slotsMenuHeight);
				Buttonizer.setupButton					(_c, this, "Slot", "onPress,onRollOver,onRollOut");
				return								_c;
			}
// GET NODE PROPERTIES ///////////////////////////////////////////////////////////////////////////////////////
			private function setPropertyForNode				(node:XML, prop:String, obj):void {
				if (!_nodesDictionary[node.@_pippoFlashXmlNodeID]) {
					node.@_pippoFlashXmlNodeID				= UText.getRandomString();
					_nodesDictionary[node.@_pippoFlashXmlNodeID] = {_node:node};
				}
				_nodesDictionary[node.@_pippoFlashXmlNodeID][prop]	= obj;
			}
			private function getPropertyForNode				(node:XML, prop:String):* {
				return								_nodesDictionary[node.@_pippoFlashXmlNodeID] && _nodesDictionary[node.@_pippoFlashXmlNodeID][prop] ? _nodesDictionary[node.@_pippoFlashXmlNodeID][prop] : null;
			}
			private function getNodeByID					(id:String):XML {
				return								_nodesDictionary[id]._node;
			}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public override function setup						(tree:XML):void {
			super.setup								(tree);
			renderSlots									();
		}
		public override function open							():void {
			if (_isOpen)								return;
			super.open								();
			_mainAnimClose.stop							();
			_mainAnimOpen.start							();
			Buttonizer.setClickThrough						(_headerGroup, false);
		}
		public override function close						():void {
			closeLastGroup								();
			if (!_hideOnRollout)							return;
			super.close								();
			_mainAnimOpen.stop							();
			_mainAnimClose.start							();
			Buttonizer.setClickThrough						(_headerGroup, true);
		}
		public function toggleOpen							():void {
			if (_isOpen)								close();
			else										open();
		}
		public function selectByID							(id:String):void {
			selectByNode								(getNodeByID(id));
		}
		public function selectByNode							(node:XML):void {
			_c										= getPropertyForNode(node, "_clip");
			onRollOverSlot								(_c);
			onPressSlot									(_c);
		}
		public function resetSelection						():void { // If there is a preselected node, I select that, otherwise I just deselect all
			if (_preselectedNode)							selectByNode(_preselectedNode);
		}
		public function createBg							(col:int=0):void {
			if (!_bg)									_bg = UDisplay.getSquareSprite(2000, _h, col);
			else 										UDisplay.setClipColor(_bg, col);
			addChildAt									(_bg, 0);
		}
		public function selectIfContentPresent					(id:String):void {
			// All selected contents get de-selected, and if the content is in one of the nodes, then that header will be selected
			// Node will be: <NAME content="id">
			deselectLastNode								();
			for each (_c in _slots) {
// 				trace("CHECKING",_c._node.toXMLString(),id);
				if (id == _c._node.@content) {
					setSlotSelected						(_c);
					return;
				}
			}
			Debug.debug								(_debugPrefix, "Content id",id,"not present. Cannot set selected.");
		}
// COMMON METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public override function update						(par:Object):void {
			// Unly gets: _hideOnRollout
			super.update								(par);
			if (_hideOnRollout)							close();
			else										open();
		}
// AUTOCLOSE ///////////////////////////////////////////////////////////////////////////////////////
		private var _closeTimeout;
		private function stopCloseTimeout						():void {
			if (_closeTimeout != null)						clearTimeout(_closeTimeout);
		}
		private function startCloseTimeout						():void {
			_closeTimeout								= setTimeout(close, 600);
		}
// GETTERS/SETTERS ///////////////////////////////////////////////////////////////////////////////////////
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		protected function isGroup							(xx:XML):Boolean {
			return									xx.name() == "GROUP";
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onRollOutAll							(c:MovieClip):void {
		}
		public function onRollOverMain						(c:MovieClip):void {
			if (!_hideOnRollout)							return;
			stopCloseTimeout								();
			closeLastGroup								();
			UCode.callMethod							(_mainSlot, "rollOver");
			if (_openMenuAction == "ROLLOVER")				open();
		}
		public function onRollOutMain						(c:MovieClip):void {
			if (!_hideOnRollout)							return;
			startCloseTimeout							();
			UCode.callMethod							(_mainSlot, "rollOut");
		}
		public function onPressMain							(c:MovieClip=null) {
			if (UXml.isTrue(_tree, "mainClick")) 				broadcastEvent("onPressNavMain");
			if (!_hideOnRollout)							return;
			if (_openMenuAction == "PRESS")					toggleOpen();
		}
		public function onRollOverSlot						(c:MovieClip):void {
			stopCloseTimeout								();
			UCode.callMethod							(c, "rollOver");
			if (c._node != _lastSelectedGroup && c._node.parent() != _lastSelectedGroup) {
				closeLastGroup();
			}
			if (c._isGroup) {
				_c									= getPropertyForNode(c._node, "_groupClip");
				_c.y = _h, _c.x = c.x; _c.visible = true; _c.alpha = 1;
				if (c._node != _lastSelectedGroup)	{
					getPropertyForNode(c._node, "_animClose").stop();
					getPropertyForNode(c._node, "_animOpen").start();
					_lastSelectedGroup					= c._node;
				}
				_c.visible								= true;
				addChild								(_c);
			}
		}
			private function closeLastGroup					():void {
				if (!_lastSelectedGroup)					return;
				Animator.fadeOutAndInvisible				(getPropertyForNode(_lastSelectedGroup, "_groupClip"), 4);
				getPropertyForNode(_lastSelectedGroup, "_animClose").start();
				_lastSelectedGroup						= null;
			}
		public function onRollOutSlot							(c:MovieClip):void {
			startCloseTimeout							();
			UCode.callMethod							(c, "rollOut");
		}
		public function onPressSlot							(c:MovieClip=null) {
			if (!_groupsAreClickable && isGroup(c._node))			return;
			deselectLastNode								();
			setSlotSelected								(c);
			broadcastEvent								("onPressNav", c._node);
		}
			private function setSlotSelected					(c:MovieClip):void {
				UCode.callMethod						(c, "setSelected", true);
				_lastSelectedNode						= c._node;
				if (_selectParentGroup) 					setCellParentGroupSelected(c, true);
			}
			private function deselectLastNode					():void {
				if (_lastSelectedNode) {
					_c								= getPropertyForNode(_lastSelectedNode, "_clip");
					UCode.callMethod(_c, "setSelected", false);
					UCode.callMethod(_c, "rollOut");
					if (_selectParentGroup) 				setCellParentGroupSelected(_c, false);
				}
			}
				private function setCellParentGroupSelected		(c:MovieClip, sel:Boolean):void {
// 					trace("CERCO IL PARENTTTTTTTTTTTTTTT!!!!", c._node.parent().toXMLString());
					if (c._node.parent() && getPropertyForNode(c._node.parent(), "_clip")) getPropertyForNode(c._node.parent(), "_clip").setSelected(sel);
// 					trace(getPropertyForNode(c._node.parent(), "_clip"));
				}
	}
}