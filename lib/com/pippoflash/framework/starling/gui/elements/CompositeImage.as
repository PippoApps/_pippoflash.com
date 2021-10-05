package com.pippoflash.framework.starling.gui.elements 
{
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.UGlobal;
	import com.pippoflash.utils.UMem;
	import com.pippoflash.utils.UNumber;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import starling.display.Image;
	import starling.display.Sprite;
	/**
	 * Composes an image horizontally, vertically or on a grid.
	 * @author Pippo Gregoretti
	 */
	public class CompositeImage extends _ElementBase 
	{
		protected var _mode:String = "horizontal"; // Taken from settings.mode
		protected var _content:Sprite;
		protected var _tiles:Vector.<Image>;
		protected var _resize:Boolean;
		protected var _resizeOnVertical:Boolean;
		
		
		private static const DEFAULT_SETTINGS:Object = {
			mode:"horizontal" // vertical, horizontal, grid
		}
		
		public function CompositeImage(size:Rectangle, id:String, cl:Class=null, settings:Object=null) {
			super(size, id, cl ? cl : CompositeImage, false);
			//_contentBox = new StarlingContentBox(size);
			//addChild(_contentBox);
			_content = new Sprite();
			renderGui(settings);
		}
		
		// RENDERING
		override protected function renderGui(settings:Object=null):void {
			_settings = addDefaultsToSettings(DEFAULT_SETTINGS, settings);
			_mode = _settings.mode;
		}

		public function cleanup():void {
			release();
		}
		public function release(andDispose:Boolean = true):void {
			if (!_tiles) return; // Nothing rendered
			//_contentBox.release();
			for each (var img:Image in _tiles) img.removeFromParent();
			if (andDispose) for each (var img2:Image in _tiles) uMem.disposeDisplayObject(img2);
			_tiles = null;
		}
		/**
		 * Renders a composite image in canvas. 
		 * @param	urls Array of urls
		 * @param	mode horizontal, vertical, grid
		 * @param	gridCells horizontal and vertical cells (if mode is set to grid)
		 */
		public function renderTiles(tiles:Vector.<Image>, mode:String = "horizontal") {
			_tiles = tiles;
			if (horizontal) assembleHorizontal();
			/* TO BE IMPLEMENTED VERTICAL AND GRID */
		}
		
		
		protected function assembleHorizontal():void {
			for (var i:int = 0; i < _tiles.length; i++) {
				const img:Image = _tiles[i];
				_content.addChild(img);
				img.x = i ? _tiles[i - 1].x + _tiles[i - 1].width : 0;
			}
			// By now it is just vertically resized
			if (_resize) {
				if (_resizeOnVertical) {
					_content.height = _size.height;
					_content.scaleX = _content.scaleY;
				} else {
					_content.width = _size.width;
					_content.scaleY = _content.scaleX;
				}
			}
			addChild(_content);
		}
		protected function assembleVertical():void {
			
		}
		protected function assembleGrid():void {
			
		}
		 
		 
		 
		//public function renderTilesFromUrls(urls:Array, mode:String = "horizontal", gridCells:Point = null):void {
			//release();
			//_urlsToLoad = urls;
			//_mode = mode;
			//loadUrlNumber(0);
			///* GRID TO BE IMPLEMENTED */
		//}
		//
		//
		//
		//
		//
		//protected function loadUrlNumber(un:uint):void {
			//_loadingUrlNum = un;
			//loadSingleAsset(_urlsToLoad[un], onLoadSuccess, null, onLoadError);
		//}
		//protected function onLoadSuccess():void {
			//trace("SUCCESS");
		//}
		//protected function onLoadError():void {
			//trace("ERROR");
		//}
		
		
		
		
		
		//protected function createCanvas():void {
			//_tiles = new Vector.<starling.display.Image>()
		//}
		
		
		
		
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
		public function get horizontal():Boolean {
			return _mode == "horizontal";
		}
		public function get vertical():Boolean {
			return _mode == "vertical";
		}
		public function get grid():Boolean {
			return _mode == "grid";
		}
		public function get imgWidth():int {
			return _content.width;
		}
		public function get imgHeight():int {
			return _content.height;
		}
		public function get mode():String {
			return _mode;
		}
		public function get tilesNum():uint {
			return _tiles.length;
			
		}
		
		public function get content():Sprite 
		{
			return _content;
		}
		
		public function set mode(value:String):void {
			_mode = value;
		}
		
		public function set resize(value:Boolean):void 
		{
			_resize = value;
		}
		
		public function set resizeOnVertical(value:Boolean):void 
		{
			_resizeOnVertical = value;
			_resize = true;
		}
	}

}