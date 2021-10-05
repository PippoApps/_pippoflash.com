/* PippoFlashMenu_Base (c) Filippo Gregoretti - www.pippoflash.com - Base class to extend for all menu components - ATTENTION - This class alone is useless, MUST BE EXTENDED */

package com.pippoflash.components {
	
// 	import 											PippoFlashAS3._components._cBase;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.Buttonizer;
// 	import											com.pippoflash.net.SuperLoader;
// 	import											com.pippoflash.net.SuperLoaderObject;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import											flash.net.*;
	import											flash.geom.*;
	
	public class PippoFlashMenu_Base extends _cBase {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="0.0 - List of names", type=Array, defaultValue="Slot 1, Slot 2, Slot 3")]
		public var _txtList								:Array = ["Slot 1", "Slot 2", "Slot 3"];
		[Inspectable 									(name="0.0a - List of data", type=Array, defaultValue="Slot 1, Slot 2, Slot 3")]
		public var _dataList								:Array = ["Data 1", "Data 2", "Data 3"];
		[Inspectable 									(name="0.1 - Text for 1st slot (leave blank for same as slot 0)", type=String, defaultValue="")]
		public var _txtFirst								:String = "";
		[Inspectable 									(name="0.2 - Can be reselected?", type=Boolean, defaultValue=false)]
		public var _reselectable							:Boolean = false;
		[Inspectable 									(name="0.3 - Where render open menu?", type=List, defaultValue="same,parent,stage")]
		public var _menuContainerString					:String = "same";
		[Inspectable 									(name="0.4 - Color", type=Color, defaultValue="#000000")]
		public var _colorNorm							:uint = 0;
		[Inspectable 									(name="0.5 - Color rollover", type=Color, defaultValue="#ff0000")]
		public var _colorRoll								:uint = 0xff0000;
		[Inspectable 									(name="0.6 - Color press", type=Color, defaultValue="#00ff00")]
		public var _colorPress								:uint = 0x00ff00;
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// USER VARIABLES
		// SYSTEM
		// REFERENCES
		public var _container								= this; // This stores the container clip, according to user choice
		public var _menu									:MovieClip = new MovieClip(); // Contains the main menu
		public var _slotsHolder								:MovieClip; // Contains all the slots (this will be reset!)
		public var _slots									:Array = [];
		// MARKERS
		public var _selectedNum							:uint = 0;
		public var _selectedData;							// The data from the array selected
		public var _isOpen								:Boolean = false;
		// DATA HOLDERS
// 		public var _dataList								:Array; // An array of data to broadcast when a menu is called
		public function PippoFlashMenu_Base					(id:String="PippoFlashMenu_Base", par:Object=null) {
			super									(id, par);
		}
// FRAMEWORK ///////////////////////////////////////////////////////////////////////////////////////
// 		protected override function update					(par:Object):void {
// 			release									();
// 			super.update								(par);
// 		}
// 		protected override function release							():void {
// 			super.release								();
// 			_dataList									= [];
// 			_txtList									= [];
// 		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function getSelectedData						():String {
			return									getData(_selectedNum);
		}
		public function getSelectedIndex						():uint {
			return									_selectedNum;
		}
		public function getData							(n:uint):String {
			return									_dataList[n];
		}
// LOADING ///////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
	
}


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