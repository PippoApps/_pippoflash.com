
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.utils.*;
	import											com.pippoflash.motion.Animator;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	// COMPONENT ASSETS IMPORT
// 	import											PippoFlashAS3_Components_PippoFlashButton_Blue;
// 	import											PippoFlashAS3_Components_PippoFlashButton_Default;
// 	import											PippoFlashAS3_Components_PippoFlashButton_Empty;
// 	import											PippoFlashAS3_Components_PippoFlashButton_Green;
// 	import											PippoFlashAS3_Components_PippoFlashButton_Minimal;
// 	import											PippoFlashAS3_Components_PippoFlashButton_Tick;
// 	import											PippoFlashButton_SimpleRadio;
	
	
	public class PippoFlashButtonColor extends PippoFlashButton {






		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////

		[Inspectable 									(name="Txt Color - UP", type=Color, defaultValue=0x000000)]
		public var _colUp								:uint = 0x000000ff;
		[Inspectable 									(name="Txt Color - ROLLO", type=Color, defaultValue=0x666666)]
		public var _colRoll								:uint = 0x666666ff;
		[Inspectable 									(name="Txt Color - DOWN", type=Color, defaultValue=0xffffff)]
		public var _colDown								:uint = 0xffffffff;
		[Inspectable 									(name="Txt Color - SLEEP", type=Color, defaultValue=0x000000)]
		public var _colSleep								:uint = 0x00000088;
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		// MARKERS ////////////////////////////////////////////////////////////////////////
		// DATA ///////////////////////////////////////////////////////////////////////////////////////
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function PippoFlashButtonColor				(par:Object=null) {
			super									(par);
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		protected override function updateTextColor			():void {
			if (_active) {
				if (_selected)							setTextDown();
				else									setTextUp();
			}
			else {
				setTextSleep							();
			}
		}
		protected override function setTexRoll				():void {
			if (_txt)									UDisplay.setClipColor(_txt, _colRoll);
		}
		protected override function setTextUp				():void {
			if (_txt)									UDisplay.setClipColor(_txt, _colUp);
		}
		protected override function setTextDown				():void {
			if (_txt)									UDisplay.setClipColor(_txt, _colDown);
		}
		protected override function setTextSleep				():void {
			if (_txt)									UDisplay.setClipColor(_txt, _colSleep);
		}
// FRAMEWORK METHODS ///////////////////////////////////////////////////////////////////////////////////////
// GETTERS/SETTERS ///////////////////////////////////////////////////////////////////////////////////////
// ICON PLACEMENT ///////////////////////////////////////////////////////////////////////////////////////
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}