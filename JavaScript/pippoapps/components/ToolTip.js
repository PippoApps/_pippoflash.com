import PippoAppsJSBase from "../PippoAppsJSBase.js"

export default class ToolTip extends PippoAppsJSBase {
    // CONSTANTS
    static TIMEOUT = 200;
    static INNER_MARGIN = 10;
    static OUTER_MARGIN = 10; // Margin from canvas dimensions
    // STATIC GETTERS
    static get toolTip() {return ToolTip._toolTip};
    // STATIC VARIABLES
    static _toolTip;
    // INIT
    constructor(toolTipId, maxW=400, font="14px Arial", txt="#000000", bg="#e6f5f7", border="#46a2aa", canvasId) {
        super(toolTipId, canvasId);
        this._bgCol = bg;
        this._borderCol = border;
        this._bg = new createjs.Shape();
        // this._bg.graphics.setStrokeStyle(1).beginStroke(border).beginFill(bg);
        this._txt = new createjs.Text("", font, txt);
        this._txt.lineWidth = maxW - (ToolTip.INNER_MARGIN*2);
        this._txt.x = this._txt.y = ToolTip.INNER_MARGIN;
        this._mainContainer.addChild(this._bg);
        this._mainContainer.addChild(this._txt);
        ToolTip._toolTip = this;
    }

    appear(text) {
        // Create tooltip
        this._mainContainer.uncache();
        this._txt.text  = text;
        let tb = this._txt.getBounds();
        let m = ToolTip.INNER_MARGIN * 2;
        this._bg.graphics.clear();
        this._bg.graphics.setStrokeStyle(0.5).beginStroke(this._borderCol).beginFill(this._bgCol).drawRoundRect(0, 0, tb.width+m, tb.height+m, 6);
        // Position tooltip
        let mb = this._mainContainer.getBounds();
        let w = mb.width + m; let h = mb.height + m;
        this._mainContainer.cache(0, 0, w, h);
        this._mainContainer.x = this._stage.mouseX + ToolTip.OUTER_MARGIN;
        this._mainContainer.y = this._stage.mouseY - h;
        if ((this._mainContainer.y - ToolTip.OUTER_MARGIN) < 0) this._mainContainer.y = ToolTip.OUTER_MARGIN;
        else if ((this._mainContainer.y + h) > this._stage.canvas.height) this._mainContainer.y = this._stage.canvas.height - (h + ToolTip.OUTER_MARGIN);
        this._stage.addChild(this._mainContainer);
        // Listen to mouse move events
        this._stage.addEventListener("stagemousemove", this._onMouseMove.bind(this));
        this.update();

        // Tweening
        this._mainContainer.alpha = 0.2;
        this.fadeIn(this._mainContainer, 200);
    }
    remove() {
        // if (this._mainContainer.parent) this._mainContainer.parent.removeChild(this._mainContainer);
        this.fadeOut(this._mainContainer, 100, true);
    }
    _onMouseMove() {
        this._stage.removeEventListener("stagemousemove", this._onMouseMove.bind(this));
        this.remove();
    }
}