/* the _BG class is extensible. It provides a bg for anything, from flat color to image to sequence of images. */


package com.pippoflash.gui.image {
	

	import com.pippoflash.utils.*;
	import com.pippoflash.motion.Animator;
	import com.pippoflash.net.ImageQueueLoader;
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	
	public class ImageSequence extends _Image {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		private static var _interval:uint = 5000;
		private static var _fadeFrames:uint = 10;
		private static var _verbose:Boolean = false;
		// SYSTEM //////////////////////////////////////////////////////////////////////////
		private var _timeout:Number;
		private var _checkTimer:Timer;
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		protected var _sequence:Array; // Sequence of urls
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
		protected var _queueLoader:ImageQueueLoader;
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		protected var _images:Array;
		// MARKERS ////////////////////////////////////////////////////////////////////////
		private var _cursor:uint;
		private var _running:Boolean = false;
		private var _elapsed:uint;
		// STATIC UTY ///////////////////////////////////////////////////////////////////////////////////////
		private static var _b:Bitmap;
		
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function ImageSequence(color:uint=0, rect:Rectangle=null) {
			super(color, rect);
			_queueLoader = new ImageQueueLoader("ImgSeq"+UText.getRandomString());
			_checkTimer = new Timer(_interval, 0);
			_checkTimer.addEventListener(TimerEvent.TIMER, checkForNext);
			_debugPrefix = "ImageSequence";
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function loadSequence(a:Array, halign:String, valign:String):void {
			_halign = halign ? halign : _halign; _valign = valign ? valign : _valign;
			// Setup alignment
			// Reset all in case its working
			reset();
			_sequence = a;
			// Start loading
			startLoadingProcess();
		}
		public override function resizeToStage():void {
			super.resizeToStage();
			for each (_b in _images) super.setupImage(_b);
		}
		public function startSequence():void {
			stopSequence();
			startSlideshow();
		}
		public function stopSequence():void {
			_checkTimer.stop();
			_running = false;
			for each (_b in _images) _b.alpha = 0;
		}
		public function reset():void {
			stopSequence();
			resetSequence();
			_elapsed = 0; _cursor = 0; _sequence = null;
		}
		public override function onResize():void {
			resizeToStage();
			for each (_b in _images) alignImage(_b);
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function resetSequence():void {
			for each (_b in _images) UDisplay.removeClip(_b);
			_images = new Array();
			_queueLoader.reset();
		}
		private function startLoadingProcess():void {
			_queueLoader.loadList(_sequence, onQueueFeedback);
		}
			public function onQueueFeedback(o:Object):void {
				if (o.isComplete()) {
					onImageLoaded(o._id, o._img);
				}
			}
			private function onImageLoaded(id:uint, img:Bitmap):void {
				_images[id] = img;
				addChild(img);
				setupImage(img);
				if (id == 0) startSlideshow();
			}
			protected override function setupImage(img:Bitmap):void {
				img.alpha = 0;
				super.setupImage(img);
			}
// SLIDESHOW ///////////////////////////////////////////////////////////////////////////////////////
		private function startSlideshow():void {
			if (_running) checkForNext();
			else {
				_running = true;
				gotoImage(0);
				_checkTimer.start();
			}
		}
		private function gotoImage(n:uint):void {
			if (_verbose) Debug.debug(_debugPrefix, "gotoImage",n);
			_cursor = n;
			_elapsed = getTimer();
			addChild(_images[_cursor]);
			Animator.fadeInTotal(_images[_cursor], _fadeFrames);
		}
		private function checkForNext(e=null):void {
			if (getTimer() - _elapsed > _interval) gotoNext();
		}
		private function gotoNext():void {
			if (_images.length < 2) return;
			var targ:uint = _cursor >= _images.length-1 ? 0 : _cursor+1;
			if (_images[targ]) gotoImage(targ);
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}