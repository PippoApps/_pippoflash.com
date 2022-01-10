/* DateManager - (c) Filippo Gregoretti - PippoFlash.com */
/* Description */
package com.pippoflash.string {
	import									flash.geom.*;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import 									flash.utils.*;
	import									flash.globalization.*;

	import									com.pippoflash.utils.UText;
	import									com.pippoflash.utils.Debug;
	
	public dynamic class DateManager {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		// SYSTEM
		private static const _debugPrefix				:String = "DateManager";
		public static var _allWeek					:String = "every day of the week"; // Converts "1111111" to this. (tutti i giorni, invece di lunedi e martedi)
		public static var _standardWeekDays			:Array = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
		public static var _weekDays					:Array = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
		public static var _standardMonths				:Array = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
		public static var _months					:Array = ["January","February","March","April","May","June","July","August","September","October","November","December"];
// 		public static var _months					:Array = ["Gennaio","Febbraio","Marzo","Aprile","Maggio","Giugno","Luglio","Agosto","Settembre","Ottobre","Novembre","Dicembre"];
		public static var _dummyGMT				:String = "GMT+0100";
		public static const _conversionObject			:Object = { // W, d M, ... metteri qui esempi di formatting!
			R:"dayOrReference", 
			r:"dayOrReferenceStandardMonths", 
			W:"weekDay",
			w:"standardWeekDay",
			N:"monthNumber", 
			U:"monthNumberZero", 
			M:"monthName", 
			C:"monthCodeName", // short month name
			Y:"fullYear", 
			y:"halfYear", 
			d:"day", 
			D:"dayZero", 
			h:"hour", 
			H:"hour24", 
			P:"PMAM", 
			p:"pmam", 
			m:"minute",
			s:"second"
			// I need to add american name with 1st, 2nd, 3rd, 4th
		};
		public static var _today					:Date = new Date(); // d M Y - H:m     d M Y - h:m P
		public static var _yesterday					:Date = new Date();
		private static var _now					:Date = new Date(); // Used for date conversions. Call updateNow() before getting a date string.
		private static const _monthsLength				:Array = [31,28,31,30,31,30,31,31,30,31,30,31];
		public static var _references					:Object = {_today:"Today", _tomorrow:"Tomorrow", _yesterday:"Yesterday", _dateSequence:"M d", _dateSequenceStandardMonth:"C d"}; // Name of references, or dates in substitution
		private static var _dateSequences				:Object = {DEFAULT:"w, U/C/Y - h:m P", DATE:"w, U/C/Y", TIME:"h:m P"}; // This are overwritten by config node _dateSequences
// 		public static var _references					:Object = {_today:"Oggi", _tomorrow:"Domani", _yesterday:"Ieri", _dateSequence:"d M"}; // Name of references, or dates in substitution
// 		public static var _countdowns				:Object = n;
		// LOCALE FORMATTING
		private static var _df						:DateTimeFormatter;

		// HTML VARIABLES			
		// USER VARIABLES
		// REFERENCES _references._dateSequence
		// MARKERS
		// DATA HOLDERS
		// UTY
		private static var _s						:String;
		private static var _a						:Array;
		private static var _i						:Number;
		private static var _b						:Boolean;
		private static var _o						:Object;
		private static var _counter					:uint;
		private static var _date					:Date;
		private static var _seq						:String;
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public static function init					() {
			// To be called ONCE
		}
		public static function crunchConfig				(config:XML=null):Boolean {
			/*
				This must be set in MainApp using DateManager.crunchConfig(_config.getDateManagerConfigNode());
				<DATEMANAGER>
					<_weekDays>Domenica,Lunedi,Martedi,Mercoledi,Giovedi,Venerdi,Sabato</_weekDays>
					<_today>oggi</_today>
					<_yesterday>ieri</_yesterday>
					<_tomorrow>domani</_tomorrow>
				</DATEMANAGER>
			*/
			if (!config) {
				Debug.error					(_debugPrefix, "DateManager.crunchConfig() error. DATEMANAGER node not present.");
				return						false;
			}
			if (config._weekDays)					_weekDays = config._weekDays.split(",");
			if (config._today)					_references._today = String(config._today);
			if (config._yesterday)					_references._yesterday = String(config._yesterday);
			if (config._tomorrow)					_references._tomorrow = String(config._tomorrow);
			if (config._dateSequence)				_references._dateSequence = config._dateSequence;
			if (config._dateSequences) {
				for each (var n:XML in config._dateSequences.children()) {
					Debug.debug				(_debugPrefix, "Adding sequence", n.toXMLString());
					_dateSequences[String(n.name())] = String(n);
				}
			}
			return							true;
		}
// RENDER //////////////////////////////////////////////////////////////////////////////////////////
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public static function updateNow				():void {
			_now								= new Date();
		}
		public static function getString				(id:String="DEFAULT", d:Date=null):String { // Uses an internal sequence and returns it's formatted date
			return 							convertDateToString(d ? d : _now, _dateSequences[id] ? _dateSequences[id] : _dateSequences.DEFAULT);
		}
		public static function convertDateToString		(d:Date=null, seq:String="R, h:mP"):String {
			// If I set a date it uses the set date, otherwise the _now (updatable with updateNow())
			_date								= d ? d : _now;
			_s								= "";
			_seq								= seq;
			for (_counter=0; _counter<_seq.length; _counter++) {
				DateManager["add_"+_conversionObject[_seq.charAt(_counter)]]();
			}
			return							_s;
		}
		public static function convertMilitaryStringToDate	(s:String, format:String="yyyymmddhhmmss"):Date {
			// 19710816000530
			const o:Object = {year:s.substr(0, 4), month:s.substr(4, 2), day:s.substr(6, 2), hour:s.substr(8, 2), minute:s.substr(10, 2), second:s.length == 14 ? s.substr(12, 2) : "00"};
			Debug.debug(_debugPrefix, "converting date: " + s + " : " + Debug.object(o));
			const d:Date = new Date();
			d.setFullYear(Number(o.year));
			d.setMonth(Number(o.month)-1); // Date object has months starting from 0
			d.setDate(Number(o.day));
			d.setHours(Number(o.hour), Number(o.minute), Number(o.second));
			return d;
		}
		public static function formatMilitaryDate			(s:String, seq:String):String {
			return							convertDateToString(convertMilitaryStringToDate(s), seq);
		}
// LOCALE METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public static function initLocaleDate			(dateMode:String="long", timeMode:String="long"):void { // Can also use "long", "medium", "short", "none" , "custom"
			_df								= new DateTimeFormatter(LocaleID.DEFAULT, dateMode, timeMode);
		}
		public static function convertLocaleDate			(d:Date):String {
			try {
				return						_df.format(d);					
			}
			catch (e:Error) {
				Debug.error					("called convertLocaleDate() but initLocaleDate() has not been called first!!! \n"+e);
			}
			initLocaleDate						();
			return							convertLocaleDate(d);
		}
		public static function getDateFormatter			():DateTimeFormatter {
			return							_df;
		}
		public static function removeFromLocale		(removeWhat:String):void { // Here I can remove directly the string, or a pointer. By now: weekday, ...
			var s								:String = removeWhat;
			var id							:String = removeWhat.toLowerCase();
			if (id == "weekday")					s = "E";
			else if (id == "year")					s = "y";
			Debug.debug						(_debugPrefix, "Removing from locale format " + removeWhat + " which turns into element " + s);
			var separators						:Array = [" ", "/", "\\"];
			var pattern						= _df.getDateTimePattern();
			// first find the separator
			for each (var separator:String in separators) {
				if (pattern.indexOf(separator))		break; // Found separator
			}
			// Reconstruct a new pattern without anything containing keyword
			var elements						:Array = pattern.split(separator);
			var newElements					:Array = [];
			for each (var element:String in elements) {
				if (element.indexOf(s) == -1)		newElements.push(element);
			}
			var newPattern						:String = newElements.join(separator);
			_df.setDateTimePattern				(newPattern);
		}
// CONVERTERS /////////////////////////////////////////////////////////////////////////////////////////
		private static function add_monthName			() {
			_s								+= _months[_date.month];
		}
		
		private static function add_monthCodeName		() {
			_s								+= _standardMonths[_date.month];
		}
		private static function add_monthNumber			() {
			_s								+= _date.month+1;
		}
		private static function add_monthNumberZero		() {
			_s								+= UText.checkOneZero(_date.month+1);
		}
		private static function add_standardWeekDay		() {
			_s								+= _standardWeekDays[_date.day];
		}
		private static function add_weekDay			() {
			_s								+= _weekDays[_date.day];
		}
		private static function add_day				() {
			_s								+= _date.date;
		}
		private static function add_dayZero				() {
			_s								+= UText.checkOneZero(_date.date);
		}
		private static function add_fullYear				() {
			_s								+= _date.fullYear;
		}
		private static function add_undefined			() {
			_s								+= _seq.charAt(_counter);
		}
		private static function add_hour24				() {
			_s								+= _date.hours > 9 ? _date.hours : "0" + _date.hours;
		}
		private static function add_hour				() {
			var h								:uint = (_date.hours>12?_date.hours-12:_date.hours);
			_s								+= h > 9 ? h : h == 0 ? "12" : "0" + h;
		}
		private static function add_pmam				() {
			_s								+= (_date.hours>11?"pm":"am");
		}
		private static function add_PMAM				() {
			_s								+= (_date.hours>11?"PM":"AM");
		}
		private static function add_minute				() {
			_s								+= _date.minutes > 9 ? _date.minutes : "0" + _date.minutes;
		}
		private static function add_second				() {
			_s								+= _date.seconds > 9 ? _date.seconds : "0" + _date.seconds;
		}
		private static function add_halfYear				() {
			_s								+= String(_date.fullYear).substr(2,2);
		}
		private static function add_dayOrReference		() { // This returns Today, Tomorrow, or December 23 (month + date)
			add_dayOrRefCode					(_references._dateSequence);
		}
		private static function add_dayOrReferenceStandardMonths() { // This returns Today, Tomorrow, or Jul 23 (month + date)
			add_dayOrRefCode					(_references._dateSequenceStandardMonth);
		}
		private static function add_dayOrRefCode		(code) {
			var ref							:int = getReference(_today, _date);
			if (ref == 0)						_s += _references._today;
			else if (ref == -1)					_s += _references._yesterday;
			else if (ref == 1)					_s += _references._tomorrow;
			else {
				var oldS						:String = _s;
				var oldSeq						:String = _seq;
				var oldCount					:uint = _counter;
				var txt						:String = convertDateToString(_date, code);
				_s							= oldS+txt;
				_seq							= oldSeq;
				_counter						= oldCount;
			}
		}
// UTY ////////////////////////////////////////////////////////////////////////////////////
		public static function getReference			(today:Date, d:Date):int { // This compares today with another date, and returns 0, +1 or -1. 9 is nothing. (today, tomorrow or yesterday)
// 			var thisYearDays						:uint = getJulianDays(today); 
// 			var dDays							:uint = getJulianDays(d);
			if (today.fullYear==d.fullYear && today.month==d.month && today.date==d.date) return 0; // Today
			else if (d < today)					return getYesterday(today, d);
			else 								return getTomorrow(today, d);
		}
		public static function getTomorrow				(today:Date, d:Date):int {
			if (today.fullYear==d.fullYear ) { // Check same year
				if (today.month == d.month) { // check same month
					if (d.date == (today.date+1)) 	return 1;
				}
				if (today.month == (d.month-1)) { // Check next month
					if (d.date == 1 && today.date == _monthsLength[today.month]) return 1;
				}
			}
			if (today.fullYear==d.fullYear-1) { // Check next year
				if (today.month == 11 && d.month == 0) { // check is december and date is january
					if (today.date == 31 && d.date==1) return 1; // If today is 1st and yesterday 31st
				}
			}
			return							9; // It is NOT yesterday
		}
		public static function getYesterday			(today:Date, d:Date):int {
			if (today.fullYear==d.fullYear ) { // Check same year
				if (today.month == d.month) { // check same month
					if (d.date == (today.date-1)) 	return -1;
				}
				if (today.month == (d.month+1)) { // Check previous month
					if (today.date == 1 && d.date == _monthsLength[d.month]) return -1;
				}
			}
			if (today.fullYear==d.fullYear+1) { // Check previous year
				if (today.month == 0 && d.month == 11) { // check is january and last date was december
					if (today.date == 1 && d.date==31) return -1; // If today is 1st and yesterday 31st
				}
			}
			return							9; // It is NOT yesterday
		}
		public static function getMonthLength			(d:Date):uint { // Returns the number of day for the month of the date. It calculates februaries with 29 days
			// Un anno è bisestile se il suo numero è divisibile per 4, con l'eccezione che gli anni secolari (quelli divisibili per 100) sono bisestili solo se divisibili per 400.
			// Sono cioè bisestili tutti gli anni la cui numerazione termina con le due cifre 04, 08, 12... fino a 96; gli anni che terminano con 00 sono bisestili solo se l'anno è divisibile per 400, cioè il 1600, il 2000, il 2400 eccetera.
			if (d.month == 1 && (d.fullYear%4) == 0)	return 29; // Find the february with 29 days
			else								return _monthsLength[d.month];
		}
// SPECIAL METHODS //////////////////////////////////////////////////////////////////////
// 		// CHAT CONVERT //////////////////////////////////////////////////////////////////////////////
// 		public static function convertStringToDate		(s:String, format:String="YYYYMMDDhhmm"):Date {
// 			// YYYYMMDDhhmmss - The string format decides the format of the received date
// 			// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)
// 			var pattern						:Object = {YYYY:"fullYear", MM:"month", DD:"date", hh:"hours", mm:"minutes", ss:"seconds"};
// 			var values							:Object = new Object();
// 			var d								= new Date();
// 			for (_s in pattern) {
// 				_i							= format.indexOf(_s);
// 				if (_i > -1)						values[pattern[_s]] = Number(s.substr(_i, _s.length));
// 			}
// 			values.month						-= 1; // In date object months are from 0 to 11
// 			for (_s in values) {
// 				d[_s] = values[_s];
// 			}
// 			return							d;
// 		}
// 	// POKEN ///////////////////////////////////////////////////////////////////////////////////////
// 		public static function convertPokenDate			(s:String):Date {
// 			// 2009-06-16-04:00
// 			// Sat Jul 18 20:01:34 GMT+0200 2009
// 			_s								= "Sat " + _standardMonths[uint(s.substr(4,2))-1] + " " + s.substr(6,2) + " 00:01:00 GMT+0100 " + s.substr(0,4);
// 			return							new Date(_s);
// 		}
// 	// CASABI ///////////////////////////////////////////////////////////////////////////////////////
// 		public static function getDateFromMinutes		(n:uint, dd:Date=null):Date { // Gets amountof minutes, and returns a date object (day, year do not matter. Just hours and minutes)
// 			var d								:Date = dd == null ? new Date() : dd;
// 			d.hours							= Math.floor(n/60);
// 			d.minutes							= n%60;
// 			return							d;
// 		}
// 	// DIGITALFUN ///////////////////////////////////////////////////////////////////////////////////////
// 		public static function secondsToMinutesSeconds	(secs:uint):String {
// 			var minutes						:uint = Math.floor(secs/60);
// 			var seconds						:uint = secs - (minutes*60);
// 			return							UText.checkOneZero(minutes) + ":" + UText.checkOneZero(seconds);
// 		}
	// EPOCH CONVERSION
		public static function epochToDate			(epoch:*):Date { // this can grab both a string and a uint
			return							new Date(uint(epoch)*1000);
		}
		public static function dateToEpoch				(d:Date):uint {
			return							Math.round(d.valueOf()/1000);
		}
	// WEEKDAYS CONVERSION
		public static function sequenceToWeekDays		(seq:String, allJoin:String=", ", lastJoin:String=" and ", invertSunday:Boolean=false):String { // Gets "0110001" and converts it to tuesday, monday, and friday.
			// Invert sunday moves sunday at the beginning as last
			// Convert weekdays:
			if (seq == "1111111") { // Every day of the week
				return						_allWeek;
			}
			// Found a custom sequence of weekdays
			else {
				var weekDays				:Array = seq.split("");
				var dayNames				:Array = [];
				for (var i:uint=0; i<7; i++) {
					if (weekDays[i] == "1")	dayNames.push(getWeekDay(i));
				}
				// Move sunday as last day if invertSunday == true
				if (invertSunday && weekDays[0] == "1") {
					dayNames.shift			(); // Removes sundey set as first
					dayNames.push			(getWeekDay(0)); // Add sunday as last
				}							
				// Create string
				var allDays					:String = "";
				// Just one day of the week
				if (dayNames.length == 1)		allDays = dayNames[0];
				// Just 2 days joined
				else if (dayNames.length == 2)	allDays = dayNames.join(lastJoin);
				// Longer than 2 days
				else { // Several days
					allDays				= dayNames[0];
					var day				:String;
					for (_i=1; _i<dayNames.length-1; _i++) {
						day				= dayNames[_i];
						allDays			+= allJoin + day;
					}
					allDays				+= lastJoin + day;
				}
				return					allDays;
			}
		}
// DATE COMPARISON ///////////////////////////////////////////////////////////////////////
		public static function getDaysDifference			(d1:Date, d2:Date):Number {
			return							getHoursDifference(d1, d2)/24;
		}
		public static function getHoursDifference			(d1:Date, d2:Date):Number {
			return							getMinutesDifference(d1, d2)/60;
		}
		public static function getMinutesDifference		(d1:Date, d2:Date):Number {
			return							getSecondsDifference(d1, d2)/60;
		}
		public static function getSecondsDifference		(d1:Date, d2:Date):Number {
			return							getMillisecondsDifference(d1, d2)/1000;
		}
		public static function getMillisecondsDifference		(d1, d2):Number {
			return							d1 - d2;
		}
		public static function isSameMonth				(d1:Date, d2:Date):Boolean {
			return							d1.fullYear == d2.fullYear && d1.month == d2.month;
		}
		public static function isSameDay				(d1:Date, d2:Date):Boolean {
			return							isSameMonth(d1, d2) && d1.date == d2.date;
		}
		public static function isTomorrow				(dayToCheck:Date, today:Date):Boolean {
			var dayMin							:uint = 24*60;
			var off							:uint = dayMin - ((today.getHours() * 60) + today.getMinutes());
			var limit							:uint = dayMin + off;
			var diff							:uint = Math.round(getMinutesDifference(dayToCheck, today));
			trace("OFFSET = " + off);
			trace("LIMIT = " + limit);
			trace("DIFF = " + diff);
			return							diff > off && diff < limit;
		}
// SIMPLE UTYS //////////////////////////////////////////////////////////////////////////////////////
		public static function getWeekDay			(day:uint):String { // converts num into weekday (0=sunday, 6=saturday)
			return							_weekDays[day];
		}
	}
}