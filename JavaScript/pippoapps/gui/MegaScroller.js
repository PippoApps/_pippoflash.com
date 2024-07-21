"use strict";
import PippoAppsJSBase from "../PippoAppsJSBase.js";
import ScrollBar from "../components/ScrollBar.js";
import ToolTip from "../components/ToolTip.js"; 
// MODULE CONSTANTS //////////////////////////////////////
// ANIMATION
const ANIM_USE_ANAMORPHIC = true; // Whether to use anamorphic animation
const HELPER_CLASS_TILE_ID = "New"; // "Default", "New", Which tile to use. Tiles classes references are set in a constants after initialization at the end of class.
// EVENTS
const EVT_TILES_SELECTION_UPDATED = "onTilesSelectionUpdated"; // Array of IDs of data objects of selected tiles
const EVT_TILE_SELECTED = "onTileSelected"; // ID
const EVT_TILE_DESELECTED = "onTileDeselected" // ID
const EVT_TILES_ALL_DESELECTED = "onAllTilesDeselected";
const EVT_CLICK_TILE = "onClickTile";
const EVT_ROLLOVER_TILE = "onRolloverTile"; // Sent with data.id as single parameter
const EVT_ROLLOVER_REMOVED = "onRolloverRemoved"; // When roller is closed
// INFO DATA - retrievable by user
const INFO_DATA = {tilesNum:0, tilesData:[], lastSelectedTileId:null, selectedTilesIds:null, lastSelecteTileIndex:-1}; // 
// SYSTEM
const TILES_X_MARGIN = 10; // X position of tiles (enough to leave space for marker)
const DESELECT_ON_RECLICK_IN_SINGLE_SELECTION = false; // If clicking again on one tile in SINGLE selection deselects it
const FORCE_ALWAYS_CTRL_SELECTED = true; // On multiple selection, click behaves always like keeping CTRL down
const SUBSITUTE_STATUS_VARIABLE_NAME = "status4rullo"; // If tis string is set, the variable "status" will be overwritten by the string in variable
// TOOLTIP
const TOOLTIP_TIMEOUT = 300; // Milliseconds before tooltip appears
const TOOLTIP_WIDTH = 400; // Width in pixels
// ROLLOVER FOR ANAMORPHIC ANIMATION
const ROLLED_TILE_HEIGHT = 46; // Heght of rolled tile (this will also scale width);
const EXTENDED_ENLARGED_TILES_AMOUNT = 5; // Besides main enlarged tile, other tiles are enlarged on top and bottom
const ENTIRE_ROLL_HEIGHT = 176; // Entire roller height
const MINIMUM_TILE_HEIGHT = 10; // Minimum height a tile can be shrunk
const MAXIMUM_TILE_HEIGHT = 24; // Maximum height, when they are all visible and stay in one page
const USE_MOUSE_WHEEL = true; // If to show tiles outside of viewport I can use mousewhee
// Change 
// MARKERS
const USE_MARKERS = true; // If markers need to be rendered
const MARKERS_COLUMN_WIDTH = 30; // Width of markers column
 
const MARKERS_RIGHT_MARGIN = 3;
const TILES_NUMERIC_MARKER_STEP = 10; // Each group of tiles there is a bg numeric stepper
const MARKER_FONT = "12px Arial";
const MARKER_COLOR = "#cccccc"; 
const MARKER_CHARACTER = ">";
const FPS = 3; // Frames per second
// SCROLLBAR
const SCROLLBAR = true;
const SCROLLBAR_WIDTH = 20;
// VISUAL INDICATORS
const SELECTED_WIDTH = 8;
const STATUS_WIDTH = 8;
// DEBUG
const DEBUG_BLOCK_ROLLOVER = false;
// CLASS /////////////////////////////////////////////
export default class MegaScroller extends PippoAppsJSBase {
    // Constants
    // static HELPER_CLASS_NAME_TO_CLASS = {"Default":MSTile};

    constructor(megaScrollerId, x=0, y=0, width=200, height=100, htmlCanvasId) {
        super(megaScrollerId, htmlCanvasId);
        // VARIABLES /////////////////////////////////////////////////////////////
        // SYSTEM
        this._selectionMultiple = false; // If true, multiple selection is allowed
        this.logScream("Selected tile class: " + HELPER_CLASS_TILE_ID)
        this._tileClass = HELPER_CLASS_NAME_TO_TILE_CLASS[HELPER_CLASS_TILE_ID]; // Stores the class for tile set in HELPER_CLASS_TILE_ID
        this._markerClass = HELPER_CLASS_NAME_TO_MARKER_CLASS[HELPER_CLASS_TILE_ID]; // Stores the class for marker set in HELPER_CLASS_TILE_ID
        // SCROLLBAR
        this._scrollBar; // If scrollbar is active this creates a scrollbar
        // DATA RETRIEVABLE
        this._infoData;
        // TILES
        this._tilesNum; // Total number of tiles
        this._tiles; // All tile instances
        this._tilesById; // Tiles by their string id
        this._visibleTiles; // Visible tile instances after filtering
        this._tilesData; // Complete array of tiles data
        this._tilesH; // Normal tile height
        this._allTilesH; // Height of all rendered tiles (not rollovered)
        // TILE MARKERS
        this._markers; // Array with visible markers
        this._markersByNumber = []; // Markers are stored in array with their own number
        // VIEWPORT AND SCROLL
        this._viewportX = x; // X position of visible viewport, on STAGE, for TILES only
        this._viewportY = y; // Y position of visible viewport, on STAGE, for TILES only
        this._viewportHeight = 0; // Height of visible viewport
        this._viewportContentOffset = 0; // Y offset position of content compared to viewport (not used yet)
        this._maxViewportContentOffset; // Maximum scroll allowed
        this._viewportWidth = width; // Total width of visible applet
        this._activeScrollerAreaW; // width of max scrolling area (removed space for scrollbar and markers)
        // ROLLOVERING
        this._rollMainH; // Size of main rolled element, must be a multiple of tile height
        this._rollTileMainHDelta; // Different in height, to be balanced according to position on tile
        this._rolledTilesNums; // Array with index of rollovered tiles in order to make them invisible
        this._rollTilesNumsPre; // Array with rollovered tiles before main
        this._rollTilesNumsPost; // Array with rollovered tiles after main
        this._rollTilesYStart; // First Y pixel available below displaced tiles on top of rollover
        this._rollTilesYEnd; // Y position of first displaced tile below rollovered ones
        // MARKERS
        this._isSelected; // If tile is selected
        this._isRollovered; // Roller is active and visible
        this._scrollActive; // If content can be scrolled
        this._selectedTile; // Reference to the selected tile
        this._selectedTileIds; // List of IDs of selected tiles for multiple selection
        this._rollActive; // Marks if rollover is active or not (depending where mouse is)
        this._enlargeOnRoll; // Marks if tiles need to be anlarged when rolled over
        this._blockTileSelection; // If tile selection is blocked, and only tile press event is sent
        // SELECTION
        this._rollingTile; // index of rollovered tile
        this._rollingTileInstance; // Instance of rolling tile
        this._rollingTileRatio; // y position perc of mouse on top of tile (0 to 1)
        this._rollingTileSprite; // Sprite object of rolled tile
        this._rollingSpriteMaxScale; // Scale of rolled sprite calculated from dimensions
        // SPRITES
        this._mainContainer;
        this._scrollableContainer;
        this._tilesHolder;
        // TOOLTIP 
        this._toolTip = new ToolTip("Tooltip", TOOLTIP_WIDTH);
        this._toolTipTimeout; // Stores setTimeout instance
        // STATUSES
        // this._statusColors = []; // Populated with setStatusColors
        // INIT //////////////////////////////////////////////////////////////////
        this._stage.addEventListener("mouseleave", this._onMouseLeave.bind(this))
        this._stage.addEventListener("mouseenter", this._onMouseEnter.bind(this))
        this.position(x, y);
        this.resize(this._canvas.width, height);
        // this.logScream("height",height);

        // Create main assets
        this._scrollableContainer = new createjs.Container();
        this._tilesHolder = new createjs.Container();
        this._mainContainer.addChild(this._scrollableContainer);
        this._scrollableContainer.addChild(this._tilesHolder);
        this._stage.addChild(this._mainContainer);
        this._mainContainer.y = this._viewportY;
        // Scrollbar
        if (SCROLLBAR) {
            this._scrollBar = new ScrollBar("DocsScrollBar", SCROLLBAR_WIDTH, height);
            this._scrollBar.addListener(this);
            this._mainContainer.addChild(this._scrollBar.asset)
        }
        // Initialise helper classes constants
        this._tileClass._mainScroller = this;
        this._tileClass.TXT_X += STATUS_WIDTH + SELECTED_WIDTH;
        // Activate info data
        this.__resetInfoData();
        // Update
        this.update();
        // Activate mouse wheel
        if (USE_MOUSE_WHEEL) this._activateMouseWheel();
    }
    // MOUSE WHEEL ////////////////////////////////////////////
    _activateMouseWheel() {
        this.log("Mouse Wheel activated.");
        this._canvas.addEventListener("mousewheel", this.__onMouseWheel.bind(this), false);
    }




















