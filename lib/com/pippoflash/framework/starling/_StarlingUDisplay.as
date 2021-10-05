package com.pippoflash.framework.starling 
{
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UNumber;
	import starling.display.Canvas;
	import starling.display.DisplayObjectContainer;
	import starling.display.DisplayObject;
	import starling.display.Quad;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class _StarlingUDisplay extends _StarlingBase 
	{
		
		static public const RESIZE_FILL:String = "FILL";
		static public const RESIZE_FILLINSIDE:String = "FILLINSIDE";
		static public const RESIZE_INSIDE:String = "INSIDE";
		static public const RESIZE_STRETCH:String = "STRETCH";
		public static const VALIGN_TOP:String = "TOP";
		public static const VALIGN_BOTTOM:String = "BOTTOM";
		public static const VALIGN_MIDDLE:String = "MIDDLE";
		public static const HALIGN_LEFT:String = "LEFT";
		public static const HALIGN_CENTER:String = "CENTER";
		public static const HALIGN_RIGHT:String = "RIGHT";
		
		public function _StarlingUDisplay() {
			super("SystemUDisplay", _StarlingUDisplay, true);
			
		}
		
		
		
		// Center and resize
		/**
		 * Resizes a display object to another displayobject or a rectangle.
		 * @param	c	to be resized
		 * @param	sizer	size source, anything with height and width
		 * @param	mode	FILL to cover the entire area, FILLINSIDE to make sure it fits inside covering as much as possible, INSIDE reduce only if is larger but untouched if smaller, STRETCH stretch it to the same size
		 */
		public function resizeTo(c:DisplayObject, sizer:Object, mode:String="FILL"):void {
			if (mode == RESIZE_FILL) {
				c.width = sizer.width;
				c.scaleY = c.scaleX;
				if (c.height < sizer.height) { // If it is smaller
					c.height = sizer.height;
					c.scaleX = c.scaleY;
				}
			}
			else if (mode == RESIZE_FILLINSIDE) {
				c.width = sizer.width;
				c.scaleY = c.scaleX;
				if (c.height > sizer.height) { // If it is larger
					c.height = sizer.height;
					c.scaleX = c.scaleY;
				}
			}
			else if (mode == RESIZE_INSIDE) {
				if (c.width > sizer.width || c.height > sizer.height) {
					c.width = sizer.width;
					c.scaleY = c.scaleX;
					if (c.height > sizer.height) { // If it is larger
						c.height = sizer.height;
						c.scaleX = c.scaleY;
					}
				}
			}
			else { // Stretch
				c.width = sizer.width;
				c.height = sizer.height;
			}
		}
		/**
		 * Aligns a display object to any other item with x,y,width and height (rectangle, display object, etc.)
		 * @param	c
		 * @param	sizer
		 * @param	h	_StarlingUDisplay.HALIGN_...
		 * @param	v	_StarlingUDisplay.VALIGN_...
		 */
		public function alignTo(c:DisplayObject, sizer:Object, h:String = "CENTER", v:String = "MIDDLE"):void {
			c.x = sizer.x; c.y = sizer.y;
			if (h == HALIGN_CENTER) c.x = (sizer.width - c.width) / 2;
			else if (h == HALIGN_RIGHT) c.x = sizer.width - c.width;
			else c.x = 0;
			if (v == VALIGN_MIDDLE) c.y = (sizer.height - c.height) / 2;
			else if (v == VALIGN_BOTTOM) c.y = sizer.height - c.height;
			else c.y = 0;
		}
		/**
		 * Positions a display object
		 * @param	c
		 * @param	pos Any object with x and y properties
		 */
		public function positionTo(c:DisplayObject, pos:*):void {
			c.x = pos.x; c.y = pos.y;
		}
		/**
		 * Resizes and aligns. 
		 * @param	c	to be resized
		 * @param	sizer	size source, anything with x, y, height and width
		 * @param	mode	FILL to cover the entire area, INSIDE to make sure it is smaller and fits inside, STRETCH to just make it the same size
		 * @param	h	C, L or R
		 * @param	v	M, T, B
		 */
		public function alignAndResize(c:DisplayObject, sizer:Object, mode:String="FILL", h:String = "CENTER", v:String = "MIDDLE"):void {
			resizeTo(c, sizer, mode);
			alignTo(c, sizer, h, v);
		}
		/**
		 * Center an element to itsellf (x = -width/2 etc)
		 * @param	c
		 */
		public function centerToItself(c:DisplayObject):void {
			c.x = -c.width / 2;
			c.y = -c.height / 2;
		}
		
		/**
		 * 
		 * @param	c
		 * @param	sizer
		 * @param	h
		 * @param	v
		 * @param	inside
		 * @return	The Quad applied as mask
		 */
		public function maskAlignResize(c:DisplayObject, sizer:Object, h:String = "CENTER", v:String = "MIDDLE", inside:Boolean=true):Quad {
			resizeTo(c, sizer, "FILL"); // First of all resize image to fill all sizer side
			var q:Quad = new Quad(sizer.width, sizer.height); // Create the mask
			// Check what kind of masking has to be applied in order to position mask correctly inside image
			if (inside) { // Masking is done inside object, therefore mask has to be moved, not object
				(c as DisplayObjectContainer).addChild(q);
				if (c.width > q.width) { // Mask has to be moved horizontally
					if (h == HALIGN_RIGHT) { // Alignment is right
						q.x = c.width - q.width;
					} else if (h == HALIGN_CENTER) { // Alignment is centered
						q.x = (c.width - q.width)/2;
					}
				}
				else if (c.height > q.height) { // Mask has to be moved vertically
					if (v == VALIGN_BOTTOM) { // Alignment is bottom
						q.y= c.height - q.height;
					} else if (v == VALIGN_MIDDLE) { // Alignment is centered in the vertical middle
						q.y = (c.height - q.height)/2;
					}
				}
				c.mask = q;
			}
			else { // Masking is done outside object in parent, therefore mask has to be positioned and content must be moved, not mask
				c.parent.addChild(q);
				q.x = sizer.x;
				q.y = sizer.y;
				if (c.width > q.width) { // Mask has to be moved horizontally
					c.y = q.y; // Height is the same, just position accordingly
					if (h == HALIGN_RIGHT) { // Alignment is right
						c.x = q.x - (c.width - q.width);
					} else if (h == HALIGN_CENTER) { // Alignment is centered
						c.x = q.x - (c.width - q.width)/2;
					}
				}
				else if (c.height > q.height) { // Mask has to be moved vertically
					c.x = q.x; // Width is the same, just position accordingly
					if (v == VALIGN_BOTTOM) { // Alignment is bottom
						c.y = q.y - (c.height - q.height);
					} else if (v == VALIGN_MIDDLE) { // Alignment is centered in the vertical middle
						c.y = q.y - (c.height - q.height)/2;
					}
				}
				c.mask = q;
			}
			return q;
		}
		
		// Work with positionings
		public function getDisplayObjectProperties(c:DisplayObject, rotation:Boolean=false):Object {
			var o:Object = {x:c.x, y:c.y, width:c.width, height:c.height};
			if (rotation) o.rotation = c.rotation;
			return o;
		}
		public function setDisplayObjectProperties(c:DisplayObject, o:Object, rotation:Boolean=false):void {
			// o can be an ibject or a display object. Anything with x, y, width, height (rotation)
			c.x = o.x; c.y = o.y; c.width = o.width; c.height = o.height;
			if (rotation) c.rotation = o.rotation;
		}
		
		
		// Common visual tasks
		public function getSquareCanvas(col:uint=0x000000, w:Number=10, h:Number=10):Canvas{
			var c:Canvas = new Canvas();
			c.beginFill(col);
			c.drawRectangle(0, 0, w, h);
			c.endFill();
			return c;
		}
		/**
		 * Returns a canvas with a circle drawn. Coordinates are relative to circle centre.
		 * @param	col
		 * @param	diameter
		 * @return
		 */
		public function getRoundCanvas(col:uint=0x000000, diameter:Number=10, x:Number=0, y:Number=0):Canvas{
			var c:Canvas = new Canvas();
			c.beginFill(col);
			c.drawCircle(x, y, diameter / 2);
			c.endFill();
			return c;
		}
		// Add or remove from parent
		public function addOrRemove(child:DisplayObject, container:DisplayObjectContainer, add:Boolean):void {
			if (!child) return; // So this can be used also with non-existing elements
			if (add) container.addChild(child);
			else child.removeFromParent();
		}
		
		
		
		
		// UTILITIES
		public function validateResizeMode(mode:String):String {
			return mode == RESIZE_FILL || mode == RESIZE_FILLINSIDE || mode == RESIZE_INSIDE || mode == RESIZE_STRETCH ? mode : RESIZE_FILL;
		}
		/**
		 * Lists all displayobject properties.
		 * @param	reference to DisplayObject
		 * @param	id of DisplayObject for trace
		 */
		public function listDisplayObjectProperties(c:DisplayObject, id:String = "DisplayObject"):void {
			Debug.debug("_StarlingUDisplay", "Properties of " + id + " - ", "x:"+c.x, "y:"+c.y, "width:"+c.width, "height:"+c.height, "scaleX:"+c.scaleX, "scaleY:"+c.scaleY, "rotation (in degrees):"+UNumber.radiansToAngle(c.rotation));
		}
		
	}

}