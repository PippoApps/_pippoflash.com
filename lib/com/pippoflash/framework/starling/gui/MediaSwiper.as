package com.pippoflash.framework.starling.gui
{
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.starling.PFVideoStarling;
	import com.pippoflash.framework.starling._StarlingBase;
	import com.pippoflash.utils.*;
	//import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	import starling.display.*;
	import starling.textures.Texture;
	import starling.main._MainContentBase;
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class MediaSwiper extends _StarlingBase 
	{
		
		public static const EVT_SWIPESTART:String = "onSwipeStart";
		public static const EVT_SWIPECOMPLETE:String = "onSwipeComplete";
		public static const VIDEO_TYPE:String = "mp4";
		private var _data:XMLList; // The list of data items
		private var _callback:Function; // Callback when al data is loaded
		private var _populated:Boolean;
		// COMPUTABLE CONSTANTS
		private static const SLIDE_TIME:Number = 1;
		// RENDER VARS
		private var _images:Vector.<DisplayObject>;
		private var _textures:Vector.<Texture>;
		private var _mask:Quad;
		private var _visibleImage:DisplayObject;
		private var _pfVideo:PFVideoStarling;
		private var _pfVideoImage:Image; // When a video is played, this is the image that swipes on
		// MOTION VAR
		private var _visibleStep:uint; // 0 to N
		private var _fading:Boolean;
		private var _tilesSprite:Sprite
		private var _numSteps:uint; // total number of steps
		private var _id:String; // ID of content
		
		public function MediaSwiper(id:String) { // Allows swiping of images and videos
			super("MediaSwiper_" + id, MediaSwiper, false);
			_id = id;
			_mask = new Quad(_MainContentBase.mainRect.width, _MainContentBase.mainRect.height);
			_pfVideo = new PFVideoStarling(_debugPrefix);
			addChild(_mask);
		}
		
		public function renderSlides(data:XMLList, onDataReady:Function):void {
			if (_populated) {
				release();
				UExec.next(render, data, onDataReady);
				return;
			}
			_data = data;
			_callback = onDataReady;
			_numSteps = _data.length();
			_images = new Vector.<DisplayObject>(_numSteps);
			_textures = new Vector.<Texture>(_numSteps);
			// First of all pre-load images
			var paths:Array = [];
			var tileData:XML;
			//var sourceName:String = String(_content.@pathPre) + "[NUM]" +  String(_content.@pathPost);
			for (var i:int = 0; i < _numSteps; i++) {
				tileData = _data[i];
				if (!UXml.hasAttribute(tileData, "path")) {
					var format:String = UXml.hasAttribute(tileData, "format") ? "." + String(tileData.@format) : ".png";
					tileData.@path = String(tileData.@id) + format; // This just loads images (also video thumbnail)
				}
				paths.push(ProjConfig.instance.getContentUrl(_id, String(tileData.@path)));
			}
			loadAssetsList(paths, onImagesLoadComplete);
		}
		private function onImagesLoadComplete():void {
			Debug.debug(_debugPrefix, "Loading complete.");
			var tileData:XML; var textureId:String;
			for (var i:int = 0; i < _numSteps; i++) {
				tileData = _data[i];
				textureId = getAssetTextureNameFromPath(String(tileData.@path));
				Debug.debug(_debugPrefix, "Rendering texture: " + textureId);
				_textures[i] = mainAssets.getTexture(textureId);
				var img:Image = new Image(_textures[i]);
				_images[i] = img;
				_MainContentBase.centerToRect(img);
				//img.x += (_mainRect.width * i);
				//if (img.height < _mainRect.height) img.y = _mainRect.height - img.height;
				//_tilesSprite.addChild(img);
				// Mask each image
				addChild(img);
				//addChild(m);
				//m.x = _MainContentBase.mainRect.width * i;
				//img.mask = m;
			}
			swipeTo(0, true, false);
			_callback();
			_callback = null;
		}
		public function next(immediate:Boolean = false, broadcast:Boolean=true):Boolean {
			return swipeTo(_visibleStep + 1, immediate, broadcast);
		}
		public function previous(immediate:Boolean = false, broadcast:Boolean=true):Boolean {
			return swipeTo(_visibleStep - 1, immediate, broadcast);
		}
		public function swipeTo(step:int, immediate:Boolean = false, broadcast:Boolean=true):Boolean {
			if (step < 0 || step >= _numSteps) return false;
			//trace("RENDER STEP", step);
			if (_fading) {
				mover.stopMotion(_mask);
				_visibleImage.mask = null;
				_fading = false;
			}
			_visibleImage = _images[step];
			addChild(_visibleImage);
			if (immediate) {
				_visibleImage.mask = null;
				onSwipeComplete();
			}
			else {
				_images[step].mask = _mask;
				var motion:Object = {width:_MainContentBase.mainRect.width, onComplete:onSwipeComplete};
				_mask.width = 0;
				if (step > _visibleStep) {
					_mask.x = _MainContentBase.mainRect.width;
					motion.x = 0;
				}
				//var dest:Number = (_mainRect.width * step);
				_fading = true;
				mover.move(_mask, SLIDE_TIME, motion);
			}
			_visibleStep = step;
			if (broadcast) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SWIPESTART);
			return true;
		}
		private function onSwipeComplete():void {
			// Proceed with removing old images
			Debug.debug(_debugPrefix, "Removing old image...");
			_fading = false;
			_visibleImage.mask = null;
			for each (var img:DisplayObject in _images) {
				if (img != _visibleImage) img.removeFromParent();
			}
			// Check video elements
			resetVideo();
			if (renderedIsVideo) { // This which just swiped in is a video
				_pfVideo.play(ProjConfig.instance.getContentUrl(_id, String(renderedData.@video)), onVideoIsReady, true);
			}
			// Broadcast event
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SWIPECOMPLETE);
		}
		private function onVideoIsReady(t:Texture):void {
			_pfVideoImage = new Image(t);
			uDisplay.alignAndResize(_pfVideoImage, new Rectangle(0, 0, _MainContentBase.mainRect.width, _MainContentBase.mainRect.height));
			addChild(_pfVideoImage);
			_pfVideoImage.alpha = 0;
			mover.fade(_pfVideoImage, 0.2, 1);
		}
		private function resetVideo():void {
			// Remove previous video if any
			if (_pfVideoImage) { // Previous one was a video
				_pfVideo.stopAndStore();
				_pfVideoImage.dispose();
				_pfVideoImage = null;
			}
		}
		public function get numSteps():uint 
		{
			return _numSteps;
		}
		
		public function get fading():Boolean 
		{
			return _fading;
		}
		
		public function get index():uint {
			return _visibleStep;
		}
		public function get renderedData():XML {
			return _data[_visibleStep];
		}
		public function get renderedIsVideo():Boolean {
			return UXml.hasFullAttribute(renderedData, "video");
		}
		
		public function release():void {
			resetVideo();
			_populated = false;
			_visibleStep = 0;
			_visibleStep = null;
			_data = null;
			_images = null;
			_textures = null;
		}
		public function cleanup():void { // Also removes images and unloads them freeing up resources
			for each (var img:Image in _images) {
				(img.texture as Texture).dispose();
				img.dispose();
			}
			release();
		}
	}

}