/* HelpMan - (c) Filippo Gregoretti - PippoFlash.com */
/* Converts PippoFlash Help xml files in navigable flash html format */

package com.pippoflash.string {
	import									flash.geom.*;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import 									flash.utils.*;
	import									com.adobe.serialization.json.JSON;
	import									com.pippoflash.utils.UText;
	import									com.pippoflash.utils.UCode;
	import									com.pippoflash.utils.Debug;
	import									com.pippoflash.utils.UXml;
	import									com.pippoflash.net.QuickLoader;
	import									com.pippoflash.net.SimpleQueueLoaderObject;
	import									com.pippoflash.framework._PippoFlashBase;
	
	public dynamic class PFHtmlMan extends _PippoFlashBase {
// VARIABLES //////////////////////////////////////////////////////////////////////////
	// CONSTANST
		private static const HTML_FILE_NAME		:String = "index.xml";
		private static const IMAGE_PATH_WILDCARD	:String = "PATH"; // This will be substituted in loaed file wih original file folder
		private static const DEFAULT_FORMATS		:Object = {
			INDEXTITLE:"<br/><li><b><font size='16' color='#bb0000'>[CONTENT]</font></b></li>", // The INDEXTITLE node
			PAGELINK:"<b><font size='12' color='#bb0000'><a href='[LINK]'>\t\t<u>[CONTENT]</u></a></font></b><br/>", // The attribute indexText of a PAGE
			TITLE:"<b><font size='21' color='#bb0000'>[CONTENT]</font></b><br/><br/>", // The TITLE of a page
			TEXT:"<p><font size='13' color='#000000'>[CONTENT]</font></p></b><br/>", // The simple block of text in a page
			SUBTITLE:"<b><font size='16' color='#bb0000'>[CONTENT]</font></b><br/>" // The SUBTITLE in a page, or title of another paragraph
		};
	// FORMATTERS
	// SYSTEM
		private var _fileUrl						:String;
		private var _fileFolder					:String;
		private var _imgsFolder					:String;
		private var _fileString					:String;
		private var _fileXml						:XML;
		private var _loaded						:Boolean;
		private var _textParams					:Object; // Parameters to be sent with UText
		private var _textField						:TextField; // Directly controllable textfield
		private var _formats						:Object;
		private var _waitForProcessedText			:Boolean = false; // I cna set this to true with setWaitForText(); - this will trigger an event and wait for processTextFile();
	// CONTENT
		private var _homePage					:String;
		private var _renderedPage					:String;
		private var _renderedSection				:String;
		private var _renderedNode					:XML;
		private var _pagesById					:Object;
		private var _hasBack						:Boolean; // If it is possible to go back
	// Format
		private var _prefix						:String = ""; // this will be set before text
		private var _postfix						:String = ""; // this will be set after text
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function PFHtmlMan				(id:String=null, indexUrl:String=null):void {
			super							(id ? id : "PFHtmlMan_"+UText.getRandomString(4));
			if (indexUrl)						loadFile(indexUrl);
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function loadHelpInFolder			(folder:String):SimpleQueueLoaderObject {
			return							loadFile(folder + HTML_FILE_NAME);
		}
		public function loadFile					(indexUrl:String):SimpleQueueLoaderObject {
			_fileUrl							= indexUrl;
			var fileName						= _fileUrl.substr(_fileUrl.length-HTML_FILE_NAME.length);
			if (fileName != HTML_FILE_NAME) {
				broadcastEvent					("onHtmlManError", "WrongFileName", "The loaded path "+_fileUrl+" is invalid. File sould be called "+HTML_FILE_NAME);
				return						null;
			}
			_fileFolder							= _fileUrl.substr(0, _fileUrl.length-HTML_FILE_NAME.length);
			_imgsFolder						= _fileFolder.split("\\").join("/") + "imgs/";
			_textParams						= {PATH:_imgsFolder}
			Debug.debug						(_debugPrefix, "Loading file",HTML_FILE_NAME,"in folder",_fileFolder);
			return							QuickLoader.loadFile(_fileUrl, this, "File");
		}
		public function setTextField				(t:TextField):void {
			_textField							= t;
			_textField.addEventListener			(TextEvent.LINK, onTextFieldLinkEvent);
		}
		public function setFormats				(o:Object):void {
			_formats							= o;
		}
		public function isNotReady				():Boolean {
			return							!_loaded;
		}
		public function setWaitForText				(w:Boolean):void {
			_waitForProcessedText				= w;
		}
		public function setPrefixAndPostfix			(pre:String="", post:String=""):void {
			_prefix							= pre;
			_postfix							= post;
		}
	// NAVIGATION
		public function home					():String { // Renders home page
			if (isNotReady())					return null;
			// Proceed rendering home page
			Debug.debug						(_debugPrefix, "Rendering HOME PAGE");
			return							renderPageHtml(_fileXml);
		}
		public function renderSection				(id:String):String {
			if (isNotReady())					return null;
			return							renderPageHtml(_pagesById[id]);
// 			var page							:XML = _pagesById[id];
// 			if (!page) {
// 				broadcastEvent					("onHtmlManError", "PageNotFound", "The page id",id,"was not found.");
// 				return						null;
// 			}
// 			var txt							:String = renderPage(page);
// 			renderTextField						(txt);
// 			return							txt;
		}
		public function back						():Boolean {
			if (hasBack()) {
				renderPageHtml					(_renderedNode.parent());
				return						true;
			}
			return							false;
		}
				private function renderPageHtml	(page:XML=null):String {
					if (!page) {
						broadcastEvent			("onHtmlManError", "PageNotFound", "The page id was not found.");
						return				null;
					}
					var txt					:String = renderPage(page);
					renderTextField				(txt);
					return					txt;
				}
	// UTY
		public function hasBack					():Boolean {
			return							_hasBack;
		}
		public function getRenderedSection			():String {
			return							_renderedSection;
		}
		public function renderTextField				(s:String):Boolean {
			if (_textField) {
				_textField.htmlText 				= _prefix + s + _postfix;
				UText.scrollToTop				(_textField);
			}
			return							Boolean(_textField);
		}
		public function getUrl					():String {
			return							_fileUrl;
		}
		public function processText				(t:String):void {
			_fileString							= t;
			doProcessText						();
		}
// RENDER //////////////////////////////////////////////////////////////////////////////////////////
		private function doProcessText				():void {
			// I try to cleanup all double ends of line
			var ends							:Array = _fileString.split("\r\n");
			_fileString							= ends.join("\n");
			var ends							:Array = _fileString.split("\n\r");
			_fileString							= ends.join("\n");
			try {
				XML.ignoreWhitespace			= true;
				_fileXml						= new XML(_fileString);
			} catch (e) {
				broadcastEvent					("onHtmlManError", "XmlNotValid", "The loaded path "+_fileUrl+" cannot be parsed as XML file.");
				Debug.error					(_debugPrefix, "Cannot parse XML help file:",e);
				return;
			}
			Debug.debug						(_debugPrefix, "Loaded: ",_fileXml.toXMLString());
			parseLoadedXmlFile					();
		}
		private function parseLoadedXmlFile			():void {
			// Seup formats
			if (!_formats)						_formats = UCode.duplicateObject(DEFAULT_FORMATS); // If it is not defined at all just copy the default ones
			else { // Make sure just defaults are set
				UCode.setDefaults				(_formats, DEFAULT_FORMATS);
			}
			_loaded							= true;
			_pagesById						= {};
			processSections						(_fileXml);
			renderHome						();
			broadcastEvent						("onHtmlManFileLoaded", this);
			home							();
		}
				private function processSections	(page:XML):void { // Recursively processes all nodes looking for PAGE nodes and storing them
					var counter				:uint = 0;
					for each (var node:* in page.children()) {
						if (node.name() == "PAGE") {
							if (!UXml.hasAttribute(node, "id")) node.@id = node.name() + "_" + UText.getRandomString(4);
							_pagesById[node.@id] = node;
							counter			++;
							if (node.children().length()) processSections(node);
						}
					}
					Debug.debug				(_debugPrefix, "Processed",counter,"pages in",page.name(),page.@id);
				}
				private function renderHome		():void {
					_homePage				= renderPage(_fileXml);
					trace(_homePage);
				}
		private function renderPage				(page:XML):String {
			_renderedNode						= page;
			_renderedSection					= page.@id;
			var p							:String = "";
			for each (var node:* in page.children()) {
				p							+= convertPageEntry(node);
			}
			_hasBack							= page != _fileXml; // If I can go back or not
			broadcastEvent						("onHtmlManPageRendered", _renderedSection);
			return							_prefix + p + _postfix;
		}
				private function convertPageEntry	(n:XML):String {
					var txt					:String = this["convert_"+n.name()] ? this["convert_"+n.name()](n) : convertGenericNode(n);
					if (UXml.hasFullAttribute(n, "onClick")) txt = UText.link(txt, "event:"+n.@onClick, true);
					return					txt;
				}
					private function convert_PAGE	(n:XML):String { // Special converion for PAGE nodes
						var o				:Object = {CONTENT:n.@indexText, LINK:"event:onPageIndexClick|"+n.@id};
						return				UText.insertParams(_formats.PAGELINK, o);
					}
					private function convertGenericNode(n:XML):String { // converts genericlly a node using it's own node name
						var o				:Object = {CONTENT:String(n)};
						return				UText.insertParams(_formats[n.name()], o);
					}
// SPECIAL METHODS //////////////////////////////////////////////////////////////////////
// DATE COMPARISON ///////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onLoadCompleteFile			(o:SimpleQueueLoaderObject):void {
			_fileString							= UText.insertParams(String(o.getContent()), _textParams);
			// Check if text has to be processed externally or if I can go directly (this is used to change keywords)
			if (_waitForProcessedText)			broadcastEvent("onHtmlManTextWaiting", _fileString);
			else								doProcessText();
		}
		public function onLoadErrorFile				(o:SimpleQueueLoaderObject):void {
			broadcastEvent						("onHtmlManError", "FileNotFound", "File not found: "+_fileUrl);
		}
		public function onTextFieldLinkEvent			(e:TextEvent):void {
			var fullLink						:String = e.text;
			Debug.debug						(_debugPrefix, "Received click event:",fullLink);
			var splitted						:Array = fullLink.split("|");
			var event							:String = splitted[0];
			var params						:String = splitted[1];
			if (event == "onPageIndexClick") { // I am following a click to go and see a page
				renderSection					(params);
			}
			else {
				broadcastEvent					("onHtmlManClick", fullLink);
			}
		}
	}
}