/* CardsDeck - (c) Filippo Gregoretti - www.pippoflash.com
*/

package com.pippoflash.components {
	
	import com.pippoflash.components._cBase;
	import com.pippoflash.utils.*;
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	
	public class CardsDeck extends _cBase{
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="UI - Class for Card Graphics", type=String, defaultValue="PippoFlash_CardDeck_FR_Card")]
		public var _classNameCard							:String = "PippoFlash_CardDeck_FR_Card";
		[Inspectable 									(name="UI - Class for Back Graphics", type=String, defaultValue="PippoFlash_CardDeck_BackCover")]
		public var _classNameBack							:String = "PippoFlash_CardDeck_BackCover";
		[Inspectable 									(name="Deck - Number of cards per seed", type=Number, defaultValue=13)]
		public var _cardsPerSeedNum						:uint =13; 
		[Inspectable 									(name="Deck - Use Jollys", type=Boolean, defaultValue=false)]
		public var _useJolly								:Boolean = false;
		[Inspectable 									(name="UI - Center Cards", type=Boolean, defaultValue=true)]
		public var _centerCards							:Boolean = true;
		[Inspectable 									(name="UX - Activate Interaction", type=Boolean, defaultValue=true)]
		public var _activateInteraction						:Boolean = true;
		[Inspectable 									(name="Deck - Number of decks", type=Number, defaultValue=1)]
		public var _numberOfDecks							:uint =1; 
		// CONSTANTS ///////////////////////////////////////////////////////////////////////////////////////
		private static const VERBOSE						:Boolean = true;
		private var _valuesOrder							:Array = [1,13,12,11,10,9,8,7,6,5,4,3,2]; // Classic sequence, with ACE, then KING, QUEEN, JACK, 10, 9..... 
		private var _seedsOrder							:Array = [0,1,2,3]; // Classic sequence: SPADES, HEARTS, DIAMONDS, CLUBS
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
		private var _classCard								:Class;
		private var _classBack								:Class;
		private var _seedOrderUse							:Array; // Temporary used for seed ordering
		private var _valueOrderUse							:Array; // Temporary used for value ordering
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		private var _cards								:Array = []; // All cards in sequence
		private var _cardsById								:Object = {}; // _cardsById - If only one deck: "seed:value", if more than one deck: "deck:seed:value"
		private var _decks								:Array = []; // Multi-dimnensional array: [deck][seed][value]
		private var _groups								:Object = {}; // Gorups where the cards are positioned - LIMBO is useful when I want to perform operations with cards in temporary storage
		// DATA HOILDERS ///////////////////////////////////////////////////////////////////////////////////////
		// MARKERS ////////////////////////////////////////////////////////////////////////
		private var _players								:uint = 0; // Marks the amount of players
		private var _interactionActive						:Boolean = true; // This enables/disables broadcasting of interaction
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		private static var _card							:CardsDeckCard;
		private static var _group							:Array;
		private static var _seedA							:uint; // Sorting option
		private static var _seedB							:uint; // Sorting option
		private static var _valueA							:uint; // Sorting option
		private static var _valueB							:uint; // Sorting option
