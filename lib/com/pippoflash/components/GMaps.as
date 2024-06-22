package com.pippoflash.components {
	// GOOGLE IMPORTS
	import 											com.google.maps.Map;
	import		 									com.google.maps.LatLng;
	import		 									com.google.maps.LatLngBounds;
	import 											com.google.maps.MapEvent;
	import 											com.google.maps.MapType;
	import 											com.google.maps.InfoWindowOptions;
	import 											com.google.maps.services.ClientGeocoder;
	import 											com.google.maps.services.GeocodingEvent;
	import 											com.google.maps.services.GeocodingResponse;
	import											com.google.maps.overlays.Marker;
	import											com.google.maps.overlays.MarkerOptions;
	import											com.google.maps.MapMouseEvent;
	import											com.google.maps.controls.*;
	import											com.google.maps.services.Placemark;
	import											com.google.maps.services.Directions;
	import											com.google.maps.services.DirectionsEvent;
	import											com.google.maps.overlays.Polyline;
	// NORMAL IMPORTS
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UXml;
	import											com.pippoflash.visual.Effector;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	import com.pippoflash.utils.UDisplay;
	
	public class GMaps extends _cBase {
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="SYS - G-Maps Key", type=String, defaultValue="ABQIAAAAc9H9Gc4VOETYg10XYwjEQBT893EX66zg0gZ9kSDEC_U27CcWsRT5Hqv15inzCXlHlAVg8RvJxB8KQA")]
		public var _gmapsKey								:String = "ABQIAAAAc9H9Gc4VOETYg10XYwjEQBT893EX66zg0gZ9kSDEC_U27CcWsRT5Hqv15inzCXlHlAVg8RvJxB8KQA";
		[Inspectable 									(name="UI - Marker Icon (GMaps icon = 'default')", type=String, defaultValue="default")]
		public var _markerDefaultIcon						:String = "default";
// 		[Inspectable 									(name="1.2 - Use mouse wheel", defaultValue=true, type=Boolean)]
// 		public var _useMouseWheel							:Boolean = true;
		[Inspectable 									(name="SYS - Initial Latitude", defaultValue=51.500248, type=Number)]
		public var _initialLat								:Number = 51.500248;
		[Inspectable 									(name="SYS - Initial Longitude", defaultValue=-0.126257, type=Number)]
		public var _initialLon								:Number = -0.126257;
		[Inspectable 									(name="SYS - Initial Zoom", defaultValue=10, type=Number)]
		public var _initialZoom								:Number = 10;
		[Inspectable 									(name="UI - Has Zoom Controls", defaultValue=true, type=Boolean)]
		public var _hasZoomControls							:Boolean = true;
		[Inspectable 									(name="UI - Has Scale Viewer", defaultValue=true, type=Boolean)]
		public var _hasScaleControls							:Boolean = true;
		[Inspectable 									(name="UI - Has Type Controls", defaultValue=true, type=Boolean)]
		public var _hasTypeControls							:Boolean = true;
		[Inspectable 									(name="UI - Has Position Controls", defaultValue=true, type=Boolean)]
		public var _hasPositionControls						:Boolean = true;
		[Inspectable 									(name="UI - Has Overview Controls", defaultValue=true, type=Boolean)]
		public var _hasOverviewControls						:Boolean = true;