    // METHODS ///////////////////////////////////////////////////////////////////////
    scrollContent(scrollNum=0, resetBeforeScrolling=false, tilePosition="TOP") {
        // console.log(scrollNum)
        if (!this._scrollActive) return; // Scroll is deactivated
        // console.log(scrollNum)
        if (resetBeforeScrolling) this._viewportContentOffset = -scrollNum;
        else this._viewportContentOffset -= scrollNum;
        // Position tile TOP, MIDDLE, BOTTOM
        if (tilePosition == "MIDDLE") this._viewportContentOffset -= (this._viewportHeight+this._tilesH)/2;
        else if (tilePosition == "BOTTOM") this._viewportContentOffset -= (this._viewportHeight-this._tilesH);


        if (this._viewportContentOffset < 0) this._viewportContentOffset = 0;
        else if (this._viewportContentOffset > this._maxViewportContentOffset) this._viewportContentOffset = this._maxViewportContentOffset;
        this._scrollableContainer.y = -this._viewportContentOffset;
        ToolTip._toolTip.remove();
        this._onMouseMove();
    }
    scrollToVisibleId(id="tile ID", resetBeforeScrolling=false, tilePosition="TOP") {
        this.log("Requested to scroll to id: " + id);
        var scrollTile = this._tilesById[id];
        let error;
        if (!scrollTile) error = "scrollToVisibleId() error, there is no tile with selected id: " + id;
        else if (this._visibleTiles.indexOf(scrollTile) == -1) error = "scrollToVisibleId() error, tile with selected ID is not visible: " + id;
        if (error) this.logError(error);
        else {
            const tileY = this._tilesH * this._visibleTiles.indexOf(scrollTile);
            this.scrollContent(-tileY, resetBeforeScrolling, tilePosition);
            this._scrollBar.setScroll(this._viewportContentOffset);
            this.log("Scrolling to tile position: " + id)
        }
    }
    resizeAll(w, h) {
        super.resizeW(w);
        this._viewportWidth = w;
        this.resizeVertical(h);
    }
    resizeVertical(h) {
        this._removeRoller();
        this.resetScroll();
        super.resizeH(h);
        this._scrollBar.resizeVertical(h, h, this._allTilesH);
        // Manage re-selection
        let isSelected = this._isSelected;
        let selectedTileIds = this._selectedTileIds;
        let selectedTileId = this._selectedTile ? this._selectedTile.id : null; 
        // Proceed re-rendering
        this.renderTiles(this._tilesData);
        // Re-select in case
        if (isSelected) {
            if (this._selectionMultiple) { // Reselect multiple tiles
                if (selectedTileIds) this.selectMultipleTiles(selectedTileIds);
            } else { // Reselect single tile
                if (selectedTileId) {
                    this.selectTileId(selectedTileId);
                }
            }
        }
        
    }
    resetScroll() {
        // console.log(scrollNum)
        if (!this._scrollActive) return; // Scroll is deactivated
        // console.log(scrollNum)
        this._viewportContentOffset = 0;
        // if (this._viewportContentOffset < 0) this._viewportContentOffset = 0;
        // else if (this._viewportContentOffset > this._maxViewportContentOffset) this._viewportContentOffset = this._maxViewportContentOffset;
        this._scrollableContainer.y = 0;
        ToolTip._toolTip.remove();
        this._onMouseMove();
        this._scrollBar.resetScroll(true);
        this.update();
    }
    setStatusColors(colors) {
        this._tileClass.STATUS_COLORS = colors;
    }
    setSelectionMultiple(s) {
        if (this._selectionMultiple == s) return;
        this._selectionMultiple = s;
        this.deselectAll();
    }
    deselectAll(broadcast=false) {
        if (this._tiles) {
            this._tiles.forEach(element => {
                element.selected = false;
            });
        }
        this._isSelected = false;
        this._selectedTile = null;
        this._selectedTileIds = [];
        this.__updateInfoData();
        this.update();
        if (broadcast) this.broadcastEvent(EVT_TILES_ALL_DESELECTED, this._selectedTileIds);
    }
    selectPreviousTile(broadcast=true, scroll=true) {
        let tile = this._getRelativeTileToSelected(-1);
        if (tile) {
            if (scroll) this.scrollToVisibleId(tile.id, true, "MIDDLE");
            this.selectTileId(tile.id, broadcast);
        } else this.logError("Cannot select previous tile.");
    }
    selectNextTile(broadcast=true, scroll=true) { 
        let tile = this._getRelativeTileToSelected(1);
        if (tile) {
            if (scroll) this.scrollToVisibleId(tile.id, true, "MIDDLE");
            this.selectTileId(tile.id, broadcast);
            // if (scroll) setTimeout(() => {
                // this.scrollToVisibleId(tile.id);
            // }, 10); 
        } else this.logError("Cannot select next tile.");
    }
    selectTileId(id, broadcast=false) {
        this._toggleTileSelection(this._tilesById[id], broadcast);
        this.update();
    }
    selectMultipleTiles(ids, broadcast=false) {
        ids.forEach(id => {
            if (this._tilesById[id]) this._toggleTileSelection(this._tilesById[id], broadcast, "CTRL");
        });
        this.update();
    }
    setBlockSelection(block) {
        this._blockTileSelection = block;
    }







