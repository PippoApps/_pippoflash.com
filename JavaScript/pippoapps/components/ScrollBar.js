import PippoAppsJSBase from "../PippoAppsJSBase.js"

export default class ScrollBar extends PippoAppsJSBase {
    // CONSTANTS
    static EVT_ONSCROLL = "onScroll"; 
    static MARGIN = 2;
    static COLOR_BG = "#dddddd";
    static COLOR_HANDLE = "#ffffff";
    static ROUND_RADIUS = 6;
    static MIN_HANDLE_HEIGHT = 30;
    // INIT
    constructor(scrollBarId, w, h, canvasId) {
        super(scrollBarId, canvasId);
        // VARIABLES
        // this._w = w;
        // this._h = h;
        this._totalH;
        this._contentH;
        // SCROLL VARIABLES
        this._hasScroll; // If scroll is active or not
        this._scrollPos = 0; // 0 to maxScroll
        this._localScrollPos = 0; // Scroll position in local coordinates
        this._scrollRatio = 0; // 0 to 1
        this._maxScroll; // Maximum scrollable amount in real values
        this._maxLocalScroll; // Maximum amunt scrollable in local coordinates
        this._localScrollArea; // Total local scroll area. Not _h since margin is removed.
        this._localScrollMultiplier; // Multiplier to convert local coordinates scroll to real values
        this._scrollHandleHeight; // Height of handle
        this._scrollDragYStartPos; // Stores mouse Y position on click to start dragging handle
        this._dragging;
        // VISUAL ELEMENTS
        // this._mainCont = new createjs.Container();
        this._bg = new createjs.Shape();
        this._handle = new createjs.Shape();
        this._mainContainer.addChild(this._bg);
        this._mainContainer.addChild(this._handle);
        this._bg.addEventListener("click", this._onClickBg.bind(this));
        this._handle.addEventListener("mousedown", this._onPressHandle.bind(this));
        this._handle.addEventListener("pressmove", this._onMoveHandle.bind(this));
        this._handle.addEventListener("pressup", this._onReleaseHandle.bind(this));
        // Internal listeners
        this.resize(w, h);
        this.setActive(false);
        // this.setScrollSize(totalH, contentH);
    }
    // METHODS
    resize(w, h) {
        super.resize(w, h);
        // Draw BG
        this._bg.graphics.clear();
        this._bg.graphics.beginFill(ScrollBar.COLOR_BG).drawRoundRect(0, 0, w, h, ScrollBar.ROUND_RADIUS).endFill();
    }
    resizeVertical(h, totalH, contentH, reset=true) {
        this.resize(this._w, h);
        // Redraw BG
        if (this._hasScroll) this.setScrollSize(totalH, contentH, reset); // Scroll is already active, therefore on resize I do update scroll values
    }
    setScrollSize(totalH=100, contentH=100, reset=true) {
        this._totalH = totalH;
        this._contentH = contentH;
        if (contentH <= totalH) {
            this.setActive(false);
            // this.log("Scroll not active. Total:", totalH,"content",contentH)
        }
        else { // Setup scroll parameters
            this._maxScroll = contentH - totalH;
            this._localScrollArea = this._h - (ScrollBar.MARGIN*2);
            this._scrollHandleHeight = Math.floor(this._localScrollArea / (contentH/totalH));
            // Check for minimum handle height and adjust values accordingly
            if (this._scrollHandleHeight < ScrollBar.MIN_HANDLE_HEIGHT) {
                let diff = ScrollBar.MIN_HANDLE_HEIGHT - this._scrollHandleHeight;
                this._scrollHandleHeight = ScrollBar.MIN_HANDLE_HEIGHT;
                // this._localScrollArea -= diff;
                this._localScrollMultiplier = contentH / (this._localScrollArea - this._scrollHandleHeight);
            }
            else this._localScrollMultiplier = contentH / this._localScrollArea;
            
            this._maxLocalScroll = this._localScrollArea - this._scrollHandleHeight;
            // this.log("Scroll active.","totalH",totalH,"contentH",contentH,"this._maxScroll",this._maxScroll,"this._localScrollArea",this._localScrollArea,"this._localScrollMultiplier",this._localScrollMultiplier,"this._scrollHandleHeight",this._scrollHandleHeight,"this._maxLocalScroll",this._maxLocalScroll)
            this.setActive(true);
            this._updateScrollValues();
            if (reset) this.resetScroll();
        }
    }
    _updateScrollValues() { // If resize is triggered while scroll is active
        this._handle.graphics.clear();
        let m = ScrollBar.MARGIN;
        this._handle.graphics.beginFill(ScrollBar.COLOR_HANDLE).drawRoundRect(m, m, this._w-(m*2), this._scrollHandleHeight, ScrollBar.ROUND_RADIUS).endFill();
    }
    _updateFromLocalScrollPosition(broadcast=true) { // Updates scroll position according to new value setup outside of this, and corrects if necessary
        if (this._localScrollPos < 0) this._localScrollPos = 0;
        else if (this._localScrollPos > this._maxLocalScroll) this._localScrollPos = this._maxLocalScroll
        // this.log("New local scroll position", this._localScrollPos);
        let lastY = this._handle.y;
        this._handle.y = this._localScrollPos;
        if (lastY != this._handle.y) { // Scroll has changed, lets do all calculations and broadcast
            this._scrollPos = this._localScrollPos * this._localScrollMultiplier;
            this._scrollRatio = this._scrollPos / this._maxScroll;
            if (this._scrollRatio > 1) this._scrollRatio = 1;
            if (broadcast) this.broadcastEvent(ScrollBar.EVT_ONSCROLL, this._scrollRatio);
            // if (broadcast) this.broadcastEvent(ScrollBar.EVT_ONSCROLL, this._scrollPos);
        }
        this.update();
    }
    // METHODS
    setActive(a=true) {
        this._hasScroll = a;
        this._handle.visible = a;
    }
    scrollStep(delta, broadcast=true) { // +1 or -1 scrolls a step
        // this.log(delta);
        this.addScroll(this._scrollHandleHeight * delta, broadcast);
    }
    addScroll(delta, broadcast=true) { // Adds positive or negative amount to scroll
        this._localScrollPos += delta;
        this._updateFromLocalScrollPosition(broadcast);
    }
    resetScroll(broadcast=true) {
        this.setScroll(0, broadcast);
    }
    setScroll(scrollPos, broadcast=true) { // Sets scroll position in non-local dimensions
        this._localScrollPos = scrollPos / this._localScrollMultiplier;
        this._updateFromLocalScrollPosition(broadcast);
    }
    // LISTENERS
    _onClickBg(event) {
        // this.log(this.getMouseEventLocalPoint(event));
        if (!this._hasScroll) return;
        // this.log(this._stage.mouseY);
        this.scrollStep(this.getMouseEventLocalPoint(event).y > this._localScrollPos ? 1 : -1);
    }
    _onPressHandle(event) {
        this._scrollDragYStartPos = this.localMouse.y;
        this._dragging = true;
    }
    _onMoveHandle(event) {
        // this._handle.y = this.localMouse.y - this._scrollDragYStartPos;
        // this._stage.update();
        this.addScroll(this.localMouse.y - this._scrollDragYStartPos);
        this._scrollDragYStartPos = this.localMouse.y;
    }
    _onReleaseHandle(event) {
        this._dragging = false;
    }
}