// 		[Inspectable 									(name="1.5 - Cover BG (shield so that content doesnt click thru)", defaultValue=true, type=Boolean)]
// 		public var _coverBg								:Boolean = true;
// 		[Inspectable 									(name="1.6 - Auto Scroll", defaultValue=false, type=Boolean)]
// 		public var _autoScroll								:Boolean = false;
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		// USER VARIABLES
		// SYSTEM GENERAL
		// SYSTEM - MAIN MAP
		private var _map									:Map = new Map();
		private var _geocoder								:ClientGeocoder;
		private var _totalBounds							:LatLngBounds;
		// SYSTEM - CONTROLS
		private var _zoomControl							:ZoomControl;
		private var _positionControl							:PositionControl;
		private var _scaleControl							:ScaleControl;
		private var _overviewControl							:OverviewMapControl;
		private var _navigationControl						:NavigationControl;
		private var _typeControl							:MapTypeControl;
		// SYSTEM - SEARCH
		private var _searchWithinMiles						:Number = 0; // If this is higher than 0, it marks search within a certain amount of miles - STORED IN METERS!!!!!
		private var _searchWithinMeters						:Number = 0;
		private var _searchType							:String; // ZIP, SINGLEMARKERDIRECTIONS....
		private var _searchCenterSpot						:Placemark; // The searched zip spot
		private var _proximityResults							:Array; // Stores a list of MARKERS which are within the proximity range
		private var _closestResult							:Marker; // Reference to the closest proximity marker (to be used in case no results are within proximity)
		public var _proximityXmlResults						:Array; // Stores a list of XML NODES as proximity result
		public var _closestXmlResult							:XML; // Stores the closest XML result
		// SYSTEM - DIRECTIONS
		private var _startMarker							:Object;
		private var _endMarker								:Object;
		private var _directions								:Directions;
		private var _polyline								= null;
		// REFERENCES
		private var _pointsById								:Object;
		private var _pointsToId							:Dictionary;
		private var _singleMarker							:Marker;
 		// MARKERS
		private var _isReady								:Boolean; // Marks when map is ready
		private var _useCustomIcon							:Boolean; // Marks if using custom icon;
		// DATA HOLDERS
		private var _pointsXml								:XML;
		// STATIC UTY
		private static var _marker							:Marker;
		private static var _latLng							:LatLng;
		private static var _latLngBounds						:LatLngBounds;
		private static var _markerOptions						:MarkerOptions;
		private static var _defaultMarkerOptionsPar				:Object;
// INIT /////////////////////////////////////////////////////////////////////////////////////////////////		
		public function GMaps								(par:Object=null) {
			super									("GMaps", par);
		}
		protected override function initialize					():void {
			super.initialize								();
			// INIT MAP
			_map.addEventListener							(MapEvent.MAP_READY, onMapReady);
			_map.key									= _gmapsKey;
			_map.setSize								(new Point(_w, _h));
			addChild									(_map);
		}
			public function onMapReady						(e:MapEvent=null):void {
				_map.setCenter							(new LatLng(_initialLat, _initialLon));
				_map.setZoom							(_initialZoom);
				// INIT GEOCODER
				_geocoder								= new ClientGeocoder();
				_geocoder.addEventListener					(GeocodingEvent.GEOCODING_SUCCESS, onGeocoderSuccess);
				_geocoder.addEventListener					(GeocodingEvent.GEOCODING_FAILURE, onGeocoderError);
				// INIT DIRECTIONS
				_directions								= new Directions();
				_directions.addEventListener					(DirectionsEvent.DIRECTIONS_SUCCESS, onDirectionsSuccess);
				_directions.addEventListener					(DirectionsEvent.DIRECTIONS_FAILURE, onDirectionsError);
				// INIT CONTROLS
				initControls								();
				// MARK READY
				_isReady								= true;
				// CHECK IF SOMEONE ALREADY ASKED FOR RENDERING BUT ITS PAUSED, SO RENDER NOW
				if (_pointsXml)							renderPointsXml();
				// Broadcast
				broadcastEvent							("onMapReady");
			}
				private function initControls					():void {
					if (_hasPositionControls) {
						_positionControl					= new PositionControl();
						_positionControl.setControlPosition		(new ControlPosition(ControlPosition.ANCHOR_TOP_LEFT, 16, 16, ControlPosition.AUTO_ALIGN_Y));
						_map.addControl					(_positionControl);
					}
					if (_hasZoomControls) {
						_zoomControl					= new ZoomControl();
						_zoomControl.setControlPosition		(new ControlPosition(ControlPosition.ANCHOR_TOP_LEFT, _hasPositionControls ? 37 : 16, _hasPositionControls ? 80 : 16, ControlPosition.AUTO_ALIGN_Y));
						_map.addControl					(_zoomControl);
					}
					if (_hasTypeControls) {
						_typeControl					= new MapTypeControl();
						_typeControl.setControlPosition		(new ControlPosition(ControlPosition.ANCHOR_TOP_RIGHT, 16, 16, ControlPosition.AUTO_ALIGN_Y));
						_map.addControl					(_typeControl);
					}
					if (_hasScaleControls) {
						_scaleControl					= new ScaleControl();
						_scaleControl.setControlPosition		(new ControlPosition(ControlPosition.ANCHOR_TOP_RIGHT, 16, _hasTypeControls ? 42 : 16, ControlPosition.AUTO_ALIGN_Y));
						_map.addControl					(_scaleControl);
					}
					if (_hasOverviewControls) {
						_overviewControl					= new OverviewMapControl();
						_overviewControl.setControlPosition	(new ControlPosition(ControlPosition.ANCHOR_BOTTOM_RIGHT, 16, 16, ControlPosition.AUTO_ALIGN_Y));
						_map.addControl					(_overviewControl);
					}
				}
