/* - PFMover with TweenNano  - NEW EITH BlitMask
Any of the following special properties can optionally be passed in through the vars object (the third parameter):

	delay 			: Number Amount of delay in seconds (or frames for frames-based tweens) before the tween should begin.
	useFrames 		: Boolean If useFrames is set to true, the tweens's timing mode will be based on frames. Otherwise, it will be based on seconds/time.
	ease 			: Function Use any standard easing equation to control the rate of change. For example, Elastic.easeOut. The Default is Regular.easeOut.
	onUpdate 			: Function A function that should be called every time the tween's time/position is updated (on every frame while the timeline is active)
	onUpdateParams 	: Array An Array of parameters to pass the onUpdate function
	onComplete 		: Function A function that should be called when the tween has finished
	onCompleteParams 	: Array An Array of parameters to pass the onComplete function.
	scaleAll			: Converts into scaleX and scaleY
	immediateRender 	: Boolean Normally when you create a from() tween, it renders the starting state immediately even if you define a delay which in typical "animate in" scenarios is very desirable, but if you prefer to override this behavior and have the from() tween render only after any delay has elapsed, set immediateRender to false.
	overwrite 			: Boolean Controls how other tweens of the same object are handled when this tween is created. Here are the options:
				false (NONE): No tweens are overwritten. This is the fastest mode, but you need to be careful not to create any tweens with overlapping properties of the same object that run at the same time, otherwise they'll conflict with each other. 
				true (ALL_IMMEDIATE): This is the default mode in TweenNano. All tweens of the same target are completely overwritten immediately when the tween is created, regardless of whether or not any of the properties overlap. 
Back
Bounce
Circ
Cubic
CustomEase
EaseLookup
Elastic
Expo
FastEase
Linear
Quad
Quart
Quint
RoughEase
Sine
SteppedEase
Strong

easeIn
easeInOut
easeOut



http://www.greensock.com/as/docs/tween/
	
	
	
*/
// emd: KILL, DESTROY, STOREREMOVE, STORE, 
// move(c:*, time:Number, vars:Object, ease:String="Strong.easeOut", emd:String=null, dir:String="to")
// Easing equations: http://www.greensock.com/as/docs/tween/com/greensock/easing/package-detail.html
// All work with: easeIn, easeOut, easeInOut
//  	Bounce	 
//  	Circ	 
//  	Cubic	 
//  	Elastic	 
//  	Expo	 
//  	Linear	 
//  	Quad	 
//  	Quart	 
//  	Quint	 
//  	Sine	 
//  	Strong



