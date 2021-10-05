package com.pippoflash.movieclips.loaders {
	import com.pippoflash.net.SimpleQueueLoaderObject;
	public interface ILoader {
		function setActive(a:Boolean):void;
		function isActive():Boolean;
		function setText(t:String):void;
		function setPercent(n:Number):void;
		function show(instant:Boolean=true, txt:String=""):void;
		function hide(instant:Boolean=true):void;
		function startAnim():void;
		function stopAnim():void;
		function setStageShield(shieldStage:Boolean = true):void;
		function connectToLoader(loader:SimpleQueueLoaderObject):void
	}
}