// FRAMEWORK METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public override function release						():void {
			// Code to release goes here
			if (_pointsXml) { // Release points
				UXml.dispose							(_pointsXml);
				_pointsXml								= null;
			}
			removeSingleMarker							();
			resetPolyline								();
			super.release								();
		}
		public override function resize						(w:Number, h:Number):void {
			super.resize								(w, h);
			_map.setSize								(new Point(w,h));
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function centerMap							(lat:Number, lon:Number):void {
			if (_isReady)								_map.setCenter(new LatLng(lat, lon));
		}
		public function render								(xml:XML):void {
			if (isRendered())								release();
			_pointsXml									= xml;
			if (!UXml.hasFullAttribute(_pointsXml, "defaultIcon"))	_pointsXml.@defaultIcon = _markerDefaultIcon;
			_useCustomIcon								= _pointsXml.@defaultIcon.toLowerCase() != "default";
			if (_isReady)								renderPointsXml();
		}
		public function searchWithinMiles						(key:String, miles:Number, type:String="ZIP"):void {
			search									(key, type);
			_searchWithinMiles							= miles;
		}
		public function search								(key:String, type:String="ZIP"):void {
			_searchWithinMiles							= 0;
			_searchType								= type;
			_geocoder.geocode							(key);
		}
		public function showBounds							(latLngBounds:LatLngBounds):void {
			_map.setZoom								(_map.getBoundsZoomLevel(latLngBounds) - 1);
			_map.setCenter								(latLngBounds.getCenter());
		}
		public function highlightPlace							(xml:XML, h:Boolean=true):void {
			highlightMarker								(getMarkerByXML(xml), h);
		}
		public function showAll								():void { // shows all markers
			showBounds								(_totalBounds);
		}
		// SINGLE MARKER
		public function setSingleMarker						(lat:Number, lng:Number, txt:String=null):void {
			// This adds only one marker, and does nothing... it can't be managed or else... its a dirty trick set for 
			removeSingleMarker							();
			_singleMarker								= addMarker(lat, lng, txt);
		}
		public function removeSingleMarker					():void {
			// Removes the single marker
			if (_singleMarker) {
				_map.removeOverlay						(_singleMarker);
				_singleMarker							= null;
			}
		}
		// DIRECTIONS
		public function showDirectionsFromSingleMarker			(key:String):void {
			if (!_singleMarker) { // Single marker is not yet defined
				Debug.debug							(_debugPrefix, "Single marker not yet defined. Cannot render Directions.");
			}
			else {
				search								(key, "SINGLEMARKERDIRECTIONS")
			}
		}
		public function resetPolyline					():void {
			if (_polyline != null) {
				_map.removeOverlay				(_polyline);
				UDisplay.removeClip				(_polyline as MovieClip);
				_polyline						= null;
			}
		}
// DIRECTIONS UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function createDirectionsPath			(startPlace:LatLng, endPlace:LatLng):void {
			Debug.debug						(_debugPrefix, "Finding directions from",startPlace,"to",endPlace);
			_directions.loadFromWaypoints			([startPlace, endPlace]);
			resetPolyline						();
		}
		public function onDirectionsSuccess			(e:DirectionsEvent):void {
			_polyline							= _directions.createPolyline(); 
			_map.addOverlay						(_polyline);
			var bounds							= _polyline.getLatLngBounds();
			_map.setCenter						(bounds.getCenter(), _map.getBoundsZoomLevel(bounds));
			broadcastEvent						("onDirectionsOk");
		}
		public function onDirectionsError				(e:DirectionsEvent):void {
			broadcastEvent						("onDirectionsError");
		}
