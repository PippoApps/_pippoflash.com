package  com.pippoflash.data.apartments
{
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class UnitSingleRoomData extends Object 
	{
		private var _room:XML;
		private var _name:String;
		private var _sqm:String;
		private var _sqft:String;
		
		
		public function UnitSingleRoomData(room:XML) 
		{
			super();
			_room = room;
			_name = String(room.@label);
			_sqm = String(room.measurementMeters);
			_sqft = String(room.measurementFeet);
		}
		public function get sqm():String 
		{
			return _sqm;
		}
		
		public function get sqft():String 
		{
			return _sqft;
		}
		
		public function get name():String 
		{
			return _name;
		}
		
		
	}

}