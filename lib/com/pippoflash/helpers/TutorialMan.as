/* TutorialMan - Manages tutorials form an XML file, check below for instructions
 * 
 * 		<tutorialBalloons idProviderMethod="MainApp.getTutorialTargetGUIElements" idCloseMethod="MainApp.onCloseTutorialId" useStageClick="true" >
				<wrapper><![CDATA[<font size="20">[TEXT]</font>]]></wrapper><!-- This wraps each baloon text, in order to give a general HTML formatting to everything. HTML tags can be used inside balloons themselves. -->
				<balloon zone="ScreenLobby" id="chatInput"><![CDATA[Type here to chat...]]></balloon>
				<balloon zone="ScreenLobby" id="chatClose"><![CDATA[Close chat to see friends list and available friends...]]></balloon>
				<balloon zone="ScreenLobby" id="chatHeader" action="PluginMan.closeChat"><![CDATA[Here you can see available chats or buddy list...]]></balloon>
				<balloon zone="ScreenLobby" id="inviteFriends" action="PluginMan.setToBuddies"><![CDATA[Click here to invite friends and <font color="#ff0000">win bonus and credits!</font>...]]></balloon>
			</tutorialBalloons>

 * 
 * The main node must be used as parameter. If wrapper node is present, wrapper will wrap all other entries.
 * zone can select between different tutorials.
 * id is required to ask to MainApp (or any other class) position of tooltip, and to tell that tooltip has been closed (in order to remove highlight if any)
 * 
 * 
 * 
 * */

