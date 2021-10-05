package com.pippoflash.framework.starling.gui.elements 
{
	import com.pippoflash.framework.starling._StarlingBase;
	import flash.geom.Rectangle;
	import starling.display.Canvas;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class _ElementBase extends _StarlingBase 
	{
		protected var _size:Rectangle;
		protected var _bgArea:Canvas;
		protected var _settings:Object;
		public function _ElementBase(size:Rectangle, id:String, cl:Class, singleton:Boolean=true) {
			super(id, cl, singleton);
			_size = size;
			_bgArea = uDisplay.getSquareCanvas(0xff0000, _size.width, _size.height);
			_bgArea.alpha = 0;
			addChild(_bgArea);
		}
		protected function renderGui(settings:Object=null):void {
			
		}
		
		
		
		protected function updateSize():void {
			_bgArea.width = _size.width;
			_bgArea.height = _size.height;
		}
		/**
		 * Injects destination with parameters from source if not defined in destination.
		 * @param	source
		 * @param	destination
		 * @return
		 */
		protected function addDefaultsToSettings(source:Object, destination:Object = null):Object {
			if (!destination) destination = {};
			for (var k:String in source) if (!destination.hasOwnProperty(k)) destination[k] = source[k];
			return destination;
		}
		protected function addExtraSettings(extraSettings:Object):void {
			for (var k:String in extraSettings) _settings[k] = extraSettings[k];
		}
		
	}

}