    // GETTERS ////////////////////////////////////////////////////
    get rolloveredTile() {return this._rollingTileInstance};
    get rolloveredData() {return this._rollingTileInstance ? this._rollingTileInstance.data : "NO ROLLOVERED TILE"};
    get selectedIds() {return this._selectedTileIds};
    get infoData() {
        return this._infoData;
    }
    get selectedPreviousLabel() { // Label of PREVIOUS tile of selected one. String or null if there is no next tile, or no tile selected
        let tile = this._getRelativeTileToSelected(-1);
        if (tile) return tile.label;
        else return null;
    }
    get selectedNextLabel() { // Label of NEXT tile of selected one. String or null if there is no next tile, or no tile selected
        let tile = this._getRelativeTileToSelected(1);
        if (tile) return tile.label;
        else return null;
    }
    _getRelativeTileToSelected(relation=1) { // Returns a relative tile. -1 is previous, +1 next. Returns null if no tile found.
        let index;
        if (this._selectionMultiple) {
            if (this._selectedTileIds.length) {
                let id = this._selectedTileIds.last();
                index = this._visibleTiles.indexOf(this._tilesById[id]);
            }
        } else {
            if (this._isSelected) {
                index = this._visibleTiles.indexOf(this._selectedTile);
            }
        }
        let relativeIndex = index + relation;
        let tile;
        if (relativeIndex > -1) tile = this._visibleTiles[relativeIndex];
        return tile;
    }











    // INTERNAL EVENT LISTENERS ///////////////////////////////////////////
    __onMouseWheel(e) {
        this.scrollContent(e.wheelDelta);
        this._scrollBar.setScroll(this._viewportContentOffset);
    }
    _onMouseMove(event) {
        // this.log(this._stage.mouseY, this.localMouse);
        if (!this._rollActive) return;
         let x = this._stage.mouseX; let y = this._stage.mouseY;
        if (x < this._viewportX || y < this._viewportY || x > this._viewportX + this._activeScrollerAreaW || y > this._viewportY + this._viewportHeight) {
            // Mouse is not on tiles
            if (this._isRollovered) this._removeRoller();
            return;
        }
        
        let localMousePoint = this._tilesHolder.globalToLocal(this._stage.mouseX, this._stage.mouseY);
        let rollingTile = Math.floor(localMousePoint.y / this._tilesH);
        let tile = this._visibleTiles[rollingTile];
        if (!tile) {
            // reset previously rolled tile if any - rollovering another tile is automatic
            if (this._isRollovered) this._removeRoller();
            return; // We are rollovering on an empty area
        }
        // Setup tile as main rollovered one
        // tile.mainRollover = true;
        // Find percent of position not based on tile actual position but on numbers (since tiles are displaced). Also add tiles scroll offset
        let yy = ((y - this._viewportY) + this._viewportContentOffset) - this._tilesH * rollingTile;
        let rollingTileRatio = yy / this._tilesH;
        if (this._rollingTile != rollingTile) {
            this._rollingTile = rollingTile;
            this._rollingTileInstance = tile;
            if (this._rollingTileSprite) this._rollingTileSprite.scale = 1;
            this._rollingTileSprite = tile.sprite;
            this._rollingTileRatio = rollingTileRatio;
            this._setupRoller();
        } else if (this._rollingTileRatio != rollingTileRatio) {
            this._rollingTileRatio = rollingTileRatio;
            this._updateRoller();
        }
        // Setup tooltip things
        if (this._toolTipTimeout) clearTimeout(this._toolTipTimeout);
        this._toolTipTimeout = setTimeout(this._onRollOverTimeout.bind(this), TOOLTIP_TIMEOUT, this._rollingTileInstance);
    }
    _onRollOverTimeout(tile) {
        // this.log("timeout", tile.id);
        if (tile == this.rolloveredTile) {
            ToolTip.toolTip.appear(tile.txt);
        }
    }
    _onMouseLeave(event) {
        // this.log("mousleave")
        this._rollActive = false;
        this._stage.removeEventListener("stagemousemove", this._onMouseMove.bind(this))
        if (this._isRollovered) this._removeRoller();
        ToolTip._toolTip.remove();
    }
    _onMouseEnter(event) {
        // this.log("mouseenter")
        this._rollActive = true;
        this._stage.addEventListener("stagemousemove", this._onMouseMove.bind(this))
    }

    // EXTERNAL EVENT LISTENERS ///////////////////////////////////
    onScroll(scrollNum) {
        this.scrollContent(this._viewportContentOffset-(scrollNum * this._maxViewportContentOffset));
    }
    onClickTile(event) {
        // this.log("PIPPO")
        // DEBUG - BY NOW JUST BROADCAST EVENT
        this.broadcastMainAppEvent(EVT_CLICK_TILE, event.currentTarget.data);
        // Check if tile clicking is blocked
        if (this._blockTileSelection) {
            // window.alert("SELECTION IS BLOCKED");
            this.logScream("Selection is blocked. Broadcasting event: " + EVT_CLICK_TILE)
            this.broadcastEvent(EVT_CLICK_TILE, event.currentTarget.data);
            return;
        }

        // Proced with norma events
        this._toggleTileSelection(this._tilesById[event.currentTarget.data.id], true, (event.nativeEvent.shiftKey ? "SHIFT" : event.nativeEvent.ctrlKey || FORCE_ALWAYS_CTRL_SELECTED ? "CTRL" : null));        
    }