// ADD MARKER GENERAL UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function addMarker							(lat:Number, lng:Number, txt:String=null):Marker {
			_latLng									= new LatLng(Number(lat), Number(lng));
			_markerOptions								= new MarkerOptions();
			if (txt)									_markerOptions.tooltip = txt;
			_marker									= new Marker(_latLng, _markerOptions);
			_map.addOverlay								(_marker);
			return									_marker;
		}
// HIGHLIGHT ///////////////////////////////////////////////////////////////////////////////////////
		private function highlightMarker						(m:Marker, h:Boolean=true):void {
			if (h) {
				Effector.startBounce(m.getOptions().icon as MovieClip, 0.2);
// 				Effector.startGlow(m.getOptions().icon as MovieClip);
			}
			else {
				Effector.stopBounce(m.getOptions().icon as MovieClip, 0.2);
// 				Effector.stopGlow(m.getOptions().icon as MovieClip);
			}
// 			PFMover.slideIn							(m.getOptions().icon, {steps:6, pow:3, endPos:h ? {scaleX:1.2,scaleY:1.2} : {scaleX:1,scaleY:1}});
		}
// TRANSLATION METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function getXmlByMarker						(m:Marker):XML {
			return									UXml.getNode(_pointsToId[m]);
		}
		public function getMarkerByXML						(n:XML):Marker {
			return									getMarkerById(UXml.getId(n));
		}
			private function getMarkerById					(id:String):Marker {
				return								_pointsById[id];
			}
// RENDERINGOF POINTS ///////////////////////////////////////////////////////////////////////////////////////
			private function renderPointsXml					():void {
				UXml.setIdRecursiveAndStore				(_pointsXml);
				_pointsById								= {};
				_pointsToId							= new Dictionary();
				_totalBounds							= new LatLngBounds();
				var id								:String;
				for each (_node in _pointsXml.children()) {
					_markerOptions						= new MarkerOptions();
					_markerOptions.tooltip 					= _node;
					_markerOptions.hasShadow				= false;
					if (UXml.hasAttribute(_node, "icon"))		_markerOptions.icon = UCode.getInstance(_node.@icon);
					else if (_useCustomIcon)				_markerOptions.icon = UCode.getInstance(_pointsXml.@defaultIcon);
					_latLng							= new LatLng(Number(_node.@lat), Number(_node.@lon));
					_totalBounds.extend					(_latLng);
					_marker							= new Marker(_latLng, _markerOptions);
					_map.addOverlay						(_marker);
					_marker.addEventListener				(MapMouseEvent.ROLL_OVER, onMarkerRollOver);
					_marker.addEventListener				(MapMouseEvent.ROLL_OUT, onMarkerRollOut);
					_marker.addEventListener				(MapMouseEvent.CLICK, onMarkerClick);
					id								= UXml.getId(_node);
					_pointsById[id]						= _marker;
					_pointsToId[_marker]					= id;
				}
				showAll								();
				// Free memory
				_marker = null; _markerOptions = null; _latLng = null;
				// Complete
				complete								();
			}
				public function onMarkerRollOver				(e:MapMouseEvent):void {
					highlightMarker						(e.feature as Marker, true);
					broadcastEvent						("onMarkerRollOver", getXmlByMarker(e.feature as Marker));
				}
				public function onMarkerRollOut				(e:MapMouseEvent):void {
					highlightMarker						(e.feature as Marker, false);
					broadcastEvent						("onMarkerRollOut", getXmlByMarker(e.feature as Marker));
				}
				public function onMarkerClick					(e:MapMouseEvent):void {
					highlightMarker						(e.feature as Marker, false);
					broadcastEvent						("onMarkerPress", getXmlByMarker(e.feature as Marker));
				}
