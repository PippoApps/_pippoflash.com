package com.pippoflash.framework.starling.gui.elements 
{
	import com.pippoflash.utils.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import starling.display.Image;
	import starling.display.Sprite;
	/**
	 * Loads urls and composes an image horizontally, vertically or on a grid.
	 * @author Pippo Gregoretti
	 */
	public class CompositeImageLoader extends CompositeImage 
	{
		public static const EVT_IMAGE_READY:String = "onCompositeImageReady";
		public static const EVT_SCROLL_START:String = "onScrollStart";
		public static const EVT_SCROLL:String = "onScroll";
		public static const EVT_SCROLL_END:String = "onScrollEnd";
		protected static const PAN_SCROLL_SPEED:Number = 0.1;
		protected static const TAP_SCROLL_SPEED:Number = 0.3;
		protected var _contentBox:StarlingContentBox;
		protected var _urlsToLoad:Array;
		protected var _loadingUrl:String;
		protected var _loadingUrlNum:uint;
		protected var _loadingUntilFound:Boolean; // If I am loading until a numbered image is found, or I am loading a numbered set of urls
		protected var _loadUntilFoundBaseUrl:String;
		protected var _loadUntilFoundSubKey:String = "NUM";
		private static const DEFAULT_SETTINGS:Object = {
		}
		
		public function CompositeImageLoader(size:Rectangle, id:String, cl:Class=null, settings:Object=null) {
			super(size, id, cl ? cl : CompositeImageLoader, settings); // Render gui is called here
			_contentBox = new StarlingContentBox(size);
			addChild(_contentBox);
		}
		
		// RENDERING
		override protected function renderGui(settings:Object = null):void {
			super.renderGui(settings);
			addExtraSettings(addDefaultsToSettings(DEFAULT_SETTINGS, settings));
		}
		override public function release(andDispose:Boolean = true):void {
			super.release(andDispose);
		}
		
		
		public function loadImagesUntilFound(urlBase:String, substituteKey:String="NUM", newMode:String="horizontal"):void {
			mode = newMode;
			_loadUntilFoundBaseUrl = urlBase;
			_loadingUntilFound = true;
			_loadUntilFoundSubKey = substituteKey;
			startLoadingProcess();
		}
		
		
		
		/**
		 * Renders a composite image in canvas. 
		 * @param	urls Array of urls - 
		 * @param	mode horizontal, vertical, grid
		 * @param	gridCells horizontal and vertical cells (if mode is set to grid)
		 */
		//public function renderTilesFromUrls(urls:Array, mode:String = "horizontal", gridCells:Point = null):void {
			//release();
			//_urlsToLoad = urls;
			//_mode = mode;
			//loadUrlNumber(0);
			///* GRID TO BE IMPLEMENTED */
		//}
		
		
		
		protected function startLoadingProcess():void {
			_tiles = new Vector.<starling.display.Image>();
			loadUrlNumber(0);
		}
		
		protected function loadUrlNumber(un:uint):void {
			_loadingUrlNum = un;
			_loadingUrl = _loadingUntilFound ? UText.insertParam(_loadUntilFoundBaseUrl, _loadUntilFoundSubKey, _loadingUrlNum) : _urlsToLoad[_loadingUrlNum];
			loadSingleAsset(_loadingUrl, onLoadSuccess, null, onLoadError);
		}
		protected function onLoadSuccess():void {
			if (_loadingUntilFound)  {
				_tiles[_loadingUrlNum] = getImage(getAssetTextureNameFromPath(_loadingUrl));
				loadUrlNumber(_loadingUrlNum + 1);
			}
		}
		protected function onLoadError():void {
			if (_loadingUntilFound)  {
				Debug.debug(_debugPrefix, "Loaded", _tiles.length, "images");
				completeLoadingProcess();
			}
		}
		
		
		protected function completeLoadingProcess():void {
			renderTiles(_tiles);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_IMAGE_READY, this);
		}
		
		
		
		
		
		
		
		
		//
		///**
		 //* Sets scroll 0 to 1
		 //* @param	s
		 //*/
		//public function setScrollValue(s:Number, immediate:Boolean=false, broadcast:Boolean = false):void {
			//mover.stopMotion(this);
			//setScrollPx(vertical ? _size.height * s : _size.width * s, immediate, broadcast);
		//}
		///**
		 //* Sets scroll in pixels.
		 //* @param	s
		 //*/
		//public function setScrollPx(s:Number, immediate:Boolean=false, broadcast:Boolean=false):void {
			//if (vertical) {
				//_scroll = s / _size.height;
			//} else {
				//_scroll = s / _size.width;
			//}
			//_targetPos =  s;
			//mover.stopMotion(this);
			//if (immediate) handlePos = _targetPos;
			//else mover.move(this, TAP_SCROLL_SPEED, {handlePos:_targetPos});
			//trace("SETTO SCROLL", _scroll, _targetPos);
			//if (broadcast) broadcastScroll(_scroll);
		//}
		///**
		 //* Moves scroll handle in time to a certain value. Does not change scroll value but only handle position.
		 //* @param	scrollTo 0 to 1, where to position scroll.
		 //* @param	time lenght of time required to move handle.
		 //*/
		//public function scrollInTime(scrollTo:Number, time:Number):void {
			//scrollTo = UNumber.getRanged(scrollTo, 1, 0);
			//mover.move(this, time, {handlePos:(vertical ? _size.height : _size.width)*scrollTo}, "Linear.easeOut");
		//}
		//// GET SET
		//public function get vertical():Boolean {
			//return _direction == "vertical";
		//}
		//
		//public function get handlePos():Number 
		//{
			//return _handlePos;
		//}
		///**
		 //* scroll position between 0 and 1
		 //*/
		//public function get scroll():Number 
		//{
			//return _scroll;
		//}
		//
		//public function get contentBox():StarlingContentBox 
		//{
			//return _contentBox;
		//}
		//
		//public function get mode():String 
		//{
			//return _mode;
		//}
		//
		//public function set handlePos(value:Number):void 
		//{
			//_handlePos = value;
			//if (vertical) _handle.y = _handlePos;
			//else _handle.x = _handlePos;
		//}
		//
		//// PANNING
		//private function onPanStart(c:DisplayObject):void {
			//mover.stopMotion(this);
			//setScrollPx(vertical ? c.y : c.x, true, false);
			//PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SCROLL_START, this);
			////_targetPos = _handlePos = vertical ? c.y : c.x;
		//}
		//private function onPanStop(c:DisplayObject):void {
			//PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SCROLL_END, this);
		//}
		//private function onPan_vertical(c:DisplayObject, coords:Point, force:Number, isEnd:Boolean):void {
			//_targetPos = UNumber.getRanged(_targetPos + coords.y, _size.height, 0);
		//}
		//private function onPan_horizontal(c:DisplayObject, coords:Point, force:Number, isEnd:Boolean):void {
			//_targetPos = UNumber.getRanged(_targetPos + coords.x, _size.width, 0);
			//mover.move(this, PAN_SCROLL_SPEED, {handlePos:_targetPos});
			//broadcastScroll(_targetPos / _size.width);
		//}
		//private function broadcastScroll(s:Number):void {
			//_scroll = s;
			//PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SCROLL, this);
		//}
		//
		//
		//private function onTapBg(c:DisplayObject):void {
			////trace(StarlingGesturizer.getTapGestureRelativeLocation(c));
			//setScrollPx(vertical ? StarlingGesturizer.getTapGestureRelativeLocation(c).y : StarlingGesturizer.getTapGestureRelativeLocation(c).x, false, true);
		//}
		//
		//
		
	}

}