    // UTY //////////////////////////////////////////////////
    // SELECTION
    _toggleTileSelection(tile, broadcast=true, keyPressed=null, forceSingleSelection=false) {
        if (this._selectionMultiple && !forceSingleSelection) {
            if (keyPressed) this.log("Key pressed: " + keyPressed);
            let ctrlKey = keyPressed == "CTRL";
            let shiftKey = keyPressed == "SHIFT";
            if (FORCE_ALWAYS_CTRL_SELECTED && !shiftKey) ctrlKey = true; // CTRL forced works only if SHIFT is not pressed, or it will take over 
               // CTRL is pressed, multiple selection behaves normally
               // OR this is the first tile selected, therefore it can be selected normally 
               console.log(this._selectedTileIds)
            if (ctrlKey || this._selectedTileIds.length == 0) {
                if (this._selectedTileIds.includes(tile.id)) {
                    this.log("deselected",tile.id);
                    this._selectedTileIds.splice(this._selectedTileIds.indexOf(tile.id), 1);
                    tile.selected = false;
                    this.__updateInfoData();
                    if (broadcast) this.broadcastEvent(EVT_TILE_DESELECTED, tile.data);
                    if (this._selectedTileIds.length == 0) this._isSelected = false;
                } else { // Event de-select is triggered only on deselection, not changing selection
                    // Proceed selecting
                    this.log("selected",tile.id)
                    this._selectedTileIds.push(tile.id);
                    this._isSelected = true;
                    tile.selected = true;
                    this.__updateInfoData();
                    if (broadcast) this.broadcastEvent(EVT_TILE_SELECTED, tile.data);
                }
            }
            // SHIFT key is pressed, we only proceed selecting a range of tiles and deselecting all other tiles
            else if (shiftKey) {
                this.logError("SHIFT selection not yet implemented");
                // Find range of tiles to select
                const lastSelectedTile = this._tilesById[this._selectedTileIds[this._selectedTileIds.length-1]];
                const firstSelectedTileIndex = this._visibleTiles.indexOf(lastSelectedTile);
                const clickedTileIndex = this._visibleTiles.indexOf(tile);
                if (firstSelectedTileIndex == clickedTileIndex) {
                    this.log("SHIFT clicking the same tile, nothing happens.");
                    return;
                }
                this.log("Previously selected index: " + firstSelectedTileIndex + ", clicked index: " + clickedTileIndex);
                // Prepare array of tiles to select, according to position in list
                // Last tile to be set as selected must be the first one so that selection might overwrite old selection
                const tileIdsToSelect = [];
                if (firstSelectedTileIndex < clickedTileIndex) { // Loop from lower to higher
                    for (let i = clickedTileIndex; i >=firstSelectedTileIndex; i--) {
                        tileIdsToSelect.push(this._visibleTiles[i].id);
                    }
                } else { // Loop from higher to lower
                    for (let i = clickedTileIndex; i <=firstSelectedTileIndex; i++) {
                        tileIdsToSelect.push(this._visibleTiles[i].id);
                    }
                }
                // Proceed selecting tiles list
                this.log("SHIFT selected tiles: " + tileIdsToSelect);
                this.deselectAll(broadcast);
                this.selectMultipleTiles(tileIdsToSelect, broadcast);
                // infoData is adjusted accordingly from selectMultipleTiles (goes on as with CTRL);

            }
            // No modifier key, in multiple selection it proceeds de-selecting all tiles and selecting only one in single selection
            else { // Deselect all tiels and call again this method as if no tiles were selected
                this.deselectAll(broadcast);
                // this._broadcastTilesSelectionUpdated(broadcast);
                // if (broadcast) this.broadcastEvent(EVT_TILES_SELECTION_UPDATED, this._selectedTileIds);
                this._toggleTileSelection(tile, broadcast); // Runs as with CTRL key
                // return;
            }

            this._broadcastTilesSelectionUpdated(broadcast);
            // if (broadcast) this.broadcastEvent(EVT_TILES_SELECTION_UPDATED, this._selectedTileIds);
        } else { // Single tile selection
            // Deselect if already selected
            if (tile == this._selectedTile && DESELECT_ON_RECLICK_IN_SINGLE_SELECTION) {
                this.log("deselected",tile.id);
                this._selectedTile.selected = false;
                this._isSelected = false;
                this._selectedTile = null;
                this.__updateInfoData();
                this.broadcastEvent(EVT_TILE_DESELECTED, tile.data);
            } else { // Event de-select is triggered only on deselection, not changing selection
                // Deselect if anothe rone is selected
                if (this._selectedTile) this._selectedTile.selected = false;
                // Proceed selecting
                this.log("selected",tile.id)
                this._selectedTile = tile;
                this._selectedTile.selected = true;
                this._isSelected = true;
                this.__updateInfoData();
                this.broadcastEvent(EVT_TILE_SELECTED, tile.data);
            }
        }
        this.update();
    }
    _broadcastTilesSelectionUpdated(broadcast=true) {
        if (broadcast) this.broadcastEvent(EVT_TILES_SELECTION_UPDATED, this._selectedTileIds);
    }











