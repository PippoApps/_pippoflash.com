/* Rasterizer - manages a set of raster images to substitute movieclips in their location and size.
 */
package com.pippoflash.visual {
	import fl.motion.Source;
	import	flash.display.*; import flash.events.*; import flash.utils.*; // system
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMem; import com.pippoflash.utils.*; // PippoFlash
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	// Rasterizer ///////////////////////////////////////////////////////////////////////////////////////
	public class Rasterizer extends _PippoFlashBaseNoDisplayUMem  {
	// VARIABLES ////////////////////////////////////////////////////////////////////////////
		private var _id:String;
		// REFERENCES
		private var _data:Dictionary;
		// UTY
		// MARKERS
	// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function Rasterizer(id:String) {
			_id = id;
			super("Rasterizer-" + id);
			UMem.addClass(RasterData);
			_data = new Dictionary(true);
			Debug.debug(_debugPrefix, "Instantiated.");
		}
	// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function rasterize(source:IBitmapDrawable, maxZoomable:Number=2):void {
			if (_data[source]) _data[source].update(maxZoomable); // It was already rasterized. Let's just update.
			else createRasterData(source, maxZoomable);
		}
		public function update(source:IBitmapDrawable, maxZoomable:Number=2):void { // This performs an update and then rasterizes again
			if (_data[source]) _data[source].update(maxZoomable);
			else {
				Debug.warning(_debugPrefix, "update() fail. Source not found: ", source, source["name"] + ". Rasterizing it now...");
				rasterize(source);
			}
		}
		public function restore(source:IBitmapDrawable):void {
			if (_data[source]) {
				var d:RasterData = _data[source];
				delete _data[source];
				UMem.storeInstance(d); // Restore actions are already in UMem framework methods
			} else Debug.error(_debugPrefix, "restore() fail. Source not found: ", source, source["name"]);
		}
		public function getBitmap(source:IBitmapDrawable):Bitmap {
			if (_data[source]) return _data[source].getBitmap();
			else return null;
		}
		public function getSprite(source:IBitmapDrawable):Sprite {
			if (_data[source]) return _data[source].getSprite();
			else return null;
		}
		public function getId():String {
			return _id;
		}
	// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function createRasterData(source:IBitmapDrawable, maxZoomable:Number=2):void {
			Debug.debug(_debugPrefix, "Creating raster data for " + source, source["name"], "zoomed: "+maxZoomable);
			_data[source] = UMem.getInstance(RasterData, this, source, maxZoomable);
		}
	// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
	// public function drawWithQuality(source:IBitmapDrawable, matrix:Matrix = null, 
	// colorTransform:flash.geom:ColorTransform = null, blendMode:String = null, clipRect:Rectangle = null, smoothing:Boolean = false, quality:String = null):void
		static public function convertToBitmap(source:DisplayObject, maxZoomable:Number =1, matrix:Matrix = null, colorTrasform:ColorTransform = null, blendMode:String = null, clipRect:Rectangle = null, smoothing:Boolean = true, quality:String =StageQuality.HIGH_8X8):Bitmap { 
			// Prepare for zoomability
			var sx:Number = source.scaleX; var sy:Number = source.scaleY;
			var previousParent:DisplayObjectContainer = source.parent;
			var previousParentIndex:int = previousParent ? previousParent.getChildIndex(source) : NaN;
			var container:Sprite = new Sprite();
			container.addChild(source);
			// Reset source matrix
			var oldMatrix:Matrix = source.transform.matrix;
			source.transform.matrix = new Matrix();
			// Apply zooming
			source.scaleX *= maxZoomable; source.scaleY *= maxZoomable;
			// Adjust child in order to overcome bounds
			var bounds:Rectangle = source.getBounds(container);
			source.x += Math.abs(bounds.x);
			source.y += Math.abs(bounds.y);
			// This converts any display object into a BitmapData, with the ability to zoom by...
			var bd:BitmapData = new BitmapData(bounds.width, bounds.height, true, 0);
			bd.drawWithQuality(container, matrix, colorTrasform, blendMode, clipRect, smoothing, quality);
			//bd.drawWithQuality(container, matrix, colorTrasform, blendMode, clipRect, smoothing, quality);
			var b:Bitmap = new Bitmap(bd, PixelSnapping.ALWAYS, true);
			// Restore old matrix
			source.transform.matrix = oldMatrix;
			//
			//if (maxZoomable > 1) {
				///* BE CAREFUL - SCALING CANNOT BE APPLIED TO BITMAP JUST WHEN IT IS CREATED, BUT ON NEXT FRAME */
				//source.scaleX = b.scaleX = sx;
				//source.scaleY = b.scaleY = sy;
				//b.scaleX = sx;
				//b.scaleY = sy;
			//}
			// Nullify container
			container.removeChild(source); // Remove source from container
			container = null; // Dispose container
			// Restore source clip in it's previous parent
			if (previousParent is DisplayObjectContainer) {
				previousParent.addChildAt(source, previousParentIndex);
			}
			 //if (source.transform) b.transform = source.transform;
			return b;
		}
	}
}