package com.pippoflash.motion {
	import flash.events.*; import flash.utils.*; // system
	import com.pippoflash.utils.*; // PippoFlash
	import com.greensock.TweenNano; import com.greensock.easing.*; import com.greensock.BlitMask; // Greensock
	import flash.display.DisplayObject;
	import com.adobe.protocols.dict.Database;
	public class PFMover {
	// CONSTANTS
		private static const VERBOSE:Boolean = false;
		private static const DEFAULT_EASE:String = "Quart.easeOut";
		private static const DEFAULT_SLIDE_STEPS:uint = 6;
		private static const OBJECT_INITIAL_PROPERTIES:Vector.<String> = new <String>["x", "y", "alpha", "scaleX", "scaleY"];
	// STATIC VARS
		private static var _internalMover:PFMover;	
		private static var _allMotions:Dictionary = new Dictionary(); // Motions are stored centrally. An object motion is ALWAYS overwritten
		private static var _allMovers:Vector.<PFMover> = new Vector.<PFMover>();
// 		private static var _endMotionDirectives					:Dictionary = new Dictionary(); // This can store special directives for end motions
	// INSTANCE
		public var _verbose:Boolean;
		private var _debugPrefix:String = "PFMover";
		private var _motions:Dictionary = new Dictionary(true);
		private var _motionsParams:Dictionary = new Dictionary(true);
		private var _blitMasks:Dictionary = new Dictionary(true);
		private var _defaultEase:String;
		private var _allTweenNano:Vector.<TweenNano> = new Vector.<TweenNano>();
		private const _displayObjectInitialProperties:Dictionary = new Dictionary(false); // Stores the initial properties of an object (position and scale);
		// UTY
		private var _tw:TweenNano; // Acts as a temporary reference
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		static public function init():void { // Called only once by UGlobal
			// Debug.debug("PFMover", "Initialized");
			_internalMover = new PFMover("Static");
		}
		static public function stopStaticMotions():void {
			// Stop motions assigned with static methods only
			_internalMover.stopMotions();
		}
		static public function stopStaticMotion(c:*):void {
			// Stop motions assigned with static methods only
			_internalMover.stopMotion(c);
		}
		static public function stopAllMotions():void {
			// Stop all motions, static, and in all new instances of PFMover
			for each (var m:PFMover in _allMovers) m.stopMotions();
		}
		static public function isMoving(c:*):Boolean {
			return Boolean(_allMotions[c]);
		}
		static public function getMover():PFMover {
			return _internalMover;
		}
// STATIC UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function processEndMotionDirective(c:*, s:String):void {
			if (_verbose) Debug.debug("PFMover", "Processing",s,"for",c);
			this["emd_"+s](c);
		}
				private function emd_KILL(c:*):void {
					if (c is DisplayObject) UDisplay.removeClip(c);
					else c.removeFromParent(); // this is for starling display object
				}
				private var emd_REMOVE:Function = emd_KILL;
				private function emd_DESTROY(c:*):void {
					UMem.killClip(c);
				}
				private function emd_INV(c:*):void {
					c.visible = false;
				}
				private function emd_STORE(c:*):void {
					UMem.storeInstance(c);
				}
				private function emd_STOREREMOVE(c:*):void {
					UMem.storeAndRemove(c);
				}
				private function emd_NONE(c:*):void { // Can be used to overwrite
				}
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function PFMover(id:String=null, defaultEase:String=null):void {
			_debugPrefix += " " + (id ? id : UText.getRandomString(3));
			_defaultEase = defaultEase ? defaultEase : DEFAULT_EASE;
			Debug.debug(_debugPrefix, "2.0 Instantiated... ");
			_allMovers.push(this);
			_verbose = VERBOSE;
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
	// OBJECTS SETUP AND AUTOMATED PROPERTIES - Methods with auto are related to the stored initial properties
		public function storeObjectInitialProperties(c:*, remove:Boolean=false, transparent:Boolean=false):void {
			var props:Object = {};
			for each(var p:String in OBJECT_INITIAL_PROPERTIES){
				props[p] = c[p];
				_displayObjectInitialProperties[c] = props;
			}
			if (_verbose) Debug.debug(_debugPrefix, "Storing initial props for " + c + Debug.object(props));
			if (transparent) c.alpha = 0;
			if (remove) UDisplay.removeClip(c);
		}
		public function restoreInitialProperties(c:*):void {
			var props:Object = _displayObjectInitialProperties[c];
			if (_verbose) Debug.debug(_debugPrefix, "Restoring instantly initial props for " + c + Debug.object(props));
			for each(var p:String in OBJECT_INITIAL_PROPERTIES){
				c[p] = props[p];
			}
		}
		public function getInitialProperty(c:*, prop:String):Number {
			if (_verbose) Debug.debug(_debugPrefix, "Retriveing property " + prop + " for " + c + ". Is it there? " + _displayObjectInitialProperties[c]);
			return _displayObjectInitialProperties[c][prop];
		}
		public function autoEnterFromZoomZero(c:*, time:Number, onComplete:Function=null, onCompleteParams:*= null, emd:String=null, resetBefore:Boolean=false, ease:String="Strong.easeOut"):TweenNano {
			c.scaleX = c.scaleY = 0;
			return doMove(c, time, {scaleX:getInitialProperty(c, "scaleX"), scaleY:getInitialProperty(c, "scaleY"), onComplete:onComplete, onCompleteParams:onCompleteParams}, ease, emd, "to");
		}
		public function autoEnterFromOffScreen(c:*, time:Number, directionFrom:String="bottom", setOffStageBeforeEnter:Boolean=false, onComplete:Function=null, onCompleteParams:*= null, emd:String=null, resetBefore:Boolean=false, ease:String="Strong.easeOut"):void {
			const p:String = directionFrom.charAt(0).toLowerCase();
			if (setOffStageBeforeEnter) autoSetOffScreen(c, p, false);
			const prop:String = (p == "b" || p == "t") ? "y" : "x";
			autoRestoreProp(c, time, prop, onComplete, onCompleteParams, emd, false, ease);
		}
		public function autoExitOffScreen(c:*, time:Number, directionTo:String="bottom", onComplete:Function=null, onCompleteParams:*= null, emd:String=null, resetBefore:Boolean=false, ease:String="Strong.easeOut"):void {
			const p:String = directionTo.charAt(0).toLowerCase();
			const prop:String = autoGetOffScreenPropName(p);
			autoMoveProp(c, time, autoGetOffScreenPropValue(c, p), autoGetOffScreenPropName(p), onComplete, onCompleteParams, emd, resetBefore, ease);
		}
		public function autoRestoreProp(c:*, time:Number, prop:String, onComplete:Function=null, onCompleteParams:*= null, emd:String=null, resetBefore:Boolean=false, ease:String="Strong.easeOut"):void { // Moves object in relation to initial properties
			autoMoveProp(c, time, getInitialProperty(c, prop), prop, onComplete, onCompleteParams, emd, resetBefore, ease);
		}
		public function autoSetOffScreen(c:*, direction:String="bottom", resetBefore:Boolean=false):void { // bottom, top, left, right or b, t, l, r
			const p:String = direction.charAt(0).toLowerCase();
			if (_verbose) Debug.debug(_debugPrefix, "Setting off screen " + c + " direction " + direction, autoGetOffScreenPropName(p), autoGetOffScreenPropValue(c, p));
			// this one needs to be redone using rectangles and bounds to optimize offscreen positions
			if (resetBefore) restoreInitialProperties(c);
			c[autoGetOffScreenPropName(p)] = autoGetOffScreenPropValue(c, p);
		}
		public function autoSetY(c:*, delta:Number, resetBefore:Boolean=false):void { // Sets object in relation to initial properties
			autoSetProp(c, delta, "y", resetBefore);
		}
		public function autoSetProp(c:*, delta:Number, prop:String, resetBefore:Boolean=false):void {
			if (resetBefore) restoreInitialProperties(c);
			c[prop] = getInitialProperty(c, prop) + delta;
		}
		public function autoMoveY(c:*, time:Number, delta:Number, onComplete:Function=null, onCompleteParams:*= null, emd:String=null, resetBefore:Boolean=false, ease:String="Strong.easeOut"):void { // Moves object in relation to initial properties
			autoMoveAddProp(c, time, delta, "y", onComplete, onCompleteParams, emd, resetBefore);
		}
		public function autoMoveX(c:*, time:Number, delta:Number, onComplete:Function=null, onCompleteParams:*= null, emd:String=null, resetBefore:Boolean=false, ease:String="Strong.easeOut"):void { // Moves object in relation to initial properties
			autoMoveAddProp(c, time, delta, "x", onComplete, onCompleteParams, emd, resetBefore);
		}
		public function autoMoveAddProp(c:*, time:Number, delta:Number, prop:String, onComplete:Function=null, onCompleteParams:*= null, emd:String=null, resetBefore:Boolean=false, ease:String="Strong.easeOut"):void {
			autoMoveProp(c, time, _displayObjectInitialProperties[c][prop] + delta, prop, onComplete, onCompleteParams, emd, resetBefore, ease);
		}
		// INTERNAL UTY
		private function autoGetOffScreenPropValue(c:*, p:String="b"):Number { // Gets value from t, b, l, r
			if (p == "b") return UGlobal.stageRect.height + c.height;
			else if (p == "t") return 0 - c.height;
			else if (p == "l") return 0 - c.width;
			else if (p == "r") return UGlobal.stageRect.width + c.width;
			Debug.error(_debugPrefix, "autoGetOffScreenProp() error, direction not understood: " + p);
			return 0;
		}
		private function autoGetOffScreenPropName(p:String):String { // Gives x or y from t, b, l, r
			return p == "b" || p == "t" ? "y" : "x";
		}
		private function autoMoveProp(c:*, time:Number, targetPos:Number, prop:String, onComplete:Function=null, onCompleteParams:*= null,  emd:String=null, resetBefore:Boolean=false, ease:String="Strong.easeOut"):void {
			if (resetBefore) restoreInitialProperties(c);
			const props:Object = {};
			props[prop] = targetPos;
			if (onComplete) {
				props.onComplete = onComplete;
				if (onCompleteParams) props.onCompleteParams = onCompleteParams;
			}
			move(c, time, props, ease, emd);
		}
	// SIMPLIFIED MOVERS
		public function fadeScale(c:*, time:Number, alpha:Number = 1, scale:Number=1, onComplete:Function = null, onCompleteParams:*= null):TweenNano { // Fades to 1, and scales to 1
			return									doMove(c, time, {alpha:alpha, scaleX:scale, scaleY:scale, onComplete:onComplete, onCompleteParams:onCompleteParams}, "Linear.easeOut", null, "to");
		}
		public function fadeScaleIn(c:*, time:Number, onComplete:Function=null, onCompleteParams:*=null):TweenNano { // Fades to 1, and scales to 1
			return									doMove(c, time, {alpha:1, scaleX:1, scaleY:1, onComplete:onComplete, onCompleteParams:onCompleteParams}, "Linear.easeOut", null, "to");
		}
		public function fade(c:*, time:Number, alpha:Number, onComplete:Function=null, onCompleteParams:*=null, emd:String=null):TweenNano {
			return doMove(c, time, {alpha:alpha, onComplete:onComplete, onCompleteParams:onCompleteParams}, "Linear.easeIn", emd, "to");
		}
		public function fadeInFrom0(c:*, time:Number, onComplete:Function=null, onCompleteParams:*=null, emd:String=null):TweenNano {
			c.alpha = 0;
			return doMove(c, time, {alpha:1, onComplete:onComplete, onCompleteParams:onCompleteParams}, "Linear.easeIn", emd, "to");
		}
		public function fadeTo0(c:*, time:Number, onComplete:Function=null, onCompleteParams:*=null, emd:String=null):TweenNano {
			return doMove(c, time, {alpha:0, onComplete:onComplete, onCompleteParams:onCompleteParams}, "Linear.easeIn", emd, "to");
		}
		public function scale(c:*, time:Number, scale:Number, onComplete:Function=null, onCompleteParams:*=null, emd:String=null, ease:String="Strong.easeOut"):TweenNano {
			return doMove(c, time, {scaleX:scale, scaleY:scale, onComplete:onComplete, onCompleteParams:onCompleteParams}, ease, emd, "to");
		}
		public function rotate(c:*, time:Number, rot:Number, onComplete:Function=null, onCompleteParams:*=null, emd:String=null):TweenNano {
			return doMove(c, time, {rotation:rot, onComplete:onComplete, onCompleteParams:onCompleteParams}, "Strong.easeOut", emd, "to");
		}
		public function scaleRotate(c:*, time:Number, scale:Number, rot:Number, onComplete:Function=null, onCompleteParams:*=null, emd:String=null):TweenNano {
			return 		doMove(c, time, {scaleX:scale, scaleY:scale, rotation:rot, onComplete:onComplete, onCompleteParams:onCompleteParams}, "Strong.easeOut", emd, "to");
		}
	// MAIN MOTION METHODS
	/**
	 * Moves an Object
	 * @param	c The Object to be moved
	 * @param	time In seconds, time of motion
	 * @param	vars variables object i.e.: {x:100, alpha:0, onComplete:Function, onCompleteParams:(Array or Object, if Array, are sent as single params to method.)}
	 * @param	ease type of usable ease. I.e. Strong.easeOut, Quint.easeOut (easeOut easeIn easeInOut), etc... Back Bounce Circ Cubic CustomEase EaseLookup Elastic Expo FastEase Linear Quad Quart Quint RoughEase Sine SteppedEase Strong
	 * @param	emd End of motion directive: KILL (just removes it from display list), INV (invisible), STORE (UMem.store), STOREREMOVE, DESTROY (UMem.kill) 
	 * @param	dir to, from
	 * @param	overwrite if overwrite previous motion
	 * @return 	TweenNano instance
	 */
		public function move	(c:*, time:Number, vars:Object, ease:String="Strong.easeOut", emd:String=null, dir:String="to", overwrite:Boolean=true):TweenNano {
			return		doMove(c, time, vars, ease, emd, dir, overwrite);
		}
		public function moveFrames(c:*, frames:uint, vars:Object, ease:String="Strong.easeOut", emd:String=null, dir:String="to"):TweenNano {
			vars.useFrames	= true;
			return		doMove(c, frames, vars, ease, emd, dir);
		}
	// MOTION REMOVAL
		public function stopMotions():void {
													//trace(_debugPrefix,"removeInternalMotion stopMotions1");

			for each (_tw in _motions) removeInternalMotion(_tw);
			// Look for other TweenNano instances
			//trace(_debugPrefix,"removeInternalMotion stopMotions2");
			for each (_tw in _allTweenNano) removeInternalMotion(_tw);
			// Nullify var
			_tw = null;
		}
		public function stopMotion(c:*):void {
			//trace(_debugPrefix,"removeInternalMotion stopMotion");
			// Remove single motion
			Debug.debug(_debugPrefix, "stopMotion: " + c, _motions[c]);
			if (_motions[c]) removeInternalMotion(_motions[c]);
			else if (VERBOSE) Debug.error(_debugPrefix, "Cannot remove motion for: " + c);
			// Proceed looking for c in all TweenNano instances
			for each (_tw in _allTweenNano) {
							//trace("stopMotion2");

				if (_tw.target == c) removeInternalMotion(_tw); // If this is moving C just remove it
			}
		}
// MOTION ///////////////////////////////////////////////////////////////////////////////////////
			private function doMove(c:*, steps:Number, userVars:Object, ease:String, emd:String = null, dir:String = "to", overwrite:Boolean = true):TweenNano {
				// Check if previous motion was in place
							//trace(_debugPrefix,"removeInternalMotion doMove");

				if (overwrite && isMoving(c)) removeInternalMotion(_allMotions[c]);
				// Adjust ease in order to allow using move with "null" instead of easing function
				if (ease == null) ease = DEFAULT_EASE;
				// Setup motions param
				var motionParams:Object = {};
				var vars:Object = UCode.duplicateObject(userVars);
				if (vars.scaleAll != undefined) {
					vars.scaleX = vars.scaleY = vars.scaleAll;
				}
				// Setup ease function
				vars.ease	= EaseLookup.find(ease ? ease : _defaultEase);
				// Setup stuff for onComplete
				if (vars.onComplete) {
					// Setup internal onComplete working
					motionParams.onComplete			= vars.onComplete;
					motionParams.onCompleteParams		= vars.onCompleteParams;
				}
				if (emd)	motionParams.emd = emd;
				_motionsParams[c]						= motionParams;
				// Always set an onComplete function
				vars.onComplete = onPFMoverComplete;
				// Debug trace
				if (_verbose) Debug.debug(_debugPrefix, "Start motion", ease, c, c.name, Debug.object(vars));
				// Setup stuff for motion
// 				var t									:TweenNano = _allMotions[c] ? _allMotions[c] : TweenNano[dir](c, steps, vars); 
				var t:TweenNano = TweenNano[dir](c, steps, vars);
				vars.onCompleteParams					= [t];
				_allMotions[c] = t;
				_motions[c] = t;
				_allTweenNano.push(t);
				return t;
			}
// STATIC-LIKE SHORTCUTS ///////////////////////////////////////////////////////////////////////////////////////
		
		
		
		
		// Pos object must have ONLY parameters for blitting mask - scrollY and scrollX
		public function setupBlitMask						(c:*, w:int, h:int, x:int=0, y:int=0, smoothing:Boolean=false, autoUpdate:Boolean=false, fillColor:uint=0x00000000, wrap:Boolean=false):void {
			if (_blitMasks[c])							destroyBlitMask(c);
			var bm									:BlitMask = new BlitMask(c, x, y, w, h, smoothing, autoUpdate, fillColor, wrap);
			_blitMasks[c]								= bm;
		}
		public function destroyBlitMask						(c:*):void {
			var bm									:BlitMask = _blitMasks[c];
			if (bm) {
				if (isMoving(bm)) {
					stopMotion							(bm);
				}
				bm.dispose								();
				delete								_blitMasks[c];
			}
// 			else {
// 				Debug.error							(_debugPrefix, "Cannot destroyBlitMask() for " + c + " please call setupBlitMask() first.");
// 			}
		}
		public function activateBlitMask						(c:*):void { // Sets active the blitting on clip
			_blitMasks[c].enableBitmapMode					();
		}
		// scrollX and scrollY are between 0 and 1. Percent/100.
		public function scrollBlitMaskH						(c:*, scrollX:Number):void { // This one just applies the blitmask
			_blitMasks[c].scrollX							= scrollX;
		}
		public function scrollBlitMaskV						(c:*, scrollY:Number):void { // This one just applies the blitmask
			_blitMasks[c].scrollY							= scrollY;
		}
		public function scrollBlitMask						(c:*, scrollX:Number, scrollY:Number):void { // This one just applies the blitmask
			var bm									:BlitMask = _blitMasks[c];
			bm.scrollY = scrollY;
			bm.scrollX = scrollX;
		}
		public function deactivateBlitMask						(c:*):void {
			_blitMasks[c].disableBitmapMode					();
		}
		/* La parte con lo scroll to l'ho fatta ma non serviva. E' da testare. Invece faccio un setup della blitmask da qui. */
// 		public function scrollBlitMask						(c:*, time:Number, vars:Object, onComplete:Function=null, onCompleteParams:*=null, ease:String="Strong.easeOut", releaseOnMotionEnd:Boolean=true):TweenNano {
// 			// This activates a BlitMask scroll on the movieclip. Motion object internally is the BlitMask, not the DisplayObject. I get the BlitMask in _blitMasks[c].
// 			// vars is the BlitMask motion object with BlitMask properties {scrollX:100, scrollY:100}
// 			// vars properties can be found here: https://www.greensock.com/asdocs/com/greensock/BlitMask.html
// 			// releaseOnMotionEnd means that at the end of motion it will be de-bitmapped and interactivity restored
// 			// First I remove traditional motion on BlitMask
// 			if (!_blitMasks[c]) {
// 				Debug.error							(_debugPrefix, "Cannot scroll BlitMask of " + c  + " : " + c.name + " without calling setupBlitMask() first! PFMover.scrollBlitMask() aborted.");
// 				return								null;
// 			}
// 			var bm									:BlitMask = _blitMasks[c];
// 			// I stop motions if its moving
// 			if (isMoving(bm)) {
// 				stopMotion								(bm);
// 			}
// 			bm.enableBitmapMode							();
// 			var mp									:Object = {isBlitMask:true, releaseOnMotionEnd:releaseOnMotionEnd, onComplete:onComplete, onCompleteParams:onCompleteParams}; // MotionParams
// 			vars.ease									= EaseLookup.find(ease ? ease : _defaultEase);
// 			vars.onComplete								= onPFMoverCompleteBlitMask;
// 			_motionsParams[bm]							= mp;
// 			var t										:TweenNano = TweenNano.to(mp, time, vars);
// 			vars.onCompleteParams						= [t];
// 			_allMotions[bm]								= t;
// 			_motions[bm]								= t;
// 			return									t;
// 		}
// 		private function getTweenInstance					(c:*):TweenNano {
// 			return									_motions[c];
// 		}
// 		private function onPFMoverCompleteBlitMask				(t:TweenNano):void {
// 			if (_verbose)								Debug.debug(_debugPrefix, "Motion complete:",t.target,t.target.name,t.vars);
// 			var p										:Object = _motionsParams[t.target];
// 			if (p.releaseOnMotionEnd)						t.target.disableBitmapMode();
// 			removeInternalMotion							(t);
// 			if (p.onComplete) {
// 				if (p.onComplete != onPFMoverCompleteBlitMask) {
// 					if (p.onCompleteParams)				UCode.callFunctionArray(p.onComplete, p.onCompleteParams);			
// 					else								p.onComplete();
// 				}
// 				else if (_verbose) {
// 					Debug.error						(_debugPrefix, "Double execution of onPFMoverComplete() prevented.",t.target,t.target.name,t.vars);
// 				}
// 			}
// 		}
		
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function onPFMoverComplete(t:TweenNano):void {
			if (_verbose) Debug.debug(_debugPrefix, "Motion complete:", t.target, t.target.name, t.vars);
			// First retrieve parameters object
			var p:Object = _motionsParams[t.target];
										//trace(_debugPrefix,"removeInternalMotion onPFMoverComplete");

			// Then clear up motion properties
			removeInternalMotion(t);
			// Continue
			if (!p) {
				if (_verbose) Debug.warning(_debugPrefix, "Motion complete for " + t.target + " but parameters have not been found. This must be an additional motion, and previous one is complete. I cannot launch a onComplete event since I have no parameters.");
				return;
			}
			if (p.emd) processEndMotionDirective(t.target, p.emd);
			if (p.onComplete) {
				if (p.onComplete != onPFMoverComplete) {
					if (p.onCompleteParams) {
						if (p.onCompleteParams is Array) UCode.callFunctionArray(p.onComplete, p.onCompleteParams);
						else p.onComplete(p.onCompleteParams);
					}
					else p.onComplete();
				}
				else if (_verbose) {
					Debug.error(_debugPrefix, "Double execution of onPFMoverComplete() prevented.",t.target,t.target.name,t.vars);
				}
			}
		}
		private function removeInternalMotion(t:TweenNano = null):void {
			//trace("TOLGO INTERNAL", t);
			if (t) {
				UCode.removeVectorItem(_allTweenNano, t);
				t.vars = null;
				t.kill();
				delete _allMotions[t.target];
				delete _motions[t.target];
				delete _motionsParams[t.target];
			}
		}
// STATIC FRAMEMOVER/ANIMATOR COMPATIBILITY ///////////////////////////////////////////////////////////////////////////////////////
	// Static method to route to unternal mover
		public static function moveStatic(c:*, time:Number, vars:Object, ease:String="Strong.easeOut", emd:String=null, dir:String="to"):TweenNano {
			return _internalMover.doMove(c, time, vars, ease, emd, dir);
		}
	// To keep compatibility, those functions here always store the moved clip as only parameter
		public static function moveTo(c:*, frames:int, x:Number, y:Number, onComplete:Function=null, par:Object=null, useFrames:Boolean=true):void {
			slideIn(c, {steps:frames, endPos:{x:x, y:y}, onCompleteParams:par, onComplete:onComplete}, true, useFrames )
		}
		public static function fadeTo						(c:*, to:Number, frames:int=5, onComplete:Function=null, par:Object=null, useFrames:Boolean=true) {
			straightMove								(c, {steps:frames, endPos:{alpha:to}, onCompleteParams:par, onComplete:onComplete}, true, useFrames);
		}
		public static function fadeInTotal						(c:*, frames:int=5, onComplete:Function=null, par:Object=null, useFrames:Boolean=true) {
			c.visible									= true;
			c.alpha									= 0;
			straightMove								(c, {steps:frames, endPos:{alpha:1}, onCompleteParams:par, onComplete:onComplete}, true, useFrames);
		}
		public static function fadeIn							(c:*, frames:int=5, onComplete:Function=null, par:Object=null, useFrames:Boolean=true) {
			straightMove								(c, {steps:frames, endPos:{alpha:1}, onCompleteParams:par, onComplete:onComplete}, true, useFrames);
		}
		public static function fadeOut						(c:*, frames:int=5, onComplete:Function=null, par:Object=null, useFrames:Boolean=true) {
			straightMove								(c, {steps:frames, endPos:{alpha:0}, onCompleteParams:par, onComplete:onComplete}, true, useFrames);
		}
		public static function fadeOutAndKill					(c:*, frames:int=5, onComplete:Function=null, par:Object=null, useFrames:Boolean=true) {
			straightMove								(c, {steps:frames, endPos:{alpha:0}, onComplete:onComplete, onCompleteParams:par, endMotionDirective:"KILL"}, true, useFrames);
		}
		public static function fadeOutAndDestroy				(c:*, frames:int=5, onComplete:Function=null, par:Object=null, useFrames:Boolean=true) {
			straightMove								(c, {steps:frames, endPos:{alpha:0}, onComplete:onComplete, onCompleteParams:par, endMotionDirective:"DESTROY"}, true, useFrames);
		}
		public static function fadeOutAndInvisible				(c:*, frames:int=5, onComplete:Function=null, par:Object=null, useFrames:Boolean=true) {
			straightMove								(c, {steps:frames, endPos:{alpha:0}, onComplete:onComplete, onCompleteParams:par, endMotionDirective:"INV"}, true, useFrames);
		}
		static public function straightMove					(c:*, p:Object, overwrite:Boolean=true, useFrames:Boolean=true) {
			doMoveCompatible							(c, p, "Linear.easeNone", useFrames);
		}
		static public function slideOut						(c:*, p:Object, overwrite:Boolean=true, useFrames:Boolean=true) {
			doMoveCompatible							(c, p, "Strong.easeIn", useFrames);
		}
		static public function slideOutIn						(c:*, p:Object, overwrite:Boolean=true, useFrames:Boolean=true) {
			doMoveCompatible							(c, p, "Strong.easeInOut", useFrames);
		}
		static public function slideIn							(c:*, p:Object,overwrite:Boolean=true, useFrames:Boolean=true) {
			doMoveCompatible							(c, p, "Strong.easeOut", useFrames);
		}
		static public function removeMotion					(c:*):void {
			_internalMover.stopMotion						(c);
		}
		static public function removeAllMotions					():void {
			_internalMover.stopMotions						();
		}
		// STATIC GETTERS
		static public function get instance():PFMover {
			return _internalMover;
		}
		
			static private function doMoveCompatible			(c:*, p:Object, ease:String="Strong.easeOut", useFrames:Boolean=true):void {
				if (_internalMover) {
// 					removeMotion						(c);
					if (p.onComplete) {
						p.endPos.onComplete 				= p.onComplete;
						p.endPos.onCompleteParams 		= p.onCompleteParams ? [p.onCompleteParams] : [c];
// 						p.endPos.emd					= p.emd;
						if (p.emd)						p.endMotionDirective = p.emd;
					}
					if (!p.steps)						p.steps = DEFAULT_SLIDE_STEPS;
					if (useFrames)						_internalMover.moveFrames(c, p.steps, p.endPos, ease, p.endMotionDirective);
					else								_internalMover.move(c, p.steps, p.endPos, ease, p.endMotionDirective);
				}
				else { // PFMover is NOT initialized
					UCode.setParameters					(c, p.endPos);
				}
			}
	}
}