// GEOCODING ///////////////////////////////////////////////////////////////////////////////////////
		public function onGeocoderSuccess			(e:GeocodingEvent):void {
			Debug.debug						(_debugPrefix, "Found addresses:", e.response.placemarks.length);
			if (e.response.placemarks.length) { // Just one address has returned
				processGeocodingSuccess			(e);
			} else {
				onGeocoderError					(e);
			}
		}
			private function processGeocodingSuccess	(e:GeocodingEvent):void {
				if (_searchType == "SINGLEMARKERDIRECTIONS") {
					createDirectionsPath			(_singleMarker.getLatLng(), e.response.placemarks[0].point);
					return;
				}
				else if (_searchType == "ZIP") { // Center on the zip code requested (only first occurrance)
					_searchCenterSpot			= e.response.placemarks[0];
					_map.setCenter				(_searchCenterSpot.point);
				}
				// Check if a bound is required, and broadcast relevant event
				if (_searchWithinMiles) { // Return search for proximity
					createProximityResults			();
					broadcastEvent				("onProximitySearchComplete", _proximityXmlResults, _closestXmlResult);
				}
				else { // Return a simple spot search
					broadcastEvent				("onSearchComplete", _searchCenterSpot);
				}
			}
				private function createProximityResults	():void {
					// This creates a list of proximity points to the center search spot
					_searchWithinMeters			= UCode.milesToMeters(_searchWithinMiles); // Distance in gmaps is calculated in meters
					_proximityResults				= [];
					_proximityXmlResults			= [];
					_closestXmlResult			= null;
					_closestResult				= null;
					_latLngBounds				= new LatLngBounds();
					_latLngBounds.extend			(_searchCenterSpot.point);
					var distance				:Number;
					var closestDistance			:Number = 99999999999999999999; // Stores closest distance to check which is the closest spot
					// find markers within range and closest spot
					for each (_marker in _pointsById) { // Loop in all markers and find the ones close enough to be in proximity search
						_latLng				= _marker.getLatLng();
						distance				= _searchCenterSpot.point.distanceFrom(_latLng);
						if (distance < closestDistance) { // Find closest spot
							closestDistance		= distance;
							_closestResult		= _marker;
						}
						if (distance < _searchWithinMeters) { // Add results if in proximity
							_latLngBounds.extend	(_latLng);
							_proximityResults.push	(_marker);
							_proximityXmlResults.push(getXmlByMarker(_marker));
						}
					}
					Debug.debug				(_debugPrefix, "Results found within",_searchWithinMiles,"miles:",_proximityXmlResults.length);
					// Store the closest xml spot
					_closestXmlResult			= getXmlByMarker(_closestResult);
					// Center map on bounds if results do exist
					if (_proximityXmlResults.length) { // Results do exist, center on results + search spot
						showBounds			(_latLngBounds);
					}	
					else { // No results found within range, just show search spot plus closest result
						_latLngBounds.extend		(_closestResult.getLatLng());
						showBounds			(_latLngBounds);
					}
				}
		public function onGeocoderError				(e:GeocodingEvent):void {
			broadcastEvent						("onSearchError");
		}
		
// LISTENERS /////////////////////////////////////////////////////////////////////////////////////
	} // CLOSE CLASS ///////////////////////////////////////////////////////////////////////////////
}