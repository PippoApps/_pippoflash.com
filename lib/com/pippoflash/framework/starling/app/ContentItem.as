package com.pippoflash.framework.starling.app 
{
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.starling.gui.elements.MediaItem;
	import com.pippoflash.utils.Debug;
	import flash.geom.Rectangle;
	/**
	 * Content to display a single item with MediaItem. It can be video or image. No Video controls. Use extensions for item dependant controls.
	 * @author Pippo Gregoretti
	 */
	public class ContentItem extends _ContentBase 
	{
		//public static const EVT_TUNNEL_MediaItem:Class = MediaItem; // Use this to add events
		
		//public static const EVT_LOADED:String = "onMediaLoaded"; // When media has been correctly prepared (do not use this to show media, bbut just to count if media has been preloaded)
		//public static const EVT_READY:String = "onMediaReady"; // When video started playing or media is visible (and transition in started)
		//public static const EVT_ARRIVED:String = "onMediaArrived"; // When transition to appear is completed (or when instant view is active)
		//public static const EVT_LEFT:String = "onMediaLeft"; // Broadcasted when an mage has left with either hide(), fadeOut() or swipeOut();
		//public static const EVT_IMAGE_VIEWER_MOVED:String = "onImageViewerMoved"; // Image viewer has moved an image, pos object
		protected var _mediaItem:MediaItem;
		public function ContentItem(id:String="ContentItem", cl:Class=null)
		{
			//if (!cl) cl = getDefinitionByName(getQualifiedClassName(this))
			super(id, cl);
			_mediaItem = new MediaItem(null, null, null, false, id);
			addChild(_mediaItem);
			// You can register to all events to ME, and you will get events from _mediaItem
			//PippoFlashEventsMan.addInstanceEventsReBroadcaster(_mediaItem, this);
			PippoFlashEventsMan.addInstanceListener(_mediaItem, this);
		}
		
		
		override public function release():void {
			_mediaItem.cleanup();
			super.release();
		}
		
		
		override public function renderData(data:Object, andActivate:Boolean = true):void {
			// Renders data from XML formatted
		}
		override public function renderXml(xmlData:XML, andActivate:Boolean = true):void {
			// Renders XML converting it to a data object
			super.renderXml(xmlData, false);
			_mediaItem.renderXML(xmlData, _size, true);
			//_mediaItem.renderUrl();
			_mediaItem.show();
		}
		
		
		// LISTENERS TO MediaItem
		public function onMediaLoaded(c:MediaItem):void {
			//trace("_mediaItem.onMediaLoaded");
		}
		public function onMediaReady(c:MediaItem):void {
			//trace("_mediaItem.onMediaReady");
		}
		public function onMediaArrived(c:MediaItem):void {
			setToActive();
		}
		public function onMediaLeft(c:MediaItem):void {
			
		}
		public function onImageViewerMoved(c:MediaItem):void {
			
		}
		
		// LISTENERS TO VIDEO
		public function onVideoStart(c:MediaItem):void {
			Debug.debug(_debugPrefix, "onVideoStart() ",c.videoPlayed);
		}
		public function onVideoData(c:MediaItem):void {
			//trace("onVideoData");
			Debug.debug(_debugPrefix, "onVideoData() " + c.videoDuration, "played",c.videoPlayed);
		}
		public function onVideoPlaying(c:MediaItem):void {
			Debug.debug(_debugPrefix, "onVideoPlaying() " + c.videoCompletion, "played",c.videoPlayed);
		}
		public function onVideoPause(c:MediaItem):void {
			Debug.debug(_debugPrefix, "onVideoPause() " + c.videoCompletion, "played",c.videoPlayed);
		}
		public function onVideoResume(c:MediaItem):void {
			Debug.debug(_debugPrefix, "onVideoResume() " + c.videoCompletion, "played",c.videoPlayed);
		}
		public function onVideoStop(c:MediaItem):void {
			Debug.debug(_debugPrefix, "onVideoStop() " + c.videoCompletion, "played",c.videoPlayed);
		}
		public function onVideoLoop(c:MediaItem):void {
			Debug.debug(_debugPrefix, "onVideoLoop() " + c.videoCompletion, "played",c.videoPlayed);
		}
		
		
		// GET SET
		public function get mediaItem():MediaItem {
			return _mediaItem;
		}
		public function get url():String {
			return _mediaItem.url;
		}
		
	}

}