// INIT ONCE ///////////////////////////////////////////////////////////////////////////////////////
		public function CardsDeck							(par:Object=null) {
			super									("CardsDeck", par);
		}
		protected override function initAfterVariables				():void { // This can be overridden. No need to be called. It gets called automatically depending on how I have been instantiated.
			initializeDeck								();
			//  Initialization after receioved variables goes here
			super.initAfterVariables						();
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
	// SETUP ///////////////////////////////////////////////////////////////////////////////////////
		public function setNamesFormat						(format:String, suits:Array, values:Array):void {
			// This sets the format of string names for cards: 
			// suits is the array names of suits, plus 2 extra suits for JOLLYS: ["spades", "hearts", "diamonds", "clubs", "jolly0", "jolly1"] 
			// values is the list of values names from JOLLY to KING (0 to 13, 1=ACE), ["jolly","ACE",1,2,3,4,5,6,7,8,9,10,"J","q","K"]
			// format, is how to format card name: "[VALUE] of [SUIT]" becomes ACE of HEARTS
			CardsDeckCard.SEEDS						= suits;
			CardsDeckCard.VALUES						= values;
			CardsDeckCard.FORMAT						= format;
		}
	// INTERACTION ///////////////////////////////////////////////////////////////////////////////////////
		public function setInteractionActive					(a:Boolean, s:String="ALL"):void {
			if (a) {
				Debug.debug							(_debugPrefix, "Activating:",s);
				setCardsInteractionActive					(false, _cards); // If I need to activate, I de-activate them all first
			}
			if (s == "ALL" || s == "A") { // Perform on all cards with A or ALL (A is to save bandwidth when sent from smartfox)
				setCardsInteractionActive					(a, _cards);
			}
			else { // Perform on a list of cards
				setCardsInteractionActive					(a, valueToCards(s));
			}
		}
		public function setCardInteractionActive					(a:Boolean, card:CardsDeckCard):void {
			if (a)										Buttonizer.setupButton(_card, this, "Card", "onPress,onRollOver,onRollOut");
			else										Buttonizer.removeButton(card);
		}
		public function setCardsInteractionActive				(a:Boolean, cards:Array):void {
			if (a)										Buttonizer.setupButtons(cards, this, "Card", "onPress,onRollOver,onRollOut");
			else										Buttonizer.removeButtons(cards);
		}
	// CARDS OPERATIONS ///////////////////////////////////////////////////////////////////////////////////////
		public function setCardsValueDarken					(s:String="ALL", darken:Boolean=true):void {
			setCardsDarken								(valueToCards(s), darken);
		}
		public function setCardsDarken						(cards:Array, darken:Boolean=true):void {
			for each (_card in cards)						_card.setDarken(darken);
		}
	// UTILITIES ///////////////////////////////////////////////////////////////////////////////////////
		public function cardsToValue							(cards:Array):String {
			_a										= [];
			for each (_card in cards)						_a.push(_card.getValue());
			return									_a.join(",");
		}
		public function valueToCards							(value:String):Array { // Both ALL and A, to make bandwidth lighter
			return									value == "ALL" || value == "A" ? _cards : getCardsById(value);
		}
		public function cardToValue							(card:CardsDeckCard):String {
			return									card.id;
		}
		public function valueToCard							(id:String):CardsDeckCard {
			return									getCardById(id);
		}
		public function getName							(id:String):String { // Gets the full fomratted name of a card from its value string
			return									valueToCard(id).getName();
		}
	// MAIN DECK ///////////////////////////////////////////////////////////////////////////////////////
		public function shuffle								(group:String="main"):void {
			reset										(_players);
			_groups[group]								= UCode.shuffleArray(_groups[group]);
		}
		public function removeCards							(cards:Array):void {
			// The array only stores a list of values, that will be removed from ALL SEEDS. I.e.: [2, 3, 4] will remove all 2, 3 and 4.
			// This has to be called AFTER shuffle, or all cards will get back in deck
			for (_i=0; _i<4; _i++) {
				for each (_valueA in cards) {
					putCard							(getCard(_i, _valueA), "discards");
				}
			}
		}
		public function cutDeck							(index:uint=NaN):void {
			if (!index)									index = Math.round(Math.random()*getGroup("main").length);
			Debug.debug								(_debugPrefix, "Cutting deck at index:",index);
			trace(getGroupValue("main"));
			for (_i=0; _i<index; _i++) { // Here I am cutting the deck
				_groups.main.push						(_groups.main.shift());
			}
			trace(getGroupValue("main"));
		}
		public function reset								(playersNum:uint=4):void { // This empties all groups, and resets all cards in main group unshuffled
			resetGroups								();
			UDisplay.removeClips							(_cards);
			for each (_card in _cards) {
// 				trace("DECK REST DECK REST DECK REST DECK REST DECK REST DECK REST DECK REST DECK REST DECK REST DECK REST ");
				_card.group							= "main";
				_card.cover							();
				setCardInteractionActive					(false, _card);
				_card.setDarken							(false);
				_card.setSelected						(false);
				_groups.main.push						(_card);
				_card.rotation = _card.x = _card.y				= 0;
				_card.scaleX = _card.scaleY					= 1;
				addChild								(_card);
			}
			if (playersNum)								setPlayers(playersNum);
		}
		public function resetCardsStatus						():void { // this just sets the cards without darken and without selection, and switches off interaction
			for each (_card in _cards) {
				setCardInteractionActive					(false, _card);
				_card.resetStatus						();
			}
		}
		public function addGroup							(group:String):void {
			if (VERBOSE)								Debug.debug(_debugPrefix, "Adding group:",group);
			if (!_groups[group])							_groups[group] = [];
		}
		public function getCardsLeft							(group:String="main"):uint {
			return									groupExists(group) ? _groups[group].length : 0;
		}
		public function getTotalCards						():uint {
			return									_cards.length;
		}
		public function getGroupValue						(group:String):String { // Return a formatted string with list of values
			return									cardsToValue(getGroup(group));
		}
		public function traceInfo							():void {
			_s										= "\n";
			for (var group:String in _groups) {
				_s += ("["+group+":"+_groups[group].length+"]");
			}
			Debug.debug								(_debugPrefix, "\n"+Debug.getLine("REPORT")+"\nDecks:",_numberOfDecks,"Cards per seed:",_cardsPerSeedNum,"Total cards:",_cards.length,_s+"\n"+Debug.getLine("END"));
		}
	// PLAYER UTILITIES ///////////////////////////////////////////////////////////////////////////////////////
		public function setPlayers							(n:uint):void { // Sets the number of players
			for (var i:uint=0; i<n; i++) {
				addGroup								(getPlayer(i)); // Adds player group
				addGroup								(getTrick(i)); // Adds player tricks group
			}
			_players									= n;
		}
		public function dealCards							(cards:uint):void { // Deals a certain amount of cards to ALL players
			for (var player:uint=0; player<_players; ++player) {
				dealCardsToPlayer						(cards, player);
			}
		}
		public function dealCardsToPlayer						(cards:uint, player:uint):void { // Deals a certain amount of cards to ONE player
			moveCards									("main", getPlayer(player), cards);
		}
		public function getPlayer							(n:uint):String {
			return									"p"+n;
		}
		public function getTrick							(n:uint):String {
			return									"t"+n;
		}
		public function playerHasSeed						(n:uint, seed:uint):Boolean {
			return									groupHasSeeds(getPlayer(n), seed);
		}
		public function getPlayerCards						(n:uint):Array {
			return									getGroup(getPlayer(n));
		}
		public function getTrickCards						(n:uint):Array {
			return									getGroup(getTrick(n));
		}
		public function playerHasCard						(player:uint, seed:uint, value:uint, deck:uint=0):Boolean { // Tells us if a player has a certain card
			return									getCard(seed, value, deck).group == getPlayer(player); // Cheks if the card belongs to the player group
		}
		public function getPlayerSeedsForValue					(player:uint, value:uint):Array { // Which seeds I have of one card value
			return									getGroupSeedsForValue(getPlayer(player), value);
		}
		public function getPlayerRichestSeed					(player:uint):uint { // which seed has the richest amount of cards (only quantity by now)
			return									getGroupRichestSeed(getPlayer(player));
		}
		public function getPlayerCardsSeed					(player:uint, seed:uint):Array { // All player cards of one seed
			return									filterCardsSeed(getGroup(getPlayer(player)), seed); 
		}
		public function getPlayerCardsSeeds					(player:uint, seeds:Array):Array {
			_group									= getGroup(getPlayer(player));
			var filtered									:Array = [];
			for each (_card in _group)						if (seeds.indexOf(_card.seed) > -1) filtered.push(_card);
			return									filtered;
		}
		public function getPlayerCardsExceptSeed				(player:uint, seed:uint):Array {
			_group									= getGroup(getPlayer(player));
			var filtered									:Array = [];
			for each (_card in _group)						if (_card.seed != seed) filtered.push(_card);
			return									filtered;
		}
		public function giveCardToPlayer						(cardValue:String, player:uint):void {
			putCard									(getCardById(cardValue), getPlayer(player));
		}
		public function getBestSuitForPlayer					(p:uint):Number { // Returns the BEST suit for player
			return									Math.floor(Math.random()*4); /* by now it just returns a random suit */
		}
		public function playerHasValues						(player:uint, values:Array):Boolean { // This is needed to check if a player has a certain sequence ([1, 2, 3, 4, 5])
			var cardFound								:Boolean;
			for (var seed:uint=0; seed<4; seed++) { // Loop in seeds
				cardFound								= false;
				for each (var val:uint in values) { // Loop in values - as soon as a card is not found, return false
					if (playerHasCard(player, seed, val)) {
						cardFound						= true;
						break;
					}
					if (!cardFound)						return false; // If none of the seeds has that value, just return false
				}
			}
			return									true; // Hey all cards are there!!!
		}
		public function playerHasSeedValues					(player:uint, seed:uint, values:Array):Boolean { // This is needed to check if a player has a certain sequence of ONE SEED ([1, 2, 3, 4, 5])
			_group									= getPlayerCardsSeed(player, seed);
			for each (_i in values) {
				if (_group.indexOf(getCard(seed, _i)) == -1)		return false; // One card not found, so sequence is not there!
			}
			return									true; // Hey all cards are there!!!
		}
	// GAMING UTILITIES ///////////////////////////////////////////////////////////////////////////////////////
		public function allCardsPlayed						():Boolean { // This tells if players have no more cards in their hands
			for (var i:uint=0; i<_players; i++) {
				if (getGroup(getPlayer(i)).length)				return false;
			}
			return									true;
		}
		public function groupHasSeeds						(group:String, ...seeds):Boolean {
			if (seeds.length == 1)							return getGroupCardsSeeds(group, seeds[0]).length;
			else if (seeds.length == 2)						return getGroupCardsSeeds(group, seeds[0], seeds[1]).length;
			else if (seeds.length == 3)						return getGroupCardsSeeds(group, seeds[0], seeds[1], seeds[2]).length;
			else if (seeds.length == 4)						return getGroupCardsSeeds(group, seeds[0], seeds[1], seeds[2], seeds[3]).length;
			else {
				Debug.error							(_debugPrefix, "groupHasSeeds() -> wrong number of arguments:", seeds.length);
				return								false;
			}
		}
		public function getGroupRichestSeed					(group:String):uint { // The seed which has more cards
			var seeds									:Array = [0, 0, 0, 0]; // This is the amount of cards per seed
			_group									= getGroup(group);
			for each (_card in _group)						seeds[_card.seed]++; // Update seeds counter
			// Fid the highest amount of cards and return it
			var highest									= 0; // Set the first highest seed, then check for the others
			for (_i=1; _i<4; _i++)							if (seeds[_i] > seeds[highest]) highest = _i;
			return									highest;
		}
		public function getGroupSeedsForValue					(group:String, value:uint):Array { // Returns a list of seeds which have that current card value
			var seeds									:Array = [];
 			_group									= getGroup(group);
			for each (_card in _group){
				if (_card.value == value) 					seeds.push(_card.seed);
			}
			return									seeds;
		}
		public function getCardsLeftToPlay						(seed):Array { // Returns all cards left in players hands
			var cards									:Array = [];
			for (_i=0; _i<_players; _i++) {
				cards									= cards.concat(getPlayerCards(_i));
			}
			return									cards;
		}
		public function getCardsSeedLeftToPlay					(seed:uint):Array { // Returns all cards of one seed left in players hands
			var cards									:Array = [];
			for (_i=0; _i<_players; _i++) {
				cards									= cards.concat(getPlayerCardsSeed(_i, seed));
			}
			return									cards;
		}
	// UTILITIES ON CARD/CARDS ///////////////////////////////////////////////////////////////////////////////////////
		public function traceCards							(cards:Array, info:String=null):void {
			_a										= [];
			for each (_card in cards)						_a.push(_card.getName());
			Debug.debug								(_debugPrefix, info?info:"Cards:",_a.join("|"));
		}
		public function hasHigherCard						(card:CardsDeckCard, cards:Array):Boolean { // If in the cards there is at least one higher than
			for each (_card in cards)						if (getCardValue(_card) < getCardValue(card)) return true; // There is a card with higher value
			return									false; // There is no card with a higher value
		}
		public function hasLowerCard						(card:CardsDeckCard, cards:Array):Boolean {
			for each (_card in cards)						if (getCardValue(_card) > getCardValue(card)) return true; // There is a card with LOWER value
			return									false; // There is no card with a LOWER value
		}
		public function getHigherCard						(card:CardsDeckCard, cards:Array):CardsDeckCard { // returns a card just higher enough than the card
			// Be careful, if there is no higher card, null will be returned!
			// I create an array sorted by value
			var sorted									:Array = UCode.duplicateArray(cards);
			sorted.sort									(compareCardsValue);
			// I loop starting from the lowest, as soon as I find a higher card I return that
			for (var i:uint=sorted.length-1; i>=0; i--) {
				if (getCardValue(sorted[i]) < getCardValue(card))	return sorted[i];
			}
			// Mhhh... nopthing has been found, so I just return the highest
			return									sorted[sorted.length-1];
		}
		public function getLowestCard						(cards:Array):CardsDeckCard {
			return									getRelativeCards(false, cards, 1)[0];
		}
		public function getHighestCard						(cards:Array):CardsDeckCard {
			return									getRelativeCards(true, cards, 1)[0];
		}
		public function getLowestCards						(cards:Array, amount:uint=1):Array {
			return									getRelativeCards(false, cards, amount);
		}
		public function getHighestCards						(cards:Array, amount:uint=1):Array {
			return									getRelativeCards(true, cards, amount);
		}
			private function getRelativeCards					(high:Boolean, cards:Array, amount:uint):Array {
				_a									= UCode.duplicateArray(cards);
				_a.sort								(compareCardsValue);
				return								high ? _a.splice(0, amount) : _a.splice(_a.length-amount, amount);
			}
		public function cardsHaveSeed						(cards:Array, seed:uint):Boolean {
			for each (_card in cards)						if (_card._seed == seed) return true;
			return									false;
		}
		public function filterCardsSeed						(cards:Array, seed:uint):Array { // Filters cards returning only cards of the seed
			var found									:Array = [];
			for each (_card in cards)						if (_card._seed == seed) found.push(_card);
			return									found;
		}
		public function filterCardsNoSeed						(cards:Array, seed:uint):Array { // Reutnrs all cards which are NOT of the seed
			var found									:Array = [];
			for each (_card in cards)						if (_card._seed != seed) found.push(_card);
			return									found;
		}
	// CARDS SELECTION ///////////////////////////////////////////////////////////////////////////////////////
		public function getGroup							(group:String):Array { // Returns a complete group of cards
			return									_groups[group];
		}
		public function getTopCard							(group:String="main"):CardsDeckCard { // Gets the first card from a group
			// Gets the first card of a group
			return									_groups[group][_groups[group].length-1];
		}
		public function getBottomCard						(group:String="main"):CardsDeckCard { // Gets the last card from a group
			// Gets the first card of a group
			return									_groups[group][0];
		}
		public function getGroupCardsSeeds					(group:String, ...seeds):Array { // This returns from a group, only the cards of the specified seeds
			// getGroupCardsSeeds("p1", 0, 2); // Returns only the cards of the seeds specified (this case, spades and diamonds)
			_group									= getGroup(group);
			var a										:Array = [];
			var seed									:uint;
			for each (seed in seeds) { // Loop through seeds
				for each (_card in _group)					if (_card._seed == seed) a.push(_card);
			}
			return									a;
		}
		public function getRandomCard						(group:String="main"):CardsDeckCard {
			return									UCode.getArrayRandom(getGroup(group));
		}
		public function getAllCards							():Array {
			return									_cards;
		}
		public function getCard							(seed:uint, value:uint, deck:uint=0):CardsDeckCard { // Gets A CARD with seed, value, deck
			return									_decks[deck][seed][value-1]; // Value is 1 to 13, but in array is stored 0 to 12
		}
		public var getCardByValue							:Function = getCardById;
		public function getCardById							(id:String):CardsDeckCard { // Gets "seed:value" returns card
			return									_cardsById[id];
		}
		public function getCardsById							(ids:*):Array { // Gets array or string list of values and returns an array of cards
			var cards									:Array = new Array();
			if (ids is Array)								_a = ids;
			else										_a = ids.split(",");
			for each (_s in _a)							cards.push(getCardById(_s));
			return									cards;
		}
		public function getCardsBySeed						(cards:Array, seed:uint):Array { // This returns from array only cards of a certain seed
			var a										:Array = [];
			for each (_card in cards)						if (_card._seed == seed) a.push(_card);
			return									a;
		}
	// CARD MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////	
		// These functions do move cards
		public function moveCard							(from:String, to:String):void { // Moves first card from a group to another
			putCard									(getTopCard(from), to);
		}
		public function moveCards							(from:String, to:String, num:uint):void { // Moves a certain amount of cards from a group to another
			for (var i:uint=0; i<num; i++)					putCard(getTopCard(from), to);
		}
		public function putCard							(card:CardsDeckCard, group:String):CardsDeckCard { // Moves THE CARD to another group
			if (VERBOSE)								Debug.debug(_debugPrefix, "Moving",card,card.group,">",group);
			UCode.removeArrayItem						(_groups[card.group], card);
			_groups[group].push							(card);
			card.group									= group;
			return									card;
		}
		public function putCards							(cards:Array, group:String):Array { // Moves THE CARDS to another group
			for each (_card in cards)						if (_card) putCard(_card, group);
			return									cards;
		}
	// ORDERING ///////////////////////////////////////////////////////////////////////////////////////
		public function orderBySeed							(cards:Array, seedOrder:Array=null):Array {
			_seedOrderUse								= seedOrder ? seedOrder : _seedsOrder;
			cards.sort									(orderSeedFunc);
			return									cards;
		}
		public function orderByValue							(cards:Array, valueOrder:Array=null):Array {
			_valueOrderUse								= valueOrder ? valueOrder : _valuesOrder;
			cards.sort									(orderValueFunc);
			return									cards;
		}
		public function orderBySeedAndValue					(cards:Array, seedOrder:Array=null, valueOrder:Array=null):Array {
			_seedOrderUse								= seedOrder ? seedOrder : _seedsOrder;
			_valueOrderUse								= valueOrder ? valueOrder : _valuesOrder;
			cards.sort									(orderSeedValueFunc);
			return									cards;
		}
			public function orderSeedFunc					(a:CardsDeckCard, b:CardsDeckCard):Number {
				_seedA								= _seedOrderUse.indexOf(a._seed);
				_seedB								= _seedOrderUse.indexOf(b._seed);
				if (_seedA > _seedB)						return 1; 
				else if (_seedA < _seedB)					return -1; 
				return								0;
			}
			public function orderValueFunc					(a:CardsDeckCard, b:CardsDeckCard):Number {
				_valueA								= _valueOrderUse.indexOf(a._value);
				_valueB								= _valueOrderUse.indexOf(b._value);
				if (_valueA > _valueB)						return 1; 
				else if (_valueA < _valueB)					return -1; 
				return								0;
			}
			public function orderSeedValueFunc				(a:CardsDeckCard, b:CardsDeckCard):Number {
				_seedA								= _seedOrderUse.indexOf(a._seed);
				_seedB								= _seedOrderUse.indexOf(b._seed);
				if (_seedA > _seedB)						return 1; 
				else if (_seedA < _seedB)					return -1; 
				else {
					_valueA							= _valueOrderUse.indexOf(a._value);
					_valueB							= _valueOrderUse.indexOf(b._value);
					if (_valueA > _valueB)					return 1; 
					else if (_valueA < _valueB)				return -1; 
				}
				return								0;
			}
// INIT DECK ///////////////////////////////////////////////////////////////////////////////////////
		private function initializeDeck						():void {
			// Init variables
			_classCard									= UCode.getClassFromString(_classNameCard);
			_classBack									= UCode.getClassFromString(_classNameBack);
			resetGroups								();
			renderCards								();
			activateInteraction							();
			traceInfo									();
		}
			private function renderCards						():void {
				var deck								:uint;
				var seed								:uint;
				var value								:uint;
				var front								:MovieClip;
				var back								:MovieClip;
				for (deck=0; deck<_numberOfDecks; ++deck) {
					_decks[deck]						= [];
					for (seed=0; seed<4; ++seed) {
						_decks[deck][seed]				= [];
						for (value=1; value<=_cardsPerSeedNum; ++value) {
							front						= new _classCard();
							front.gotoAndStop			((_cardsPerSeedNum*seed)+value);
							back						= new _classBack();
							back.gotoAndStop			(deck+1);
							front.width = back.width		= _w;
							front.height = back.height		= _h;
							if (_centerCards) {
								front.x = back.x			= -(_w/2);
								front.y = back.y			= -(_h/2);
							}
							_card						= new CardsDeckCard(this, deck, seed, value, front, back);
							_cards.push				(_card);
							_decks[deck][seed].push		(_card); // Seed array stores cards 
							_groups.main.push			(_card);
							_cardsById[_card.getValueString()] = _card;
							addChild					(_card);
						}
					}
				}
				_groups.all								= _cards; // Lets see if his works... should allow me to perform group operations on all cards
			}
			private function activateInteraction				():void {
				if (_activateInteraction) {
					setCardsInteractionActive				(true, _cards);
				}
			}
// INIT ANY TIME ///////////////////////////////////////////////////////////////////////////////////////
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function resetGroups							():void { // This resets all groups to their original state
			for (_s in _groups)							_groups[_s] = [];
			_groups									= {main:[], table:[], discards:[], limbo:[], all:[]};
			_players									= 0;
		}
		private function groupExists							(group:String):Boolean {
			if (_groups[group])							return true;
			else {
				Debug.error							(_debugPrefix, "Requested group ["+group+"] does not exist!");
				return								false;
			}
		}
		private function compareCardsValue					(card0:CardsDeckCard, card1:CardsDeckCard):int {
			if (getCardValue(card0) < getCardValue(card1))		return -1; // card0 has higher value
			else if (getCardValue(card0) > getCardValue(card1))	return 1; // card1 has higher value
			else										return 0; // same value
		}
		private function getCardValue						(card:CardsDeckCard):uint {
			// This return index positioning in the values array. Lowest is value, higher is cards value.
			return									_valuesOrder.indexOf(card.value);
		}
// DISPOSE ///////////////////////////////////////////////////////////////////////////////////////
// METHODS //////////////////////////////////////////////////////////////////////////////////////
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onPressCard							(c:MovieClip=null) {
			if (!_interactionActive)							return;
			broadcastEvent								("onPressCard", c);
		}
		public function onRollOverCard						(c:MovieClip=null) {
			if (!_interactionActive)							return;
			c.onRollOver								();
			broadcastEvent								("onRollOverCard", c);
		}
		public function onRollOutCard						(c:MovieClip=null) {
			if (!_interactionActive)							return;
			c.onRollOut									();
			broadcastEvent								("onRollOutCard", c);
		}
	}
}