// HELPER CLASSES ///////////////////////////////////////////////////////////////////////////////////////	
	import fl.transitions.Transition;
	import flash.events.*; import flash.display.*; 
	import	com.pippoflash.utils.*; import com.pippoflash.framework._PippoFlashBaseNoDisplayUMem; import com.pippoflash.visual.Rasterizer;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Transform;
	// USoundListener ///////////////////////////////////////////////////////////////////////////////////////
	class RasterData extends _PippoFlashBaseNoDisplayUMem {
	// VARIABLES ////////////////////////////////////////////////////////////////////////////
		// REFERENCES
		private var _rasterizer:Rasterizer;
		private var _container:Sprite; // This contains bitmap so that it is displaced on registration like initial clip, and it can be controlled in the same way
		private var _b:Bitmap;
		private var _source:DisplayObject; // This is the source object stored here as reference
		private var _sourceParent:DisplayObjectContainer; // Parent of source
		private var _sourceIndex:uint; // Index of source position
		private var _maxZoom:Number; // Stores the maxZoom
		private var _previousScale:Point; // Stores original scale values
		private var _renderingSeed:Number; // Stores a seed in order to make sure next frame action is followin the same sequence (and not happening in a recycled RasterData);
		private var _matrix:Matrix; // Stores the original transformation matrix
		
		// UTY
		// MARKERS
	// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function RasterData(r:Rasterizer, source:IBitmapDrawable, maxZoomable:Number=2) {
			super("RasterData_" + r.getId());
			recycle(r, source, maxZoomable);
		}
	// FRAMEWORK /////////////////////////////////////////////////////////////////////////////
		public function recycle(r:Rasterizer, source:IBitmapDrawable, maxZoomable:Number=2):void {
			_rasterizer = r;
			_source = source as DisplayObject;
			_maxZoom = maxZoomable;
			_container = new Sprite();
			activateRaster(maxZoomable);
		}
		override public function release():void { // Inverts rasterization and puts the original clip bac to its place
			restore();
			super.release();
		}
		override public function cleanup():void { // Destroys everything, and makes RasterData ready to be reused by another rasterizer
			release();
			_rasterizer = null;
			super.cleanup();
		}
	// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function update(maxZoomable:Number =2):Bitmap {
			activateRaster(maxZoomable);
			return _b;
		}
		public function getBitmap():Bitmap {
			return _b;
		}
		public function getSprite():Sprite {
			return _container;
		}
	// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function activateRaster(maxZoomable:Number=2):void {
			Debug.debug(_debugPrefix, "Activating raster for " + _source, _source.name+". WARNING - This will happen after one frame since scale and width cannot be applied to bitmap at the moment of creation.");
			// Store scaling
			_previousScale = new Point(_source.scaleX, _source.scaleY);
			// First thing find parent
			if (_source.parent) { // Source is in display lists, lets manage it's parent
				// This could set it initially, or just change parent
				_sourceParent = _source.parent;
				_sourceIndex = _sourceParent.getChildIndex(_source);
			}
			// Check if this is an update, that previous bitmap gets ready for GC
			killBitmap();
			// Prepare source and matrix to transform
			_matrix = _source.transform.matrix.clone(); // Store previous transform
			// Then rasterize the bitmap
			_b = Rasterizer.convertToBitmap(_source, maxZoomable);
			// Add bitmap to container
			_container.addChild(_b);
			// Other transformations must be applied on next frame
			_renderingSeed = Math.random();
			UExec.next(postProcessRasterNextFrame, _renderingSeed);
		}
		private function postProcessRasterNextFrame(seed:Number):void {
			if (seed != _renderingSeed) return; // Just abort if in previous frame I was destroyed. This must follow through the same call.
			// Raster done, lets apply reverse zooming
			if (_maxZoom > 1) _b.scaleX = _b.scaleY = 1 / _maxZoom;
			// Re-apply trasform to source and apply it also to container (separate)
			_container.transform.matrix = _matrix.clone();
			// now let's put it in parent if necessary
			if (_sourceParent) { // This can be retrieved or kept from before, since this could be an update
				_sourceParent.addChildAt(_container, _sourceIndex);
			}
			// Remove old clip if is still in parent
			UDisplay.removeClip(_source);
		}
		private function restore():void { // Restores source to it's original place and destroys bitmap
			_renderingSeed = NaN;
			UDisplay.removeClip(_container);
			_container = null;
			killBitmap();
			if (_source) {
				if (_sourceParent) {
					_sourceParent.addChildAt(_source, _sourceIndex);
					_sourceParent = null;
					_sourceIndex = NaN;
				}
				_source = null;
			}
		}
		private function killBitmap():void {
			if (_b) {
				UMem.killBitmap(_b);
				_b = null;
			}
		}
	}