package com.pippoflash.helpers {
	import com.pippoflash.components.PippoFlashButton;
	import com.pippoflash.framework._Application;
	import com.pippoflash.framework._PippoFlashBase; import com.pippoflash.utils.*; import com.pippoflash.components.ToolTipBalloon;
	import com.pippoflash.motion.SpriteSheetAnimator; import com.pippoflash.visual.Effector;
	import flash.display.*; import flash.events.*; import flash.geom.*; import flash.media.*; import flash.net.*; import flash.system.*; import flash.text.*; import flash.utils.*; 
	public dynamic class TutorialMan extends _PippoFlashBase {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// CONSTANTS
		public static const EVT_TUTORIAL_COMPLETE:String = "onTutorialComplete"; // id:String - When tutorial of a certain ID is cmplete
		public static const DEFAULT_SKIP_TUTORIAL_POS:String = "BR"; // TL; TR; BL; BR; - position top left, etc.
		public static const ELAPSED_TUTORIALS_OBJECT_SO_VAR_NAME:String = "TutorialManElapsedZones7"; // This is the name of the object stored in SO to manage internally permanently elapsed tutorials
		public static const MAX_DPI_RELATIVE_FONT_SIZE:int = 50; // If DPI related font size gets higher than this, this will be used
		public static const DEVICE_LINE_THICKNESS:Number = 10; // On device there is no glowing effect. Thickness of line and expansion of rectangle.
		public static const DEVICE_LINE_COLOR:int = 0xff0000; // Color of device line
		public static const DEVICE_LINE_ALPHA:Number = 1; // Alpha of device line
		//public static const BASE_FONT_SIZE_FOR_72DPI:Number = 20; // If progressive DPI enlargement is active, this is how it looks on 72 DPI screens. With increase of DPI, font size is increased too.
		// SYSTEM
		static private var _tutorialMan:TutorialMan;
		private var _elapsedTutorials:Object; // {ZoneName:Boolean} if zone tutorial is elapsed
		private var _cornerRound:Number = 0; // set this with setCornerRound(), if > 0 square corners will be rounded
		private var _progressiveDPIIncrease:Number = 0; // This can be set to minimum size for 72 DPI with activateProgressiveDPI(size:Number). If this is 0 is not used.
		private var _progressiveDPIWrapper:Array = ["", ""]; // This wraps the main text. If DPI is not defined, it just adds "", otherwise it will become an HTML wrapper.
		// REFERENCES
		private var _getIdPositionMethod:Function;
		private var _closeIdMethod:Function;
		private var _highlightClip:Sprite; // contains the graphics that will highlight content
		private var _draw:Graphics; // The drawing layer in _highlightClip
		private var _darkenClip:Sprite;
		private var _darkenDraw:Graphics; // Negative darkening glow for background
		private var _tipPoint:Point;
		private var _buttSkipTutorial:MovieClip; // This can be set externally and if presente will be managed here
		// STAGE INSTANCES
		// MARKERS
		private var _showingNodeNum:int; // Index of node showing
		private var _showingNode:XML;
		private var _useStageClick:Boolean;
		private var _tipInvertY:Boolean; // If pos="BOTTOM" Y is inverted
		private var _clickIsBlocked:Boolean; // Click is blocked because interface is changing or events are executing
		private var _isRunning:Boolean; // If tutorial is running
		private var _isDevice:Boolean = true; // Taken from USystem. If I am on a device instead of glow effect, I will just have a rounded border
		private var _propagateClick:Boolean; // If click on stage needs to be propagated to underneath objects
		// DATA HOLDERS
		private var _tutorialXml:XML;
		private var _tutorialNodes:Object; // Stores tutorial nodes by "zone"
		private var _runningId:String; // The running ID (zone) of tutorial group active
		private var _runningNodes:Array; // Once an ID is selected, this referecnces the group of nodes for that id
		private var _wrapperString:String; // If there is a wrapper string, this is populated
		private var _singleNodeAppendText:String; // This gets text from a special node, that will be added at the end of text, instead of skip tutorial, if there is only one node
		private var _tipText:String; // The main text contained in tip
		private var _tipId:String; // The ID of displayed tip
		private var _tipAreaRect:Rectangle; // Sotres the consolidated are rectangle for that tip
		private var _pauseTime:Number; // Stores the @pause in node, that leaves time to methods to execute
		private var _tutorialSharedObjectVarName:String; // this is defuned in _tutorialXml.@sharedObjectVarName or defaults to ELAPSED_TUTORIALS_OBJECT_SO_VAR_NAME
		// NODE TIMEOUT
		private var _timeoutTimer:Timer; // Timer for timeout of node
		private var _timeoutSeed:Number; // Seed to verify that timeout is correct
		// STATIC UTY
// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		static public function get instance():TutorialMan {
			return _tutorialMan;
		}
// INIT //////////////////////////////////////////////////////////////////////////////////
		public function TutorialMan(tutorial:XML):void {
			super("TutorialMan", TutorialMan);
			_tutorialMan = this;
			_highlightClip = new Sprite();
			_darkenClip = new Sprite();
			Buttonizer.setClickThrough(_highlightClip);
			Buttonizer.setupButton(_darkenClip, this, "NoEvent", "onPress"); // To stop clicks underneath dark area
			//Buttonizer.setClickThrough(_darkenClip);
			//Buttonizer.setupButton(_darkenClip, this, "NoEvent", "onClick");
			//_highlightClip.addEventListener(MouseEvent.CLICK, onHighlightClick, true);
			//_highlightClip.addEventListener(MouseEvent.CLICK, onHighlightClick, false);
			//_highlightClip.addEventListener(MouseEvent.MOUSE_DOWN, onHighlightPress, true);
			//_highlightClip.addEventListener(MouseEvent.MOUSE_DOWN, onHighlightPress, false);
			_draw = _highlightClip.graphics;
			_darkenDraw = _darkenClip.graphics;
			// Setup shared object var name
			_tutorialSharedObjectVarName = String(tutorial.@sharedObjectVarName).length ? String(tutorial.@sharedObjectVarName) : ELAPSED_TUTORIALS_OBJECT_SO_VAR_NAME; // If var name is defined in XML, uses that one, otherwise defaults to internal constant
			// Retrieve permanently stored elapsed tutorials, or create the object if non existing
			_elapsedTutorials = _mainApp.getSharedObject(_tutorialSharedObjectVarName);
			// Check if tutorial run is forced
			//Debug.warning(_debugPrefix, "FREGNAAAAAAAAAA", );
			if (UCode.isTrue(String(tutorial.@forceRun))) {
				_elapsedTutorials = null; // Nullify elapsed tutorials
				(_mainApp as _Application).promptOk("Tutorial is set in forced mode and will always run", "WARNING");
			}
			// Proceed
			if (!_elapsedTutorials) {
				_elapsedTutorials = {};
				_mainApp.setSharedObject(_tutorialSharedObjectVarName, _elapsedTutorials);
			}
			setTutorial(tutorial);
			_isDevice = USystem.isDevice();
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
	// CHEcks
		public function isRunning():Boolean { // If a tutorial is running
			return _isRunning;
		}
	// MANAGE
		// SYSTEM
		public function setSkipTutorialButton(b:MovieClip):void {
			_buttSkipTutorial = b;
			_buttSkipTutorial.addListener(this);
			positionSkipTutorialButton();
		}
		public function setCornerRound(r:Number):void {
			_cornerRound = r;
		}
		public function activateProgressiveDPI(sizeFor72DPI:Number):void { // Sets up progressive font increase from dpi. This amount is shown at 72 and progressively increased.
			_progressiveDPIIncrease = sizeFor72DPI;
			// Calculate size and create wrapper
			var dpi:uint = USystem.getDPI();
			var mult:Number = _progressiveDPIIncrease / 72;
			var dpiComputedSize:int = Math.ceil(mult * dpi);
			if (dpiComputedSize > MAX_DPI_RELATIVE_FONT_SIZE) dpiComputedSize = MAX_DPI_RELATIVE_FONT_SIZE; // Limit to MAX DPI size
			_progressiveDPIWrapper = ["<font size='" + dpiComputedSize+"'>", "</font>"];
			Debug.debug(_debugPrefix, "Activated DPI compliant sizer. Device DPI:" + dpi + ", 72dpi size:"+_progressiveDPIIncrease+", computed size:"+dpiComputedSize);
		}
		// DATA
		public function setTutorial(t:XML):void { // this can overwrite tutorial. Entire tutorial flow.
			_tutorialXml = t;
			prepareTutorial();
		}
		// WORK WITH PERMANENT STORAGE
		public function zoneIsComplete(zone:String):Boolean { // If selected zone has yet been completed
			return Boolean(_elapsedTutorials[zone]);
		}
		public function zoneIsNotComplete(zone:String):Boolean { // If selected zone has NOT yet been completed
			return !zoneIsComplete(zone);
		}
		public function zoneIsNotCompleteAndNotRunning(zone:String):Boolean {
			return _isRunning || !zoneIsComplete(zone);
		}
		public function startIfNotCompleted(zone:String):Boolean {
			if (zoneIsComplete(zone)) { // Check if zone has apready been completed
				Debug.debug(_debugPrefix, "startIfNotCompleted() Zone already completed. Skipping: " + zone);
				return false;
			}
			// Zone is not completed, can be started
			UExec.next(start, zone); // Next frame so I leave time to interface to do whatever before tutorial runs
			return true;
		}
		public function setZoneComplete(zone:String, broadcastTutComplete:Boolean=false):void {
			Debug.debug(_debugPrefix, "Setting zone to complete: " + zone);
			if (_runningId == zone) complete(broadcastTutComplete); // The same zone is running, just complete it.
			else storeZoneComplete(zone, broadcastTutComplete); // zone is not running just add it to complete list
		}		
		// WORK WITH DATA - Below methods work always, and do not consider permanent storage of completed zones
		public function prepare(zone:String):void { // Sets tutorialman to running. ALWAYS. Independent from storage. Only zone id must be set. This is needed since some parts of interface might want TutorialMan running even when tutorial is not yet started.
			Debug.debug(_debugPrefix, "Preparing tutorial for " + zone);
			_isRunning = true;
			_runningNodes = _tutorialNodes[zone];
			_runningId = zone;
		}
		public function start(id:String):void { // Prepares and starts step 0
			prepare(id);  
			Debug.debug(_debugPrefix, "Starting tutorial for " + id);
			showStep(0);
			// Add listener to stage resize events
			UGlobal.addResizeListener(onStageResize);
		}
		public function onTimeout(e:TimerEvent):void { // When timer is ticked
			Debug.debug(_debugPrefix, "Moving to next node on timeout event.");
			next();
		}
		public function next():void { // Next step
			if (_showingNodeNum < (_runningNodes.length - 1)) showStep(_showingNodeNum + 1);
			else {
				complete();
			}
		}
		public function previous():void { // Previous step
			if (_showingNodeNum > 0) showStep(_showingNodeNum - 1);
		}
		public function showStep(n:int):void {
			if (_showingNode) {
				dismissActiveNode();
			}
			_showingNodeNum = n;
			_showingNode = _runningNodes[n];
			// Setup a conditional for running node
			if (String(_showingNode.@conditionals).length) {
				var conditionals = String(_showingNode.@conditionals).split(",");
				//if (conditionals.length) {
				Debug.debug(_debugPrefix, "Tutorial node to be executed only if these conditionals apply: " + conditionals);
				for (_i = 0; _i < conditionals.length; _i++) {
					if (!UCode.convertMethodString(conditionals[_i])()) {
						Debug.debug(_debugPrefix, "Skipping node because conditional returned false: " + conditionals[_i]);
						next();
						return;
					}
				}
				//}
			}
			// No conditionals or conditionals are passed, render node
			renderNode();
		}
		public function complete(broadcastComplete:Boolean=true):void { // Closes the running tutorial
			if (!_isRunning) {
				Debug.error(_debugPrefix, "complete() fail, no tutorial is running.");
				return;
			}
			dismissActiveNode(); // Stop active tutorial node if any
			// Store on SO that tutorial has been elapsed
			// Proceed stopping execution
			UGlobal.setStageShield(false);
			if (_buttSkipTutorial) UDisplay.removeClip(_buttSkipTutorial);
			_isRunning = false;
			Debug.debug(_debugPrefix, "Tutorial is complete: " + _runningId);
			storeZoneComplete(_runningId, broadcastComplete);
			_runningId = null; 
			_showingNode = null;
			// Remove stage resize listener
			UGlobal.removeResizeListener(onStageResize);
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		private function prepareTutorial():void {
			_tutorialNodes = {};
			_runningNodes = null;
			_wrapperString = "";
			_singleNodeAppendText = "";
			_getIdPositionMethod = UCode.convertMethodString(String(_tutorialXml.@idProviderMethod));
			_closeIdMethod = UCode.convertMethodString(String(_tutorialXml.@idCloseMethod));
			_useStageClick = UCode.isTrue(String(_tutorialXml.@useStageClick));
			if (_tutorialXml.wrapper.length()) _wrapperString = String(_tutorialXml.wrapper);
			if (_tutorialXml.singleItemClick.length()) _singleNodeAppendText = String(_tutorialXml.singleItemClick);
			var node:XML; var zone:String;
			for (var i:int = 0; i < _tutorialXml.balloon.length(); i++) {
				node = _tutorialXml.balloon[i];
				zone = String(node.@zone);
				if (!_tutorialNodes[zone]) _tutorialNodes[zone] = [];
				_tutorialNodes[zone].push(node);
			}
		}
		private function renderNode():void {
			Debug.debug(_debugPrefix, "Showing tutorial node " + _showingNode.toXMLString());
			_tipText = _progressiveDPIWrapper[0] + (_wrapperString ? UText.insertParam(_wrapperString, "TEXT", String(_showingNode)) : String(_showingNode)) + _progressiveDPIWrapper[1];
			if (isSingleNode()) _tipText = _tipText + _singleNodeAppendText;
			_tipId = String(_showingNode.@id);
			_tipInvertY = String(_showingNode.@pos).toUpperCase().charAt(0) == "B"; // If it says bottom or BOTTOM or B or b Y is inverted
			_pauseTime = String(_showingNode.@pause).length ? Number(_showingNode.@pause) : 0;
			// Here I have to retrieve my GUI elements
			// checkout for methods, Here I have to set eventually a timeout
			if (String(_showingNode.@actions).length) {
				var actions = String(_showingNode.@actions).split(",");
				Debug.debug(_debugPrefix, "Actions to be executed: " + actions);
				if (actions.length == 1) UCode.convertMethodString(actions[0])();
				else for (_i = 0; _i < actions.length; _i++) UExec.frame(_i + 1, UCode.convertMethodString(actions[_i]));
				if (_pauseTime > 0)	{
					if (_useStageClick) {
						UGlobal.setStageShield(true, onPressStage);
						_clickIsBlocked = true; 
					}
					UExec.time(_pauseTime, createHighlight); // This will also unblock stage click
				}
				else UExec.frame(_i + 1, createHighlight);
			}
			else createHighlight(); // No actions, also no pause
			// Create timer if any
			if (UXml.hasFullAttribute(_showingNode, "timeout")) {
				var secs:int = int(_showingNode.@timeout);
				Debug.debug(_debugPrefix, "Step times out in seconds: " + secs);
				_timeoutTimer = new Timer(secs * 1000, 1);
				_timeoutTimer.addEventListener(TimerEvent.TIMER, onTimeout);
				_timeoutTimer.start();
			}
			// Setup propagation
			_propagateClick = UCode.isTrue(String(_showingNode.@propagate));
			// Clear click from stage and set it to cover in order to leave white space empty
			if (_propagateClick) {
				UGlobal.setStageShield(false);
				Buttonizer.setGeneralOnClick(onPressStage);
				//Buttonizer.setClickThrough(this);
				//Buttonizer.setupButton(UGlobal.stage, this, "Root", "onPress,onClick,tunnel", true);
			}
		}
		private function createHighlight():void {
			if (!_isRunning) return; // This can be called after a complete is issued due to timeouts
			_tipPoint = UGlobal.getCenterPoint(); // I default to screen center if there are no gui elements for that ID
			_tipAreaRect = new Rectangle();
			UGlobal.stage.addChild(_darkenClip);
			UGlobal.stage.addChild(_highlightClip);
			_draw.clear();
			if (_isDevice) _draw.lineStyle(DEVICE_LINE_THICKNESS, DEVICE_LINE_COLOR, DEVICE_LINE_ALPHA, true, "normal"); // If on device, we have a line style
			_draw.beginFill(0xff0000, _isDevice ? 0 : 1); // If on device, fill is transparent
			_darkenDraw.clear();
			_darkenDraw.beginFill(0x000000, 0.8);
			if (!_isDevice) Effector.startGlow(_highlightClip, 0.5, "superKnockout"); // Effect only on desktop
			updateHighlight(); // First update, positioning of tip is forced
		}
		private function updateHighlight():void {
			var guiElements:Array = _getIdPositionMethod(_tipId); // This should return the gui elements I have to highlight
			if (guiElements.length) { // There are gui elements with that ID
				Debug.debug(_debugPrefix, "GUI elements for this node: " + guiElements);
				// Now I have to find the biggest rectangle in order to find the bottom middle point
				var area:Rectangle;// = new Rectangle(UGlobal._sw, UGlobal._sh, 0, 0); // I start with highest for x and y and lowest for width and height
				// I loop in all visual elements and find the larger rectangle that contains all the elements
				var stageRect:Rectangle;
				for each (var e:DisplayObject in guiElements) {
					trace("Working on element: " + e.name);
					stageRect = e.getBounds(UGlobal.stage);
					if (!area) area = stageRect.clone();
					//if (stageRect.x < area.x) area.x = stageRect.x;
					//if (stageRect.y < area.y) area.y = stageRect.y;
					//if (stageRect.width > area.width) area.width = stageRect.width;
					//if (stageRect.height > area.height) area.height = stageRect.height;
					else {
						if (stageRect.left < area.left) area.left = stageRect.left;
						if (stageRect.top < area.top) area.top = stageRect.top;
						if (stageRect.right > area.right) area.right = stageRect.right;
						if (stageRect.bottom > area.bottom) area.bottom = stageRect.bottom;
					}
				}
				_tipAreaRect = area.clone();
				// Draw darkening all screen rect
				_darkenDraw.drawRect(0, 0, UGlobal._sw, UGlobal._sh); // Left side rectangle
				// Draw simple rectangle for highligh, and draw hole in darkening rect
				var _highlightAreaRect:Rectangle = _tipAreaRect.clone();
				if (_isDevice) _highlightAreaRect.inflate(DEVICE_LINE_THICKNESS, DEVICE_LINE_THICKNESS); // If on device I use a line, needs to be expanded in order not to cover content
				if (_cornerRound > 0) { // With rounded corners
					_draw.drawRoundRect(_highlightAreaRect.x, _highlightAreaRect.y, _highlightAreaRect.width, _highlightAreaRect.height, _cornerRound, _cornerRound);
					_darkenDraw.drawRoundRect(_tipAreaRect.x, _tipAreaRect.y, _tipAreaRect.width, _tipAreaRect.height, _cornerRound, _cornerRound);
				}
				else { // Without rounded corners
					_draw.drawRect(_highlightAreaRect.x, _highlightAreaRect.y, _highlightAreaRect.width, _highlightAreaRect.height);
					_darkenDraw.drawRect(_tipAreaRect.x, _tipAreaRect.y, _tipAreaRect.width, _tipAreaRect.height);
				}
				// Now I need to find the better point. Horizontally is always in the middle. Vertically, it can be bottom or top according to lower or higher to centerpoint.
				// Position vertically according to pos (TOP; MIDDLE; BOTTOM)
				var pos:String = String(_showingNode.@pos).charAt(0).toUpperCase();
				if (pos == "M") _tipPoint.y = _tipAreaRect.y + (_tipAreaRect.height / 2); // Middle position
				else if (pos == "B") _tipPoint.y = _tipAreaRect.y + _tipAreaRect.height; // Bottom position - also inverts Y (appears below the element)
				else _tipPoint.y = _tipAreaRect.y; // TOP - default
				//if (_tipPoint.y < UGlobal.getCenterPoint().y) _tipPoint.y = _tipAreaRect.y + _tipAreaRect.height; // Its on top of it, so I use lower side
				_tipPoint.x = _tipAreaRect.x + (_tipAreaRect.width / 2);
			}
			else Debug.warning(_debugPrefix, "No GUI elements returned for ID " + _tipId);
			// Create highlight and tip
			Debug.debug(_debugPrefix, "Area is " + _tipAreaRect + " tip positioned at " + _tipPoint + " with text: " + _tipText);
			UGlobal.setToolTipStatic(_tipText, _tipPoint, _tipId, _tipInvertY); // _getIdPositionMethod(String(_showingNode.@id)));
			// CREATE STAGE CLICK ALWAYS AFTER CREATING HIGHLIUGHT (OR THEY WILL COVER CLICKABLE AREA)	
			if (_useStageClick) {
				UGlobal.setStageShield(true, onPressStage);
				_clickIsBlocked = false;
			}
			// SETUP SKIP TUTORIAL BUTTON
			updateSkipTutorialButton();
		}
		private function updateSkipTutorialButton():void {
			if (!_buttSkipTutorial) return;
			if (isSingleNode()) UDisplay.removeClip(_buttSkipTutorial);
			else {
				UGlobal.stage.addChild(_buttSkipTutorial);
				_buttSkipTutorial.visible = true;
				positionSkipTutorialButton();
			}
		}
		private function positionSkipTutorialButton():void {
			const MARGIN:int = 10;
			if (DEFAULT_SKIP_TUTORIAL_POS.charAt(0) == "B") { // Bottom
				_buttSkipTutorial.y = UGlobal._sh - (_buttSkipTutorial.height + MARGIN);
			}
			if (DEFAULT_SKIP_TUTORIAL_POS.charAt(1) == "R") { // Right
				_buttSkipTutorial.x = UGlobal._sw - (_buttSkipTutorial.width + MARGIN);
			}
		}
		
		private function dismissActiveNode():void {
			if (!_showingNode) return; // This might be called also before an actual node is rendered
			// Remove timer if any
			if (_timeoutTimer) {
				if (_timeoutTimer.running) _timeoutTimer.stop();
				_timeoutTimer.removeEventListener(TimerEvent.TIMER, onTimeout);
				_timeoutTimer = null;
			}
			// Proceed
			_closeIdMethod(String(_showingNode.@id));
			_draw.clear();
			_darkenDraw.clear();
			UGlobal.hideToolTipStatic(_tipId);
			if (!_isDevice) Effector.stopGlow(_highlightClip, 0.01);
			UGlobal.hideToolTipStatic(String(_showingNode.@id));
			UDisplay.removeClips([_highlightClip, _darkenClip]);
			_showingNode = null;
			_showingNodeNum = NaN;
		}
		
		private function storeZoneComplete(zone:String, broadcastComplete:Boolean=true):void {
			_elapsedTutorials[zone] = true;
			_mainApp.setSharedObject(_tutorialSharedObjectVarName, _elapsedTutorials);
			if (broadcastComplete) broadcastEvent(EVT_TUTORIAL_COMPLETE, _runningId);
		}
	// UTY - INTERNAL
		private function isSingleNode():Boolean { // If the zone running has one single node
			return _singleNodeAppendText && _singleNodeAppendText.length && _runningNodes && _runningNodes.length == 1;
		}
		//private function checkForPropagation():void {
			//_propagateClick = true;
			//if (_propagateClick) {
				//// Grab mouse position
				//var e:MouseEvent = new MouseEvent(MouseEvent.MOUSE_DOWN, false, true, UGlobal.stage.mouseX, UGlobal.stage.mouseY); // , UGlobal.stage, false, false, false, true);
				//Debug.debug(_debugPrefix, "Click propagation with event: " + e, UGlobal.root.dispatchEvent(e));
				//var e:MouseEvent = new MouseEvent(MouseEvent.MOUSE_UP, false, true, UGlobal.stage.mouseX, UGlobal.stage.mouseY); // , UGlobal.stage, false, false, false, true);
				//Debug.debug(_debugPrefix, "Click propagation with event: " + e, UGlobal.root.dispatchEvent(e));
				//
			//}
		//}
		
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		private function onPressStage():void {
			if (_clickIsBlocked) {
				Debug.debug(_debugPrefix, "Click is blocked by tutorial executing. Pause is seconds " + _pauseTime);
				return;
			}
			UGlobal.setStageShield(false);
			next();
		}
		//public function onPressRoot(c:DisplayObject = null):void {
			//trace("PRESS");
		//}
		//public function onClickRoot(c:InteractiveObject=null):void {
			//trace("click");
			////onPressStage();
		//}
		//public function onHighlightClick(e:MouseEvent):void {
			//trace("CLICK", e);
			//var e:MouseEvent = new MouseEvent(MouseEvent.CLICK, false, true, UGlobal.stage.mouseX, UGlobal.stage.mouseY);
			//UGlobal.stage.dispatchEvent(e);
		//}
		//private function onHighlightPress(e:MouseEvent):void {
			//trace("PRESS", e);
			//var e:MouseEvent = new MouseEvent(MouseEvent.MOUSE_DOWN, false, true, UGlobal.stage.mouseX, UGlobal.stage.mouseY);
			//UGlobal.stage.dispatchEvent(e);
		//}
		public function onClickDarkBg(c:Sprite):void {
			onPressStage();
		}
		public function onPressSkipTutorial(c:DisplayObject = null) {
			complete();
		}
		private function onStageResize():void {
			if (isRunning()) {
				showStep(_showingNodeNum);
				updateSkipTutorialButton();
			}
		}
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