    // #####   ####  #      #       ####  #    # ###### #####  
    // #    # #    # #      #      #    # #    # #      #    # 
    // #    # #    # #      #      #    # #    # #####  #    # 
    // #####  #    # #      #      #    # #    # #      #####  
    // #   #  #    # #      #      #    #  #  #  #      #   #  
    // #    #  ####  ###### ######  ####    ##   ###### #    # 
    _removeRoller() {
        this.log("Removing roller.")
        this.__restoreRolledTiles();
        this.__updateAllMarkersPosition();
        this._isRollovered = false;
        this._rollingTile = null;
        this._rolledTilesNums = null;
        this._rollingTileSprite = null;
        if (this._rollingTileInstance) this._rollingTileInstance.mainRollover = false;
        this._rollingTileInstance = null;
        this.broadcastEvent(EVT_ROLLOVER_REMOVED);
        this.update();
    }
    _setupRoller() {
        if (DEBUG_BLOCK_ROLLOVER) return;
        this._isRollovered = true;
        // Restore previously selected tiles
        this.__restoreRolledTiles();
        // Set rolled tile as rollovered
        this._visibleTiles[this._rollingTile].mainRollover = true;
        // Bring tile on foreground
        // Create newly selected tiles
        this._rolledTilesNums = [];
        // Create dimensions for newly selected tiles.
        // Do the animated roller thing only if scroll is active
        if (this._enlargeOnRoll) {
            let counter = 1;
            let openingDelta = (ENTIRE_ROLL_HEIGHT - this._tilesH) /2;
            let openingFullSpace = openingDelta + (EXTENDED_ENLARGED_TILES_AMOUNT * this._tilesH);
            this._rollTilesNumsPre = [];
            for (let i = this._rollingTile-EXTENDED_ENLARGED_TILES_AMOUNT; i < this._rollingTile; i++) {
                this._rolledTilesNums.push(i);   
                this._rollTilesNumsPre.push(i);
            }
            this._rolledTilesNums.push(this._rollingTile);
            this._rollTilesNumsPost = [];
        for (let i = this._rollingTile+1; i <= this._rollingTile+EXTENDED_ENLARGED_TILES_AMOUNT; i++) {
                if (i < this._visibleTiles.length) {
                    this._rolledTilesNums.push(i);   
                    this._rollTilesNumsPost.push(i);
                }
            }

            // Displace unchanged tiles
            for (let i = 0; i < this._rolledTilesNums[0]; i++) {
                let tile = this._visibleTiles[i];
                tile.sprite.y = (i * this._tilesH) - openingDelta;
            }
                
            for (let i = this._rolledTilesNums[this._rolledTilesNums.length-1]+1; i < this._visibleTiles.length; i++) {
                let tile = this._visibleTiles[i];
                tile.sprite.y = (i * this._tilesH) + openingDelta;
            }
            // Activate rollover in rolled tiles
            for (let i = 0; i < this._rolledTilesNums.length; i++) {
                const tile = this._visibleTiles[this._rolledTilesNums[i]];
                if (tile) tile.rollover = true;
            }
            // Update markers position
            this.__updateAllMarkersPosition();
            // Grab initial and ending Y point where tiles moved
            let lastTile = this._visibleTiles[this._rolledTilesNums[0]-1];
            this._rollTilesYStart = this._rollingTileSprite.y - openingFullSpace;
            let nextTile = this._visibleTiles[this._rolledTilesNums[this._rolledTilesNums.length-1]+1];
            this._rollTilesYEnd = this._rollingTileSprite.y + this._tilesH + openingFullSpace;
            // Modify height of rollovered tile
            this._rollingTileSprite.scale = this._rollingSpriteMaxScale;
            this._updateRoller();
        }
        else {
            this.update();
        }
    }
    __restoreRolledTiles() {
        if (this._rollingTileSprite) {
            this._rollingTileSprite.scale = 1;
        }
        let tile;
        for (let i = 0; i < this._visibleTiles.length; i++) {
            tile = this._visibleTiles[i];
            tile.sprite.y = this._tilesH * i;
            tile.sprite.scale = 1;
            tile.rollover = false;
        }
    }
    __updateAllMarkersPosition() {
        this._markers.forEach(marker =>{marker.positionToTile()})
    }
    _updateRoller() {
        if (DEBUG_BLOCK_ROLLOVER) return; // Rollover is blocked for debugging reasons
        if (!this._enlargeOnRoll) return; // There is nothing to scroll therefore rollover is blocked
        this._tiles[this._rollingTile].updateMarker();
        // Main roller tile Y position
        let mainRollerTileY = (this._tilesH * this._rollingTile) - (this._rollTileMainHDelta * this._rollingTileRatio);
        let mainRollerTileLowerY = mainRollerTileY + this._rollMainH;
        this._rollingTileSprite.y = mainRollerTileY;
        // Position other tiles accordingly.
        // Find available space below and on top
        let topSpace = mainRollerTileY - this._rollTilesYStart;
        let bottomSpace = this._rollTilesYEnd - (mainRollerTileY + this._rollMainH);
        // Find positions and sizes of top and below stretched tiles
        let dividersUp = [0]; let dividersDown = []; let totalSteps = 0;
        // Find total number of steps
        for (let i = 0; i < EXTENDED_ENLARGED_TILES_AMOUNT; i++) {
            totalSteps += i+1;     
            dividersUp.push(i+1);
            dividersDown[i] = EXTENDED_ENLARGED_TILES_AMOUNT - i;
        }
        // Find top divider unit
        let dividerSpace = topSpace / totalSteps;
        // Distribute top
        let lastY = 0;
        let newY; let yPos = [];
        // Create positions
        for (let i = 0; i < dividersUp.length; i++) {
            if (i == 0) newY = 0;
            else {
                newY = dividersUp[i] * dividerSpace;
                if (newY < this._tilesH) newY = this._tilesH;
            }
            lastY += newY;
            yPos.push(lastY);
            
       }
       // Position tiles
       for (let i = 0; i < dividersUp.length; i++) {
            let tile = this._visibleTiles[this._rollTilesNumsPre[i]];
            if (tile) {
                tile.sprite.y = yPos[i] + this._rollTilesYStart;
                tile.updateMarker();
            }
        }
        // Scale top
        for (let i = 0; i <= dividersUp.length; i++) {
            let tile = this._visibleTiles[this._rollTilesNumsPre[i]];
            if (tile) {
                if (i == dividersUp.length-1) {
                    tile.sprite.scale = (mainRollerTileY - yPos[dividersUp.length-1]) / this._tilesH;
                }
                else {
                    tile.sprite.scale = (yPos[i+1] - yPos[i]) / this._tilesH;
                }
            }
        }
        // Find bottom divider unit
        dividerSpace = bottomSpace / totalSteps;
        // Distribute bottom
        yPos = [];
        // First I creat an array of positions starting from the bottom
        // Create positions
        for (let i = 0; i < dividersUp.length-1; i++) {
            newY = (dividersUp[i+1] * dividerSpace);
            if (newY < this._tilesH) newY = this._tilesH;
            yPos.push(newY);
        }
       // Position tiles
       lastY = this._rollTilesYEnd;
       for (let i = 0; i < dividersUp.length; i++) {
            lastY -= yPos[i];
            let tile = this._visibleTiles[this._rollTilesNumsPost[EXTENDED_ENLARGED_TILES_AMOUNT-(i+1)]];
            if (tile) {
                tile.sprite.y = lastY;
                tile.sprite.scale = yPos[i]/this._tilesH;
                tile.updateMarker();
            }
        }
        this.update();
    }











