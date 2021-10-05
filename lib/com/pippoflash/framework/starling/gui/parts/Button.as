package com.pippoflash.framework.starling.gui.parts 
{
	import com.pippoflash.framework.starling._StarlingBase;
	import flash.geom.Rectangle;
	import com.pippoflash.utils.*;
	import starling.display.*;
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import com.pippoflash.framework.PippoFlashEventsMan;
	
	/**
	 * A Button made of loaded images, an icon with a clickable margin around.
	 * @author Pippo Gregoretti
	 */
	public class Button extends _PartBase 
	{
		
		// EVENTS
		public static const EVT_SELECT:String = "onButtonSelect"; 
		public static const EVT_DESELECT:String = "onButtonDeselect";  // Only switch sends this
		public static const EVT_PRESS:String = "onButtonPress";
		private static const FADE_TIME:Number = 0.3;
		// Statics
		private static var _radioGroups:Object = {}; // From group to Array of buttons
		// References
		private var _clickableArea:Canvas;
		private var _active:Image;
		private var _inactive:Image;
		private var _selected:Image;
		private var _icon:Image;
		// Data
		private var _size:Rectangle;
		private var _id:String;
		// Markers
		private var _isSwitch:Boolean;
		private var _radioGroup:String;
		private var _isSelected:Boolean;
		private var _isActive:Boolean;
		private var _status:int = 0; // 0 disabled, 1 enabled, 2 selected
		// Setup thigs
		private var _blinkSelectedOnTap:Boolean = true;
		
		public function Button(id:String, size:Rectangle = null) {
			super(id, Button);
			_id = id;
			_size = size ? size : new Rectangle(0, 0, 10, 10);
		}
		public function setImages(active:String, icon:String = null,  selected:String = null, inactive:String = null, clickableMargin:uint = 10):void {
			if (_active) {
				Debug.error(_debugPrefix, "setImages called twice. Button cannot be initialized twice.");
				return;
			}
			_active = getImage(active);
			if (selected) _selected = getImage(selected);
			if (inactive) _inactive = getImage(inactive);
			if (icon) setIcon(icon);
			setSize(_active.width, _active.height, clickableMargin);
			setStatus(1, true);
			addChild(_active);
			StarlingGesturizer.addTap(this, onTap);
		}
		/**
		 * Set an area to expand in all directions of button in order to intercept clicks. BEWARE, width and height will return dimensions with margins. Use the size:Rectangle property instead.
		 * @param	margin pixels to expand in all directions
		 */
		public function setIcon(icon:String):void {
			_icon = getImage(icon);
			uDisplay.alignTo(_icon, _size);
			addChild(_icon);
		}
		public function setClickableMargin(margin:int):void {
			if (!_clickableArea) {
				_clickableArea = uDisplay.getSquareCanvas(0xff0000);
				_clickableArea.alpha = 0;
				addChildAt(_clickableArea, 0);
			}
			_clickableArea.width = _size.width + margin * 2;
			_clickableArea.height = _size.height + margin * 2;
			_clickableArea.x = _clickableArea.y = -margin;
		}
		public function setSize(w:Number, h:Number, clickableMargin:uint=0, mode:String="STRETCH"):void {
			_size.width = w; _size.height = h;
			uDisplay.resizeTo(_active, _size, mode);
			if (_selected) uDisplay.resizeTo(_selected, _size, mode);
			if (_inactive) uDisplay.resizeTo(_inactive, _size, mode);
			setClickableMargin(clickableMargin);
			if (_icon) uDisplay.alignTo(_icon, _size);
		}
		
		
		// UTY
		/**
		 * Sets the status of button (inactive, active, selected)
		 * @param	status 0 is inactive, 1 is active, 2 is selected
		 * @param	immediate if immediately or animate
		 */
		public function setStatus(status:uint,  immediate:Boolean = false) {
			if (status == _status) return;
			if (immediate) {
				uDisplay.addOrRemove(_inactive, this, status == 0);
				uDisplay.addOrRemove(_active, this, status == 1);
				uDisplay.addOrRemove(_selected, this, status == 2);
			}
			else {
				if (inactive) fadeOut(_inactive);
				else if (status == 0) fadeIn(_inactive);
				if (active) fadeOut(_active);
				else if (status == 1) fadeIn(_active);
				if (selected) fadeOut(_selected);
				else if (status == 2) fadeIn(_selected);
			}
			// Always add icon
			uDisplay.addOrRemove(_icon, this, true);
			// Set the status
			_status = status;
		}
		
		public function toggleSwitch():void {
			setStatus(_status == 2 ? 1 : 2);
		}
		
		public function blinkSelected():void {
			if (_selected) {
				addChild(_selected);
				_selected.alpha = 1;
				mover.fade(_selected, 0.2, 0, null, null, "KILL");
			}
		}
		
		
		private function fadeOut(c:Image):void {
			mover.fade(c, FADE_TIME, 0, null, null, "KILL");
		}
		private function fadeIn(c:Image):void {
			addChild(c);
			c.alpha = 0;
			mover.fade(c, FADE_TIME, 1);
			// Always add icon
			uDisplay.addOrRemove(_icon, this, true);
		}
		
		// LISTENERS
		public function onTap(c:Button):void {
			if (inactive) return; // Button is inactive
			if (isSwitch) {
				toggleSwitch();
				PippoFlashEventsMan.broadcastInstanceEvent(this, selected ? EVT_SELECT : EVT_DESELECT, this);
				if (radioGroup) {
					for each (var b:Button in _radioGroups[_radioGroup]) {
						if (b != this) b.setStatus(1);
					}
				}
			} else {
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PRESS, this);
				if (_blinkSelectedOnTap) blinkSelected();
			}
		}
		
		// GET SET
		public function get size():Rectangle {
			return _size;
		}
		public function get selected():Boolean {
			return _status == 2;
		}
		public function get active():Boolean {
			return _status == 1;
		}
		public function get inactive():Boolean {
			return _status == 0;
		}
		
		public function get isSwitch():Boolean {
			return _isSwitch;
		}
		public function set isSwitch(value:Boolean):void {
			_isSwitch = value;
			//if (!value && selected) setStatus(1, true); // Bring back to active if switch is removed and is selected
		}
		public function get radioGroup():String {
			return _radioGroup;
		}
		
		public function get id():String 
		{
			return _id;
		}
		
		public function set radioGroup(value:String):void {
			_radioGroup = value;
			if (!_radioGroups[_radioGroup]) _radioGroups[_radioGroup] = [];
			if (_radioGroups[_radioGroup].indexOf(this) == -1) _radioGroups[_radioGroup].push(this);
			isSwitch = true;
		}
	}

}