//  ///////////////////////////////////////////////////////////////////////////////////////
// HELPER CLASSES ///////////////////////////////////////////////////////////////////////////////////////
//  ///////////////////////////////////////////////////////////////////////////////////////
	// CardsDeckCard ///////////////////////////////////////////////////////////////////////////////////////
	import flash.display.*; import com.pippoflash.components.CardsDeck; import com.pippoflash.utils.*; import com.pippoflash.motion.Animator;
	import PippoFlash_CardDeck_BackCover; import PippoFlash_CardDeck_FR_Card;
	dynamic class CardsDeckCard extends MovieClip { // JOLLY NOT YET IMPLEMENTED
		public static var VALUES							:Array=["jolly","A","2","3","4","5","6","7","8","9","10","J","Q","K"];
		public static var SEEDS							:Array=["SPADES","HEARTS","DIAMONDS","CLUBS","JOLLY0","JOLLY1"];
		public static var FORMAT							:String = "[VALUE] of [SUIT]";
		private var _deck								:CardsDeck;
		public var _deckId								:uint; // The id of deck (in case main deck uses 2 decks, this can be 0 or 1, etc.)
		public var _seed									:uint; // The number of seed
		public var _value									:uint; // The value: 1 to 13
		private var _front								:MovieClip; // Link to front clip
		private var _back								:MovieClip; // Link to back clip
		private var _group								:String; // Marks to which subecks it belongs (main, discards, p0, p1, p2, p3, tp0, tp2, tp3, tp4, table);
		public var _numValue								:uint; // A numeric value optained by joining vlue + seed (i.e: 1:12 = 112, 0:3 = 3)
		private var _faceDown								:Boolean = true; // Marks if card is face down or face up. Initially is face down always.
		private var _selected								:Boolean = false; // Marks if the card is selected
		public function CardsDeckCard						(deck:CardsDeck, deckId:uint, seed:uint, value:uint, front:MovieClip, back:MovieClip, group:String="main") {
			super									();
			_deck									= deck;
			_deckId									= deckId;
			_seed									= seed;
			_value									= value;
			_front									= front;
			_back									= back;
			_group									= group;
			_numValue									= uint(_seed +""+ _value);
			addChild									(_front);
			addChild									(_back);
			_front._darken.visible							= false;
			updateVisibility								();
		}
		// UTY ///////////////////////////////////////////////////////////////////////////////////////
		public function resetStatus							():void { // Removes selection, rollover, darkiening, and makes it visible
			setDarken									(false);
			setSelected								(false);
			onRollOut									();
			show										();
		}
		public function traceInfo							():void {
			Debug.debug								("Card", VALUES[_value],"of",SEEDS[_seed],"deck:"+_deckId+", seed:"+_seed+", val:"+_value+", num:"+_numValue+", ["+_group+"]");
		}
		public function getValueString						():String {
			return									_seed+":"+_value;
		}
		public var getValue								:Function = getValueString;
		public function getName							():String {
			return									UText.insertParams(FORMAT, {VALUE:VALUES[_value], SUIT:SEEDS[_seed]});
		}
		public function onRollOver							() {
			Animator.fadeIn								(_front._rollOver, 2);
		}
		public function onRollOut							() {
			Animator.fadeOut							(_front._rollOver);
		}
		public function setDarken							(v:Boolean=true):void {
			_front._darken.visible							= v;
		}
		public function setSelected							(s:Boolean):void {
			_selected									= s;
			_front._select.visible							= _selected;
			_front._select.alpha							= _selected ? 1 : 0;
		}
		public function toggleSelected						():void {
			setSelected								(!_selected);
		}
		public function isSelected							():Boolean {
			return									_selected;
		}
		public override function toString						():String {
			return									"["+getName()+" ("+getValueString()+")]";
		}
		// GETTERS ///////////////////////////////////////////////////////////////////////////////////////
		public function get numValue							():uint {
			return									_numValue;
		}
		public function get seed							():uint {
			return									_seed;
		}
		public function get value							():uint {
			return									_value;
		}
		public function get id								():String {
			return									getValueString();
		}
		// COVER/UNCOVER ///////////////////////////////////////////////////////////////////////////////////////
		public function cover								():void {
			_faceDown									= true;
			updateVisibility								();
		}
		public function show								():void {
			_faceDown									= false;
			updateVisibility								();
		}
			private function updateVisibility					():void {
				_back.visible							= _faceDown;
			}
		// GROUPING ///////////////////////////////////////////////////////////////////////////////////////
		public function set group							(g:String):void {
			_group									= g;
		}
		public function get group							():String {
			return									_group;
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
	
	
	