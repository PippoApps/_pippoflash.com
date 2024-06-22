package com.pippoflash.framework.starling.app 
{
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.starling._StarlingBase;
	import com.pippoflash.utils.UGlobal;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import com.pippoflash.utils.Debug;
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 * Base class for a content section of application. These are all singleton and do not get recycled. 
	 * They can be cleaned up and released.
	 */
	public class _ContentBase extends _StarlingBase {
		//public static const EVT_INIT:String = "onContentInit"; // Content is initialized
		public static const EVT_READY:String = "onContentReady"; // Content is ready to be rendered
		public static const EVT_ACTIVE:String = "onContentActive"; // this:_ContentBase - Content is rendered and ready to be displayed
		public static const EVT_FROZEN:String = "onContentFrozen"; // Content has been deactivated and it is ready to be faded out
		public static const EVT_CLEANED:String = "onContentCleaned"; // content has been removed and it is ready to be rendered again
		static protected var _defaultRect:Rectangle;
		
		private var _status:int = 0; // 0 unborn, 1 ready to render, 2 rendered/ready, 3 active, 4 inactive/frozen
		private var _xmlData:XML;
		private var _data:Object;
		protected var _size:Rectangle;
		
		public function _ContentBase(id:String = null, cl:Class = null) {
			if (!id) id = getQualifiedClassName(this);
			if (!cl) cl = Class(getDefinitionByName(getQualifiedClassName(this)));
			_size = _defaultRect ? _defaultRect.clone() : UGlobal.getStageRectProportional();
			super(id, cl, true);
			init();
		}
		// INIT
		protected function init():void { // One time initialization
			_status = 1;
			setToReady();
		}
		
		// METHODS
		public function renderDebugXml():void { // This has to be extended
			throw new Error("renderDebugXml() must be extended in subclasses with debug xml node...");
		}
		public function renderXml(xmlData:XML, andActivate:Boolean=true):void {
			_xmlData = xmlData;
			Debug.debug(_debugPrefix, "\n"+xmlData.toXMLString());
			//if (andActivate) activate();
		}
		public function renderData(data:Object, andActivate:Boolean=true):void {
			_data = data;
			//if (andActivate) activate();
		}
		
		
		// METHODS FOR ACTIVATION
		public function activate():void { // Should tell content to start actiating BEFORE fading
			setToActive();
		}
		public function fadingIn(time:Number):void { // Tells content that it is starting to fade in (useful for mixed content using also regular display list)
			
		}
		public function fadingOut(time:Number):void { // Tells content that it is starting to fade out
			
		}
		public function deactivate():void { // Tells content to freeze before dectivating
			setToFrozen();
		}
		public function release():void { // After content disappeared this tells it to empty memory if needed
			Debug.debug(_debugPrefix, "RELEASE");
			_status = 1;
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_CLEANED, this);
		}
		
		
		// METHODS FOR MANAGEMENT
		public function pause():void {
			
		}
		public function resume():void {
			
		}
		
		
		
		
		
		// STATUS UTY
		protected function setToReady():void {
			Debug.debug(_debugPrefix, "READY");
			_status = 2;
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_READY, this);
		}
		protected function setToActive():void {
			Debug.debug(_debugPrefix, "ACTIVE");
			_status = 3;
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_ACTIVE, this);
		}
		protected function setToFrozen():void {
			Debug.debug(_debugPrefix, "FROZEN");
			_status = 4;
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_FROZEN, this);
		}
		
		
		// STATUS
		public function get isReady():Boolean {
			return _status == 1;
		}
		public function get isRendered():Boolean {
			return _status == 2;
		}
		public function get isActive():Boolean {
			return _status == 3;
		}
		public function get isFrozen():Boolean {
			return _status == 4;
		}
		
		static public function get defaultRect():Rectangle 
		{
			return _defaultRect;
		}
		
		static public function set defaultRect(value:Rectangle):void 
		{
			_defaultRect = value;
		}
		
		public function get size():Rectangle 
		{
			return _size;
		}
		
		public function get xmlData():XML 
		{
			return _xmlData;
		}
		
		public function set size(value:Rectangle):void 
		{
			_size = value;
		}
		
		
	}

}