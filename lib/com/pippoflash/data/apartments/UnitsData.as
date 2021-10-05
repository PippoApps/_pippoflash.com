package  com.pippoflash.data.apartments
{
	import com.pippoflash.utils.*;
	import flash.display.TriangleCulling;
	import com.pippoflash.framework._PippoFlashBaseNoDisplay;
	/**
	 * All Units data. Render a list of apartments using an XML formatted for SectorLight backend.
	 * Provides search and filtering functionalities.
	 * @author Pippo Gregoretti
	 */
	public class UnitsData extends _PippoFlashBaseNoDisplay 
	{
		
		// Static
		public static const EVT_FILTER_CHANGE:String = "onUnitsFilterChange";
		private static var _instance:UnitsData;
		// Data containers
		private var _availability:XML;
		private var _units:Vector.<UnitSingleData>; // All Units data nodes
		private var _buildingIds:Vector.<String>; // Contains building IDs that are converted to numeric building ID
		// Data pointers
		private var _unitById:Object = {};
		// MARKERS
		private var _firstRenderDone:Boolean;
		// Filtering
		private var _filterAll:Boolean; // If all are visible
		private var _filterByUnitId:String; // If this exists and length > 1 we are filtering by unit ID (this removes all other filters?)
		private var _filterByBeds:int; // If over 0 is filtered - if 4 is penthouse filtered
		private var _filterByFloor:int = -1; // If over -1 is fileterd (0 is G)
		private var _filterByPriceMin:int;
		private var _filterByPriceMax:int;
		private var _filterByBlock:String;
		private var _filterByHTB:Boolean; // If only items filtered by HTB needs to be added
		private var _mixedFilterApplied:Boolean; // If price or beds is applied
		private var _filteredUnits:Vector.<UnitSingleData>; // List of visible units
		private var _filteredUnitsIndex:Vector.<uint>;
		
		static public function get instance():UnitsData {
			return _instance;
		}
		
		// FIlter uty methods
		private function resetFilterParams():void {
			Debug.debug(_debugPrefix, "Resetting all filters.");
			_filterAll = true;
			_filterByUnitId = "";
			_filterByBeds = 0;
			_filterByPriceMin = 0;
			_filterByPriceMax = 0;
			_filterByFloor = -1;
			_filteredUnits = _units;
			updatesVisibleIndexes();
			_filterByHTB = false;
			_filterByBlock = "";
		}
		
		// Execute filtering
		public function clearFilter(doNotBroadcast:Boolean=false):void {
			resetFilterParams();
			if (doNotBroadcast) return; // Do not broadcast clear filter
			broadcastFilterChanged();
		}
		
		
		public function filterByUnitId(id:String):void { // Added and changed
			resetFilterParams();
			_filterByUnitId = id;
			var units:Vector.<UnitSingleData> = new Vector.<UnitSingleData>();
			for each (var unit:UnitSingleData in _units) {
				if (unit.containsId(id)) units.push(unit);
			}
			_filteredUnits = units;
			updatesVisibleIndexes();
			broadcastFilterChanged();
		}
		
		public function filterByPrice(min:int, max:int):void {
			// Proceed filtering
			_filterByPriceMin = min;
			_filterByPriceMax = max;
			updateComplexFilter();
		}
		

		
		public function filterByBeds(beds:int):void {
			// Proceed filtering
			_filterByBeds = beds;
			updateComplexFilter();
		}
		
		
		public function filterByBlock(block:String):void {
			// Proceed filtering
			_filterByBlock = block;
			updateComplexFilter();
		}
		
		
		public function filterByFloor(floor:int):void {
			_filterByFloor = floor;
			updateComplexFilter();
		}
		
		//public function filterByHTB(filter:Boolean):void {
			//_filterByHTB = filter;
			//updateComplexFilter();
		//}
		public function toggleFilterByHTB():void { // This toggles on-off filtering by HTB
			if (hasFilterUnitId) {
				Debug.debug(_debugPrefix, "Removing filter by Unit ID.");
				clearFilter(true);
			}
			if (_filterByHTB) {
				Debug.debug(_debugPrefix, "Removing filter by HTB");
				_filterByHTB = false;
			} else {
				Debug.debug(_debugPrefix, "Adding filter by HTB");
				_filterByHTB = true;
			}
			updateComplexFilter();
		}
		
		private function updateComplexFilter():void { // This filters by price, floor and/or beds.
			Debug.debug(_debugPrefix, "Updating filter (_filterByBeds, _filterByPriceMin, _filterByPriceMax, _filterByFloor, _filterBuHTB): ", _filterByBeds, _filterByPriceMin, _filterByPriceMax, _filterByFloor, _filterByHTB);
			if (_filterByUnitId.length) resetFilterParams(); // There was a previous filter by id, remove it. 
			// Proceed filtering
			//if (!_filterByBeds && !_filterByPriceMin ) clearFilter(); // Both filters are at 0
			//else { 
				var units:Vector.<UnitSingleData> = new Vector.<UnitSingleData>();
				for each (var unit:UnitSingleData in _units) {
					if (unit.filteredBy(_filterByBeds, _filterByPriceMin, _filterByPriceMax, _filterByFloor, _filterByHTB, _filterByBlock)) {
						Debug.debug(_debugPrefix, "Added unit " + unit.id);
						units.push(unit);
					}
				}
				_filteredUnits = units;
				updatesVisibleIndexes();
			//}
		}
		
		
		private function broadcastFilterChanged():void {
			broadcastEvent(EVT_FILTER_CHANGE);
		}
		private function updatesVisibleIndexes():void {
			_filteredUnitsIndex = new Vector.<uint>(_filteredUnits.length);
			for (var i:int = 0; i < _filteredUnits.length; i++) {
				_filteredUnitsIndex[i] = _units.indexOf(_filteredUnits[i]);
			}
		}
		
		
		public function UnitsData(availability:XML) { // This is the first render
			super("UnitsData", UnitsData);
			_availability = availability;
			_instance = this;
			firstRender();
		}
		
		// METHODS
		/**
		 * Apartments are designed not to change in number if updated, but only in status.
		 * If this is called, only status of apts will update.
		 * @param	availabilty
		 */
		public function update(availabilty:XML):void { // This is on update
			clearFilter(true);
			_availability = availabilty;
			furtherRender();
		}
		
		// RENDER
		private function firstRender():void {
			if (_firstRenderDone) {
				Debug.error(_debugPrefix, "firstRender()  called again but it has been called already before!!!");
				return;
			}
			Debug.debug(_debugPrefix, "Rendering availability...");
			_firstRenderDone = true;
			// Loop in all buildings
			Debug.debug(_debugPrefix, "Processing " + _availability.building.length() + " buildings.");
			_buildingIds = new Vector.<String>();
			_units = new Vector.<UnitSingleData>();
			
			// This works when appartments are divided by building
			if (_availability.building.length()) {
				Debug.warning(_debugPrefix, "Apartments are divided by building.");
				trace("_availability", _availability.toXMLString());
				for each (var bdg:XML in _availability.building) {
					var bdgName:String = String(bdg.@name);
					var bdgId:int = _buildingIds.length;
					_buildingIds.push(bdgName);
					Debug.debug(_debugPrefix, "Processing building: " + bdgName, "id", bdgId);
					for each (var apt:XML in bdg.apartment) {
						var aptData:UnitSingleData = new UnitSingleData(apt, bdgId, bdgName);
						_units.push(aptData);
						_unitById[aptData.id] = aptData;
					}
				}
			}
			// This works when there are directly apartments in root node
			// Assumes only: apartments.apartment[]
			else {
				Debug.warning(_debugPrefix, "Apartments are NOT divided by building.");
				const defaultBdgName:String = "Main";
				_buildingIds[0] = defaultBdgName;
				for each (var apt:XML in _availability.apartment) {
					var aptData:UnitSingleData = new UnitSingleData(apt, 0, defaultBdgName);
					_units.push(aptData);
					_unitById[aptData.id] = aptData;
					trace(aptData);
				}
			}
			// Proceed
			resetFilterParams();
		}
		// UPDATE
		private function furtherRender():void {
			if (!_firstRenderDone) {
				Debug.error(_debugPrefix, "furtherRender() call can only be done after first render.");
				return;
			}
			Debug.debug(_debugPrefix, "Updating availability...");
			UnitSingleData.resetStatusesOnUpdate(); // This resets status indexing
			// Apartments divided by building
			if (_availability.building.length()) {
				Debug.warning(_debugPrefix, "Apartments are divided by building.");
				for each (var bdg:XML in _availability.building) {
					var bdgName:String = String(bdg.@name);
					var bdgId:int = _buildingIds.indexOf(bdgName);
					//_buildingIds.push(bdgName);
					Debug.debug(_debugPrefix, "Processing building: " + bdgName, "id", bdgId);
					for each (var apt:XML in bdg.apartment) {
						//trace(apt.toXMLString());
						var aptId:String = String(apt.@unitno);
						//trace("Cerco apt: " + aptId);
						//trace(Debug.object(_unitById));
						var aptData:UnitSingleData = _unitById[aptId];
						aptData.updateData(apt, true);
					}
				}
			}
			// This works when there are directly apartments in root node
			// Assumes only: apartments.apartment[]
			else {
				Debug.warning(_debugPrefix, "Apartments are NOT divided by building.");
				//const defaultBdgName:String = "Main";
				//_buildingIds[0] = defaultBdgName;
				for each (var apt:XML in _availability.apartment) {
					var aptId:String = String(apt.@unitno);
					var aptData:UnitSingleData = _unitById[aptId];
					//_units.push(aptData);
					//_unitById[aptData.id] = aptData;
					//trace(aptData);
					aptData.updateData(apt, true);
				}
			}
		}
		
		
		// CHECKS FOR FILTERS
		public function get hasFilterUnitId():Boolean {
			return _filterByUnitId.length > 0;
		}
		public function get hasFilterFloor():Boolean {
			return _filterByFloor != -1;
		}
		public function get hasFilterBed():Boolean {
			return _filterByBeds > 0;
		}
		public function get hasFilterByPrice():Boolean{
			return _filterByPriceMax > 0 && _filterByPriceMin > 0;
		}
		public function get hasFilterByHTB():Boolean {
			return _filterByHTB;
		}
		public function get hasFilterBlock():Boolean {
			return _filterByBlock.length > 0;
		}

		
		// GETTERS FOR FILTERS
		public function get units():Vector.<UnitSingleData> {
			return _units;
		}
		
		public function get filteredUnits():Vector.<UnitSingleData> {
			return _filteredUnits;
		}
				
		public function get length():int {
			return _units.length;
		}
		public function get hasFilters():Boolean {
			return _filteredUnits.length != _units.length;
		}
		
		public function get filterUnitId():String {
			return _filterByUnitId;
		}
		public function get filterFloor():int {
			return _filterByFloor;
		}
		public function get filterBeds():int {
			return _filterByBeds;
		}
		public function get filterPriceMin():int {
			return _filterByPriceMin;
		}
		public function get filterPriceMax():int {
			return _filterByPriceMax;
		}
		public function get filterBlock():String {
			return _filterByBlock;
		}
		
		
		
		
		
		public function get visibleUnitsNum():int {
			return _filteredUnits.length;
		}
		
		public function get filteredUnitsIndex():Vector.<uint> 
		{
			return _filteredUnitsIndex;
		}
		
		public function get allUnitsNum():int {
			return _units.length;
		}
	}

}