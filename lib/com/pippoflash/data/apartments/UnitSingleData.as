package  com.pippoflash.data.apartments
{
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.UText;
	/**
	 * Data element for single unit.
	 * @author Pippo Gregoretti
	 */
	public class UnitSingleData extends Object 
	{
		// Create vectors with lists. This is horrible, I need to set a maximum value since I can't use push
		private static const FORMATTED_PRICE_SYMBOL:String = "€";
		private static const BEDS_FOR_PENTHOUSE:int = 4; // Penthouse has 3 beds, but if number of beds is 4, I am looking for a penthouse
		private static const APT_NAME_PREFIX:String = "UNIT "; // Unit ID is added at the end
		private static const FLOOR_PREFIX:String = ""; // Floor is added
		private static const FLOOR_POSTFIX:String = " FLOOR";
		private static const FLOOR_NAME_FOR_LIST:Array = ["Ground", "First", "Second", "Third", "Fourth", "Fifth"];
		private static const TYPE_PREFIX:String = ""; // Type is added
		private static const UNAVAILABLE_PRICE_SHOWS_IN_SEARCH:Boolean = false; // When price is unavailable unit never shows up in search
		private static var _unitsStatuses:Vector.<String> = new Vector.<String>(); // Stores status name to ID number. this uses push no need for a max number.
		private static var _unitsByBeds:Vector.<Vector.<UnitSingleData>> = new Vector.<Vector.<UnitSingleData>>(10);
		private static var _unitsByPrice:Vector.<Vector.<UnitSingleData>> = new Vector.<Vector.<UnitSingleData>>(9999999);
		private static var _unitsByFloor:Vector.<Vector.<UnitSingleData>> = new Vector.<Vector.<UnitSingleData>>(100);
		private static var _unitsByStatus:Vector.<Vector.<UnitSingleData>> = new Vector.<Vector.<UnitSingleData>>(100);
		static private var _lowestPrice:int = 99999999; // this has o be high since it marks the lowest price
		static private var _highestPrice:int = 0; // This has to be low since it marks the lowest price
		
		private static const FLOOR_CONV = {Ground:0, First:1, Second:2, Third:3};
		private static const BEDS_CONV = {"1 Bedroom":1, "2 Bedroom":2, "3 Bedroom":3, "4 Bedroom":4, "3 Bedroom Duplex":5};
		
		
		
		private var _unit:XML;
		private var _id:String;
		private var _building:int;
		private var _beds:int;
		private var _floor:int;
		private var _status:String;
		private var _statusId:int;
		private var _price:uint;
		private var _rooms:Vector.<UnitSingleRoomData>;
		private var _totalMt:String;
		private var _totalFt:String;
		private var _formattedPrice:String;
		private var _formattedFloor:String;
		private var _formattedName:String;
		private var _formattedBeds:String;
		private var _label:String;
		private var _type:String;
		private var _buildingName:String;
		private var _htb:Boolean;
		private var _unavailablePrice:Boolean; // This means price is written as UNAVAILABLE
		private var _isPenthouse:Boolean;
		
		
		
		// System
		private var _infoString:String;
		private static const INFO_VALUES:Array = ["buildingName", "id", "floor", "beds", "price", "status", "label", "type", "formattedPrice", "formattedName", "formattedFloor"];
		
		static public function resetStatusesOnUpdate():void {
			_unitsByStatus = new Vector.<Vector.<UnitSingleData>>(100);
		}
		
		public function toString():String {
			return _infoString;
		}
		private function updateInfoString():void {
			_infoString = "";
			for each (var value:String in INFO_VALUES) {
				_infoString += value + ":" + this[value] + ", ";
			}
		}
		
		
		
		public function UnitSingleData(u:XML, buildingId:int, buildingName:String) {
			super();
			_building = buildingId;
			_buildingName = buildingName;
			_id = String(u.@unitno);
			_floor = FLOOR_CONV[String(u.floor)];
			_beds = BEDS_CONV[String(u.beds)];
			_price = int(u.price);
			_status = String(u.status);
			_totalMt = String(u.measurementMetersTotal);
			_totalFt = String(u.measurementFeetTotal);
			_label = String(u.label).toUpperCase();
			_type = TYPE_PREFIX + String(u.type);
			_formattedPrice = FORMATTED_PRICE_SYMBOL + UText.formatMoney(_price);
			_formattedName = APT_NAME_PREFIX + _id;
			_formattedFloor = FLOOR_PREFIX + String(u.floor) + FLOOR_POSTFIX;
			_formattedBeds = String(u.beds);
			_isPenthouse = UCode.isTrue(String(u.penthouse));
			// Stup gorupiung
			if (!_unitsByPrice[_price]) _unitsByPrice[_price] = new Vector.<UnitSingleData>();
			if (!_unitsByBeds[_beds]) _unitsByBeds[_beds] = new Vector.<UnitSingleData>();
			if (!_unitsByFloor[_floor]) _unitsByFloor[_floor] = new Vector.<UnitSingleData>();
			// Add rooms
			//trace(" ADDING ROOMS");
			_rooms = new Vector.<UnitSingleRoomData>();
			for each (var r:XML in u.rooms.room) _rooms.push(new UnitSingleRoomData(r));
			// Add to goruping
			_unitsByBeds[_beds].push(this);
			_unitsByPrice[_price].push(this);
			_unitsByFloor[_floor].push(this);
			updateStatus(u);
			if (_price < _lowestPrice) _lowestPrice = _price;
			if (_price > _highestPrice) _highestPrice = _price;
			//Debug.debug("UnitSingleData", "Processed apt " + _id);
			_htb = UCode.isTrue(String(u.help2buy).toLowerCase());
			//_htb = Math.random() > 0.5; /* RANDOMIZE HTB */
			//trace("Block: " + _buildingName + ", apt: " + _id + ", file: '" + _buildingName+ "/" + _id + "_floorplan.jpg', is HTB:" + _htb);
			// Check for override price
			var op:String = String(u.overridePrice);
			if (op.length) {
				Debug.warning("Unit " + _id, "Unit has price overridden: " + op);
				_unavailablePrice = true;
				_formattedPrice = op;
			}
			updateInfoString();
		}
		
		
		
		
		
		public function updateData(u:XML):void {
			_unit = u;
			updateStatus(u);
			updatePrice(u);
			updateInfoString();
		}
		
		
		
		public function updateStatus(u:XML):void {
			// remove from old status
			if (_unitsByStatus[_statusId] && _unitsByStatus[_statusId].indexOf(this) != -1) {
				_unitsByStatus[_statusId].splice(_unitsByStatus[_statusId].indexOf(this), 1);
			}
			// Create new status group index id if it doesn't exist
			if (_unitsStatuses.indexOf(_status) == -1) _unitsStatuses.push(_status);
			// Grab status index ID
			_statusId = _unitsStatuses.indexOf(_status);
			// Create new status group if it is a new status
			if (!_unitsByStatus[_statusId]) _unitsByStatus[_statusId] = new Vector.<UnitSingleData>();
			// Add data item to status group
			_unitsByStatus[_statusId].push(this);
			// Update status name
			_status = String(u.status);
		}
		private function updatePrice(u:XML):void {
			// Remove from units by price
			if (_unitsByPrice[_price].indexOf(this) != -1) _unitsByPrice[_price].splice(_unitsByPrice[_price].indexOf(this), 1);
			_price = int(u.price);
			_unitsByPrice[_price].push(this);
			_formattedPrice = FORMATTED_PRICE_SYMBOL + UText.formatMoney(_price);
			if (_price < _lowestPrice) _lowestPrice = _price;
			if (_price > _highestPrice) _highestPrice = _price;
			var op:String = String(u.overridePrice);
			if (op.length) {
				Debug.warning("Unit " + _id, "Unit has price overridden: " + op);
				_unavailablePrice = true;
				_formattedPrice = op;
			}
		}
        //<apartment unitno="101">
            //<status>Available</status>
            //<floor>3</floor>
            //<beds>1</beds>
            //<price>1000000</price>
            //<measurementMetersTotal>67.92 sq m</measurementMetersTotal>
            //<measurementFeetTotal>731.09 sq ft</measurementFeetTotal>
            //<rooms>
                //<room label="Kitchen/Living/Dining">
                    //<measurementMeters>2.20m x 3.07m</measurementMeters>
                    //<measurementFeet>7&#39;3&#39;&#39; x 10&#39;1&#39;&#39;</measurementFeet>
                //</room>
                //<room label="Master Bedroom">
                    //<measurementMeters>5.85m x 4.86m</measurementMeters>
                    //<measurementFeet>19&#39;2&#39;&#39; x 15&#39;11&#39;&#39;</measurementFeet>
                //</room>
                //<room label="Bedroom 2">
                    //<measurementMeters>5.85m x 4.86m</measurementMeters>
                    //<measurementFeet>19&#39;1&#39;&#39; x 15&#39;5&#39;&#39;</measurementFeet>
                //</room>
            //</rooms>
		
		public function set unit(value:XML):void {
			_unit = value;
			// Setting up unit
			
		}
		// Filter checks
		public function containsId(id:String):Boolean {
			return _id.indexOf(id) != -1;
		}
		public function filteredBy(beds:int, min:int, max:int, floor:int, htb:Boolean, block:String):Boolean {
			// If 0 means no filter
			//if (beds  || (min && max) || floor != -1)
			//trace("CAZZO",hasBeds(beds) , isFloor(floor) , isPrice(min, max));
			
			return hasBeds(beds) && isFloor(floor) && isPrice(min, max) && isBlock(block) && (htb == false || htb == _htb); // Check for HTB only if HTB is true
			// return true; // No filter has been applied
		}
		public function hasBeds(beds:int):Boolean {
			if (beds == 0) return true; // No beds filtering
			else if (beds == BEDS_FOR_PENTHOUSE && _isPenthouse) { // I am looking for a penthouse. If this is a penthouse I return true.
				return true;
			}
			else return beds == _beds;
		}
		public function isEqualPrice(equalPrice:int):Boolean {
			if (equalPrice == 0) return true; // No equalPrice filtering
			else return _price == equalPrice;
		}
		public function isPrice(min:int, max:int):Boolean {
			if (min == 0) return true; // No min/max filtering
			else if (_unavailablePrice) return false; // There is min/max filtering, but price is unavailable
			else return _price >= min && _price <=max;
		}
		public function isHTB():Boolean {
			return _htb;
		}
		public function isFloor(floor:int):Boolean	 {
			//trace("FILTRO FLOOR:",floor,_floor == floor);
			if (floor == -1) {
				//trace("FRREGNA");
				return true; // No floor filtering
			}
			else return _floor == floor;
		}
		public function isBlock(block:String):Boolean {
			return _buildingName.indexOf(block) != -1;
		}
		
		
		// GETTERS
		public function get unit():XML {
			return _unit;
		}
		public function get building():int {
			return _building;
		}
		public function get beds():int {
			return _beds;
		}
		public function get floor():int {
			return _floor;
		}
		public function get status():String {
			return _status;
		}
		public function get id():String 
		{
			return _id;
		}
		
		public function get rooms():Vector.<UnitSingleRoomData> {
			return _rooms;
		}
		
		public function get totalMt():String 
		{
			return _totalMt;
		}
		
		public function get totalFt():String 
		{
			return _totalFt;
		}
		
		public function get formattedPrice():String 
		{
			return _formattedPrice;
		}
		
		public function get formattedFloor():String 
		{
			return _formattedFloor;
		}
		
		public function get formattedName():String 
		{
			return _formattedName;
		}
		
		static public function get lowestPrice():int 
		{
			return _lowestPrice;
		}
		
		static public function get highestPrice():int 
		{
			return _highestPrice;
		}
		
		public function get label():String 
		{
			return _label;
		}
		
		public function get type():String 
		{
			return _type;
		}
		
		public function get buildingName():String 
		{
			return _buildingName;
		}
		
		public function get formattedBeds():String 
		{
			return _formattedBeds;
		}
		public function get formattedBedsForList():String 
		{
			return _beds == 5 ? "3 Bed Dup" : _formattedBeds.substr(0, 5);
		}
		public function get formattedFloorForList():String 
		{
			return FLOOR_NAME_FOR_LIST[_floor];
		}
		
		public function get price():uint 
		{
			return _price;
		}
		
		
	}

}