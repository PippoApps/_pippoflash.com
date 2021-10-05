/* UXml - ver 0.1 - Filippo Gregoretti - www.pippoflash.com
0.15 - getPathFromString(origin:DisplayObject, path:String); // Converts a string "parent.parent.clip3" into a reference.

*/

package com.pippoflash.utils {

	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.UText;
	import com.pippoflash.utils.Debug;
	
	import flash.display.*;
	import flash.events.*;
	import flash.external.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;

	
	public class UXml {
// UTILITIES ////////////////////////////////////////////////////////////////////////////
		// CONSTANTS
		private static const _debugPrefix				:String = "Uxml";
		private static const _verbose					:Boolean = false;
		// REFERENCES
		private static var _nodesReference				:Object = {}; // This stores the reference by ID to each XML node
		private static var _attributesReference			:Object = {}; // This stores nodees by attribute value (of course value must be unique or they will be overwritten)
		// UTY
		private static var _node					:XML;
		private static var _s						:String;
		private static var _o						:Object;
		private static var _xmlIdName				:String = "_pfXID";
		private static var _depth					:uint;
		private static var _formatNodes				:XML = new XML("<FORMATNODES/>"); // Stores a whole list of format nodes ADDING them to the main list
		// MARKERS
// DEPTH AND STRUCTURE ///////////////////////////////////////////////////////////////////////////////////////
		public static function getXmlDepth				(n:XML):uint {
			_depth							= 0;
			return							calculateXmlDepthRecursive(0, n);
		}
			private static function calculateXmlDepthRecursive(c:uint, n:XML):uint {
				//var d:uint = startCount;
				if (c > _depth)					_depth = c;
				if (hasChildren(n)) {
					for each (_node in n.children()) {
						calculateXmlDepthRecursive(c+1, _node);
					}
				}
				return 						_depth;
			}
		public static function setIdRecursive			(n:XML):void {
			setId								(n);
			if (hasChildren(n))					for each (_node in n.children()) setIdRecursive(_node);
		}
		public static function setIdRecursiveAndStore		(n:XML):void {
			setIdAndStore						(n);
			if (hasChildren(n))					for each (_node in n.children()) setIdRecursiveAndStore(_node);
		}
// STORE BY ATTRIBUTE CONTENT /////////////////////////////////////////////////////////////////////////////
		public static function storeByAttribute			(xml:XML, attName:String, ns:Namespace=null):void {
			if (ns)							if (hasAttribute(xml, attName, ns)) {
				// Debug.debug					(_debugPrefix, "Storo con attributo",attName,xml.@ns::[attName]);
				_attributesReference[xml.@ns::[attName]] = xml;
			}
			else								if (hasAttribute(xml, attName)) _attributesReference[xml.@[attName]] = xml;
		}
		public static function storeByAttributeRecursive	(xml:XML, attName:String, ns:Namespace=null):void {
			storeByAttribute						(xml, attName, ns);
			if (hasChildren(xml))					for each (_node in xml.children()) storeByAttributeRecursive(_node, attName, ns);
		}
		public static function getByAttribute			(attName:String):XML {
			return							_attributesReference[attName] ? _attributesReference[attName] : null;
		}
// ID MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		public static function setIdAndStore		(n:XML):void {
			_s							= hasId(n) ? getId(n) : UText.getRandomString();
			n.@[_xmlIdName]					= _s;
			_nodesReference[_s]				= n;
		}
		public static function getNode			(id:String):XML {
			return						_nodesReference[id];
		}
		public static function setId				(n:XML):void {
			n.@[_xmlIdName] 				= UText.getRandomString();
		}
		public static function getId				(n:XML):String {
			return						n.@[_xmlIdName];
		}
		public static function hasId				(n:XML):Boolean {
			return						n.@[_xmlIdName] != undefined;
		}
		public static function dispose			(n:XML):void {
			if (hasId(n))					removeReferenceRecursive(n);
			System.disposeXML				(n);
		}
		public static function removeReferenceRecursive(n):void {
			removeReference					(n);
			if (hasChildren(n))				for each (_node in n.children()) removeReferenceRecursive(_node);
		}
		public static function removeReference		(n:XML):void {
			if (hasId(n)) {
				delete					_nodesReference[n.@[_xmlIdName]];
				delete					n.@[_xmlIdName];
			}
		}
// FORMATTING - Website 1.0 ///////////////////////////////////////////////////////////////////////////////////////
		public static function addFormatNodes		(nl:XMLList):void { // This clones nodes to add them to tthe format list, unlimited nodes can be added
			for each (_node in nl) {
				_formatNodes.appendChild		(_node);
			}
			if (_verbose)					Debug.debug(_debugPrefix, "Updated format nodes:\n", _formatNodes.toXMLString());
		}
		public static function getFormatNode		(id:String):String {
			return						_formatNodes[id] ? _formatNodes[id] : new XML("<NODE><![CDATA[]]></NODE>");
		}
		public static function formatNode			(tn:*):String { // This automatically looks for a format node name in the list
			return						_formatNodes[tn.name()] != undefined ? formatTextNode(tn, _formatNodes[tn.name()][0]) : tn.@name;
		}
		public static function formatTextNode		(tn:XML, fn:XML):String { // Gets a text node and a format node and returns a string using Website 1.0 formatting
			if (fn.hasComplexContent())			return formatTextNodeAdvanced(tn, fn); // If its an advanced format nodes (with nodes)
			else							return formatTextNodeSimple(tn, fn); // If its a simple format node (just one string)
		}
			public static function formatTextNodeAdvanced(tn:XML, fn:XML):String {
				if (_verbose) {
					Debug.debug(_debugPrefix, "Setting text node ADVANCED.");
					trace(tn); trace(fn);
				}
				_s						= "";
// 				_o						= getAttributesObject(tn);
				for each (_node in fn.FORMAT) {
					if (hasAttribute(_node, "if")) { // Check if property format node is linked to exists
						if (hasFullAttribute(tn, _node.@["if"])) {
							_s += UText.insertParams(_node, getAttributesObject(tn));
						}
					}
					else					_s += UText.insertParams(_node, _o); // Insert params if "if" attribute doesnt exist
				}
				return					_s;
			}
			public static function formatTextNodeSimple(tn:XML, fn:XML):String {
				if (_verbose) {
					Debug.debug(_debugPrefix, "Setting text node SIMPLE.");
					trace(tn); trace(fn);
				}
				return					UText.insertParams(fn, getAttributesObject(tn));
			}
// GENERAL UTY ///////////////////////////////////////////////////////////////////////////////////////
		public static function hasChildren			(n:*):Boolean {
			return						Boolean(n.children().length());
		}
		public static function hasAttribute			(n:XML, id:String, ns:Namespace=null):Boolean { // Attribute exists
			return						ns ? n.@ns::[id] != undefined : n.@[id] != undefined;
		}
		public static function hasFullAttribute		(n:XML, id:String, ns:Namespace=null):Boolean { // Attribute exists and contains data
			return						ns ? n.@ns::[id] != undefined && n.@ns::[id] != "" : n.@[id] != undefined && n.@[id] != "";
		}
		public static function isTrue(n:XML, id:String):Boolean {
			return hasAttribute(n, id) && (String(n.@[id]) == "1" || String(n.@[id]) == "true");
		}
		static public function isAttributeTrue(att:Object):Boolean {
			return (String(att) == "1" || String(att) == "true");
		}
		public static function getAttributesObject	(n:XML):Object { // Converts attributes in a name/string pairs object
			var o							:Object = new Object();
			for (var i:uint=0; i<n.attributes().length(); i++) {
				o[String(n.attributes()[i].name())] = String(n.attributes()[i]);
			}
			return						o;
		}
		public static function exists				(n:*):Boolean {
			return						n != null && n != undefined;
		}
		public static function hasContent			(n:*):Boolean { // XML or XMLList, If a node has some content: <N/> = false, <N>p</N> = true;
			return						Boolean(n.toString());
		}
// LOADERS AND LOADING ///////////////////////////////////////////////////////////////////////////////////////
		public static function getXML				(s:String):XML {
			var x								:XML = new XML();
			x.ignoreWhitespace 					= true;
			x								= XML(s);
			return							x;
		}
		public static function getLoaderXML			(o, noNameSpace:Boolean=false):XML {
			var s								:String = noNameSpace ? o.getContent().split("xmlns=").join("noNameSpaceXmlns=") : o.getContent();
			return							getCleanedXML(o.getContent(), noNameSpace);
		}
		public static function getCleanedXML			(s:String, noNameSpace:Boolean=false):XML {
			return							getXML(noNameSpace ? s.split("xmlns=").join("noNameSpaceXmlns=") : s);
		}
	}
}

/* ________________________________________________________
All AS files and libraries included in the domain com.pippoflash.*
Are open.source libraries developed by Filippo Gregoretti, and are therefore not copyrightable.
They can be used in commercial projects but must be left free for re-distribution and usage.
They go with all MovieClips included in the .fla or .xfl document, in the folders:
- PippoFlash.com - Framework

- PippoFlash.com - Components
All movieclips and assets within those folders in the source flash document (fla or xfl) 
are open source anc dan be used in commercial projects, but cannot be copyrighted.
__________________________________________________________ */