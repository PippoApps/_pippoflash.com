package com.pippoflash.framework.starling.app.manager 
{
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.starling._StarlingBase;
	import com.pippoflash.framework.starling.app.*;
	import com.pippoflash.motion.PFMover;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.UExec;
	import com.pippoflash.utils.UGlobal;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import starling.display.Canvas;
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import starling.display.DisplayObject;
	import com.pippoflash.framework.starling.gui.elements.StarlingContentBox;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.gui.ContentCompositePanel;
	import starling.textures.Texture;
	
	/**
	 * Moves and manages several instances of _ContentBase like Gallery, video, etc.
	 * Content is never visible together. One disappears the other appears.
	 * @author Pippo Gregoretti
	 */
	public class ContentManager extends _StarlingBase 
	{
		public static const EVT_CONTENT_RENDERED:String = "onManagedContentRendered"; // c:_ContentBase, when a content is rendered, BEFORE it is displayed
		public static const EVT_CONTENT_ARRIVED:String = "onManagedContentArrived"; // c:_ContentBase, when a content is fully visible
		public static const EVT_GALLERY_IMAGE_INDEX_CHANGE:String = "onGalleryImgIndexChange"; // id:String, index:int
		public static const EVT_GALLERY_IMAGE_VIEWER_MOVED:String = "onGalleryImageViewerMoved"; // id:String, index:int, pos:Object
		public static const TYPE_TO_CLASS:Object = {"gallery":ContentSwiperZoomerBalls, "mov":ContentItemVideo, "composite":ContentImageComposite};
		private static const FADE_TIME_OUT:Number = 0.2;
		private static const FADE_TIME_IN:Number = 0.5;
		
		// SYSTEM
		private var _contentArea:Rectangle;
		private var _allContent:Vector.<_ContentBase>;
		private var _typeToClass:Object; // Taken from STATIC on initialization (Allows to initialize more managers with different classes to id)
		private var _typeToInstance:Object;
		private var _mover:PFMover = new PFMover("ContentManager");
		private var _hasContent:Boolean;
		// Content motion
		private var _transitioning:String; // This can be null, o in or out
		private var _activeDataXML:XML;
		private var _activeContent:_ContentBase;
		private var _nextActiveDataXML:XML;
		//private var _nextActiveContent:_ContentBase;
		 
		
		
		
		// DEBUGU
		private var _box:StarlingContentBox;
		/**
		 * Sets a Class to handle a content type.
		 * @param	id
		 * @param	cl
		 */
		static public function setClassForType(id:String, cl:Class):void {
			Debug.debug("ContentManager", "Adding class:",id,cl);
			TYPE_TO_CLASS[id] = cl;
		}
		
		
		
		public function ContentManager(id:String="ContentManager", cl:Class=null, contentArea:Rectangle=null) {
			super(id, cl ? cl : ContentManager, false);
			_contentArea = contentArea ? contentArea : UGlobal.getStageRectProportional(true);
			_typeToClass = UCode.duplicateObject(TYPE_TO_CLASS);
			_typeToInstance = {};
			_ContentBase.defaultRect = _contentArea;
			for (var id:String in _typeToClass) {
				_typeToInstance[id] = new _typeToClass[id]();
				PippoFlashEventsMan.addInstanceListener(_typeToInstance[id], this);
				// listens to base events
		//public static const EVT_READY:String = "onContentReady"; // Content is ready to be rendered
		//public static const EVT_ACTIVE:String = "onContentActive"; // this:_ContentBase - Content is rendered and ready to be displayed
		//public static const EVT_FROZEN:String = "onContentFrozen"; // Content has been deactivated and it is ready to be faded out
		//public static const EVT_CLEANED:String = "onContentCleaned"; // content has been removed and it is ready to be rendered again
			}
			//return;
			
			
			//var xx:XML = new XML(<SLOT type="gallery">
					//<ITEM type="img" src="_assets/imgs/gallery0/media_0.jpg">
						//<en><![CDATA[Image 0 EN]]></en>
						//<ru><![CDATA[Image 0 RU]]></ru>
						//<az><![CDATA[Image 0 AZ]]></az>
					//</ITEM>
					//<ITEM type="img" src="_assets/imgs/gallery0/media_1.jpg">
						//<en><![CDATA[Image 1 EN]]></en>
						//<ru><![CDATA[Image 1 RU]]></ru>
						//<az><![CDATA[Image 1 AZ]]></az>
					//</ITEM>
					//<ITEM type="img" src="_assets/imgs/gallery0/media_2.jpg">
						//<en><![CDATA[Image 2 EN]]></en>
						//<ru><![CDATA[Image 2 RU]]></ru>
						//<az><![CDATA[Image 2 AZ]]></az>
					//</ITEM>
					//<ITEM type="img" src="_assets/imgs/gallery0/media_3.jpg">
						//<en><![CDATA[Image 3 EN]]></en>
						//<ru><![CDATA[Image 3 RU]]></ru>
						//<az><![CDATA[Image 3 AZ]]></az>
					//</ITEM>
				//</SLOT>);
				//
				//renderContentXml(xx);
			
			return;
			//_box = new StarlingContentBox(new Rectangle(0, 0, 800, 400), true);
			_box = new StarlingContentBox(_contentArea, true);
			_box.setPanX();
			addChild(_box);
			// TEST
			//var c:Image = new Image(Texture.fromBitmapData(new TestBmp2()));
			//addChild(c);
			
			
			// Build example object
			const startColor:int = 0xffffff;
			const endColor:int = 0;
			const steps:int = 300;
			const colStep:int = Math.floor(startColor/steps);
			const s:Sprite = new Sprite();
			for (var i:int = 0; i < steps; i++) 
			{
				const c:Canvas = new Canvas();
				c.beginFill(colStep * i);
				c.drawRectangle(0, 0, 100, 1000);
				c.x = 100 * i;
				s.addChild(c);
				//StarlingGesturizer.addTap(c, onTap);
			}
			
				_box.setContent(s);
		
			//StarlingGesturizer.addPan(c, onPan, true, true);
			//StarlingGesturizer.addPanStart(c, onPanStart);
			//StarlingGesturizer.addPanEnd(c, onPanEnd);
			//scale = 0.2;
			
			//var c:Image = new Image(Texture.fromBitmapData(new TestBmp()));
			//addChild(c);
			
		}
		
		
		// METHODS
		public function renderContentXml(contentXml:XML, reRenderIfSameContent:Boolean=false):void {
			if (_transitioning) {
				Debug.warning(_debugPrefix, "Rendering aborted because I am transitioning.");
				return;
			}
			const type:String = String(contentXml.@type);
			Debug.debug(_debugPrefix, type + "\n "+contentXml.toXMLString());
			if (_activeDataXML == contentXml) {
				if (!reRenderIfSameContent) {
					Debug.debug(_debugPrefix, "Same content already rendered. Rendering process stopped.");
					return;
				} else {
					Debug.debug(_debugPrefix, "Same content already rendered, but I have to render again from scratch if same content.");
				}
			}

			if (type == "loadingScreen") {
				_MainAppBase.instance.setMainLoader(true, ProjConfig.instance.getSubnodeLocaleXML(contentXml));
				var timeout:Number = Number(contentXml.@timeout);
				if (timeout > 0) UExec.time(timeout, _MainAppBase.instance.setMainLoader, false);
			} else {
				if (_typeToInstance[type]) proceedRenderingXML(contentXml);
				else Debug.error(_debugPrefix, "render aborted, cannot find type: " + type);
			}
		}
		// Generic methods for visible instance of content
		public function setGalleryIndex(index:int):void {
			if (_activeContent is ContentGallery) {
				(_activeContent as ContentGallery).setToStepAutoDirection(index);
			}
		}
		public function moveGalleryImageViewer(pos:Object):void {
			if (_activeContent is ContentGallery) {
				(_activeContent as ContentGallery).moveImageViewer(pos);
			}
		}
		public function stopMovie(url:String=null):void {
			if (_activeContent is ContentItemVideo && (!url || url == (_activeContent as ContentItemVideo).url)) {
				(_activeContent as ContentItemVideo).stopMovie();
			}
		}
		public function playMovie():void {
			if (_activeContent is ContentItemVideo) {
				(_activeContent as ContentItemVideo).playMovie();
			}
		}
		public function playMovieFrom(time:Number):void {
			if (_activeContent is ContentItemVideo) {
				(_activeContent as ContentItemVideo).playMovieFrom(time);
			}
		}
		public function scrubMovie(ratio:Number):void {
			if (_activeContent is ContentItemVideo) {
				(_activeContent as ContentItemVideo).scrubMovie(ratio);
			}
		}
		public function scrubMovieTime(time:Number):void {
			if (_activeContent is ContentItemVideo) {
				(_activeContent as ContentItemVideo).scrubMovieTime(time);
			}
		}
		public function panImageX(ratio:Number, force:Number=5):void {
			//trace("PANNING",_activeContent);
			if (_activeContent is ContentImageComposite || _activeContent is ContentCompositePanel) {
				//trace("DAJE");
				(_activeContent as ContentImageComposite).panImageX(ratio, force);
			}
		}
		public function panImageXStep(step:Number, force:Number=5):void {
			//trace("PANNING",_activeContent);
			if (_activeContent is ContentImageComposite || _activeContent is ContentCompositePanel) {
				//trace("DAJE");
				(_activeContent as ContentImageComposite).panImageXStep(step, force);
			}
		}
		
		
		// CONTENT RENDERING
		private function proceedRenderingXML(contentXml:XML):void {
			_hasContent = true;
			_nextActiveDataXML = contentXml;
			// Deactivate active content if any
			if (_activeContent) removeActiveContent();
			else renderNextContent();
		}
		
		public function resetContent():void {
			_hasContent = false;
			if (_activeContent) {
				_nextActiveDataXML = _activeDataXML = null;
				_activeContent.removeFromParent();
				_activeContent.release();
			}
		}
		
		// CONTENT SETUP FLOW, WITH LISTENERS AND PRIVATE METHODS
		
		// CONTENT LISTENERS
				//public static const EVT_READY:String = "onContentReady"; // Content is ready to be rendered
		//public static const EVT_ACTIVE:String = "onContentActive"; // this:_ContentBase - Content is rendered and ready to be displayed
		//public static const EVT_FROZEN:String = "onContentFrozen"; // Content has been deactivated and it is ready to be faded out
		//public static const EVT_CLEANED:String = "onContentCleaned"; // content has been removed and it is ready to be rendered again
		// CONTENT GOES AWAY
		private function removeActiveContent():void {
			_hasContent = Boolean(_nextActiveDataXML);
			_transitioning = "OUT";
			_activeContent.deactivate();
		}
		public function onContentFrozen(c:_ContentBase):void { // Content is frozen and is ready to go away
			fadeOutActiveContent();
		}
		private function fadeOutActiveContent():void {
			_mover.fade(_activeContent, FADE_TIME_OUT, 0, onActiveContentRemoved, null, "KILL");
		}
		private function onActiveContentRemoved():void {
			_activeContent.release();
		}
		public function onContentCleaned(c:_ContentBase):void { // Content has been cleared and is ready to be rendered again
			_activeContent = null;
			_activeDataXML = null;
			if (_nextActiveDataXML) UExec.next(renderNextContent);
		}
		
		
		
		
		// NEW CONTENT IS RENDERED
		private function renderNextContent():void {
			_hasContent = true;
			_transitioning = "IN";
			_activeDataXML = _nextActiveDataXML;
			_nextActiveDataXML = null;
			_activeContent = _typeToInstance[String(_activeDataXML.@type)];
			_activeContent.renderXml(_activeDataXML);
		}
		public function onContentActive(c:_ContentBase):void { // LISTENED FROM new content when it is rendered - Content has been rendered and is ready to show
			addChild(_activeContent);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_CONTENT_RENDERED, c);
			_activeContent.alpha = 0;
			_mover.fade(_activeContent, FADE_TIME_IN, 1, onNewContentFullyVisible);
		}
		private function onNewContentFullyVisible():void {
			_transitioning = null;
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_CONTENT_ARRIVED, _activeContent);
		}
		
		
		
		// GENERAL CONTENT LISTENERS
		// GALLERY
		public function onImgIndexChange(index):void {
			//Debug.scream(_debugPrefix, "index", _activeDataXML.toXMLString() );
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_GALLERY_IMAGE_INDEX_CHANGE, contentId,  index);
		}
		public function onImageViewerMoved(pos:Object):void {
			//Debug.scream(_debugPrefix, "moved",Debug.object(pos));
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_GALLERY_IMAGE_VIEWER_MOVED, contentId, (_activeContent as ContentGallery).currentStep, pos);
		}
		
		// CONTENT RENDER
		//private function setContent(c:_ContentBase, xmlData:XML = null):void {
			//trace(_transitioning, _activeContent, c);
			//if (_transitioning) return;
			//if (_activeContent == c) return;
			//_transitioning = true;
			//Debug.debug(_debugPrefix, "Setting content to ", c);
			//_nextActiveContent = c;
			//// Adesso è fatto per mandare via il contenuto precedente PRIMA, ma dipenderà dalle transizioni
			//if (_activeContent) _activeContent.deactivate(); // Block clicks within active content if any
			////if (xmlData) _nextActiveContent.renderXml(xmlData); // Activate new content
			////else _nextActiveContent.activate();
			//_nextActiveContent.activate();
		//}
		//// CONTENT ACTIVATION LISTENERS
		//public function onContentFrozen(c:_ContentBase):void {
			////_nextActiveContent.activate();
			////removeActiveContent();
		//}
		//public function onContentActive(c:_ContentBase):void {
			//if (c != _nextActiveContent) return; // Wrong content has been activated
			//Debug.debug(_debugPrefix, c, "is ACTIVE.");
			//if (_activeContent) UExec.next(removeActiveContent); // Remove an active content if there is already one
			//else UExec.next(showNextContent);
		//}
		//// Remove active content
		//private function removeActiveContent():void {
			//_activeContent.deactivate();
			//mover.fade(_activeContent, 0.3, 0, onActiveContentLeft);
			//_activeContent.fadingOut(0.35);
			//if (_nextActiveContent == _search) hideBlackBg(true, 0.3); // If next is search, black has to be removed BEFORE search appears
		//}
		//private function onActiveContentLeft():void {
			//_activeContent.release();
			//_activeContent.removeFromParent();
			//UExec.next(showNextContent);
		//}
		//// Show new content
		//private function showNextContent():void {
			//_nextActiveContent.alpha = 0;
			//addChild(_nextActiveContent);
			//addChild(_interface);
			//mover.fade(_nextActiveContent, 0.5, 1);
			//_nextActiveContent.fadingIn(0.55);
			//_activeContent = _nextActiveContent;
			//_nextActiveContent = null;
			//_transitioning = false;
			//if (_activeContent != _search) hideBlackBg(false, 0.5);
		//}

		
		
		// GET SET ///////////////////////////////////////////////////////////////////////////////////////
		public function isTransitioning():Boolean { // transitioning IN or OUT
			return Boolean(_transitioning);
		}
		
		// TYPE QUERY
		public function isType(type:String):Boolean {
			return _activeDataXML ? String(_activeDataXML.@type) == type : false;
		}
		public function isVideo():Boolean {
			return isType("mov");
		}
		
		
		public function get hasContent():Boolean 
		{
			return _hasContent;
		}
		
		public function get transitioning():String { // Setting transitioning in or out
			return _transitioning;
		}
				
		public function getContentInstance(id:String):_ContentBase {
			return _typeToInstance[id];
		}
		public function get contentId():String {
			return _activeDataXML ? String(_activeDataXML.@id) : null;
		}
		
		public function get typeToInstance():Object 
		{
			return _typeToInstance;
		}
		
		public function get activeDataXML():XML 
		{
			return _activeDataXML;
		}
		public function get galleryIndexShowingXML():XML {
			return _activeDataXML.ITEM[galleryIndexShowing];
		}
		
		
		public function get galleryIndexShowing():int {
			if (_activeContent is ContentGallery) return (_activeContent as ContentGallery).currentStep;
			return 0;
		}
		
		public function get activeContent():_ContentBase 
		{
			return _activeContent;
		}
		
		public function get activeContentType():String {
			return _activeDataXML ? String(_activeDataXML.@type) : "no active content set";
		}
	}

}