    // RENDERING TILES ////////////////////////////////////////////////////////
    renderTiles(tilesData) {
        if (this._tilesData) this.release();
        // else this.__resetInfoData();
        this._tilesData = tilesData;
        this._tilesNum = tilesData.length;
        this.__updateInfoData();
        // Proceed rendering
        this.log(this, "Rendering tiles: " + this._tilesNum);
        this.updateSize();
        this._tiles = [];
        this._visibleTiles = [];
        this._selectedTileIds = [];
        this._tilesById = {};
        this._tilesData.forEach(element => {
            // _pippoApps.logItem(this, element)
            // Fix status4rullo
            if (SUBSITUTE_STATUS_VARIABLE_NAME) element.status = element.status4rullo;
            let tile = new this._tileClass(element);
            this._tiles.push(tile);
            this._visibleTiles.push(tile);
            this._tilesById[element.id] = tile;
            this._tilesHolder.addChild(tile.sprite);
            tile.sprite.addEventListener("click", this.onClickTile.bind(this));
        });
        this.orderInitialTiles();
        // this._stage.addChild(this._tilesHolder)
        // this.update();
        // if (USE_MARKERS) setTimeout(this.renderMarkers.bind(this), 50);
        if (USE_MARKERS) this.renderMarkers();
        this.update();
    }
    release() {
        this.log(this, "Releasing data.");
        this.resetScroll();
        this._tileData = null;
        this._tilesHolder.removeAllChildren();
        let tile; let marker;
        for (let i = 0; i < this._tiles.length; i++) {
            tile = this._tiles[i];
            tile.release();
        }
        this._tiles = null;
        for (let i = 0; i < this._markers.length; i++) {
            marker = this._markers[i];
            marker.release();
        }
        this._markers = null;
        this._isSelected = false;
        this._selectedTile = null;
        this._selectedTileIds = [];
        this.__resetInfoData();
    }
    __resetInfoData() {
        // Reset info data - copy from original
        this._infoData = JSON.parse(JSON.stringify(INFO_DATA));
    }
    __updateInfoData() {
        // {tilesNum:0, tilesData:[], lastSelectedTileId:null, selectedTilesIds:[], lastSelecteTileIndex:0}; // 
        this._infoData.tilesNum = this._tilesNum;
        this._infoData.tilesData = this._tilesData;
        this._infoData.lastSelectedTileId = null;
        this._infoData.lastSelecteTileIndex = -1;
        this._infoData.selectedTilesIds = null;
        if (this._selectionMultiple) { // Selezione multipla
            this._infoData.selectedTilesIds = this._selectedTileIds;
            if (this._selectedTileIds.length) {
                this._infoData.lastSelectedTileId = this._selectedTileIds[this._selectedTileIds.length-1];
                this._infoData.lastSelecteTileIndex = this._visibleTiles.indexOf(this._tilesById[this._infoData.lastSelectedTileId]);
            } else {
            }
        } else { // Selezione singola
            if (this._isSelected) {
                this._infoData.lastSelectedTileId = this._selectedTile.id;
                this._infoData.lastSelecteTileIndex = this._visibleTiles.indexOf(this._selectedTile);
            }
        }
    }
    updateSize() {
        // General size
        this._viewportHeight = this._h - this._viewportY; 
        let tilesXPos = TILES_X_MARGIN;
        if (SCROLLBAR) tilesXPos += SCROLLBAR_WIDTH;
        if (USE_MARKERS) tilesXPos += MARKERS_COLUMN_WIDTH;
        this._scrollableContainer.x = tilesXPos;
        this._viewportX = this._x + tilesXPos;
        this._activeScrollerAreaW = this._viewportWidth - tilesXPos;
        this.log("ViewPort Height: " + this._viewportHeight)
        let h = this._viewportHeight/this._tilesNum;
        if (h < MINIMUM_TILE_HEIGHT) h = MINIMUM_TILE_HEIGHT;
        else if (h > MAXIMUM_TILE_HEIGHT) h = MAXIMUM_TILE_HEIGHT;
        this._tilesH = h;
        this._rollingSpriteMaxScale = ROLLED_TILE_HEIGHT / this._tilesH;
        this.log("Regular tile height: " + this._tilesH)
        this._tileClass.H = h; 
        this._tileClass.TXT_H = this._tilesH - 2; this._tileClass.TXT_Y = 1;
        this._tileClass.FONT = String(this._tileClass.TXT_H) + "px Arial";
        this._rollMainH = ROLLED_TILE_HEIGHT;
        this.log("Main roller height: " + this._rollMainH);
        this._rollTileMainHDelta = this._rollMainH - this._tilesH;
        // this._completeContentHeight = this._tilesH * this._tilesNum;
    }
    orderInitialTiles() {
        this._tiles.forEach((element, index) => {
            element.sprite.y = this._tilesH * index;
        });
        this.updateTilesView();
    }
    updateTilesView() { // Everytime tiles are rendered or filtered, thils will update all parameters
        this._allTilesH = this._tilesNum * this._tilesH;
        // Below allows scroll only if content can be scrolled
        this._scrollActive = this._allTilesH > this._viewportHeight;
        // Allow enlargement only if tiles are smaller than max size
        this._enlargeOnRoll = this._tilesH < MAXIMUM_TILE_HEIGHT && ANIM_USE_ANAMORPHIC;
        this._maxViewportContentOffset = this._allTilesH - this._viewportHeight;
        this._scrollBar.setScrollSize(this._viewportHeight, this._allTilesH);
    }
    renderMarkers() {
        let markersAmount = Math.floor(this._tilesNum/TILES_NUMERIC_MARKER_STEP);
        this.log("Rendered " + markersAmount + " markers.");
        this._markers = [];
        let tile; let num; let marker;
        for (let i = 1; i <= markersAmount; i++) {
            num = i * TILES_NUMERIC_MARKER_STEP;
            tile = this._tiles[num];
            if (!tile) return;
            marker = new this._markerClass(num, this._tiles[num]);
            this._markers.push(marker);
            this._markersByNumber[num] = marker;   
            // Add markers
            this._tilesHolder.addChild(marker.sprite);
            marker.sprite.x = -MARKERS_RIGHT_MARGIN;
        };
        // For some reason code after this line is NOT executed!!!
    }




}
 






















// HELPER CLASSES //////////////////////////////////////////////////////////////////
// #     #  #####  ####### ### #       ####### 
// ##   ## #     #    #     #  #       #       
// # # # # #          #     #  #       #       
// #  #  #  #####     #     #  #       #####   
// #     #       #    #     #  #       #       
// #     # #     #    #     #  #       #       
// #     #  #####     #    ### ####### ####### 
// /////////////////////////////////////////////////////////////////////////////////////
class MSTile {
    static H; static TXT_H; static TXT_Y; static FONT; static STATUS_COLORS; // Defined by parent
    static SELECTED_COLOR = "#898989";
    static STATUS_MARGIN = 0;
    static COLOR = "#000000";
    static COLOR_ROLL = "#bb0000";
    static TXT_X = 3;
    
    // static EVT_SELECT_TILE = "onSelectTile";
    // static EVT_UNSELECT_TILE = "onDeselectTile";
    static _mainScroller; // Used to broadcast events
    static _lastMainRolloveredTile; // References the last main rollovered tile
 
