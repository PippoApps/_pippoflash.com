/* DataList - (c) Filippo Gregoretti - www.pippoflash.com*/package com.pippoflash.components {	import com.pippoflash.utils.*; import com.pippoflash.motion.Animator; com.pippoflash.components.ScrollBarArrows; com.pippoflash.components.PippoFlashButton; com.pippoflash.components.ContentBox; 	import flash.display.*; import flash.text.*; import flash.events.*; import flash.utils.*; import flash.net.*; import flash.geom.*;// 	import PippoFlashAS3_UTY_SquareClip; import DataListDefaultTile; import DataListDefaultBackground; import DataListDefaultSorter; import PippoFlashButton_DataListDefaultHeader;	public dynamic class DataList extends _cBase {	// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////	// HEADER		[Inspectable 									(name="HEADER - Class Header PFButton", type=String, defaultValue="PippoFlashButton_DataListDefaultHeader")]		public var _headerButtonClassName					:String = "PippoFlashButton_DataListDefaultHeader";		[Inspectable 									(name="HEADER - Names", type=Array, defaultValue="Header 1,Header 2,Header 3, Header 4, Header 5")]		public var _headerNames							:Array = ["Header 1","Header 2","Header 3","Header 4","Header 5"];		[Inspectable 									(name="HEADER - Percent Size (total 100)", type=Array, defaultValue="30,20,20,15,15")]		public var _headerPercents							:Array = [30,20,20,15,15];		[Inspectable 									(name="HEADER -  Use Header", type=Boolean, defaultValue=true)]		public var _useHeader								:Boolean = true;		[Inspectable 									(name="HEADER - Heder Height", type=uint, defaultValue=20)]		public var _headerHeight							:uint = 20;	// TILE		// Class of tile to attach 		[Inspectable 									(name="TILE - Class Tile", type=String, defaultValue="DataListDefaultTile")]		public var _tileClassName							:String = "DataListDefaultTile";
		// If use tile height property, or set a custom height property		[Inspectable 									(name="TILE - Height - Choose tile prop. to position", type=String, defaultValue="height")]		public var _tileHeightProperty						:String = "height";		// If set manually a custom tile distance		[Inspectable 									(name="TILE - Height - Custom distance (0 to use property)", type=Number, defaultValue=0)]		public var _tileHeightAmount						:uint = 0;		// Name of textfields in tile. all of them. Associated to headers. ALL OF THEM, THIS IS NEEDED TO RESET TEXTFIELDS WHEN RECYCLED.		[Inspectable 									(name="TILE - ALL TEXTFIELD NAMES", type=Array, defaultValue="_txt0,_txt1,_txt2,_txt3,_txt4")]		public var _textFieldsAllNames						:Array = ["_txt0","_txt1","_txt2","_txt3","_txt4"];		// Name of textfields in tile. The ones that have to be updated with properties.		[Inspectable 									(name="TILE - Fields names for data slot.", type=Array, defaultValue="_txt0,_txt1,_txt2,_txt3,_txt4")]		public var _textFieldsNames							:Array = ["_txt0","_txt1","_txt2","_txt3","_txt4"];		// Name of associated data property in data object.		[Inspectable 									(name="TILE - Text data names", type=Array, defaultValue="_txt0,_txt1,_txt2,_txt3,_txt4")]		public var _textDataNames							:Array = ["_txt0","_txt1","_txt2","_txt3","_txt4"];		// If use html in populating textfields		[Inspectable 									(name="TILE - Use HTML for each text field", type=Array, defaultValue="0,0,0,0,0")]		public var _useHtml								:Array = [0,0,0,0,0]; /* TO BE IMPLEMENTED */		// Instead of rollover, rollout and press internally, call onRollOver, onRollOut and onPress in tile class.		[Inspectable 									(name="TILE - Use tile functions (onRollOver, onPress, etc.)", type=Boolean, defaultValue=false)]		public var _useTileCustomFunctions					:Boolean = false;		// Activate Interaction		[Inspectable 									(name="TILE - Activate interaction", type=Boolean, defaultValue=true)]		public var _activateInteraction						:Boolean = true;		// Render the tile with cuastom internal methods. Otherwise just tell the tile that data arrived.		[Inspectable 									(name="TILE - Use internal render.", type=Boolean, defaultValue=true)]		public var _useTileInternalRender						:Boolean = true;		// If height is 0, it will be taken from tile.height. Otherwise this value will be used.		[Inspectable 									(name="TILE - Tiles Height (0 for .height)", type=uint, defaultValue=0)]		public var _tilesHeight								:uint = 0; // To be implemented!!!!!		// If this is true, tiles height is adjusted on textfield size. It means textfields can be manually resized in tile, or set to auto-height.
		// If this is true, all textfields will also have autoSize to true. ONLY TEXTFIELDS WHO ARE SET TO MULTILINE HAVE THIS ACTIVATED.		[Inspectable 									(name="TILE - Tiles Height - Based on TextFields size.", type=Boolean, defaultValue=false)]		public var _tilesHeightBasedOnTextFields				:Boolean = false;		// Margin to be added on left and right of each textfield used in tile		[Inspectable 									(name="TILE - Text Margin - HORIZ", type=uint, defaultValue=3)]		public var _tilesTextMargin							:uint = 3;		// Vertical margins of text are retrieved from text vertical position. Set this to set numerically.
		/* TO BE IMPLEMENTED */		[Inspectable 									(name="TILE - Text Margins - VERT (0 for height)", type=uint, defaultValue=0)]		public var _tilesTextMarginVERT						:uint = 0;		// Colors of tile for odd and even and roll and selected statuses		[Inspectable 									(name="TILE - Color Tile Even", type=Color, defaultValue="#eeeeee")]		public var _colorTileEven							:uint = 0xeeeeee;		[Inspectable 									(name="TILE - Color Tile Odd", type=Color, defaultValue="#dddddd")]		public var _colorTileOdd							:uint = 0xdddddd;		[Inspectable 									(name="TILE - Color Tile Roll", type=Color, defaultValue="#A2CBD5")]		public var _colorTileRoll								:uint = 0xA2CBD5;		[Inspectable 									(name="TILE - Color Tile Select", type=Color, defaultValue="#ffbbbb")]		public var _colorTileSelect							:uint = 0xffbbbb;		// Colors of text in various statuses		[Inspectable 									(name="TILE - Color Text, use it?", type=Boolean, defaultValue=false)]		public var _useColorText							:Boolean = false;		[Inspectable 									(name="TILE - Color Text Even", type=Color, defaultValue="#000000")]		public var _colorTextEven							:uint = 0x000000;		[Inspectable 									(name="TILE - Color Text Odd", type=Color, defaultValue="#000000")]		public var _colorTextOdd							:uint = 0x000000;		[Inspectable 									(name="TILE - Color Text Roll", type=Color, defaultValue="#990000")]		public var _colorTextRoll							:uint = 0x990000;		[Inspectable 									(name="TILE - Color Text Select", type=Color, defaultValue="#cc0000")]		public var _colorTextSelect							:uint = 0xcc0000;	// SORTING		// Attachment for the sorting arrow graphics		[Inspectable 									(name="SORT - Class Sorter", type=String, defaultValue="DataListDefaultSorter")]		public var _sorterClassName							:String = "DataListDefaultSorter";		// Property of data to be sorted according to header position (can differ from data to populate text)		[Inspectable 									(name="SORT - Header sort prop names", type=Array, defaultValue="_txt0, _txt1,_txt2,_txt3,_txt4")]		public var _headerSortPropNames						:Array = ["_txt0","_txt1","_txt2","_txt3","_txt4"];		// List of sorting methods. T is textual, N is numeric.		[Inspectable 									(name="SORT - Headers sort mode (T, N)", type=Array, defaultValue="T,T,T,T,T")]		public var _sortList								:Array = ["T","T","T","T","T"];	// SCROLL BAR		// Class of graphics to be used by ScrollBarArrow		[Inspectable 									(name="SB - Class ScrollBar Graphics", type=String, defaultValue="PippoFlashScrollBar_DataListDefault")]		public var _scrollBarClassName						:String = "PippoFlashScrollBar_DataListDefault";		// Use scrollbar yes or not		[Inspectable 									(name="SB - ScrollBar", type=Boolean, defaultValue=true)]		public var _useScrollBar							:Boolean = true;		// Show the arrows of scrollbar		[Inspectable 									(name="SB - ScrollBar Disappear when No scroll", type=Boolean, defaultValue=true)]		public var _scrollBarArrows							:Boolean = true;		// Disappear scrollbar if no scroll is involved		[Inspectable 									(name="SB - ScrollBar use Arrows", type=Boolean, defaultValue=true)]		public var _scrollBarDisappearIfNoScroll					:Boolean = true;		// Width of scrollbar graphics		[Inspectable 									(name="SB - ScrollBar Width", type=uint, defaultValue=16)]		public var _scrollBarWidth							:uint = 16;	// GENERAL UI		// Class name of background to be attached		[Inspectable 									(name="UI - Class Background (nothing for no bg)", type=String, defaultValue="DataListDefaultBackground")]		public var _bgClassName							:String = "DataListDefaultBackground";	// USER EXPERIENCE		// Once a tile is clicked, if keep it selected or just press. Brodacasts would be onTileSelected & onTileDeselected. While if press only, is onTilePress		[Inspectable 									(name="UX - Select Remains", type=Boolean, defaultValue=false)]		public var _keepSelected							:Boolean = false;		// Multiple tiles can be selected. TO BE IMPLEMENTED		[Inspectable 									(name="UX - Multiple Select", type=Boolean, defaultValue=false)]		public var _multipleSelect							:Boolean = false;		// Activate automatic scroll with mouse movement		[Inspectable 									(name="UX - Auto Scroll", type=Boolean, defaultValue=false)]		public var _autoScroll								:Boolean = false;	// SYSTEM		// Broadcast rollover events		[Inspectable 									(name="SYS - Broadcast Roll", type=Boolean, defaultValue=false)]		public var _broadcastRoll							:Boolean = false;		// Broadcast press events		[Inspectable 									(name="SYS - Broadcast Press", type=Boolean, defaultValue=true)]		public var _broadcastPress							:Boolean = true;		// Broadcast sort events		[Inspectable 									(name="SYS - Broadcast Sort", type=Boolean, defaultValue=true)]		public var _broadcastSort							:Boolean = true;		// Broadcast double click		[Inspectable 									(name="SYS - Broadcast Double Click", type=Boolean, defaultValue=false)]		public var _broadcastDoubleClick						:Boolean = false;		// Use internal automatic sort or external functions. TO BE IMPLEMENTED		[Inspectable 									(name="SYS - Automatic Sort", type=Boolean, defaultValue=true)]		public var _autoSort								:Boolean = true;								// STATIC ////////////////////////////////////////////////////////////////////////////////		private static const HORIZ_TIP_DIST					:uint = 30;		private static const VERT_TIP_DIST					:uint = 20;		private static const DOUBLE_CLICK_TIME					:uint = 500; // Milliseconds within another click is considered a double click		// UTY		private var _tile									:*;		// VARIABLES //////////////////////////////////////////////////////////////////////////		// USER VARIABLES		// SYSTEM		// REFERENCES		private var _header								:MovieClip = new MovieClip();		private var _headerButtons							:Array;		private var _selectedHeaderNum						:uint = 0;		private var _sortDescending							:Boolean = false;		private var _content								:Sprite = new Sprite();		private var _sorter								:DisplayObject;		private var _sorterBg								:MovieClip; // Transparent square to intercept sorter		private var _scrollBar								:ScrollBarArrows;		private var _contentBox							:ContentBoxTouch;		private var _bg									:DisplayObject;		private var _tiles									:Array = [];		private var _visibleTiles							:Array;		private var _customRenderFunction					:Function;		private var _dataToTile							:Dictionary;		private var _tileToData								:Dictionary;		private var _tileIsEven								:Dictionary; // Filled during display routine, tells which tiles are even.
		private var _untouchedBaseTile						:*; // this stores the first tile, which is used to grab initial height and other parameters without touching content		// MARKERS		public var _headerButtonsWidths						:Array;		public var _headerButtonsPos						:Array;		private var _rolloveredTile							:*;		private var _selectedTile							:*;		private var _selectedTiles							:Array; // Holds the list of selected tiles		// DATA HOLDERS		private var _data								:Array; // array with list of text		private var _visibleData							:Array; // Array with filtered data (before sorting happens)		private var _sortedData							:Array; // array with sorted data. 
		// SYSTEM - RENDERING UTY		private var _setTextFunctions						:Array; // Stores functions to set text according to type		private var _tileClass								:Class; // Stores tile class		private var _txt									:TextField; // Uty to loop		private var _propertiesNum							:uint; // Stores number of properties to set		private var _doubleTextMargin						:uint; // Multiplies text margin only once		// SYSTEM - DOUBLE CLICK		private var _doubleClickLastClickedTile					:*; // Markes the last tile which has been clicked, in order to activate double click		private var _doubleClickLastClickedTimer					:uint; // Marks the last time a tile has been clicked// INIT ///////////////////////////////////////////////////////////////////////////////////////		public function DataList							(par:Object=null) {			super									("DataList", par);		}// RECURRENT INIT ///////////////////////////////////////////////////////////////////////////////////////		protected override function initialize					():void { 			// This is called EVERY TIME the component is initialized. It suppose a full re-rendering. Its called automatically in recycle().			initializeGraphics								();			initializeProperties							();			super.initialize								();		}			private function initializeGraphics					():void {			// Add all data to UMem				UMem.addClass							(UCode.getClassFromString(_bgClassName));				UMem.addClass							(UCode.getClassFromString(_tileClassName));
				UMem.addManagedClass					("ContentBox", ContentBoxTouch);				UMem.addManagedClass					("PippoFlashButton", PippoFlashButton);				UMem.addManagedClass					("ScrollBarArrows", ScrollBarArrows);			// First initialize all graphics that have to be initialized anyway				// Setup header height vairable				if (!_useHeader)							_headerHeight = 0; // Set height of header to 0 if I have decided NOT to use it				// Background				if (UCode.exists(_bgClassName)) {					_bg								= UMem.getInstance(UCode.getClassFromString(_bgClassName));					addChild							(_bg);					_bg.width							= _w;					_bg.height							= _h;
				}				// Content Box				_contentBox							= UMem.getInstance(ContentBoxTouch, {_autoScroll:_autoScroll, width:_w, height:_h-_headerHeight});				addChild								(_contentBox);				_contentBox.y							= _headerHeight;				// HEADER				if (_useHeader) {					// Render Header
					_headerButtons						= [];					_headerButtonsWidths					= [];					_headerButtonsPos					= [];					var xPos							:Number = 0;					var ww							:Number;					var butt							:PippoFlashButton;					var radioGroup						:String = "DataListH"+Math.random();					for (var i:uint=0; i<_headerNames.length; i++) {						// ADD THE CUSTOM HEADER CLASS						ww							= Math.round(UCode.getPercent(_w, Number(_headerPercents[i])));						_headerButtonsWidths[i]			= ww;						butt							= UMem.getInstance(PippoFlashButton, {_cBase_eventPostfix:"Header", _textMargin:0, _textAlign:"LEFT", width:ww, height:_headerHeight, _text:_headerNames[i], _buttonLinkage:_headerButtonClassName, _radioGroup:radioGroup});						_header.addChild				(butt);						butt.x						= xPos;						_headerButtonsPos[i]				= xPos;						xPos							+= ww;						butt.addListener					(this);						_headerButtons.push				(butt);
// 						butt.setText					("fregna");					}					_headerButtons[0].setSelected			(true);					addChild							(_header);					// Sorter					_sorter							= UCode.getInstance(_sorterClassName);					_header.addChild						(_sorter);					_sorter.y							= Math.floor(_headerHeight/2);					Buttonizer.setClickThrough				(_sorter);					_sorterBg							= UDisplay.getSquareMovieClip(100, _headerHeight);					_sorterBg.alpha						= 0;					_header.addChild						(_sorterBg);					Buttonizer.setupButton				(_sorterBg, this, "SorterBg", "onPress");					positionSorterTo						(0);				}				// scrollbar				if (_useScrollBar) {					_scrollBar							= UMem.getInstance(ScrollBarArrows, {_showArrows:_scrollBarArrows, _disappearOnNoScroll:_scrollBarDisappearIfNoScroll, width:_scrollBarWidth, height:_h-_headerHeight, x:_w-_scrollBarWidth, y:_headerHeight, _graphLinkage:_scrollBarClassName});					addChild							(_scrollBar);					_contentBox.setScrollBarV				(_scrollBar);				}			}			private function initializeProperties				():void {				_tileClass								= UCode.getClassFromString(_tileClassName);
				_untouchedBaseTile						= UMem.getInstance(_tileClass);				_propertiesNum							= _textFieldsNames.length;				_doubleTextMargin						= _tilesTextMargin*2;				_setTextFunctions						= [];				if (_multipleSelect)						_keepSelected = true; // If multiple select is active, obviously also keep selection has to be active.				for (var ii:uint=0; ii<_propertiesNum; ii++)		_setTextFunctions[ii] = _useHtml[ii] ? UText.setTextHtml : UText.setTextSingleLine;			}// FRAMEWORK METHODS ///////////////////////////////////////////////////////////////////////////////////////				public override function cleanup						():void {			release									();
			super.cleanup								();
			// I remove the untouched tile
			UMem.storeInstance							(_untouchedBaseTile);
			_untouchedBaseTile							= null;			// I also have to remove all the fucking rest
			if (_bg)							UMem.storeInstance(_bg);
			_bg									= null;
			_contentBox.cleanup						();
			_contentBox							= null;
			if (_useHeader) {
				for each (_c in _headerButtons)			UDisplay.removeClip(_c);
				UMem.storeInstances(_headerButtons);
				UDisplay.removeClip					(_header);
				UDisplay.removeClip					(_sorter);
				UDisplay.removeClip					(_sorterBg);
				Buttonizer.removeButton				(_sorterBg);
// 				_header							= null;
				_sorter							= null;
				
				_headerButtons						= null;
			}
			if (_useScrollBar) {
				UMem.storeInstance					(_scrollBar);
				_scrollBar							= null;
			}
		}		public override function release						():void {			UMem.storeInstances							(_tiles);			UDisplay.removeClips							(_tiles);			if (_activateInteraction)						Buttonizer.removeButtons(_tiles);			// Perform operations on all tiles			for each (_tile in _tiles) {				// Do nothing by now
			}			// Perform operations on selected tiles			for each (_tile in _selectedTiles) {				// Do nothing by now			}			_tiles										= [];			_dataToTile									= new Dictionary();			_tileToData									= new Dictionary();			_tileIsEven									= new Dictionary();			_selectedTile								= null;			_selectedTiles								= [];			_rolloveredTile								= null;			_data = _sortedData = _visibleTiles = _visibleData		= null;			_contentBox.release							();			super.release								();		}		public override function resize						(w:Number, h:Number):void {			// This one only resizes component. Rendered or not, this has to work to resize it.
			// If this is not overridden, it will only change the values in memoryt, but nothing happens.
			cleanup									();
			super.resize								(w, h);
			initialize									();		}// METHODS //////////////////////////////////////////////////////////////////////////////////////	// RENDER		// Renders a complete data list		public function render								(data:Array):void { // Renders accordingly on textfields			renderData									(data);		}		// Renders with a custom function. Function must have 2 params:(data:*, tile:MovieClip);		public function renderCustom						(data:Array, renderFunc:Function):void {			/* TO BE IMPLEMENTED */			_customRenderFunction						= renderFunc;			renderNewDataCustom							(); // Rendering here is done with an external custom function		}	// UPDATE & FILTER		// This updates and filters data. If data is not rendered, it will NOT be added. It shows only the data set in the array.		public function updateData							(data:Object):void {
			updateDatas								([data]);		}		public function updateDatas							(data:Array):void {			updateRenderedData							(data);		}		// This only filters data. It assumes that existing data is NOT updated to save time. It only filters and ADDS data which is missing.		public function filterData							(data:Array):void {			filterRenderedData							(data);		}		// Shows all data stored and removes all filtering		public function showAll							():void {			Debug.debug								(_debugPrefix, "Showing all items.");		}	// ADD & DELETE		// This deletes a set of data objects. If one of these data objects is selected, the onTileDeselect event will be fired.		public function deleteData							(data:Object):void {			deleteDatas								([data]);		}		public function deleteDatas							(data:Array):void {			Debug.debug								(_debugPrefix, "Deleting " + data.length + " items.");			for each (_o in data)							deleteDataObject(_o);			sortVisibleTiles								();			updateContentBoxSize							();		}		// This adds data. If data is already here, it will be updated, otherwise added. It doesn't filter, but runs the sorting again. Filter is done externally always.		public function addData							(data:Object):void {			addDatas									([data]);		}		public function addDatas							(data:Array):void {			addDataObjects								(data);		}	// SORT		// Selects a button and sorts accordingly		public function sortOn								(headerButtNum:uint, descending:Boolean=false):void {			positionSorterTo								(headerButtNum, descending);			_selectedHeaderNum							= headerButtNum;			_sortDescending								= descending;			sortVisibleTiles								();			if (_broadcastSort)							broadcastEvent("onDataListSort", _selectedHeaderNum, _sortDescending);		}	// TILES OPERATIONS		// Deselects all tiles
		public function deselectTiles							(broadcast:Boolean=false):void {			_rolloveredTile								= null;			if (_multipleSelect && _selectedTiles.length) {
				if (broadcast) {
					for each (_tile in _selectedTiles) {						// Here I can't use toggleTileSelection() since it removes the tile form aray causing trouble...						setTileDeSelected				(_tile);
						broadcastEvent("onDataListDeselect", _tileToData[_tile]);											}				}				else {
					for each (_tile in _selectedTiles) {						// Here I can't use toggleTileSelection() since it removes the tile form aray causing trouble...						setTileDeSelected				(_tile);						}				}				_selectedTiles							= [];			}			else {				if (_selectedTile)							toggleTileSelection(_selectedTile, broadcast);			}		}		public var deselectAll								:Function = deselectTiles;		public function selectAll							():void {			if (_multipleSelect) {				for each (_tile in _tiles) {					// Here I can't use toggleTileSelection() since it removes the tile form aray causing trouble...					setTileSelected						(_tile);					}				_selectedTiles							= UCode.duplicateArray(_tiles);			}			else {				Debug.error							(_debugPrefix, "selectAll() can't be performed on single selection list.");			}		}	// RETRIEVE STUFF		// Retrieves selected tile or tiles. Returns one tile, or one array, according to selection if is multiple or single.		public function getSelected							():* {			if (_multipleSelect) {				return								_selectedTiles;			}			else 										return _selectedTile;		}		// retrieves all data		public function getData							(sorted:Boolean=false):Array {			return									sorted ? _sortedData : _data;		}		public function getTiles							(onlyVisible:Boolean=false):Array {			return									onlyVisible ? _visibleTiles : _tiles;		}
		public function getScrollBar							():ScrollBarArrows {
			return									_scrollBar;
		}		// Retireves selected data		public function getSelectedData						():* {			// Check if someting is selected first...			if ((_multipleSelect && _selectedTiles.length == 0) || (!_multipleSelect && !_selectedTile)) {				Debug.error							(_debugPrefix, "Nothing is selected! getSelectedData() can't work!");				return								null;			}			// Something is selected, return selection			if (_multipleSelect) {				var selData							:Array = [];				for each (_tile in _selectedTiles)				selData.push(_tileToData[_tile]);				return								selData;			}			else 										return _tileToData[_selectedTile];		}
		// Retieves tile by data object
		public function getDataTile							(data:Object):* {
			return									_dataToTile[data];
		}
	// SELECTION OPERATIONS
		public function selectData							(data:Object, broadcast:Boolean=false):void {
			_tile										= _dataToTile[data];
			if (_tile) {
				if (tileIsSelected(_tile))					return; // Tile is already selected
				toggleTileSelection						(_tile, broadcast);
				_contentBox.scrollToShowContent				(_tile);
			}
			else {
				Debug.debug							(_debugPrefix, "Data " + Debug.object(data) + " can't be selected. Not present in list.");
			}
		}
	// COSMETICS OPERATIONS
		public function setHeaderText						(headerIndex:uint, t:String):void {
			var b										:PippoFlashButton = _headerButtons[headerIndex];
			if (b)										b.setText(t);
			else										Debug.error(_debugPrefix, name, " cannot find button at index " + headerIndex + " to set text " + t);
		}
		public function setHeaderTextColor					(c:uint, headerIndex:Number=-1):void { // If number is specified, choses one, otherwise ALL
			var 										tf:TextFormat = UText.makeTextFormat({color:c});
			if (_headerButtons[headerIndex])					UText.setTextFormat(_headerButtons[headerIndex].getTextField(), tf);
			else {
				for each (var h:MovieClip in _headerButtons)	UText.setTextFormat(h.getTextField(), tf);
			}
		}
		public function setRowColors						(c0:uint, c1:uint):void {
			super.update								({_colorTileEven:c0, _colorTileOdd:c1}); // Updates color data
			// Loops in visible tiles and colorizes the BGs
			sortVisibleTiles								();
		}
		public function setTextColors						(c0:int, c1:int, cRoll:int=-1, cSelect:int=-1):void {
			_colorTextEven								= c0;
			_colorTextOdd								= c1;
			if (cRoll >= 0)								_colorTextRoll = cRoll;
			if (cSelect >= 0)							_colorTextSelect = cSelect;
			var tiles									:Array = getTiles();
			for each (_tile in tiles) {
				if (_tileIsEven[_tile]) {
					for each (_s in _textFieldsNames) {
						UText.setTextColor				(_tile[_s], _colorTextEven);
					}
				}
				else {
					for each (_s in _textFieldsNames) {
						UText.setTextColor				(_tile[_s], _colorTextOdd);
					}
				}
			}
		}
		public function setTileColors							(data:Object, txtCol:int=-1, bgCol:int=-1):void { // Updates colors for one tile (on re-render colorizing is lost). It gets both text and bg, but none are mandatory (if >= 0)
			_tile										= getDataTile(data);
			if (_tile) {
				if (txtCol > -1) {
					for each (_s in _textFieldsNames) {
						UText.setTextColor				(_tile[_s], txtCol);
					}
				}
				if (bgCol > -1) {
					UDisplay.setClipColor					(_tile._bg, bgCol);
				}
			}
			else {
				Debug.error							(_debugPrefix, "Tile not found, cannot setTileColors(). Data node is:\n",Debug.object(data));
			}
		}
		// RENDER //////////////////////////////////////////////////////////////////////////////////////////////////	// RENDERING SETS OF DATA		// Renders a new set of data with default functionalities. It supposes a full re-render.		private function renderData							(data:Array):void {			// Kill all previous renderings and reset all data holders			release									();			// Prepare new data holders
			_data									= [];			_data									= UCode.duplicateArray(data);
			_visibleData								= UCode.duplicateArray(_data); // In full re-render no filtering applies. Filtered data is now EQUAL to complete data.			// Render ALL tiles in data			for (var i:uint=0; i<_data.length; i++) {
				renderTileDefault							(_data[i]);			}
			// Apply sorting (assuming we keep the old sorting procedure)			sortVisibleTiles								();			// Content is set only here. Changing sorting only moves tiles around, so size remains the same, and we do not want to scroll again.			_contentBox.setContent						(_content);			// Debug report
			traceDataList								("RENDERED FIRST TIME");		}	// FILTERING WITHOUT UPDATING EXISTING TILES, BUT ADDING NEW ONES (safety)		private function filterRenderedData						(data:Array):void {			// Integrate received data			integrateData								(data);			// Set received dataset as visible. Filtering is done externally, therefore it does exist.			_visibleData								= UCode.duplicateArray(data);			// Apply sorting			sortVisibleTiles								();			// Setup new content			_contentBox.setContent						(_content);		}	// ADDING DATA		private function addDataObjects						(data:Array):void {			Debug.debug								(_debugPrefix, "Adding " + data.length + " items.");   			for each (_o in data) {				if (_dataToTile[_o]) { // tile already exists					Debug.error						(_debugPrefix, "Data already exists, can't add. Updating data object instead.");					updateRenderedData					([_o]);				}				else { // Data doesn't exist. Adding new data item.					_data.push							(_o);					_visibleData.push						(_o);					renderTileDefault						(_o);				}			}			sortVisibleTiles								();			updateContentBoxSize							();
			// Debug report
			traceDataList								("ADDED DATA: " + data.length);					}	// TILE PREPAREATION, RENDERING AND UPDATE				// Renders a new tile from data, if data doesnt exist. Otherwise it updates it.				private function renderTileDefault				(data:Object):void {
					// Render with internal default method
					if (_useTileInternalRender) {						if (_dataToTile[data]) { // Tile already exists							_tile							= _dataToTile[data];						}						else { // Tile doesn't exist - Create it and perform base operations which do not change							_tile							= UMem.getInstance(_tileClass);
							_tile._bg.width					= _w;
							_tile._bg.height					= _untouchedBaseTile._bg.height;							_dataToTile[data]				= _tile;							_tileToData[_tile]				= data;							_tiles.push						(_tile);							// Setup interactivity							if (_activateInteraction)			Buttonizer.setupButton(_tile, this, "Tile", "onPress,onRollOver,onRollOut,onRelease,onReleaseOutside");							// Reset tile content which is not used, and positions used textfields correctly for content which is in use (only on tile creation)							prepareNewTile					(_tile);						}
						// Setup textfields for automatic resizing - I re-do a loop sinc eI don't want to if for each textfield
						// This must be done BEFORE setting text since textfield size must be reset before setting text
						if (_tilesHeightBasedOnTextFields) {
							// Set text content with dynamic sizing							for (_i=0; _i<_propertiesNum; _i++) {
								_txt							= _tile[_textFieldsNames[_i]];
								if (_txt.multiline) {
									_txt.height = 1;
								}
							}
						}
						// Set text content						var tallest							:int = 0; // This is needed only if automatic height based on textfields is set
						var tallestFull						:int = 0; // This calculates tallest textfield plus margins
						for (_i=0; _i<_propertiesNum; _i++) {
							_txt							= _tile[_textFieldsNames[_i]];
// 							trace("SETTO " + _i, _textDataNames[_i], Debug.object(data));
							// Often an error is generate here. I need to trace the stack and give more info.
// 							try {
// 							trace("RENDERO",_i,_setTextFunctions[_i],_textFieldsNames[_i],_textDataNames[_i], _tile[_textFieldsNames[_i]], data[_textDataNames[_i]]);
								_setTextFunctions[_i]			(_tile[_textFieldsNames[_i]], data[_textDataNames[_i]]);
// 							}
// 							catch (e) {
// 								Debug.error				(_debugPrefix, "Error setting datalist text line. ", _i, _textFieldsNames[_i], _textDataNames[_i], data[_textDataNames[_i]] + "\n" + String(e));
// 								
// 							}
							if (_txt.height > tallest) {
								tallest = _txt.height;
								tallestFull = tallest + _txt.y * 2;
							}
						}
						// Now, if height is automatic on textfield, I set the BG to automatic height
						if (_tilesHeightBasedOnTextFields) {
							_tile._bg.height					= tallestFull;
						}
					}
					// render with normal pippoflash framework style... mhhh but sounds kind of strange... lets see...
					else {
						if (!_dataToTile[data]) { // Tile doesn't exist, create it
							_tile							= UMem.getInstance(_tileClass, data, this);
							if (_activateInteraction)			Buttonizer.setupButton(_tile, this, "Tile", "onPress,onRollOver,onRollOut,onRelease,onReleaseOutside");							_dataToTile[data]				= _tile;							_tileToData[_tile]					= data;							_tiles.push						(_tile);
						}
						// Tile exists, use existing one
						else {
							_tile 							= _dataToTile[data];
							_tile.cleanup					();
							_tile.recycle					(data, this);
						}					}				}						private function prepareNewTile			(tile:*):void {						_i							= 0;
						while (_i < _textFieldsAllNames.length) {							if (_i < _propertiesNum) { // This is a USED textfield								_txt					= tile[_textFieldsNames[_i]];								_txt.visible 				= true;								_txt.x				= _headerButtonsPos[_i] + _tilesTextMargin;								_txt.width				= _headerButtonsWidths[_i] - _doubleTextMargin;							}							else { // TextField is unused, 								tile[_textFieldsAllNames[_i]].visible = false;							}
							_i						++;						}
						// Setup textfields for automatic resizing - I re-do a loop sinc eI don't want to if for each textfield
						if (_tilesHeightBasedOnTextFields) {
							_i						= 0;
							while (_i < _textFieldsAllNames.length) {
								_txt					= tile[_textFieldsNames[_i]];
								if (_txt.multiline) {
									_txt.autoSize		= TextFieldAutoSize.LEFT;
									_txt.wordWrap		= true;
								}								_i					++;							}
						}
						setTileTextColor					(tile, _colorTextOdd);					}	// Renders data with a custom external function		private function renderNewDataCustom					():void {			/* TO BE IMPLEMENTED */		}	// UPDATING WITH RENDERING ALREDY DONE		private function updateRenderedData					(data:Array):void {
			// Render with default rendering
			if (_useTileInternalRender) {				for each (_o in data) {					_tile									= _dataToTile[_o];					if (_tile) {
						for (_i=0; _i<_propertiesNum; _i++) {
							_txt							= _tile[_textFieldsNames[_i]];
							_setTextFunctions[_i]				(_tile[_textFieldsNames[_i]], _o[_textDataNames[_i]]);						}					}					else {						Debug.error							(_debugPrefix, "Updating data failed. Data not present: " + Debug.object(_o));					}				}
			}
			// Render with custom rendering
			else {
				for each (_o in data) {					_tile									= _dataToTile[_o];					if (_tile) {
						_tile.cleanup						();
						_tile.recycle						(_o, this);
					}					else {						Debug.error						(_debugPrefix, "Updating data failed. Data not present: " + Debug.object(_o));					}				}
			}
			// Debug report
			traceDataList								("UPDATED " + Debug.object(data));					}	// DELETES DATA & TILE		// Deletes completely tile and data object		private function deleteDataObject						(data:Object):void {			// Debug report
			traceDataList								("Before delete " + Debug.object(data));			_tile										= _dataToTile[data];
			if (_tile) {
				// Check if tile is visible				var isVisible							:Boolean = _visibleData.indexOf(data) > -1;				// Broadcast toggle selection before data is deleted. Only if tile was selected.				if (_tile == _selectedTile)					toggleTileSelection(_selectedTile);
				// Remove general data				UCode.removeArrayItem					(_data, data);				UCode.removeArrayItem					(_sortedData, data);				UCode.removeArrayItem					(_tiles, _tile);				// check if it was visible and behave accordingly.				if (isVisible) {					UCode.removeArrayItem				(_visibleData, data);					UCode.removeArrayItem				(_visibleTiles, _tile);				}				// remove the tile graphics				delete								_dataToTile[data];				delete								_tileToData[_tile];				harakiriTile								(_tile);				// Nullify uty				_tile									= null;
			}			else {				Debug.debugError						(_debugPrefix, "Deleting data object, but object is not there: " + Debug.object(data));			}			// Debug report
			traceDataList								("Deleted " + Debug.object(data));		}	// RENDERING UTY		// Integrates received data with existing data, rendering new tiles.		private function integrateData						(data:Array):void {			for each (_o in data) {				if (_dataToTile[data]) {					// Tile already exists, do nothing				}				else {					// Add tile if it doesn't exist					renderTileDefault						(_o);					// Add data if it wasn't in the original data array					_data.push							(_o);				}			}		}
