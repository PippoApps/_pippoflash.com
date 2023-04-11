/* _Prompt - Base class for all Prompts
- allprompts are singleton, therefore they extend the _PippoFlashBase class

Allowed parameters (none is mandatory):
_funcOk		:Function			Function to be called on OK		
_funcCancel	:Function			Function to be called on CANCEL (Where there is a cancel)
_timeout		:uint				Milliseconds after which close the prompt window
_bgColor		:uint				0xff0000 - If I want a bg color
_bgAlpha		:Number			0 to 1, alpha of the bg shield
_blockOthers	:Boolean			Blocks the opening of more prompts.
_closeOthers	:Boolean			Closes all other eventually open prompts



*/

package com.pippoflash.framework.prompt {
	
	import com.pippoflash.framework._Application;
	import com.pippoflash.framework._PippoFlashBase;
	import com.pippoflash.motion.Animator;
	import com.pippoflash.motion.PFMover;
	import com.pippoflash.components.PippoFlashButton;
	import com.pippoflash.utils.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.*;
	import flash.geom.*;
	
	public dynamic class _Prompt extends _PippoFlashBase {
		// STATIC SWITCHES ///////////////////////////////////////////////////////////////////////////////////////
		public static var _verbose:Boolean = false;
		public static var _activateDragger:Boolean = false;
		public static var _fadeType:String = "FADE"; // FADE, INSTANT, SHRINK
		public static var _fadeSpeed:uint = 3;
		public static var _resetCenter:Boolean = true; // If true, everytime a prompt appears, it is set again to the center of the screen. Otherwise, it will be positioned where last prompt was
		public static var _draggerToolTip:String; // If this is defined, dragger has a tooltip
		// public static var _shieldAlpha:Number = 0;
		public static var _addToRoot:Boolean = false; // If this is true, prompts will be added to root, else, they are added to stage (and scaled according to root scaling if any)
		static public var _scaleToStageScaling:Boolean = true; // Scales up or down prompts in relation to ratio between original rect and stage rect
		static public var _setInstantIfDevice:Boolean = true; // If I am running on a device, all prompts do not fade but appear instantly
		static public var _cacheAsBitmapWhenDragging:Boolean = true; // Activate cache as bitmap when dragging starts
		static public var _defaultContainer:DisplayObjectContainer; // If this is set, prompt is added to this
		// STATIC ////////////////////////////////////////////////////////////////////////////////
		protected var _defaultPar:Object = { // I set this NOT as a static, so that each prompt can modify it's default
			// Button text default when nbutton texts are missing
			_buttOk:"OK",
			_buttCancel:"CANCEL",
			// These defaults can be modified using the instance method updateDefault(namr:String, value:*);
			_bgColor:0, 
			_bgAlpha:0, 
			_blockOthers:false,
			_closeOthers:false,
			_popupNode:null, // The XML node which triggered the popup
			_timeout:null,
			_buttonTimeout:null, // An object that adds a timeout to a button text: {button:"_buttOk", timeout:5} - it will show countdown in seconds besides the writing on button
			_promptId:null, // An identifier for the prompt message.
			_mode:null, // override, replace, replaceAll
			_funcOk:null,
			_funcOkParam:null, // Parameters for function OK
			_funcCancel:null,
			_funcCancelParam:null, // Parameters for function OK
			_funcPopup:null, 
			_funcClose:null, // Called as soon as the popup is closed, no matter what. After fade or on instant close. Actually on next frame to allow prompt disappearing.
			_funcGone:null, // Called after prompt is completely gone and on reset functions
			_params:null, // A params object that can be retrieved from functions
			_sounds:null, // Object containing sounds for each action {_soundPopup:""}
			_enlargeOnBoundaries:false, // If true, popup is not just reduced in order to have all boundaries visible, but also enlarged if boundaries are smaller than one stage size
			_promptUnderOthers:false, // If true, this prompt will be added BELOW all others
			_doNotQueue:false, // Queue makes so that if another prompt is called when this is opened, will be queued and launched when this is closed. Set this to true to just discard any other occurrance when prompt is active.
			_blockStage:false // If stage below this prompt should be blocked
		};
		protected static var _prompts:Array = []; // Stores all prompts. The singleton instance of each.
		protected static var _promptsById:Object = {}; // Store prompts by ID only
		protected static var _promptsGroup:Object = {main:[]}; // Stores prompts in groups arrays - "main" is the list when no group is assigned
		protected static var _lastPos:Point; // this stores last dragged position
		protected static var _blockingPrompt:_Prompt; // Reference to the prompt which is blocking
		protected static var _lastOpenedPrompt:_Prompt; // The prompt that was last opened
		protected static var _promptsChain:Vector.<_Prompt> = new Vector.<_Prompt>(); // Stores the sequence of opened prompts (when multiple prompts are opened)
		// STATIC QUEUE MANAGEMENT (if a blocking prompt is active, queues will not work. Subsequent prompts are just discarded.)
		protected static var _queues:Object = {}; // Holds vectors of _Prompt for each prompt name for which queue has been activated
		static protected var _manualQueue:Vector.<Object> = new Vector.<Object>(); // If this is active, overrides single prompt queue. {prompt:_Prompt, par:Object}
		static protected var _manualQueueActive:Boolean = false; // If manual queue has been activated
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// USER SWITCHES DEFAULTS (TO BE SETUP IN EXTENSIONS)
		// QUEUE VARIABLES
		protected var _hasQueue:Boolean = false; // If prompts of this instance should be queued when one is already opened. Defaults to NOT!!!
		protected var _overrideManualQueue:Boolean = false; // If this prompt needs to prompt anyway also if manual queue is active, set this to true.
		// SWITCHES
		protected var _hideInactiveItems:Boolean = false; // If I set this to true in extensions, buttons and elements which are not populated are made invisible
		protected var _centerTextVertically:Boolean = false;
		protected var _buttHtml:Boolean = false; // If use html for button text
		public var _useHtml:Boolean = true; // If use HTML text or normeal text
		// USER VARIABLES
		protected var _par:Object = {}; // All user variables are stored into _par
		protected var _popupNode:XML; // If prompt is triggered by an XML node
		// SYSTEM
		protected var _timeout;								// Stores the setTimeout
		protected var _sideLimits:Rectangle; // Stores the minimum position x,y,w,h  left,top,right,bottom
		protected var _boundariesRectangle:Rectangle; // This stores a rectangle for boundaries. Tries "_boundaries first, then "_bg", the "this".
		// REFERENCES
		protected var _dragger:MovieClip;
		protected var _butts:Array;
		protected var _txts:Array;
		protected var _queue:Array; // Reference to queue for this _Prompt (if _hasQueue is set to true)
		// MARKERS		
		protected var _visible:Boolean = false; // Markes if prompt is active and visible
		protected var _firstOpen:Boolean = true;
		// STATIC UTY
		protected static var _s:String;
		protected static var _a:Array;
		protected static var _c:DisplayObject;
// STATIC INIT (called by _Applicaiton init) ///////////////////////////////////////////////////////////////////////////////////////
		public static function init():void {
			// Called by _Application on initialization
			UDisplay.removeClips(_prompts);
		}
		public static function setPromptDefaultPar(promptId:String, parName:String, value:*):void {
			Debug.warning("_Prompt", "Setting default par",parName,"of prompt",promptId,"to",value);
			const p:_Prompt = _promptsById[promptId];
			if (!p) Debug.error("_Prompt", "Error, prompt not found: " + promptId);
			else p.setDefaultPar(parName, value);
		}
		public function setDefaultPar(parName:String, value:*):void {
			_defaultPar[parName] = value;
		}
// INIT ////////////////////////////////////////////////////////////////////////////////////
		public function _Prompt(id:String="_Prompt", group:String="default") {
			super(id);
			_prompts.push(this);
			_promptsById[id] = this;
			if (!_promptsGroup[group]) _promptsGroup[group] = []; // Creates new group list if not present
			_promptsGroup[group].push(this); // Adds prompt to the groups list
			activateDragger();
			visible = false;
			_visible = false;
			UExec.next(UDisplay.removeClip, this);
		}
			// This is called ONLY the first time prompt is launched
			protected function initializePrompt():void {
				// Setup references
				setupChildren();
				// Device dependant things
				if (_setInstantIfDevice && USystem.isDevice()) {
					_fadeType = "INSTANT";
				}
				// Check for queueing system
				if (_hasQueue) resetQueue(); // Create queue array if this type of popup should be queued
				// Proceed with resizing, positioning, boundaries setup
// 				onResize								();
				// Shielding
				// if (this["_shield"]) this["_shield"].alpha = _shieldAlpha;
			}
					private function setupChildren():void {
						_butts = [];
						_txts = [];
						_a = UDisplay.getChildren(this);
						for each (_c in _a) {
							if (_c.name.indexOf("_butt") == 0) {
								_butts.push(_c);
								// Only buttons which are not already buttons should be buttonized. Buttonizing a PippoFlashButton makes it work, but stops all internal working.
								if (!(_c is PippoFlashButton)) {
									try {
										Buttonizer.autoButton(_c, this);
									}
									catch(e) {
										if (_verbose)		Debug.debug(_debugPrefix, "Cannot setup auto button on:",_c.name);
									}
								}
							}
							if (_c.name.indexOf("_txt") == 0) { // Found a txt
								_txts.push				(_c);
							}
						}
						_a							= null; // Release static var
					}
			protected function activateDragger(forceActivation:Boolean=false, draggerHeight:Number=0):* {
				// This can be set in a static variable or forced calling in instantiation. This requires a _header sprite set inside prompt in order to get measurements.
				if (_activateDragger || forceActivation) {
					var header:DisplayObject = this["_header"];
					if (!header) {
						if (_verbose) Debug.warning(_debugPrefix, "Dragger activation aborted: no DisplayObject named _header.")
						return;
					}
					_dragger = UDisplay.getSquareMovieClip(header.width, draggerHeight ? draggerHeight : header.height, 0x000000);
					_dragger.alpha = 0;
					_dragger.x = header.x;
					_dragger.y = header.y;
					Buttonizer.setupButton(_dragger, this, "Dragger", "onPress,onRelease,onReleaseOutside");
					addChild(_dragger);
				}
			}
	// PLUGIN MANAGEMENT
		protected function get mainApp():* { // This is overridden in _PromptPlugin. So that mainApp in plugin always returns plugin main app.
			// Since this is used mostly in plugin with shared application domain, casting it to _Application would trigger an error in plugin
			return _mainApp as _Application;
		}
// LAUNCH PROMPT ///////////////////////////////////////////////////////////////////////////////////////
		public function prompt(par:Object=null):void {
			// Vediamo un po...
			Debug.debug(_debugPrefix, "Prompting...");
			// check if prompts need to be blocked - this has to happen first! Queue is not implements in this case.
			if (promptsAreBlocked(this)) { // This only wastes and discards prompt
				Debug.warning(_debugPrefix, "My type of prompt is blocked. Aborting prompt.");
				return;
			}
			// Check if manual caching is active. If manual cache is active, ALL prompts are queued just in FIFO
			if (_manualQueueActive) {
				if (!_overrideManualQueue) {
					if (par._doNotQueue) {
						Debug.debug(_debugPrefix, "This prompt should be queued because manual queue is active, but parameter _doNotQueue=true.");
						return;
					}
					_manualQueue.push({prompt:this, par:par}); // Store prompt for future use
					Debug.warning(_debugPrefix, "Manual queue is active. All prompts are blocked and stored. I will be triggered when manual queue gets deactivated. Total stored prompts: " + _manualQueue.length);
					return;
				} else Debug.debug(_debugPrefix, "Manual queue is active. But this prompt has been instructed not to give a shit.");
			}
			// Check if _Prompt is already active and queing system is implemented
			// This is a regular prompt, that if THIS prompt is active, stores the next one
			if (isActive() && _hasQueue) {
				if (par._doNotQueue) {
					Debug.debug(_debugPrefix, "This prompt should be queued because aleady active, but the parameter _doNotQueue=true makes me just discard any other occurrance until prompt is closed.");
					return;
				}
				_queues[_pfId].push(par);
				Debug.debug(_debugPrefix, "This prompt is already active, and queing system is active (_hasQueue = true in extension), therefore I queue this action. This is N."+_queues[_pfId].length+" in queue:" + Debug.object(par));
				return;
			}
			// Control that prompt is initialized
			if (_firstOpen) {
				_firstOpen = false;
				initializePrompt();
			}
			// Setup params with defaults first, then overwritten by prompt params
			_par = UCode.duplicateObject(_defaultPar);
			UCode.setParametersForced(_par, par);
			/* This below shouldn't be needed anymore since all that isa called whn proompt is closed */
			// reset prompt
			// Checkup if we have to close all other prompts
			if (_par._closeOthers) clearAllPrompts();	
			// Check if we have to block the opening of new prompts
			if (_par._blockOthers) _blockingPrompt = this;
			// Prevent wrong function names
			if (_par._okFunc) _par._funcOk = _par._okFunc;
			if (_par._cancelFunc) _par._funcCancel = _par._cancelFunc;
			// Setup default texts
			resetTexts(_par); // Sets texts as from parameters
			// Renders _Prompt content. This has to be used in extensions! This is not triggered if _Prompt is blocked or queued.
			renderPrompt(par);
			// Just restore prompt on top and add to visible chain
			restoreOnTop();
			// Let prompt appear
			fadeIn();
			// Setup invisible timeout for closing
			removeTimeout();
			if (UCode.exists(_par._timeout)) _timeout = setTimeout(fadeOut, _par._timeout);
			// Activate button timeout
			if (_par._buttonTimeout) activateButtonTimeout();
			// Check for default prompt action
			if (_par._funcPopup) _par._funcPopup();
			// Resize prompt
			onResize();
		}
		protected function renderPrompt(par:Object=null):void {
			/* THIS HAS TO BE OVERRIDDEN, IS NOT EXECUTED IF PROPMT IS QUEUED OR BLOCKED */
		}
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public static function clearAllPrompts(group:String=null, clearQueue:Boolean=true):void {
			var p:_Prompt;
			// Close prompts only for one group (and eventually reset queues, BEFORE closing them or they will trigger other queues.
			if (group) {
				for each (p in _promptsGroup[group]) { // loop in each prompt in selected group
					if (clearQueue) p.resetQueue(); // Reset queue for that prompt (only if queue exists)
					p.setOut(); // Close and reset prompt
				}
			}
			// Close all prompts
			else {
				if (clearQueue) resetQueues(); // Reset all queues
				for each (p in _prompts) if (p.isActive()) p.setOut(); // Close all prompts
			}
			_blockingPrompt = null;
		};
		public static function resetQueues():void { // Reset all queues waiting to be triggered
			for each (var p:_Prompt in _prompts) p.resetQueue(); // Close all prompts
		}
		public static function closeLastPrompt():void {
			if (_lastOpenedPrompt) _lastOpenedPrompt.setOut();
		}
		public static function promptsAreBlocked(candidatePrompt:_Prompt):Boolean { // Clears all prompts, removes queues, and clears all blockers
			if (_blockingPrompt) {
				Debug.debug("_Prompt", "I can't trigger " + candidatePrompt._debugPrefix + " because " + _blockingPrompt._debugPrefix + " is set to block other prompts.");
				return true;
			}
			return false; // Nothing is blocking
		}
		public static function getPrompt(id:String):_Prompt {
			return _promptsById[id];
		}
		public static function getDepthBelow():uint { // Returns depth of lowest prompt in order to allow to position stuff under all prompts
			// If there is a visible prompt, return it's position in container clip. Otherwise, next available index in container clip.
			if (_promptsChain.length) return ( _addToRoot ? UGlobal.root : UGlobal.stage).getChildIndex(_promptsChain[0]);
			else return ( _addToRoot ? UGlobal.root : UGlobal.stage).numChildren + 1;
		}
		static public function activateManualCache():void { // This activates a prompt cache, so that they will all be sent once cache is removed
			Debug.debug("_Prompt", "Manual cache ACTIVE.");
			_manualQueueActive = true;
		}
		static public function removeManualCache(deleteCachedPrompts:Boolean=false):void { // This removes block, and triggers all cached prompts
			_manualQueueActive = false; // Switch off manual cache
			// Trigger prompt if any. Check first that prompt is not already in visible list. Closing that prompt will eventually launch this queue again
			if (_manualQueue.length && _promptsChain.indexOf(_manualQueue[_manualQueue.length - 1].prompt) == -1)	{
				Debug.debug("_Prompt", "Manual cache DEACTIVATED. Triggering first prompt in queue. total prompts in queue: " + _manualQueue.length);
				var queuedPromptObj:Object = _manualQueue.shift(); // this is the stored object: {prompt:_Prompt, par:Object}
				queuedPromptObj.prompt.prompt(queuedPromptObj.par); // Prompt stored prompt
			}
			else Debug.debug("_Prompt", "Manual cache DEACTIVATED. No prompts in queue, or queued prompt is already visible (therefore cannot be launched).");
		}
		static public function hasManualCache():Boolean {
			return _manualQueueActive;
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function restoreOnTop():void {
			// Called when prompt is launched or...
			// Called when from BELOW another prompt. The other prompt is closed, and I am restored again as top prompt.
			// Block stage if necessary befor adding prompt window. Only if it has to be blocke dI call block, but do not remove it if it was already there
			if (_par._blockStage) blockStage(true); // Stage might be already blocked by another popup below, so in case I just leave it
			// Setup variable that tells me if I have to do anything special to prompt UNDER other prompts (I must be instructed to do so, and there must be other prompts opened)
			var addOnBottomOfOthers:Boolean = _par._promptUnderOthers && _promptsChain.length; // I must be below, and there are other prompts open
			var parentContainer:DisplayObjectContainer = _addToRoot ? UGlobal.root : UGlobal.stage; // Find parent container
			if (_defaultContainer) parentContainer = _defaultContainer;
			// Adds prompt to sequence of prompts - check if it was already in the list and remove last occurrance
			if (_promptsChain.indexOf(this) != -1) {
				// I am prompted again, but I was already in the list of visible prompts
				_promptsChain.removeAt(_promptsChain.indexOf(this));
			}
			// Add to stage to activate stage on initialization
			if (addOnBottomOfOthers) { // Add below others
				// Add at position 0
				_promptsChain.unshift(this);
				// re-add all prompt stack
				for (var j:int = 0; j < _promptsChain.length; j++) {
					parentContainer.addChild(_promptsChain[j]);
				}
				
				
				
				//Debug.debug(_debugPrefix, "Adding prompt BELOW other opened prompts.");
				//trace("fregna chain: " + _promptsChain);
				//var index:int =  parentContainer.getChildIndex(_promptsChain[0]);
				//if (index > 0) index--;
				//trace("index is " + index);
				////trace(parentContainer.getChildIndex(_promptsChain[0]));
				//for (var i:int = 0; i < _promptsChain.length; i++) 
				//{
					//trace("prompt " + i + " : " + _promptsChain[i] + " : " + parentContainer.getChildIndex(_promptsChain[i]));
				//}
				//parentContainer.addChildAt(this, index); // Add below others, steal place to lowest prompt
				//trace("new index of other popup " + parentContainer.getChildIndex(_promptsChain[0]));
			}
			// Just add on top 
			else {
				parentContainer.addChild(this); // Add in top of others
				_promptsChain.push(this);
				// Set this as last opened prompt - ONLY IF IT OPENS ON TOP! Otherwise the last opened popup is still the first...
				_lastOpenedPrompt = this;
			}
			// Adds prompt to sequence of prompts - add to visible sequence. If it goes below is added on the bottom, toehrwise on top
			//if (addOnBottomOfOthers) _promptsChain.unshift(this);
			//else _promptsChain.push(this);
		}
		//public function restoreOnBottom():void { // This opens this prompt on the BOTTOM of prompt chain.
			//// Uses the same prompt logic, but instead of opening prompt on top, it resotres me in the bottom
		//}
		public function close								():void {
			onPressClose								();
		}
		public function updateDefault						(defName:String, value:*):void {
			_defaultPar[defName]							= value;
		}
// FADE //////////////////////////////////////////////////////////////////////////////////////
		public function fadeIn(e=null):void {
			if (_visible) return; // do not trigger visible on if its already visible
			setIn();
			this["fadeIn_"+_fadeType]();
		}
			private function fadeIn_FADE():void {
				alpha = 0;
				Animator.fadeInTotal(this, _fadeSpeed);
			}
			private function fadeIn_INSTANT():void {
				setIn();
			}
			private function fadeIn_SHRINK():void {
				scaleX = scaleY = 0;
				PFMover.slideIn(this, {steps:5, pow:2, endPos:{scaleX:1, scaleY:1}, onComplete:setIn});
			}
		public function fadeOut(e=null):void {
			if (!_visible) return; // do not trigger visible off if its already invisible
			_visible = false;
			this["fadeOut_"+_fadeType]();
		}
			private function fadeOut_FADE():void {
				PFMover.fadeOutAndInvisible(this, _fadeSpeed, resetFunctions);
				//Animator.fadeOutAndInvisible(this, _fadeSpeed, resetfunctions);
				launchFunctionWithParams(_par._funcClose, _par._funcCloseParam, "CLOSE PROMPT");
				//resetFunctions();
			}
			private function fadeOut_INSTANT():void {
				setOut();
			}
			private function fadeOut_SHRINK():void {
				PFMover.slideIn(this, {steps:5, pow:2, endPos:{scaleX:0, scaleY:0}, onComplete:resetFunctions});
				launchFunctionWithParams(_par._funcClose, _par._funcCloseParam, "CLOSE PROMPT");
				//resetFunctions();
			}
// SHOW/HIDE ///////////////////////////////////////////////////////////////////////////////////////
		public function setOut():void {
			_visible = visible = false;
			launchFunctionWithParams(_par._funcClose, _par._funcCloseParam, "CLOSE PROMPT");
			resetFunctions();
		}
		public function setIn								():void {
			alpha										= 1;
// 			scaleX = scaleY								= 1;
			_visible = visible								= true;
		}
// BLOCK CLICKS BELOW ///////////////////////////////////////////////////////////////////////////////////////
		public function blockStage(b:Boolean=true, stageMethod:Function=null):void {
			UGlobal.setStageShield(b, stageMethod);
		}
// CHECKS ///////////////////////////////////////////////////////////////////////////////////////
		public function isActive							():Boolean {
			return									_visible;
		}
		public function hasQueue():Boolean { // If there are other prompts in queue. NOT IF QUEING SYSTEM IS ACTIVE.
			return _hasQueue && _queue.length;
		}
// QUEUES ///////////////////////////////////////////////////////////////////////////////////////
		public function resetQueue():void { // Clears queue of this prompt only
			if (_hasQueue) {
				for each (var o:Object in _queue) UCode.disposeObject(o); // Nullify all parameters for queued prompts (if any)
				_queue = _queues[_pfId] = []; // Create new queue
			}
		}
		public function launchNextInQueue():void {
			if (_hasQueue && _queue.length) {
				var par:Object = _queue.shift(); // Grabs the first object in queue
				Debug.debug(_debugPrefix, "Launching queued prompt. Left in queue: " + _queue.length);
				prompt(par);
			}
			else {
				Debug.error(_debugPrefix, "launchNextInQueue() fail: _hasQueue="+_hasQueue+", _queue.length="+_queue.length);
			}
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		public function resetTexts							(p:Object=null):void {
			// First make everything invisible
			if (_hideInactiveItems) {
				for each (_c in _txts) _c.visible = false;
				for each (_c in _butts) _c.visible = false;
			}
			// Look for possible button namesin PAR
			if (!p)									p = _par;
			var textProp								:String = _useHtml ? "htmlText" : "text";
			var txtMethod								:Function = _useHtml ? UText.setHtmlTextDynamicSize : UText.setTextDynamicSize;
			trace(Debug.object(p));
			for (_s in p) {
				// Extension classes must be set as dynamic or will trigger an error here
				// trace("ECCO: " + _s);
				if (this[_s]) { // If there is an instance of something with the same name of parameter
				// trace(_s)
					if (_s.indexOf("_butt") == 0 && p[_s]) {
						trace("Cerco i bottoni " + _s, this[_s], p[_s])
						const b:InteractiveObject = this[_s];
						if (b is PippoFlashButton) (b as PippoFlashButton).setText(p[_s]);
						else {
							Buttonizer.setButtonText			(this[_s], p[_s], _buttHtml);
							this[_s].visible					= true;
						}
					}
					else if (_s.indexOf("_txt") == 0 && p[_s]) {
						// Use UText framework to enter text
						txtMethod						(this[_s], p[_s]);
						// this[_s][textProp] 				= p[_s];
						this[_s].visible					= true;
					}
				}
			}
			// Setup main text and center it vertically
			if (_centerTextVertically && p._txt && this["_txt"]) {
				UText.centerTextVertically					(this["_txt"], p._txt, _useHtml);
			}
		}
// BUTTON TIMEOUT ///////////////////////////////////////////////////////////////////////////////////////
		private function activateButtonTimeout					():void {
			// This expects that in _par._buttonTimeout there is an object: {button:"_buttOk", timeout:5}
			var error									:String;
			if (!this[_par._buttonTimeout.button]) 				error = "Cannot find button with name: " + _par._buttonTimeout.button;
			if (error) {
				Debug.error							(_debugPrefix, "Button timeout: " + error + " : " + Debug.object(_par._buttonTimeout));
				return;
			}
			// Proceed without errors
			_par._buttonTimeout.clip						= this[_par._buttonTimeout.button];
			_par._buttonTimeout.countdown					= _par._buttonTimeout.timeout;
			_par._buttonTimeout.txt						= _par[_par._buttonTimeout.button] ? _par[_par._buttonTimeout.button] : Buttonizer.getButtonText(_par._buttonTimeout.clip);
			renderButtonTimeoutStep						();
		}
			private function renderButtonTimeoutStep			():void {
				if (!_visible)							return;
				Buttonizer.setButtonText					(_par._buttonTimeout.clip, _par._buttonTimeout.txt + " (" + _par._buttonTimeout.countdown + ")");
				if (_par._buttonTimeout.countdown)			UExec.time(1, renderButtonTimeoutStep);
				else {
					Debug.debug						(_debugPrefix, "Triggering timeout for " + Debug.object(_par._buttonTimeout));
					Buttonizer.triggerButtonEvent			(_par._buttonTimeout.clip, "onPress");
					return;
				}
				_par._buttonTimeout.countdown --;
			}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		// This gets called whenever _Prompot expires. This is what hapopens on each prompt removal.
		private function resetFunctions(animParam:_Prompt=null):void { // Param is only needed because this can be launched at the end of a fade process
			// This is the closure method for prompt
			if (_par._buttonTimeout) { // Reset text for button timeout, or it will interfere with default text at next prompt
				if (_par._buttonTimeout.clip) Buttonizer.setButtonText(_par._buttonTimeout.clip, _par._buttonTimeout.txt);
			}
			if (_blockingPrompt == this) _blockingPrompt = null; // Reset blocking prompt if I am closing ME
			_lastOpenedPrompt = null; // Reset last opened prompt
			// Intercept _Prompt position in visibility chain and remove me. They are all singletons, so it has to be me.
			if (_promptsChain.length && _promptsChain.indexOf(this) != -1) _promptsChain.removeAt(_promptsChain.indexOf(this));
			// Unblock stage if it was blocked
			if (_par._blockStage) blockStage(false); 
			// Check for _promptGone method and trigger it on next frame
			if (_par._funcGone is Function) {
				Debug.debug(_debugPrefix, "Triggering method for Prompt disappered.");
				var f:Function = _par._funcGone; // This is because params object will be nullified
				UExec.next(f);
			}
			// Safe disposal for GC - nullify par and contents
			UCode.disposeObject(_par); 
			_par = null;
			// Check for manual queue, BUT, do not trigger if the same prompt is set in visibility list (triggering it would destroy previously visible prompt)
			if (_manualQueue.length && _promptsChain.indexOf(_manualQueue[_manualQueue.length - 1].prompt) == -1) { // There is one prompt in manual queue, and prompt is NOT already visible
				if (_manualQueueActive) return; // Manual queue is still active, doesnt make sense to trigger other prompts
				var queuedPromptObj:Object = _manualQueue.shift(); // this is the stored object: {prompt:_Prompt, par:Object}
				queuedPromptObj.prompt.prompt(queuedPromptObj.par); // Prompt stored prompt
				return;
			}
			// Check for queue, and if so launch queued item, or restore previous popup
			else if (hasQueue()) launchNextInQueue();
			// No queued prompt, just launch
			else if (_promptsChain.length) _promptsChain[_promptsChain.length-1].restoreOnTop(); // There is another prompt, I leave everything to it
		}
		protected function removeTimeout():void {
			if (UCode.exists(_timeout)) clearTimeout(_timeout); // Remove timeout on new action
		}
// SIZE & POSITION UTY & LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public function onResize							(firstResize:Boolean=false):void {
			// This gets resized also when not visible
			if (!_visible || !Boolean(parent))				return; // Popup is not visible and is not added to stage anywhere
			Debug.debug								(_debugPrefix, "Resizing popup: ", this);
			// Update limits rectangle
			// I can't resize and center properly if clip is not added to 
			// Reposition accordingly (re-center, or within limits)
			// Recenter
			positionPrompt								();
// 			if (_resetCenter) { // If popup has to be always centered
// 				if (_addToRoot) { // If popup is in root
// 					UDisplay.centerOnRoot				(this);
// 				}
// 				else { // Popup is on stage
// 					UDisplay.centerOnStage				(this);
// 					// This means that they apply the same scaling as root, in order to keep consistency with scaling (since they are added to stage)
// 					if (_scaleOnStage)					scaleX = scaleY = UGlobal.getResizeScale();
// 				}
// 			}
// 			else {
// 				if (!_lastPos)							_lastPos = UGlobal.getCenterPoint();
// 				UDisplay.positionToPoint					(this, _lastPos);
// 				checkForSideLimits						();
// 			}
			// Update for device
			if (USystem.isAir()) { // Always use isAir, since the behaviour for devices needs to be emulated also in air on desktop
				scaleX = scaleY = _mainApp._uAir.getOptimalScale();
			}
			// Proceed with resizing check
			resizeToBoundaries						();
			// Update shield
			if (this["_shield"]) {
				this["_shield"].update					();
				this["_shield"].alpha					= _par._bgAlpha;
			}
		}
			private function positionPrompt					():void {
				// Re-center before checking boundaries
				if (_resetCenter)							UDisplay.centerToStage(this);
			}
			private function updateBoundaries():void { // Grab boundaries according to stage
				// Find correct boundaries
				if (this["_boundaries"]) {
					var b:DisplayObject = this["_boundaries"];
					addChild(b);
					_boundariesRectangle = b.getRect(stage);
					removeChild(b);
				}
				else if (this["_bg"]) _boundariesRectangle = this["_bg"].getRect(stage);
				else _boundariesRectangle = this.getRect(stage);
				// Find dragging limits (if dragger is active)
				if (_dragger) {
					_localPoint							= new Point(this["_header"].x, this["_header"].y);
					var dragger						:Rectangle = _dragger.getRect(stage);
					_sideLimits							= new Rectangle();
					_sideLimits.x						= dragger.x - _boundariesRectangle.x;
					_sideLimits.width						= UGlobal._sw - (_boundariesRectangle.width);
					_sideLimits.y						= dragger.y - _boundariesRectangle.y;
					_sideLimits.height					= UGlobal._sh - (_boundariesRectangle.height);
				}
			}
			private function resizeToBoundaries				():void {
				updateBoundaries(); // Updates boundaries accordborn in october 198ing to stage
				// Resize checking both sides 
				// I do not need to check scaleX since boundaries are updated according to stage bounds
				if (_par._enlargeOnBoundaries) { // Popup needs to be enlarged if smaller than stage
					// This means popup will ALWAYS occupy all space available according to boundaries
					// Be careful, this can make popups VERY LARGE
					if (_boundariesRectangle.width < UGlobal._sw && _boundariesRectangle.height < UGlobal._sh) {
						// Yes, popup is smaller than stage, therefore I just enlarge it and interrupt function
						scaleX *= UGlobal._sw / _boundariesRectangle.width;
						scaleY = scaleX;
						// If vertically is now larger, I apply to vertical sizing
						if (_boundariesRectangle.height > UGlobal._sh) {
							scaleY *= UGlobal._sh / _boundariesRectangle.height;
							scaleX = scaleY;
						}
						return; // Popup is enlarged, no need to check if it has to be shrunk
					}
				}
				else if (_scaleToStageScaling) { // This scales popup according to original scale
					scaleX = scaleY = UGlobal.getContentScale();
					updateBoundaries(); // This is neded again in order to perform following checks after resizing
				}
				// After enlargement is done, I still check if boundaries are out of view
				if (_boundariesRectangle.width > UGlobal._sw) {
					scaleX *= UGlobal._sw / _boundariesRectangle.width;
					scaleY = scaleX;
				}
				if (_boundariesRectangle.height > UGlobal._sh) {
					scaleY *= UGlobal._sh / _boundariesRectangle.height;
					scaleX = scaleY;
				}
			}
			private function checkForSideLimits(e:Event=null):void { // This checks that position is not outside limits, and repositions accordingly
				if (x < _sideLimits.x) x = _sideLimits.x;
				else if (x >_sideLimits.width) x = _sideLimits.width;
				if (y < _sideLimits.y) y = _sideLimits.y;
				else if (y >_sideLimits.height) y = _sideLimits.height;
				_lastPos = new Point(x, y);
			}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onPressCancel(c:DisplayObject=null):void {
			launchFunctionWithParams(_par._funcCancel, _par._funcCancelParam, "CANCEL");
			fadeOut();
		}
		public function onPressOk(c:DisplayObject=null):void {
			launchFunctionWithParams(_par._funcOk, _par._funcOkParam, "OK");
			fadeOut();
		}
		public function onPressClose(c:DisplayObject=null):void {
			fadeOut();
		}
		// This is for EVERY button that presses a generic function, button postfix is Generic, seand PAR as only parameter so that I can add whatever  
		public function onPressGeneric						(c:MovieClip):void {
			var id									:String = c.name.substr(5); // Whatever after "_butt"
			launchFunctionWithParams						(_par["_func"+id], null, id);
			onPressClose								();
		}
				private function launchFunctionWithParams(func:Function=null, par:*=null, id:String="NO ID"):void {
					if (func == null) return;
					// Tries to launch the function with _par, otherwise launches it with nothing
					// Here function needs to be called next frame BUT I need to construct an unnamed function in order to try both next frame
					function __executeFunctionWithOrWithoutParams() {
						try {
							var p:Object = par ? par : _par;
							if (func.length) {
								Debug.debug(_debugPrefix, "Launching function " + id + " with param " + (p == par ? Debug.object(p) : "[default _par Object]"));
								func(p);
							}
							else {
								func();
							}
						}
						catch (e:Error) {
							Debug.debugError(_debugPrefix, e, "Lunaching function " + id + " from prompt " + this);
						}
					}
					UExec.next(__executeFunctionWithOrWithoutParams);
					//try {
						//var p:Object = par ? par : _par;
						//if (func.length) {
							//Debug.debug(_debugPrefix, "Launching function " + id + " with param " + (p == par ? Debug.object(p) : "[default _par Object]"));
							//func(p);
						//}
						//else {
							//func();
						//}
					//}
					//catch (e:Error) {
						//Debug.debugError(_debugPrefix, e, "Lunaching function " + id + " from prompt " + this);
					//}
				}
	//  DRAGGING
		private var _localPoint:Point; // Created on dragging initialization, stores position of dragger object (same as header)
		private var _globalPoint:Point; // Local point converted to global point
		private var _offsetPoint:Point; // Difference between prompt position and dragger position
		private static const DRAGGING_MULTIPLIER:Number = 0.2; // Speed multiplier
		public function onPressDragger(c:MovieClip=null) {
			onRollOutDragger(); // this is for tooltip
			// Reposition dragger on stage and create points
			updateBoundaries();
			_globalPoint = localToGlobal(_localPoint);
			_dragger.scaleX = _dragger.scaleY = scaleX;
			parent.addChild(_dragger);
			_dragger.alpha = 0;
			UDisplay.positionToPoint(_dragger, _globalPoint);
			var globalCenter = this.localToGlobal(new Point(0, 0));
			_offsetPoint = new Point(globalCenter.x-_globalPoint.x, globalCenter.y-_globalPoint.y);
			// Reposition boundaries
// 			addChildAt									(this["_boundaries"], 0);
// 			this["_boundaries"].alpha 						= 0.5;
			// Initiate dragging and enter frame actions
			_dragger.startDrag(false, _sideLimits);
			UExec.addEnterFrameListener(processDraggingEnterFrame);
			// Activate caching
			if (_cacheAsBitmapWhenDragging) UDisplay.cacheAsBitmapMatrix(this, true);
		}
		public function onReleaseDragger(c:MovieClip=null) {
			// Stop dragging dragger, and reclaim it inside prompt
			_dragger.stopDrag();
			addChild(_dragger); // I take it back here
			_dragger.scaleX = _dragger.scaleY = 1;
			UDisplay.positionToPoint(_dragger, _localPoint);
			// Remove freme event and update shield
			UExec.removeEnterFrameListener(processDraggingEnterFrame);
			if (this["_shield"]) UCode.callMethod(this["_shield"], "update");
			if (_cacheAsBitmapWhenDragging) UDisplay.cacheAsBitmapMatrix(this, false);
		}
				private function processDraggingEnterFrame(e:Event=null):void {
					x += ((_dragger.x + _offsetPoint.x)-x)*DRAGGING_MULTIPLIER;
					y += ((_dragger.y + _offsetPoint.y)-y)*DRAGGING_MULTIPLIER;
				}
		public function onReleaseOutsideDragger(c:MovieClip=null):void {
			onReleaseDragger();
		}
		public function onRollOverDragger(c:MovieClip=null) {
			if (_draggerToolTip) UGlobal.setToolTip(true, _draggerToolTip);
		}
		public function onRollOutDragger(c:MovieClip=null) {
			if (_draggerToolTip) UGlobal.setToolTip(false);
		}
	}
	
	
	
}