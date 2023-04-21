/* UAlign - ver 0.1 - Filippo Gregoretti - www.pippoflash.com

Manages alignment and resizing of clips


*/

package com.pippoflash.utils {


	import									com.pippoflash.utils.Debug;
	import									com.pippoflash.utils.UGlobal;
	import									flash.system.*;
	import									flash.display.*;
	import									flash.geom.*;
	import									flash.events.*;
	import									flash.text.TextField;
	import 									fl.motion.Color; 
	
	
	public class UDisplay {
		
// UTILITIES ////////////////////////////////////////////////////////////////////////////
		// Constants
		private static const RADIANS_TO_ANGLE:Number = 180 / Math.PI;
		// Static switches
		public static var _verbose:Boolean = true;
		public static var _debugPrefix:String = "UDisplay";
		// UTY
		private static var _ww:Number; // Uty to test width
		private static var _hh:Number; // Uty to test height
		private static var _s:String;
		private static var _i:int;
		private static var _n:Number;
		private static var _c:*;
		private static var _bmpCacheMatrix:Matrix = new Matrix();
// 		public static var _a						:Array;
// 		public static var _b						:Boolean;
// 		public static var _j;						// Jolly variable, can be anything
// 		public static var _clip						:MovieClip;
// 		public static var _counter					:int;
// RESIZE AND ALIGN //////////////////////////////////////////////////////////////////////////////////
	// RELATIVE TO STAGE /////////////////////////////////////////////////////// ////////////////////////////////
		public static function centerToStage(c:DisplayObject):void {
			// If clip has yet a parent, it will be centered according to stage or else it will be root (nothing can be higher than stage)
			if (c.hasOwnProperty("parent")) {
				if (c.parent is Stage) centerOnStage(c);
				else centerOnRoot(c);
			}
			else { // If no parent, it gets centered to stage
				centerOnStage(c);				
			}
		}
		public static function centerOnStage(c:DisplayObject):void { // This centers exatly in the middle of stage. Only things which are positioned in stage or in clips that are not scaled or displaced get centered.
			positionToPoint(c, UGlobal.getCenterPoint());
		}
		public static function centerOnRoot(c:DisplayObject):void { // This centers exactly within the root center point. It assumes that root could be misplaced.
			positionToPoint(c, UGlobal.getRootCenterPoint());
		}
		public static function alignToStage(c:DisplayObject, halign:String="CENTER", valign:String="MIDDLE"):void {
			alignSpriteTo(c, UGlobal.getStageRect(), halign, valign);
		}
		public static function resizeToStage(c:DisplayObject):void { // Sets the size exactly like it is the stage
			c.width = UGlobal._sw; c.height = UGlobal._sh;
		}
		static public function resizeToStageProportions(c:DisplayObject, onlyIfLarger:Boolean = true):void {
			// Since this might happen also after items have shrunk, I have to reset scaling first
			c.scaleX = c.scaleY = 1;
			// Proceed with resizing
			if (onlyIfLarger && c.width < UGlobal._sw && c.height < UGlobal._sh) return; // Clip is not larger, and I resize only if larger
			// Proceed resizing
			//var diffW:Number = c.width - UGlobal._sw; // Find the highest difference and use that one
			//var diffH:Number = c.height - UGlobal._sh;
			//if (diffW > diffH) {
				//c.width = UGlobal._sw;
				//c.scaleY = c.scaleX;
				//// Perform a second check
			//}
			//else {
				//c.height = UGlobal._sh;
				//c.scaleX = c.scaleY;
			//}
			// Works better in the simpler way. Just resize one side, then the other, then if the first side is still too hight, resize it again
			// Starts by the horizontal factor
			c.width = UGlobal._sw;
			c.scaleY = c.scaleX;
			// If higher, resize to high side
			if (c.height > UGlobal._sh) {
				c.height = UGlobal._sh;
				c.scaleX = c.scaleY;
			}
		}
		public static function applyToStage(c:DisplayObject, center:Boolean=true, resize:String="CROP-RESIZE"):void { // Any display object is displaced and repositioned to cover the stage area totally
			resizeSpriteTo(c, UGlobal.getStageRect(), resize);
			if (center) alignSpriteTo(c, UGlobal.getStageRect());
		}
// 		public static function positionToStageCenter	(c:DisplayObject):void { // Object is positioned relatively to the stage. Wherever the object is, it is positioned to look exactly on the stage center
// 			c.x								= UGlobal.getCenterPoint().x;
// 			c.y								= UGlobal.getCenterPoint().y;
// 		}
	// CENTERING ///////////////////////////////////////////////////////////////////////////////////////
		public static function centerToSelf(c:DisplayObject):void {
			c.x = -(c.width/2);
			c.y = -(c.height/2);
		}
		public static function centerToArea			(c:DisplayObject, w:Number, h:Number):void {
			centerV(c, h); centerH(c, w);
		}
		public static function centerTextVertTo(c:TextField, o:Object):void {
			c.y = (o.height - c.textHeight)/2;
			// trace(c);
			// trace(o)
			// trace(o.width)
			// trace(c.textWidth)
			// c.x = (o.width - c.textWidth)/2;
		}
		public static function centerV				(c:*, h:Number):void {
			c.y								= c is TextField ? centerAmount(UCode.getHeight(c), h) : centerAmount(UCode.getHeight(c), h);
		}
		public static function centerH				(c:*, w:Number):void {
			c.x								= c is TextField ? centerAmount(UCode.getWidth(c), w) : centerAmount(UCode.getWidth(c), w);
		}
			public static function centerAmount		(w:Number, a:Number):Number {
				return						(a-w)/2;
			}
// POSITIONING & RESIZING ///////////////////////////////////////////////////////////////////////////////////////
	// SIMPLE BASE METHODS
		public static function resizeToRect				(c:DisplayObject, rect:*):void {
			c.x = rect.x; c.y = rect.y; c.width = rect.width; c.height = rect.height;
		}
		public static function positionToPoint(c:DisplayObject, p:*):void {
			c.x = p.x; c.y = p.y;
		}
		public static function scaleTo				(c:DisplayObject, scale:Number):void {
			c.scaleX							= scale;
			c.scaleY							= scale;
		}
		public static function roundPosition			(c:DisplayObject):void {
			c.x = Math.round(c.x); c.y = Math.round(c.y); 
		}
		public static function roundSize				(c:DisplayObject):void {
			c.width = Math.round(c.width); c.height = Math.round(c.height);
		}
		public static function round					(c:DisplayObject):void {
			roundSize							(c);
			roundPosition						(c);
		}
	// RESIZE AND ALIGN ///////////////////////////////////////////////////////////////////////////////////////
		public static function resizeAndAlign			(c:*, rect:*, resizeMode:String="NORMAL", horiz:String="CENTER", vert:String="MIDDLE", useBounds:Boolean=false, useRect:Boolean=false):void {
			resizeSpriteTo						(c, rect, resizeMode, useBounds, useRect);
			alignSpriteTo						(c, rect, horiz, vert, useBounds, useRect);
		}
	// AUTO RESIZING ///////////////////////////////////////////////////////////////////////////////////////
		public static var resizeTo					:Function = resizeSpriteTo;
		public static function resizeSpriteTo(c:*, rect:*, myMode:String="NORMAL", useBounds:Boolean=false, useRect:Boolean=false):void {
			const mode:String = myMode.toUpperCase();
			// Check if it is with bounds
			if (useBounds) {
				const bounds:Rectangle = useRect ? c.getRect(c.parent) : c.getBounds(c.parent);
				const sx:Number = rect.width / bounds.width;
				const sy:Number = rect.height / bounds.height;
				
				if (mode == "NORMAL") { // Gets resized within rectangle
					c.scaleX = c.scaleY 			= sx > sy ? sy : sx;
				}
				else if (mode.indexOf("CROP") == 0) {
					c.scaleX = c.scaleY 			= sx > sy ? sx : sy;
				}
				else {
					c.scaleX					= sx;
					c.scaleY					= sy;
				}
				return;
			}
			// Without bounds
			if (mode == "NORMAL") {
				c.height						= rect.height;
				c.scaleX						= c.scaleY;
				if (c.width > rect.width) {
					c.width					= rect.width;
					c.scaleY					= c.scaleX;
				}
			}
			else if (mode.indexOf("CROP") == 0) {
				if (mode == "CROP-RESIZE") {
					c.height					= rect.height;
					c.scaleX					= c.scaleY;
					if (c.width < rect.width) {
						c.width				= rect.width;
						c.scaleY				= c.scaleX;
					}
				}
			}
			else {
				UCode.setParameters(c, {x:rect.x, y:rect.y, width:rect.width, height:rect.height});
			}
			// If NONE or else nothing will happen
		}
	// BOUNDARIES RESIZING //////////////////////////////////////////////////////////////////////////
		// It gives for granted that movieclip containes a display object called "_boundaries". Or a rectangle.
		public static function resizeToBoundaries		(c:DisplayObject, boundariesArea:*, containerArea:*):void {
			// boundariesArea and containerArea can be a displayobject or a rectangle
			c.scaleX							= containerArea.width/boundariesArea.width;
			c.scaleY							= containerArea.height/boundariesArea.height;
			if (c.scaleX < c.scaleY)				c.scaleY = c.scaleX;
			else								c.scaleX = c.scaleY;
		}
	// ALIGNMENT ///////////////////////////////////////////////////////////////////////////////////////
		public static var alignTo:Function = alignSpriteTo;
		public static function alignSpriteTo(c:*, rect:*, horiz:String="CENTER", vert:String="MIDDLE", useBounds:Boolean=false, useRect:Boolean=false, useTextBounds:Boolean=false):void {
			alignSpriteHorizTo(c, rect, horiz, useBounds, useRect, useTextBounds);
			alignSpriteVertTo(c, rect, vert, useBounds, useRect, useTextBounds);
		}
		public static function alignSpriteHorizTo(c:*, rect:*, m:String="CENTER", useBounds:Boolean=false, useRect:Boolean=false, useTextBounds:Boolean=false):void {
			if (useBounds) {
				// Element bounds can be measure ONLY if element is positioned at 0.
				c.x = 0;
				const bounds:Rectangle = useRect ? c.getRect(c.parent) : c.getBounds(c.parent);
				const diff:Number = (rect.width - bounds.width) / 2;
				c.x = rect.x + diff;
				c.x -= bounds.x;
			}
			else {
				const ww:Number = c.hasOwnProperty("_w") ? c["_w"] : c.width;
				m = m.toUpperCase();
				if (m == "CENTER") c.x = rect.x + ((rect.width-ww)/2);
				else if (m == "RIGHT") c.x = rect.x + (rect.width-ww);
				else if (m == "LEFT") c.x = rect.x;
			}
		}
		public static function alignSpriteVertTo(c:*, rect:*, m:String="MIDDLE", useBounds:Boolean=false, useRect:Boolean=false, useTextBounds:Boolean=false):void {
			if (useBounds) {
				c.y = 0;
				const bounds:Rectangle = useRect ? c.getRect(c.parent) : c.getBounds(c.parent);
				const diff:Number = (rect.height - bounds.height) / 2;
				c.y = rect.y + diff;
				c.y -= bounds.y;
			} else if (useTextBounds && c is TextField) {
				// Here I am using text boundaries, therefore it is a bit more complex
				const ty:Number = (c as TextField).getCharBoundaries(0).y;
				const th:Number = (c as TextField).textHeight;
				m = m.toUpperCase();
				if (m == "MIDDLE" || m == "CENTER")c.y = rect.y + ((rect.height-th)/2);
				else if (m == "BOTTOM") c.y = rect.y + (rect.height-th);
				else if (m == "TOP") c.y = rect.y;
				c.y -= ty; // Remove offset from text positioning
			} else {
				const hh:Number = c.hasOwnProperty("_h") ? c["_h"] : c.height;
				m = m.toUpperCase();
				if (m == "MIDDLE" || m == "CENTER")c.y = rect.y + ((rect.height-hh)/2);
				else if (m == "BOTTOM") c.y = rect.y + (rect.height-hh);
				else if (m == "TOP") c.y = rect.y;
			}
		}
// COORDINATES /////////////////////////////////////////////////////////////////////////////////
// 		public static function getClipsCoordinates		(c1, c2):Point { // Returns c1 position in coordinates space of c2
// 			// COMPLETELY BUGGY!!!!!!
// 			var p								:Point = new Point(0, 0);
// 			c1.parent.localToGlobal				(p);
// 			return							p;
// 		}
		public static function getClipGlobalRect		(c:*):Rectangle {
			return							c.getRect(UGlobal.stage);
		}
		
		public static function setClipToPoint			(c:*, p:Point):void {
			c.x								= p.x;
			c.y								= p.y;
// 			UCode.setParameters				(c, {x:p.x, y:p.y});
		}
		public static function positionRelativeTo			(clip:*, relClip:*, point:Point):Point {
			// This positions a clip to a coordinate space relativve to another clip
			if (!clip.parent) {
				Debug.error					(_debugPrefix, "positionRelativeTo",clip,"but clip.parent not defined.");
				return						null;
			}
			var p								:Point = clip.parent.globalToLocal(relClip.localToGlobal(point));
			positionToPoint						(clip, p);
			return							p;
		}
// 		public static function getRelativePosition		(clip:DisplayObject, relClip:DisplayObjectContainer):Point {
// 			var p								= new Point(clip.x, clip.y);
// 			return							relClip.globalToLocal(relClip.localToGlobal(p));
// 		}
		public static function mouseIsOnTop			(c:*):Boolean {
			// Tells if mouse is on top of a display object
			return							(c.mouseX >= 0 && c.mouseY >= 0 && c.mouseX <= c.width && c.mouseY <= c.height);
		}
		public static function moveClip				(c:*, newContainer:*):void { // Moves the clip to a new container mantaining all positioning
			// This is experimental, but will really save my ass
			var p								:Point = new Point(c.x, c.y);
			newContainer.addChild					(c);
			positionRelativeTo					(c, newContainer, p);
		}
// DISPLAY OBJECT CONTAINER ///////////////////////////////////////////////////////////////////////////
		public static function removeChild				(container:DisplayObjectContainer, child:DisplayObject):void {
			if (container.contains(child))			container.removeChild(child);
		}
		public static function addNewClip				(container:DisplayObjectContainer, par:Object=null):DisplayObject {
			return							addChild(container, new MovieClip(), par);
		}
		public static function wrapInNewSprite			(c:DisplayObject):Sprite {
			var s:Sprite = new Sprite(); s.addChild(c); return s;
		}
		public static function addChild(container:DisplayObjectContainer, child:DisplayObject, par:Object=null):DisplayObject {
			container.addChild(child);
			if (par) UCode.setParametersForced(child, par);
			return child;
		}
		public static function addChilds(container:DisplayObjectContainer, ...childs):void {
			for each(var child:DisplayObject in childs) container.addChild(child)
		}
		public static function removeClip(c:DisplayObject):void {
			// Added check for DisplayObjectContainer because Loader results as a parent
			// trace(c);
			// trace(c.parent);
			// trace(c.parent is DisplayObjectContainer)
			if (c && c.parent && c.parent) try {
				c.parent.removeChild(c);
			} catch (e:Error) {
				Debug.error(_debugPrefix, "Cannot remove clip from parent:",c,c.parent);
			}
		}
		public static function removeClips(...rest):void {
			const a:* = rest[0] is Array || rest[0] is Vector.<*> ? rest[0] : rest; 
			for each (var c:DisplayObject in a) removeClip(c);
		}
		// public static function resetClip				(container:DisplayObjectContainer, c:MovieClip, par:Object=null):DisplayObject {
		// 	// This function removes the MovieClip and replace it with a new one (returning it)
		// 	// If the movieclip doesnt exist, it creates a new one and adds it to container (thats why I need container)
		// 	removeClip						(c);
		// 	return							addNewClip(container, par);
		// }
		public static function resetDisplayObjectProperties(c:DisplayObject):void {
			c.x = c.y = 0;
			c.rotation = 0;
			c.scaleX = c.scaleY = 0;
			c.rotationX = c.rotationY = c.rotationZ = 0;
			c.alpha = 1;
		}
		public static function clipIsRemovable(c:DisplayObject):Boolean {
			return c != null && c.hasOwnProperty("parent");
		}
		public static function moveToTop(c:DisplayObject):void { // Moves selected sprite to higher depth
			if (clipIsRemovable(c)) c.parent.addChild(c);
		}
		// public static function moveToBottom(c:DisplayObject):void { // Moves selected sprite to lowest depth
			
		// }
		public static function getChildren(c:DisplayObjectContainer):Array { // Gets an array with all children
			var a:Array = [];
			for (_i=0; _i<c.numChildren; _i++) a[_i] = c.getChildAt(_i);
			return a;
		}
		static public function getChildrenObj(c:DisplayObjectContainer):Object { // Returns an object with all children of displayobjectcontainer divided by name. No Shapes!!!
			var o:Object = {}; var d:DisplayObject;
			for (_i = 0; _i < c.numChildren; _i++) {
				d = c.getChildAt(_i);
				o[d.name] = d;
			}
			return o;
		}
		public static function getChildrenVector(c:DisplayObjectContainer):Vector.<DisplayObject> { // Gets a vector with all children
			var v:Vector.<DisplayObject> = new Vector.<DisplayObject>(c.numChildren);
			for (_i=0; _i<c.numChildren; _i++) v[_i] = c.getChildAt(_i);
			return v;
		}
		public static function getChildrenNameContains(c:DisplayObjectContainer, key:String):Array { // Gets an array with only children who's nale contains a string
			var a:Array = [];
			var d:DisplayObject;
			var lowerKey:String = key.toLowerCase();
			for (_i=0; _i<c.numChildren; _i++) {
				d = c.getChildAt(_i);
				if (d.name.toLowerCase().indexOf(lowerKey) != -1) a.push(d);
			}
			return a;
		}
		static public function getChildrenObjectByClass(c:DisplayObjectContainer, cl:Class = null):Object { // Returns an object with all children by name, or only children of that class
			var o:Object = {}; var d:DisplayObject;
			if (cl) { // Only of a certain class
				for (_i = 0; _i < c.numChildren; _i++) {
					d = c.getChildAt(_i);
					if (d is cl) o[d.name] = d;
				}
			} else { // All children
				for (_i = 0; _i < c.numChildren; _i++) {
					d = c.getChildAt(_i);
					o[d.name] = d;
				}
			}
			return o;
		}
		public static function listChildren(c:DisplayObjectContainer):void {
			_n = c.numChildren;
			_s = "";
			for (_i=0; _i<_n; _i++) {
				_s += _i + ": " + c.getChildAt(_i) + ", ";
			}
			Debug.debug(_debugPrefix, "Child List for",c,">",_s);
		}
		public static function hideAllChildrenNameContains	(p:DisplayObjectContainer, search:String, removeFromStage:Boolean=true):Boolean {
			// CASE INSENSITIVE - Finds all chindren of a clip, and if their name contains a certain string, they are made invisible and removed from stage
			var children						:Vector.<DisplayObject> = getChildrenVector(p);
			var s								:String = search.toLowerCase();
			var c								:DisplayObject;
			var found:Boolean;
			if (removeFromStage) {
				for each (c in children) {
					if (c.name.toLowerCase().indexOf(s) != -1) {
						p.removeChild(c);
						found = true;
					}
				}
			}
			else {
				for each (c in children) {
					if (c.name.toLowerCase().indexOf(s) != -1) {
						c.visible = false;
						found = true;
					}
				}
			}
			return found;
		}
		//public static function resetClipReference			(c, id:String) {
			//// This gets the container, the reference name, removes the clip and sets reference to dummy clip
			//removeClip							(c[id]);
			//c[id]								= null;
		//}
// DISPLAYOBJECTCONTAINER ABSTRAT REFERENCE FIND ////////////////////////////////
		// Sets up in an array a list of clips with a sequential number name (i.e. _clip0, 1, 2 ti retrieve in an abstract class from it's visual extension)
		public static function getContainerClipsArray(container:DisplayObjectContainer, prefix:String, n:uint):Array {
			// Utility that prepares local array without targeting visual elements in abstract class
			var a:Array = [];
			var c:DisplayObject;
			for (var i:uint=0; i<n; i++) {
				c = container[prefix+String(i)];
				if (c) a[i] = c;
				else Debug.error(_debugPrefix, "getContainerClipsArray() problem: cannot find " + prefix+String(i) + " in " + container);
			}
			return a;
		}
		
// SHIELDER ///////////////////////////////////////////////////////////////////////////////////////
		public static var _standardShield				:MovieClip;
		public static function setShieldActive			(a:Boolean):MovieClip {
			// If true, this function creates a transparent clip in _mainApp and covers all buttons below. 
			// If false or no parameter, it removes the shield if present
			removeClip							(_standardShield);
			if (!a)							return null;
			_standardShield						= getSquareClip({width:UGlobal._sw, height:UGlobal._sh, alpha:0});
			addChild							(UGlobal.mainApp, _standardShield);
			return							_standardShield;
		}
// COLORING ////////////////////////////////////////////////////////////////////////////////////////
		public static function setClipColor(clip:DisplayObject, col:uint, amount:Number=1):void {
			var c:Color = new Color();
			c.setTint(col, amount);
			clip.transform.colorTransform = c;
		}
		public static function setClipsColor(clips:*, col:uint, amount:Number=1):void { // Gets an Array, a Vector, or a hash
			var c:Color = new Color();
			c.setTint(col, amount);
			var clip:DisplayObject;
			for each (clip in clips) clip.transform.colorTransform = c;
		}
// GEOMETRY //////////////////////////////////////////////////////////////////////////////////////////
		// Returns a rectangle from a sprite
		public static function getRectangle			(c:DisplayObject):Rectangle {
			return							new Rectangle(c.x, c.y, c.width, c.height);
		}
		public static function getAngle				(x:Number, y:Number):Number { // Returns an angle from 2 coordinates starting from 0
			return							Math.atan2(x, y) * RADIANS_TO_ANGLE;
		}
		public static function getRelAngle				(source:DisplayObject, targ:DisplayObject):Number {
			return							getAngle(targ.x - source.x, targ.y - source.y);
		}
// FRAMEWORK ELEMENTS ///////////////////////////////////////////////////////////////////////////////////////
		public static function getSquareClip			(par:Object=null):MovieClip { // Returns a square clip and assigns parameters
			var c								:MovieClip = getSquareMovieClip(50, 50);
			if (par)							UCode.setParameters(c, par);
			return							c;
		}
		public static function getSquareSprite			(w:Number=10, h:Number=10, col:uint=0):Sprite {
			var s								:Sprite = new Sprite();
			drawSquare						(s, w, h, col);
			return							s;
		}
		public static function getSquareMovieClip		(w:Number=10, h:Number=10, col:uint=0):MovieClip {
			var c								:MovieClip = new MovieClip();
			drawSquare						(c, w, h, col);
			return							c;
		}
		public static function drawSquare				(c:*, w:Number, h:Number, col:uint):void {
			/* I have to find out which Interface implements drawable obkjects */
			c.graphics.clear						();
			c.graphics.beginFill					(col);
			c.graphics.drawRect					(0,0,w,h);
			c.graphics.endFill						();
		}
		public static function drawRectangle			(c:*, p:Rectangle, col:uint=0, andClear:Boolean=false):void {
			/* I have to find out which Interface implements drawable obkjects */
			if (andClear)						c.graphics.clear();
			c.graphics.beginFill					(col);
			c.graphics.drawRect					(p.x,p.y,p.width,p.height);
			c.graphics.endFill						();
		}
		public static function getAutoShield			():MovieClip {
			return							UCode.getInstance("PippoFlashAS3_UTY_AutoShield");
		}
		public static function getRoundClip				(par:Object=null):MovieClip { // Returns a round clip and assigns parameters
			var c								:MovieClip = UCode.getInstance("PippoFlashAS3_UTY_RoundClip");
			if (par)							UCode.setParameters(c, par);
			return							c;
		}
// BMP CACHING ///////////////////////////////////////////////////////////////////////////////////////
		public static function cacheAsBitmap(d:DisplayObject, cache:Boolean=true, hasOpaqueBackground:Boolean=false, backgroundColor:int=0):void {
			// For normal caching without matrix
			d.cacheAsBitmap = cache;
			// Using an opaque background, bitmap is cached as 16bit instead of 32 bit. Saves memory and cpu.
			if (hasOpaqueBackground) d.opaqueBackground = backgroundColor; 
		}
		static public function isCachedAsBitmap(d:DisplayObject):Boolean {
			return d.cacheAsBitmap;
		}
		public static function cacheAsBitmapMatrix(d:DisplayObject, cache:Boolean=true, scale:Number=1):void {
			// For GPU caching with matrix
			d.cacheAsBitmap = cache;
			var prop:String = "cacheAsBitmapMatrix"; // I must use prop name or this will not compile in swf for player
			try {
				if (cache && scale > 1) { // Scaling a 0 means no scalineg. Scaling at 1 means no scaling. 2 is double, 0.5 half.
					var m :Matrix = new Matrix();
					m.scale(scale, scale);
					d[prop] = m;
				}
				else {
					d[prop] = cache ? _bmpCacheMatrix : null;
				}
			}
			catch (e:Error) {
				Debug.error(_debugPrefix, "Cannot set bitmapMatrix of " + d + " Caching/uncaching to bitmap instead\n"+e);
			}
		}
		static public function cacheAsBitmapMatrixAutoDPI(d:DisplayObject, roundToTop:Boolean=false):void {
			// This calculates optimal DPI according to item scaling and proportions with stage coordinates bounds
			// roundToTop always rounds to higher int
			var w:Number = d.width / d.scaleX; // Retrieve real width of item
			var h:Number = d.height / d.scaleY; // Retrieve real height of item
			var b:Rectangle = d.getBounds(UGlobal.stage); // Retrieve bounds according to stage
			var sx:Number = b.width / w; // Horizontal scale
			var sy:Number = b.height / h; // Vertical scale
			var hs:Number = sx > sy ? sx : sy; // Find the largest scaling accoring to more stretched side
			var hsr:int = Math.ceil(hs);
			Debug.debug(_debugPrefix, "Finding optimal scaling for " + d + "real w, real h, bounds, bmpScaleX, bmpScaleY", w, h, b, sx, sy, hsr);
			//Debug.debug(_debugPrefix, "TESTIAMO LO STAGE DIMENSIONS!!! " + UGlobal.getStageRect(), UGlobal.stage.stageWidth);
			cacheAsBitmapMatrix(d, true, roundToTop ? hsr : hs);
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		public static function getSizeWithScale			(d:DisplayObject, scale:Number):Rectangle {
			// Gets a display object, and returns its size according to a scale
			return							new Rectangle(0,0,(d.width/d.scaleX)*scale,(d.height/d.scaleY)*scale);
		}
		public static function getScaleForMaxSize		(d:DisplayObject, ww:Number):Number {
			// Gets a display object and an amount in pixels, and returns the scale according to the maximum allowed size, may it be vertical or horizontal
			// I.E., to know which scale to use to have a display object of 500*1000 to maximum size 2000, (d, 2000), returns 2;
			var w:Number = d.width/d.scaleX; var h:Number = d.height/d.scaleY; var check:Number = w>h ? w : h;
			return							ww / check;
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