// SORTING ///////////////////////////////////////////////////////////////////////////////////////	// Default internal sorting		private function sortVisibleTiles						():void {			if (!_visibleData)								return; // No data has been set so far. Nothing to sort.			Debug.debug								(_debugPrefix, "Visible data items:",_visibleData.length);			UDisplay.removeClips							(_visibleTiles);			// Sort data			_sortedData								= UCode.duplicateArray(_visibleData);			var sortNumOption							:uint = (_sortList[_selectedHeaderNum].toUpperCase() == "N" ? Array.NUMERIC : Array.CASEINSENSITIVE); // Set numeric or case insensitive			if (_sortDescending ) {				_sortedData.sortOn						(_headerSortPropNames[_selectedHeaderNum], sortNumOption | Array.DESCENDING);			}			else {				_sortedData.sortOn						(_headerSortPropNames[_selectedHeaderNum], sortNumOption);			}			// Reset variables			_tileIsEven									= new Dictionary();			_visibleTiles								= [];			// Visualize tiles			var yPos									:uint = 0;			var odd									:Boolean = true;
			var yStep									:Number;			for (var i:uint=0; i<_sortedData.length; i++) {				_tile									= _dataToTile[_sortedData[i]];
				_tile.y								= yPos;				yStep								= _tileHeightAmount ? _tileHeightAmount : _tile[_tileHeightProperty];				if (odd) {					UDisplay.setClipColor					(_tile._bg, _colorTileOdd);					setTileTextColor						(_tile, _colorTextOdd);
					odd								= false;
				}				else {					UDisplay.setClipColor					(_tile._bg, _colorTileEven);					_tileIsEven[_tile]						= true; // Set tile as even					setTileTextColor						(_tile, _colorTextEven);
					odd								= true;				}				_visibleTiles.push							(_tile);				yPos									+= yStep;				_content.addChild						(_tile);			}			_tile										= null;			// Here selected tiles have to be set to selected again			reselectSelectedTiles							();		}		private function reselectSelectedTiles					():void {			if (_multipleSelect) {				for each (_tile in _selectedTiles)				setTileSelected(_tile);			}			else {				if (_selectedTile)							setTileSelected(_selectedTile);			}		}		// UTY ///////////////////////////////////////////////////////////////////////////////////////		private function positionSorterTo						(headerButtNum:uint, descending:Boolean=false):void {			var butt									:PippoFlashButton = _headerButtons[headerButtNum];			_sorter.x									= (butt.x + butt._w) - _sorter.width;			_sorter.scaleY								= descending ? -1 : 1;			_sorterBg.x									= butt.x;			_sorterBg.width								= butt._w;			if (!butt.isSelected())							butt.setSelected(true); // this is in case the sorton thing is used in code		}		private function updateContentBoxSize					():void {			_contentBox.updateLastScroll					();			_contentBox.update							({});			_contentBox.restoreScroll						();		}				public function getHeaders ():Array {			return _headerButtons;		}// TILES UTY ///////////////////////////////////////////////////////////////////////////////////////		private function tileIsSelected						(tile:*):Boolean {			if (_multipleSelect) {				return								_selectedTiles.indexOf(tile) > -1;			}			else {				return								tile == _selectedTile;			}		}		private function setTileSelected						(tile:*):void {			UDisplay.setClipColor							(tile._bg, _colorTileSelect);
			setTileTextColor								(tile, _colorTextSelect);		}		private function setTileDeSelected						(tile:*):void {			// De-selects tile according to rollover status			if (_rolloveredTile == tile)						setTileRollOver(tile);			else										setTileRollOut(tile); 		}		private function setTileRollOver						(tile:*):void {			UDisplay.setClipColor							(tile._bg, _colorTileRoll);			setTileTextColor								(tile, _colorTextRoll);		}		private function setTileRollOut						(tile:*):void {
			UDisplay.setClipColor							(tile._bg, _tileIsEven[tile] ? _colorTileEven : _colorTileOdd);			setTileTextColor								(tile, _tileIsEven[tile] ? _colorTextEven : _colorTextOdd);		}		private function toggleTileSelection					(tile:*, broadcast:Boolean=true):void { // This toggles selection AND broadcasts selection			// If TILE is already selected. DE-SELECT			if (tileIsSelected(tile)) { 				// If I should use custom functions in tile itself				if (_useTileCustomFunctions) {					UCode.callMethod					(this, "setSelected", false);				}				// Internal default de-selection process				else {					// De-select multiple tiles					setTileDeSelected					(tile);					if (_multipleSelect) { 						UCode.removeArrayItem			(_selectedTiles, tile);					}					// De-select single tile					else { 						_selectedTile					= null;					}				}				if (_broadcastPress && broadcast){
					broadcastEvent("onDataListDeselect", _tileToData[tile]);
				}			}			// Tile is NOT selected. DO SELECT TILE			else {				// If I should use custom functions in tile itself				if (_useTileCustomFunctions) {					UCode.callMethod					(this, "setSelected", true);				}				// Internal default selection process				else {					// Perform general visual operation					setTileSelected						(tile);					// Select tile for multiple selection					if (_multipleSelect) {						_selectedTiles.push				(tile);					}					// Select single tile					else { 						// de-select previously selected tile if it exists						if (_selectedTile)					toggleTileSelection(_selectedTile);						// Set tile as selected one						_selectedTile					= tile;					}				}				if (_broadcastPress && broadcast)				broadcastEvent("onDataListSelect", _tileToData[tile]);			}		}		private function harakiriTile							(tile:*):void {			UDisplay.removeClip							(tile);			if (_activateInteraction)						Buttonizer.removeButton(tile);			for each (_s in _textFieldsNames) {				tile[_s].text							= "";			}			UMem.storeInstance							(tile);		}
		private function setTileTextColor						(tile:*, color:uint):void {
			if (_useColorText) {
				for each (_s in _textFieldsAllNames)			UText.setTextColor(tile[_s], color);
			}
		}// DEBUG UTY ////////////////////////////////////////////////////////////////////////////////////////
		private function traceDataList						(id:String=""):void {
			// Debug.debug							(_debugPrefix, "--------------------------------- " + name + " items: " +_data.length+ " ------ " + id);
			//for (_i=0; _i<_data.length; _i++) trace("_data["+_i+"]\t" + Debug.object(_data[_i]));
		}// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////	// Header listeners		public function onPressHeader						(c:PippoFlashButton):void { // Changes sort completely (resets to descending)			sortOn									(_headerButtons.indexOf(c));		}		public function onPressSorterBg						(c:MovieClip=null):void { // Inverts sorting direction			sortOn									(_selectedHeaderNum, !_sortDescending);		}	// Tiles		public function onPressTile							(c:*=null):void {			// Double click stuff - if this is a double click, just that is triggered, and nothing else			if (_broadcastDoubleClick) { // I do need to intercept double click
				if (_doubleClickLastClickedTile == c && ((getTimer() - _doubleClickLastClickedTimer) < DOUBLE_CLICK_TIME)) { // Tile was already clicked
						broadcastEvent					("onDataListDoubleClick", _tileToData[c]);						_doubleClickLastClickedTile			= null;						_doubleClickLastClickedTimer		= 0;				}				else { // Tile was not clicked, set it as clicked one					_doubleClickLastClickedTile				= c;					_doubleClickLastClickedTimer			= getTimer();				}
			}			// I first do stuff for previously selected things (if selection has to be kept)			if (_keepSelected) {				toggleTileSelection						(c);			}			// Below here is stuff for single click			else { 				if (_useTileCustomFunctions) {					UCode.callMethod					(c, "onPress");				}				else {					setTileSelected						(c);				}				if (_broadcastPress)						broadcastEvent("onDataListPress", _tileToData[c]);			}		}		public function onReleaseTile							(c:*=null):void {			if (_keepSelected) { // Selection is not removed				// Do nothing				return;			}			// Below here is stuff for single click			else {				if (_useTileCustomFunctions) {					UCode.callMethod					(c, "onRelease");				}				else {					if (_rolloveredTile == c) 				UDisplay.setClipColor(c._bg, _colorTileRoll);				}			}			if (_broadcastPress)							broadcastEvent("onDataListRelease", _tileToData[c]);		}		public function onRollOverTile						(c:*=null):void {			_rolloveredTile								= c;			if (tileIsSelected(c))							return;			if (_useTileCustomFunctions) {				UCode.callMethod						(c, "onRollOver");			}			else {				UDisplay.setClipColor						(c._bg, _colorTileRoll);			}			if (_broadcastRoll)							broadcastEvent("onDataListRollOver", _tileToData[c]);		}		public function onRollOutTile							(c:*=null):void {			if (_useTileCustomFunctions) {				UCode.callMethod						(c, "onRollOut");			}			else {				if (_keepSelected && tileIsSelected(c)) { // Selection is not removed									}				else {					UDisplay.setClipColor					(c._bg, _tileIsEven[c] ? _colorTileEven : _colorTileOdd);				}			}			if (_broadcastRoll)							broadcastEvent("onDataListRollOut", _tileToData[c]);		}	}}

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