    constructor(data) {
        this._data; // Stores data node
        this._status = 0;
        this._rollovered; // Marks if tile is in rollovered group
        this._mainRollovered; // Marks if tile is the central main rollovered
        this._selected = false; // If this tile is selected
        this._statusMark = new createjs.Shape();
        this._selectedMark = new createjs.Shape();
        this._marker; // Reference to its own marker if any
        this._width; // Stores sprite width for caching once tile is rendered
        this._sprite = new createjs.Container();
        this._shape = new createjs.Shape();
        this._text = new createjs.Text("", MSTile.FONT, MSTile.COLOR);
        this._text.x = MSTile.TXT_X; this._text.y = MSTile.TXT_Y;
        this._sprite.addChild(this._text);
        this._sprite.addChild(this._statusMark);
        this._sprite.addChild(this._selectedMark);
        // this._sprite.addChild(this._shape);
        this.render(data);
    }
    release() { // Release all data
        this._marker = null;
        this._sprite.removeAllEventListeners();
        this._sprite.removeAllChildren();
        this._sprite.data = this._sprite = this._shape = this._text = this._selectedMark = this._statusMark = null;
    }
    render(data) {
        if (this._data) { // This is a recycled object
            this._graphics.clear();
        }
        this._data = data;
        this._text.text = data.label;
        // console.log(this.data.label);
        this._width = MSTile.TXT_X + Math.ceil(this._sprite.getBounds().width);
        this._shape.graphics.clear();
        this._shape.graphics.beginFill("red").drawRect(0,0,this._width,MSTile.H);
        this._shape.alpha = 1;
        this._sprite.hitArea = this._shape;
        this._sprite.data = this._data;
        this.setStatus(this._data.status);
        this.rollover = false;
    }
    setStatus(status) {
        this._statusMark.graphics.clear();
        if (status) this._statusMark.graphics.beginFill(MSTile.STATUS_COLORS[status]).drawRect(SELECTED_WIDTH,MSTile.STATUS_MARGIN,STATUS_WIDTH,MSTile.H-(MSTile.STATUS_MARGIN*2));
    }
    setMarker(marker) { // Called by a marker when is associated to this tile
        this._marker = marker;
    }
    updateMarker() {
        if (this._marker) this._marker.positionToTile();
    }
    set rollover(r) {
        if (r == this._rollover) return;
        this._rollover = r;
        if (r) {
            this._sprite.uncache(); 
        }
        else {
            this.mainRollover = false;
            // this._sprite.cache(0, 0, this._width, MSTile.H);
        }
    }
    set mainRollover(r) {
        if (r == this._mainRollovered) return;
        this._mainRollovered = r;
        // this._sprite.uncache();
        if (r) {
            this._sprite.uncache();
            MSTile._mainScroller.broadcastEvent(EVT_ROLLOVER_TILE, this._data, MSTile._mainScroller._stage.mouseY);
            if (this._text) this._text.color = MSTile.COLOR_ROLL;
            this._sprite.parent.addChild(this._sprite);
            if (MSTile._lastMainRolloveredTile && MSTile._lastMainRolloveredTile != this) {
                MSTile._lastMainRolloveredTile.mainRollover = false;
            }
            MSTile._lastMainRolloveredTile = this;
        }
        else {
            // console.log("Cazzo è????",this.data.label)
            if (this._text) this._text.color = MSTile.COLOR;
            // this._sprite.cache(0, 0, this._width, MSTile.H);
        }
        // console.log("mainroll",this.data.label, r)
        MSTile._mainScroller.update();
    }
    set selected(s) {
        if (this._selected == s) return;
        this._selected = s;
        this._selectedMark.graphics.clear();
        if (s) {
            this._selectedMark.graphics.beginFill(MSTile.SELECTED_COLOR).drawCircle(SELECTED_WIDTH/2, MSTile.H/2, SELECTED_WIDTH/3);
            // this._selectedMark.graphics.beginFill(MSTile.SELECTED_COLOR).drawRect(0,MSTile.STATUS_MARGIN,SELECTED_WIDTH-1,MSTile.H-(MSTile.STATUS_MARGIN*2));
        }
        if (this._sprite.bitmapCache) this._sprite.updateCache();
    }
    get sprite() {return this._sprite};
    get label() {return this._data.label};
    get data() {return this._data};
    get id() {return this._data.id};
    get txt() {return this._data.text};
}
class Marker {
    // static COLOR = "#bbbbbb"
    constructor(num, tile) {
        this._tile = tile; // The associated tile
        this._sprite = new createjs.Container();
        // this._shape = new createjs.Shape();
        // this._shape.graphics.setStrokeStyle(1,"square",0,10,true)
        // this._shape.graphics.beginFill(MARKER_COLOR).drawRect(0, 0, TILES_X-15, 1).endStroke().endFill();
        // this._shape.x = 14;
        // this._sprite.addChild(this._shape);
        this._text = new createjs.Text(String(num)+MARKER_CHARACTER, MARKER_FONT, MARKER_COLOR);
        this._text.textAlign = "right";
        // this._sprite.x = MARKERS_COLUMN_WIDTH; // this._text.y = -5;
        this._sprite.addChild(this._text);
        this._tile.setMarker(this);
        // let b = this._sprite.getBounds();
        // this._sprite.cache(b.x, b.y, b.width, b.height);
        this.positionToTile();
    }
    release() { // Release all data
        this._marker = null;
        this._sprite.removeAllEventListeners();
        this._sprite.removeAllChildren();
        this._sprite = this._tile = this._text = null;
    }
    positionToTile() {
        this._sprite.y = this._tile.sprite.y;
    }
    get sprite() {return this._sprite};
}


















// HELPER CLASSES //////////////////////////////////////////////////////////////////
// #     # ####### #     #    ####### ### #       ####### 
// ##    # #       #  #  #       #     #  #       #       
// # #   # #       #  #  #       #     #  #       #       
// #  #  # #####   #  #  #       #     #  #       #####   
// #   # # #       #  #  #       #     #  #       #       
// #    ## #       #  #  #       #     #  #       #       
// #     # #######  ## ##        #    ### ####### ####### 
// /////////////////////////////////////////////////////////////////////////////////////
class NEWTile {
    static H; static TXT_H; static TXT_Y; static FONT; static STATUS_COLORS; // Defined by parent
    static SELECTED_COLOR = "#898989";
    static ROLLOVER_BG_COLOR = "#aaaaaa";
    static SELECTED_BG_COLOR = "#ccccff";
    static STATUS_MARGIN = 0;
    static COLOR = "#000000";
    static COLOR_ROLL = "#bb0000";
    static TXT_X = 3;
    static WIDTH_MARGIN = 10;
    static BGS_Y = -2;
    
    // static EVT_SELECT_TILE = "onSelectTile";
    // static EVT_UNSELECT_TILE = "onDeselectTile";
    static _mainScroller; // Used to broadcast events
    static _lastMainRolloveredTile; // References the last main rollovered tile
 
