/* Buttonizer - 2.3 - Filippo Gregoretti - www.pippoflash.com - Added tunneling events


2.3	Added tunneling function.
Tunneling is needed when I have other kinds of events, like gestures or staff, on a container that contains Buttonized items. 
If I set tunnel on the container, is: "tunnel,onClick", onClick will be tunneled in the elements inside and not called on the container (I will add a logic to do both things in the future).
Other working events are the ones not set with buttonizer. Using my libraries for smooth touch motions for example.
Now the Buttonizer can be used to tunnel events to clips inside clips (this is used mostrly for when a buttons container is used inside Gesture touch library.
Activating touch events blocks all mouse interaction inside. PFTouchViewer library tunnels taps as CLICK events on the object transformed.
In order to reach buttons inside the comntainer, a "tunnel" must be added to the initialization events. In that case, events will be only tunneled to the container event and not fired.

This class converts any displayobject inhertiting from Sprite to a button.
It uses standard buttonizing functions (fopr movieclips it shows frames labeled _up _over _down).
It works using instance name, so MAKE SURE EACH BUTTONIZED INSTANCE HAS A UNIQUE "name" PROPERTY!!!!
sinco buttonMode is set to true, calling label _up, _over and _down abilitates frame state change in MovieClips

METHODS
	Buttonizer.setupButton(sprite, listener, post, actions);
		Converts a sprite (or movieclip) into a button.
	
		sprite		Sprite	The DisplayObject to convert to a button
		listener		Object	Any object to receive on... commands from the button
		post			String	The string to add to the commands called in listener onPress[post](), onRollOver[post]() etc.
		actions		String	Comma separated list of button actions to activate, full is: "onPress,onRollOver,onRollOut,onRelease". Defaults: "onPress,onRollOver,onRollOut"
	
	Buttonizer.removeButton(sprite);
		Removes button functionalities (MAKE SURE THE SPRITE "name" DIDNT CHANGE IN THE MEANTIME)
	
BROADCASTS
	Within the listener object, several commands are called as activated in the actions parameter.
	All actions are called with a single parameter, which is a reference to the sprite buttonized.
	Assuming we used "Button" as post parameter in setupButton();
	
	listener.onPressButton(sprite);
	listener.onRollOverButton(sprite);
	listener.onRollOutButton(sprite);
	listener.onReleaseButton(sprite);
	
REVISIONS
	1.2 - [TO BE CONTROLLED] - Added temporary check to control if buttons still exist. If they do not, all buttonizer events will be removed.
	2.0 - Change from adding a property to a movieclip, to a dictionary. Added helper class to manage buttons. Improved greately performance. Added stop propagation and prevent default to events.
*/
package com.pippoflash.utils {
	
	import 									flash.events.MouseEvent;
	import									flash.display.*;
	import									flash.display.InteractiveObject;
	import									flash.text.*;
	import									flash.utils.Dictionary;
	import									com.pippoflash.components.PippoFlashButton;
	
	public class Buttonizer {
	// CONSTANTS ///////////////////////////////////////////////////////////////////////////////////////
		public static const EVENT_USE_CAPTURE:Boolean = false; // If events work in the capture phase
		public static const EVENT_PRIORITY:uint = 10; // Priority of events in the events chain - ContentBoxTouch is 20; Highest the number, higher the priority.
		public static const EVENT_WEAK_REFERENCE:Boolean = true; // Use weak references
		public static const FORCE_TOUCH_DEVICE:Boolean = true;
	// VARIABLES ///////////////////////////////////////////////////////////////////////////////////////
		public static var _verbose:Boolean = true; // If buttonizer has to trace all events
		public static var _debugPrefix:String = "Buttonizer";
		private static var _initialized:Boolean; // If buttonizer has been initialized
		// SYSTEM
		private static var _buttonsItem:Dictionary = new Dictionary(true); // Stores instances of ButtonizerItem associated to button
		// MARKERS
		private static var _lastInteractedItem:ButtonizerItem; // Stored the last item who's interaction was received
		private static var _lastPressedItemWaitingRelease:ButtonizerItem; // When an item is waiting for onRelease, it is stored here
		private static var _lastEvent:MouseEvent; // Stores the last received mouse event, to retrieve values such as ctrlKey, etc.
		// MARKERS
		private static var _isTouchDevice:Boolean; // This marks if we are working on a touch device. Is so, clicks are handled differently
		// STATIC LISTENERS
		static private var _onClickGeneralMethod:Function; // Broadcasted on each click, no matter where
		// STATIC UTY
		private static var _c:DisplayObject;
		private static var _a:Array;
		private static var _s:String;
// FRAMEWORK ///////////////////////////////////////////////////////////////////////////////////////
		private static function traceDebug(...rest):void {
			Debug.debug(_debugPrefix, rest.join(" "));
		}
		private static function traceError(...rest):void {
			Debug.error(_debugPrefix, rest.join(" "));
		}
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public static function init():void {
			_isTouchDevice = USystem.isDevice() || FORCE_TOUCH_DEVICE;
		}
// METHODS ////////////////////////////////////////////////////////////////////////////////////////////////////
		
	// CREATE BUTTONS
		public static function setupButton(c:InteractiveObject, listener:*, post:String="", actions:String="onClick", useFinger:Boolean=true):void {
			// check if button is already set and clear it
			if (isButton(c)) removeButton(c);
			// Setup button with new system
			var item:ButtonizerItem = new ButtonizerItem(c, listener, post);
			_buttonsItem[c] = item;
			// Proceed setting button
			setToButton(c, true);
			if (actions.indexOf(ButtonizerItem.ON_CLICK) != -1) c.addEventListener(MouseEvent.CLICK, onClick, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
			if (actions.indexOf(ButtonizerItem.ON_PRESS) != -1) c.addEventListener(MouseEvent.MOUSE_DOWN, onPress, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
			if (!USystem.isDevice()) { // Rollover and Rollout events are only used on desktop
				if (actions.indexOf(ButtonizerItem.ON_ROLLOVER) != -1) c.addEventListener(MouseEvent.MOUSE_OVER, onRollOver, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
				if (actions.indexOf(ButtonizerItem.ON_ROLLOUT) != -1) c.addEventListener(MouseEvent.MOUSE_OUT, onRollOut, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
			}
			if (actions.indexOf(ButtonizerItem.ON_RELEASE) != -1) {
				item.setOnRelease(true);
			}
			// Setup tunneling
			if (actions.toLowerCase().indexOf(ButtonizerItem.ON_TUNNEL) != -1) item.setTunnel(true);
			// Setup for extended classes
			if (c is MovieClip) {
				MovieClip(c).useHandCursor = useFinger;
				try {
					MovieClip(c).gotoAndStop		("_up")
				} 
				catch(e) {
				}
			}
			else if (c is Sprite) {
				Sprite(c).useHandCursor 			= useFinger;
			}
		}
		public static function autoButton(c:*, listener:*, actions:String="onPress,onRollOver,onRollOut"):void {
			setupButton(c, listener, c.name.substr(5), actions);
		}
		public static function autoButtons				(a:*, listener:*, actions:String="onPress,onRollOver,onRollOut"):void { // Array or Vector
			for each (var c:InteractiveObject in a)		autoButton(c, listener, actions);
		}
		public static function setupButtons			(a:*, listener:*, post:String="", actions:String="onPress,onRollOver,onRollOut") { // Array or Vector
			for each (var c:InteractiveObject in a)		setupButton(c, listener, post, actions);
		}
		public static function setupChildrenButtons		(c:DisplayObjectContainer, listener:*, post:String=null, actions:String="onPress,onRollOver,onRollOut"):void {
			// Sets up as buttons all clips whose name starts with "_butt". If post is defined, they will have a post event setup, otherwise is automatically taken from name.
			var buttons						:Array = UDisplay.getChildrenNameContains(c, "_butt");
			Debug.debug						(_debugPrefix, "Buttonizing " + buttons.length + " buttons in clip " + c);
			if (post) 							setupButtons(buttons, listener, post, actions);
			else								autoButtons(buttons, listener, actions);
		}
	// REMOVE BUTTONS
		public static function removeButton			(c:InteractiveObject) {
			if (!getItem(c)) 						return;
			setButtonActive						(c, false);
			removeInteraction					(c);
			getItem(c).harakiri					();
			delete							_buttonsItem[c];
		}
			private static function removeInteraction	(c):void { // This only removes all interactions from an object
				c.removeEventListener				(MouseEvent.CLICK, onClick);
				c.removeEventListener				(MouseEvent.MOUSE_DOWN, onPress);
				c.removeEventListener				(MouseEvent.MOUSE_OVER, onRollOver);
				c.removeEventListener				(MouseEvent.MOUSE_OUT, onRollOut);
				if (getItem(c) == _lastInteractedItem) {
					removeOnReleaseListener		();
					_lastInteractedItem			= null;
				}
			}
		public static var removeButtons				:Function = removeButtonList;
		public static function removeButtonList			(l:*) {  // Array or Vector
			for (var i:uint=0; i<l.length; i++)		removeButton(l[i]);
		}
	// TOOLTIP
		public static var setTooltip					:Function = setToolTip;
		public static function setToolTip				(c:InteractiveObject, s:String = null, tOff:String = null):void {
			if (getItem(c)) {
				getItem(c).setTooltip					(s, tOff);
			}
		}
		public static function removeToolTip			(c:*):void {
			if (getItem(c)) {
				getItem(c).setTooltip					(null, null);
			}
		}
		private static function getItem				(c:InteractiveObject):ButtonizerItem {
			return							_buttonsItem[c];
		}
	// GENERAL METHOD
		static public function setGeneralOnClick(clickMethod:Function=null):void { // Sets or remove a general click method that happens at each click
			_onClickGeneralMethod = clickMethod;
		}
// MAKE BUTTONS LIST ///////////////////////////////////////////////////////////////////
		public static function makeList				(a:*, listener:*, post:String="", listId:String=null) {  // Array or Vector // Gets an array and preselected index. -1 to preselect none, true to make buttons deselectable
			// Creates a list of buttons, sets them all with the same listener, and sends an event with the index of the button
			// The list does not pre-select an item, to select it we must use the setSelected(c);
			var c								:InteractiveObject;
			var actions							:String = "onPress,onRollOver,onRollOut";
			var item							:ButtonizerItem;
			var id							:String = listId ? listId : String(Math.random());
			for each (c in a) {
				setupButton					(c, listener, post, actions);
				item							= getItem(c);
				item.addToList					(id);
			}
		}
		public static function setSelected				(c:*, s:Boolean):void {
			var i								:ButtonizerItem = getItem(c);
			if (i)								i.setSelected(s);
		}
// SWITCH /////////////////////////////////////////////////////////////////////////////
		public static function setupSwitch				(c:InteractiveObject, listener:*, post:String="", actions:String=null) {
			setupButton						(c, listener, post, actions);
			setToSwitch						(c, true);
		}
		public static function setupSwitchList			(a:*, listener:*, actions:String=null) {  // Array or Vector // Automatic as before
			for each (var c:InteractiveObject in a) 		setupSwitch(c, listener, c.name.substr(5), actions);
		}
		public static function setToSwitch				(c:InteractiveObject, s:Boolean=true) {
			// Remember, to have toolTip working, on the actions also onRollOver and onRollOut must be activated
			var item							:ButtonizerItem = getItem(c);
			if (item) {
				item.setToSwitch					(s);
			}
			else {
				Debug.error					(_debugPrefix, "Setting to switch " + c + " which is not a button.");
			}
		}
		public static function isSelected			(c:InteractiveObject):Boolean {
			return							getItem(c).selected;
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		public static function getLastEvent			():MouseEvent {
			return							_lastEvent;
		}
		public static function dispatchLastEvent			():void {
			_lastEvent.target.dispatchEvent			(_lastEvent.clone());
		}
		public static function triggerButtonEvent		(c:InteractiveObject, event:String="onPress"):void {
			/* BE CAREFUL USING THIS, IT CAN INTERFERE WITH A LOT OF OTHER THINGS */
			Debug.debug						(_debugPrefix, "External call to trigger button event",c,c.name,event);
			if (c is PippoFlashButton) {
				(c as PippoFlashButton).triggerEvent	(event);
				return;
			}
			var item							:ButtonizerItem = getItem(c);
			if (item)							item.callMethod(event);
		}
// BUTTON EVENTS////////////////////////////////////////////////////////////////////////////
		public static function onClick(e:MouseEvent):void {
			processGeneralEvent();
			processEvent(e);
			if (_lastInteractedItem && _lastInteractedItem.active) {
				_lastInteractedItem.onClick(e);
			}
		}
		public static function onPress(e:MouseEvent):void {
			processGeneralEvent();
			processEvent(e);
			if (_lastInteractedItem && _lastInteractedItem.active) {
				_lastInteractedItem.onPress(e);
			}
			// If button is deacivated inside an onPress event, then this _lastInteractedItem can disappeared before this line is executed.
			if (_lastInteractedItem && _lastInteractedItem.release) activateOnReleaseListener();
		}
			// General event
		private static function processGeneralEvent():void { // Only on press or click, processes a general event that happens at every click
			if (_onClickGeneralMethod) {
				var m:Function = _onClickGeneralMethod; // This has to be nullified before calling it, or if I set it again it might be nullified
				_onClickGeneralMethod = null;
				m();
			}
		}
			// On release shit
			private static function activateOnReleaseListener():void {
				_lastPressedItemWaitingRelease		= _lastInteractedItem;
				UGlobal.stage.addEventListener		(MouseEvent.MOUSE_UP, onStageRelease, false, 1, true);
			}
			private static function removeOnReleaseListener():void {
				if (UGlobal.stage) UGlobal.stage.removeEventListener(MouseEvent.MOUSE_UP, onStageRelease);
				_lastPressedItemWaitingRelease		= null;
			}
			private static function onStageRelease		(e:MouseEvent):void {
				// Here I process the onRelease event ONLY if the last 
// 				_lastInteractedItem.button.stage.removeEventListener(MouseEvent.MOUSE_UP, onStageRelease);
				if (e.target==_lastPressedItemWaitingRelease.button) {
					// Release has happened inside the same button
// 					_lastInteractedItem.onRelease		();
					_lastPressedItemWaitingRelease.onRelease(e);
				}
				else {
					// Release has happened outside the button
					_lastPressedItemWaitingRelease.onReleaseOutside(e);
				}
				// Check if release is pertinent to last interacted button
				removeOnReleaseListener			();
				_lastPressedItemWaitingRelease		= null;			
			}
		public static function onRollOver				(e:MouseEvent) {
			processEvent						(e);
			if (_lastInteractedItem && _lastInteractedItem.active) {
				_lastInteractedItem.onRollOver		(e);
			}
		}
		public static function onRollOut				(e:MouseEvent) {
			processEvent						(e);
			if (_lastInteractedItem && _lastInteractedItem.active) {
				_lastInteractedItem.onRollOut		(e);
			}
		}
		// COMMON METHODS TO ALL LISTENERS ////////////////////////////////////////////////////////////////
			private static function processEvent(e:MouseEvent):void {
				_lastEvent = e;			
				_lastInteractedItem = getItem(e.target as InteractiveObject);
				//if (_lastInteractedItem._stopPropagation) {
					e.stopPropagation();
					e.stopImmediatePropagation();
					e.preventDefault();
				//}
			}
// UTY ///////////////////////////////////////////////////////////////////////////////
		public static function setActive(c:InteractiveObject, a:Boolean) {
			setButtonActive(c, a);
		}
		public static function setButtonActive(c:InteractiveObject, a:Boolean) {
			if (getItem(c)) { 
				setToButton(c, a);
				getItem(c).setActive(a);
			}
		}
		private static function setToButton(c:InteractiveObject, a:Boolean) {
			if (c is Sprite) {
				(c as Sprite).buttonMode = a;
				(c as Sprite).mouseChildren = !a;
			}
			else if (c is DisplayObjectContainer) {
				(c as DisplayObjectContainer).mouseChildren = !a;
			}
		}
		public static function setClickThroughList		(a, through:Boolean=true) { // Gets an ARRAY or an OBJECT
			for each (var c:InteractiveObject in a) setClickThrough(c, through);
		}
		public static function setClickThrough(c:InteractiveObject, through:Boolean=true) {
			c.mouseEnabled = !through;
			if (c is DisplayObjectContainer) {
				(c as DisplayObjectContainer).mouseChildren = !through;
			}
		}
// BUTTON TEXT ///////////////////////////////////////////////////////////////////////////////////////
		public static function setButtonText			(c:*, s:String, isHtml:Boolean=false, reposition:Boolean=true, ...rest):void {
			if (c is PippoFlashButton) {
				c.setToHtml					(isHtml);
				c.setText						(s);
			}
			else if (c.hasOwnProperty("_txt") && c._txt is TextField) {
				c[isHtml ? "htmlText" : "text"].text	= s;
			}
			else {			
				Debug.error					(_debugPrefix, "Can't set button text for",c,"it is probably called by",c.parent);
			}
		}
		public static function getButtonText			(c:*):String {
			if (c is PippoFlashButton) {
				return						c.text;
			}
			else if (c.hasOwnProperty("_txt") && c._txt is TextField) {
				return						c._txt.text;
			}
			else {			
				Debug.error					(_debugPrefix, "Can't get button text from: " + c,c.name);
				return						"ERROR";
			}
		}
		public static function isButton				(c:InteractiveObject):Boolean {
			return							_buttonsItem[c];
		}
	}
}

// HELPER CLASSES ///////////////////////////////////////////////////////////////////////////////////////	 
	import									flash.events.*;
	import									flash.display.*;
	import									flash.geom.*;
	import									com.pippoflash.utils.*;
	// CLASS///////////////////////////////////////////////////////////////////////////////////////
	class ButtonizerItem { // This is a reusable class, memory managed, to store buttons data and references
		// CONSTANTS
		public static const ON_CLICK				:String = "onClick";
		public static const ON_PRESS				:String = "onPress";
		public static const ON_ROLLOVER				:String = "onRollOver";
		public static const ON_ROLLOUT				:String = "onRollOut";
		public static const ON_RELEASE				:String = "onRelease";
		public static const ON_RELEASE_OUTSIDE		:String = "onReleaseOutside";
		public static const ON_SELECT_LIST			:String = "onSelectList";
		public static const ON_TUNNEL				:String = "tunnel"; // Just add this to the initializer events of Buttonizer, and I will tunnel events to underneath children
		// STATIC
		private static var _lists						:Object = {}; // Stores the arrays of buttons associated with list
		private var _button						:InteractiveObject;
		private var _listener						:*; // This can be anything, an object, a class, a Sprite...
		private var _post						:String;
		private var _toolTipOn						:String; // If this is populated, toolitp is setup
		private var _toolTipOff						:String; // If this is populated, tooltip for switch button is setup
		private var _listId						:String; // this is the list id to which the button is associated
		private var _active						:Boolean;
		private var _onRelease					:Boolean;
		private var _switch						:Boolean; // If this is true, this button is a switch
		private var _selected						:Boolean; // If this is true, this button is a switch (or list) and is selected
		private var _list							:Boolean; // This nutton belongs to a list
		private var _listIndex						:uint = 0; // The index positioned in the list array
		private var _isTunnel						:Boolean; // This container has been instructed to tunnel events
		//private var _stopPropagation:Boolean; // New system would stop propagation ONLY if specified
	// FRAMEWORK ///////////////////////////////////////////////////////////////////////////////////////
		public function harakiri					():void { // Destroyes class and frees memory
			// If button is part of a list, remove the button from list, or if is the last button, kill the list
			if (_list) {
				if (_lists[_listId]) {
					if (_lists[_listId].length == 1) 	delete _lists[_listId];
					else {
						UCode.removeArrayItem	(_lists[_listId], this);
					}
				}
			}
			_active = _onRelease = _switch = _selected = _list = _isTunnel = null as Boolean; // Nullify booleans
			_post = _toolTipOn = _toolTipOff = _listId	= null; // nullify strings
			_listIndex							= 0;
			_button							= null;
			_listener							= null;
		}
	// GETTERS ///////////////////////////////////////////////////////////////////////////////////////
		public function get active					():Boolean {
			return							_active;
		}
		public function get release					():Boolean {
			return							_onRelease;
		}
		public function get selected					():Boolean {
			return							_selected;
		}
		public function get button					():InteractiveObject {
			return							_button;
		}
	// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function ButtonizerItem				(c:InteractiveObject, listener:*, post:String):void {
			_button							= c;
			_listener							= listener;
			_post								= post;
			_active							= true;
		}
		public function setOnRelease				(b:Boolean):void {
			_onRelease							= b;
		}
		public function setTunnel					(b:Boolean):void {
			if (_button is DisplayObjectContainer) {
				_isTunnel						= b;
			}
			else {
				Debug.error					(Buttonizer._debugPrefix, "Tunneling cannot be activated on " + _button + " since it is not a DisplayObjectContainer.");
			}
		}
		public function setTooltip					(t:String=null, tOff:String=null):void {
			_toolTipOn							= t;
			_toolTipOff							= tOff;
		}
		public function hasTooltip					():Boolean { // Tooltip is considered active only if tooltipon is defined
			return							Boolean(_toolTipOn);
		}
		public function callMethod					(m:String, e:MouseEvent=null):void {
			// First I check if I am in tunneling mode
			// If I want to FIRE events also, not just tunnel them, I need to move the event call ON TOP OF THIS BLOCK
			// Otherwise, it needs to be in an else statement. Activating tunneled clicks, destroys the Buttonizer last interacted item flow, therefore it can't be called afterwards.
// 			if (Buttonizer._verbose)				Debug.debug(Buttonizer._debugPrefix, "Calling method:",m);
			if (_isTunnel && e) {
				if (Buttonizer._verbose)			Debug.debug(Buttonizer._debugPrefix, "I am tuneling",m,"children of " + _button, _button.name);
				// Dirst I loop through all children that are inside the clip
				var d							:DisplayObject;
				const stagePoint					:Point = new Point(e.stageX, e.stageY);
				const doc						:DisplayObjectContainer = _button as DisplayObjectContainer;	
				const n						:int = doc.numChildren;
				var localPoint					:Point;
				for (var i:uint=0; i<n; i++) { // I loop in all children of the clip
					d						= doc.getChildAt(i);
					//trace("PROVA",d);
					// I am looking for an InteractiveObject that is also Buttonized
					if (d is InteractiveObject && Buttonizer.isButton(d as InteractiveObject)) {
						//trace("E? BOTTONE!!!");
						// I found one, I check now if my mouse event was on top of it
						if (d.hitTestPoint(stagePoint.x, stagePoint.y, true)) {
							// Yes, I am on top of it. I now find local coordinates.
							localPoint			= d.globalToLocal(stagePoint);
							// I create the event, and populate it with local coordinates from the dispatcher
							const ee			:MouseEvent = new MouseEvent(e.type);
							ee.localX			= localPoint.x;
							ee.localY			= localPoint.y;
							// Global coordinates will be set correctly AFTER event is dispatched
							(d as InteractiveObject).dispatchEvent(ee);
						}
					}
				}
				/* Uncomment this to debug stage positions
							var c:Sprite = UDisplay.getSquareSprite(5,5,0x0000ff);
							UGlobal.stage.addChild(c);
							c.x = stagePoint.x;
							c.y = stagePoint.y;
				*/
			}
			else {
				UCode.callMethod					(_listener, m+_post, _button);
			}
		}
		public function setActive					(a:Boolean):void {
			_active							= a;
		}
	// EVENTS
		public function onRollOver					(e:MouseEvent):void {
			callMethod							(ON_ROLLOVER, e);
			if (hasTooltip()) {
				if (_selected) { // Show correct tooltip for switch if selected, or doesn't show tip for list if selected
					// Lists do not show tooltip when button is selected, only switches do
					if (_switch && _toolTipOff)		UGlobal.setToolTip(true, _toolTipOff);
				}
				else {
					UGlobal.setToolTip			(true, _toolTipOn);
				}
				
			}
		}
		public function onRollOut					(e:MouseEvent):void {
			callMethod							(ON_ROLLOUT, e);
			if (hasTooltip())						UGlobal.setToolTip(false);
		}
		public function onPress					(e:MouseEvent):void {
			if (hasTooltip())						UGlobal.setToolTip(false);
			if (_switch) { // Behaviour for switch
				toggleSwitchSelected				();
			}
			else if (_list) {
				selectListItem					();
			}
			callMethod							(ON_PRESS, e);
		}
		public function onRelease					(e:MouseEvent):void {
			callMethod							(ON_RELEASE, e);
		}
		public function onReleaseOutside				(e:MouseEvent):void {
			callMethod							(ON_RELEASE_OUTSIDE, e);
		}
		public function onClick					(e:MouseEvent):void {
			
			callMethod							(ON_CLICK, e);
		}
	// UTY
		private function toggleSwitchSelected			():void {
			setSelected							(!_selected);
		}
		private function selectListItem				():void {
			for each(var c:ButtonizerItem in _lists[_listId]) {
				if (c.selected)					c.setSelected(false);
			}
			setSelected							(true);
			UCode.callMethod					(_listener, ON_SELECT_LIST+_post, _listIndex);
		}
		public function setSelected					(s:Boolean):void {
			// Prevent motion in movieclips
			(_button as Sprite).buttonMode			= !s;
			// Do what it has to do
			if (s) {
// 				if (_button is MovieClip) {
					try {
						(_button as MovieClip).gotoAndStop("_down");
					}
					catch (e:Error) {
					};
// 				}
			}
			else {
// 				if (_button is MovieClip) {
					try {
						(_button as MovieClip).gotoAndStop("_up");
					}
					catch (e:Error) {
					};
// 				}
			}
			_selected							= s;
		}
		public function setToSwitch					(s:Boolean):void {
			// This overrides _list
			if (s) {
				_list							= false;
				_listId						= null;
			}
			_switch							= s;
		}
		public function addToList					(id:String):void {
			_switch							= false;
			_list								= true;
			_listId							= id;
			if (!_lists[id])						_lists[id] = [];
			_listIndex							= _lists[id].length;
			_lists[id].push						(this);
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