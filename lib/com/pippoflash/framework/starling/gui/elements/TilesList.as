package com.pippoflash.framework.starling.gui.elements 
{
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import flash.geom.Rectangle;
	import com.pippoflash.framework.starling.gui.parts.Tile;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import com.pippoflash.utils.*;
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class TilesList extends _ElementBase 
	{
		public static const EVT_TAP:String = "onTapTile"; // tile
		public static const LAYOUT_HORIZONTAL:String = "H"; // tiles layout horizontally, limit is vertical
		public static const LAYOUT_VERTICAL:String = "V"; // Tiles layout vertically, limit is horizontal
		public static const LAYOUT_GRID:String = "G"; // Limit is the entire rectangle
		
		protected var _layout:String = "V";
		//protected var _size:Rectangle;
		protected var _allTiles:Vector.<Tile>;
		protected var _visibleTiles:Vector.<Tile>;
		//protected var _content:Sprite;
		protected var _tileSize:Rectangle;
		protected var _tileSelector:Sprite;
		protected var _bg:Canvas;
		
		protected var _tilesData:XMLList;
		
		protected var _tappedTileIndex:int = -1;
		
		
		
		
		public function TilesList(id:String, cl:Class=null, singleton:Boolean=true) {
			super(new Rectangle(), id, cl ? cl : TilesList, singleton);
			//_content = new Sprite();
			StarlingGesturizer.addTap(this, onTap);
			_bg = uDisplay.getSquareCanvas(0xff0000, 100, 100);
			_bg.alpha = 0;
			addChild(_bg);
		}
		
		// METHODS - SETUP
		public function setupTileSize(tileSize:Rectangle):void {
			_tileSize = tileSize;
		}
		public function setupSelector(selector:Sprite):void {
			_tileSelector = selector;
		}
		public function setupTiles(tiles:Vector.<Tile>, showTiles:Boolean = true):void {
			Debug.warning(_debugPrefix, tiles);
			_allTiles = tiles;
			if (!_tileSize) _tileSize = new Rectangle(0, 0, tiles[0].width, tiles[0].height);
			if (showTiles) showAllTiles();
		}
		// METHODS - DISPLAY
		public function showAllTiles():void {
			displayTiles(_allTiles);
		}
		public function filterTiles(display:Vector.<uint>):void {
			var tiles:Vector.<Tile> = new Vector.<Tile>(display.length);
			for (var i:int = 0; i < display.length; i++) {
				tiles[i] = _allTiles[display[i]];
			}
			displayTiles(tiles);
		}
		public function setSelected(index:int =-1):void {
			_tappedTileIndex = index;
			if (index == -1) {
				if (_tileSelector) _tileSelector.removeFromParent();
			}
			else {
				Debug.debug(_debugPrefix, "Tapped index: " + _tappedTileIndex);
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_TAP, _visibleTiles[_tappedTileIndex]);
				updateSelector();
			}
		}
		public function setTileSelected(tile:Tile):void {
			if (_visibleTiles.indexOf(tile) != -1) setSelected(_visibleTiles.indexOf(tile));
			else Debug.error(_debugPrefix, "setTileSelected() error. Tile is not in list of visible tiles.");
		}
		
		
		// UTY
		private function displayTiles(tiles:Vector.<Tile>, andResetSelection:Boolean = true):void {
			if (_visibleTiles) for each (var tile:Tile in _visibleTiles) removeChild(tile);
			_visibleTiles = tiles;
			_bg.width = _bg.height = 10;
			this["renderTiles_" + _layout]();
			if (_layout == LAYOUT_VERTICAL) {
				_bg.width = _tileSize.width;
				_bg.height = _tileSize.height * _visibleTiles.length;
			}
			if (andResetSelection) setSelected(-1);
			else setSelected(_tappedTileIndex);
		}
		private function renderTiles_V():void {
			var tile:Tile;
			for (var i:int = 0; i < _visibleTiles.length; i++) {
				tile = _visibleTiles[i];
				tile.y = _tileSize.height * i;
				addChild(tile);
			}
		}
		private function updateSelector():void {
			if (_tileSelector) {
				if (layoutVertical) {
					_tileSelector.y = _tileSize.height * _tappedTileIndex;
				}
				addChildAt(_tileSelector, 0);
				_tileSelector.alpha = 0;
				mover.fade(_tileSelector, 0.2, 1);
			}
		}
		
		
		// LISTENERS
		private function onTap(myself:TilesList):void {
			const p = StarlingGesturizer.getTapGestureRelativeLocation(myself);
			var index:int;
			if (_layout == LAYOUT_VERTICAL) {
				index = Math.floor(p.y / _tileSize.height);
			}
			if (index == _tappedTileIndex) {
				Debug.debug(_debugPrefix, "Tile already selected.");
				return;
			}
			setSelected(index);
		}
		
		
		
		public function get tappedTileIndex():int 
		{
			return _tappedTileIndex;
		}
		public function get tileIsSelected():Boolean {
			return _tappedTileIndex != -1;
		}
		public function get layoutVertical():Boolean {
			return _layout == LAYOUT_VERTICAL;
		}
		
	}

}