    constructor(data) {
        this._class = NEWTile; // Stores a reference to the class in order not to rewrite the class name all the time
        this._data; // Stores data node
        this._status = 0;
        this._rollovered; // Marks if tile is in rollovered group
        this._mainRollovered; // Marks if tile is the central main rollovered
        this._selected = false; // If this tile is selected
        this._statusMark = new createjs.Shape();
        this._selectedMark = new createjs.Shape();
        this._selectedMarkBG = new createjs.Shape();
        this._rolloverMark = new createjs.Shape();
        this._marker; // Reference to its own marker if any
        this._width; // Stores sprite width for caching once tile is rendered
        this._sprite = new createjs.Container();
        this._shape = new createjs.Shape();
        this._text = new createjs.Text("", this._class.FONT, this._class.COLOR);
        this._text.x = this._class.TXT_X; this._text.y = this._class.TXT_Y;
        this._sprite.addChild(this._selectedMarkBG);
        this._sprite.addChild(this._rolloverMark);
        this._sprite.addChild(this._text);
        this._sprite.addChild(this._statusMark);
        this._sprite.addChild(this._selectedMark);
        // this._sprite.addChild(this._shape);
        this.render(data);
    }
    release() { // Release all data
        this._marker = null;
        this._sprite.removeAllEventListeners();
        this._sprite.removeAllChildren();
        this._sprite.data = this._sprite = this._shape = this._text = this._selectedMark = this._rolloverMark = this._selectedMarkBG = this._statusMark = null;
    }
    render(data) {
        if (this._data) { // This is a recycled object
            this._graphics.clear();
        }
        this._data = data;
        this._text.text = data.label;
        this.createRollover();
        // console.log(this.data.label);
        this._width = this._class.TXT_X + Math.ceil(this._sprite.getBounds().width) + this._class.WIDTH_MARGIN;
        this._shape.graphics.clear();
        this._shape.graphics.beginFill("red").drawRect(0,0,this._width,this._class.H);
        this._shape.alpha = 1;
        this._sprite.hitArea = this._shape;
        this._sprite.data = this._data;
        this.setStatus(this._data.status);
        this.rollover = false;
    }
    createRollover() {
        this._rolloverMark.graphics.clear();
        this._selectedMarkBG.graphics.clear();
        // const ENTIRE_WIDTH = false;
        // if(ENTIRE_WIDTH) {
            // this._rolloverMark.graphics.beginFill(this._class.ROLLOVER_BG_COLOR).drawRect(SELECTED_WIDTH+STATUS_WIDTH,-this._class.STATUS_MARGIN*3,this._class._mainScroller._viewportWidth,this._class.H-(this._class.STATUS_MARGIN*2));
        // } else {
            this._rolloverMark.graphics.beginFill(this._class.ROLLOVER_BG_COLOR).drawRect(SELECTED_WIDTH+STATUS_WIDTH,this._class.BGS_Y,this._text.getBounds().width+this._class.WIDTH_MARGIN,this._class.H-(this._class.STATUS_MARGIN*2));
            this._selectedMarkBG.graphics.beginFill(this._class.SELECTED_BG_COLOR).drawRect(SELECTED_WIDTH+STATUS_WIDTH,this._class.BGS_Y,this._text.getBounds().width+this._class.WIDTH_MARGIN,this._class.H-(this._class.STATUS_MARGIN*2));
            this._rolloverMark.alpha = this._selectedMarkBG.alpha = 0;
        // }
    }
   setStatus(status) {
        this._statusMark.graphics.clear();
        if (status) this._statusMark.graphics.beginFill(this._class.STATUS_COLORS[status]).drawRect(SELECTED_WIDTH,this._class.STATUS_MARGIN,STATUS_WIDTH,this._class.H-(this._class.STATUS_MARGIN*2));
    }
    setMarker(marker) { // Called by a marker when is associated to this tile
        this._marker = marker;
    }
    updateMarker() {
        if (this._marker) this._marker.positionToTile();
    }
    set rollover(r) {
        if (r == this._rollover) return;
        this._rollover = r;
        if (r) {
            this._sprite.uncache(); 
        }
        else {
            this.mainRollover = false;
            // this._sprite.cache(0, 0, this._width, this._class.H);
        }
    }
    set mainRollover(r) {
        if (r == this._mainRollovered) return;
        this._mainRollovered = r;
        // this._sprite.uncache();
        if (r) {
            this._sprite.uncache();
            this._class._mainScroller.broadcastEvent(EVT_ROLLOVER_TILE, this._data, this._class._mainScroller._stage.mouseY);
            if (this._text) this._text.color = this._class.COLOR_ROLL;
            this._sprite.parent.addChild(this._sprite);
            if (this._class._lastMainRolloveredTile && this._class._lastMainRolloveredTile != this) {
                this._class._lastMainRolloveredTile.mainRollover = false;
            }
            this._class._lastMainRolloveredTile = this;
            // this._rolloverMark.scaleX = 1;
            this._class._mainScroller.fadeTo(this._rolloverMark, 100, 0.5);
            // createjs.Tween.get(this._rolloverMark, {override:true, useTicks:true}).to({alpha:1}, 1000);
        }
        else {
            // console.log("Cazzo è????",this.data.label)
            if (this._text) this._text.color = this._class.COLOR;
            // this._rolloverMark.scaleX = 0;
            this._class._mainScroller.fadeOut(this._rolloverMark, 400);
            // createjs.Tween.get(this._rolloverMark, {override:true, useTicks:true}).to({alpha:0}, 1000);
            // this._sprite.cache(0, 0, this._width, this._class.H);
        }
        // console.log("mainroll",this.data.label, r)
        this._class._mainScroller.update();
    }
    set selected(s) {
        if (this._selected == s) return;
        this._selected = s;
        this._selectedMark.graphics.clear();
        if (s) {
            this._class._mainScroller.fadeIn(this._selectedMarkBG, 150);
            this._selectedMark.graphics.beginFill(this._class.SELECTED_COLOR).drawCircle(SELECTED_WIDTH/2, this._class.H/2, SELECTED_WIDTH/3);
            this._selectedMark.alpha = 0;
            this._class._mainScroller.fadeIn(this._selectedMark, 150);
            // this._selectedMark.graphics.beginFill(this._class.SELECTED_COLOR).drawRect(0,this._class.STATUS_MARGIN,SELECTED_WIDTH-1,this._class.H-(this._class.STATUS_MARGIN*2));
        } else {
            this._class._mainScroller.fadeOut(this._selectedMarkBG, 400);

        }
        if (this._sprite.bitmapCache) this._sprite.updateCache();
    }
    get sprite() {return this._sprite};
    get label() {return this._data.label};
    get data() {return this._data};
    get id() {return this._data.id};
    get txt() {return this._data.text};
}
class NEWMarker {
    // static COLOR = "#bbbbbb"
    constructor(num, tile) {
        this._class = NEWMarker;
        this._tile = tile; // The associated tile
        this._sprite = new createjs.Container();
        // this._shape = new createjs.Shape();
        // this._shape.graphics.setStrokeStyle(1,"square",0,10,true)
        // this._shape.graphics.beginFill(MARKER_COLOR).drawRect(0, 0, TILES_X-15, 1).endStroke().endFill();
        // this._shape.x = 14;
        // this._sprite.addChild(this._shape);
        this._text = new createjs.Text(String(num)+MARKER_CHARACTER, MARKER_FONT, MARKER_COLOR);
        this._text.textAlign = "right";
        // this._sprite.x = MARKERS_COLUMN_WIDTH; // this._text.y = -5;
        this._sprite.addChild(this._text);
        this._tile.setMarker(this);
        // let b = this._sprite.getBounds();
        // this._sprite.cache(b.x, b.y, b.width, b.height);
        this.positionToTile();
    }
    release() { // Release all data
        this._marker = null;
        this._sprite.removeAllEventListeners();
        this._sprite.removeAllChildren();
        this._sprite = this._tile = this._text = null;
    }
    positionToTile() {
        this._sprite.y = this._tile.sprite.y;
    }
    get sprite() {return this._sprite};
}























// CONSTANTS AFTER HELPER CLASSES INITIALIZATION ////////////////////////////////////////////////////////////////
const HELPER_CLASS_NAME_TO_TILE_CLASS = {"Default":MSTile, "New":NEWTile};
const HELPER_CLASS_NAME_TO_MARKER_CLASS = {"Default":Marker, "New":NEWMarker};