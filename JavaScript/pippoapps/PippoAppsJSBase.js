

// Private variables unaccessible from outside
var _canvas;
var _canvasId;
var _stage;
var _update; // Marked true when stage has to update
var _mainApp; // Instance of MainApp
var _baseUrl = "";
// var _queue;
// var _queueForIDs; // Another load queue for IDs
// var _loaderIds = {};
// var _loadedCacheIds = {}; 
// var _singleLoader; // LoadItem for the single loader
// var _alwaysUpdate;
// PippoAppsJSBase.FPS = 30;
/* Base Class for all visual elements in PippoAppsJS Framework */
module.exports = class PippoAppsJSBase {
    constructor(instanceId, useCreateJs, htmlCanvasId) {
        // Static variables
        PippoAppsJSBase.FPS = 60;
        PippoAppsJSBase._logCounter = 0;
        PippoAppsJSBase._logIdsCounters = {};
        PippoAppsJSBase._queue;
        PippoAppsJSBase._onFileLoadedCallback = null;
        PippoAppsJSBase._cacheNextSingleFileLoaded = false;
        PippoAppsJSBase._queueFileCacheByUrl = {};
        PippoAppsJSBase._baseUrl = "";
        // Dynamic variables
        this._id = instanceId;
        if (!_canvas && htmlCanvasId) {
            _canvasId = htmlCanvasId;
            _canvas = document.getElementById(htmlCanvasId);
            _stage = new createjs.Stage(htmlCanvasId, {antialias:true});
            createjs.Ticker.framerate = PippoAppsJSBase.FPS;
            createjs.Ticker.addEventListener("tick", this.onEnterFrame.bind(this));
            console.log("PippoAppsJS Canvas CreateJS OOP Framework initialized.")
            this._sprite = new createjs.Container(); // The main sprite container
            this._sprite.name = this._id;
            this._canvasId = _canvasId;
            this._canvas = _canvas;
            this._mainContainer = new createjs.Container();
            this._stage = _stage;
        }
        this._verbose = true; // Set htis to false in order to shut down log
        this._active = true; // Utility to use in everything
        // DOM Managers
        this._domParents = {}; // Stores parent for each object
        // Regular classes variables
        // if (!PippoAppsJSBase._canvas) {
        //     PippoAppsJSBase._canvasId = htmlCanvasId;
        //     PippoAppsJSBase._canvas = document.getElementById(htmlCanvasId);
        //     PippoAppsJSBase._stage = new createjs.Stage(htmlCanvasId, {antialias:true});
        // }
        // PREPARE DATA LOAD STUFF
        // if (!_queue) {
            // _queue = new createjs.LoadQueue();
            // _queue.addEventListener("fileload", this._onFileLoaded.bind(this), this);
        // }
        // this._canvasId = PippoAppsJSBase._canvasId;
        // this._canvas = PippoAppsJSBase._canvas;
        // this._stage = PippoAppsJSBase._stage;
        // this.log(this._stage);
       // window._pippoApps.addLogItem(this, this._id);
        PippoAppsJSBase._logIdsCounters[this] = 0;
        // Create main container
        // Setup facilitators
        if (!Array.prototype.last){
            Array.prototype.last = function(){
                return this[this.length - 1];
            };
            Array.prototype.random = function(removeFromArray){
                if (removeFromArray) return this.splice(Math.floor(this.length*Math.random()), 1)[0];
                return this[this.length  * Math.random() | 0];
            };
        };    
        this.log("PippoAppJS Initialized as " + this._id)    
    }
    // INIT
    initAsMainApp() {
        if (_mainApp) {
            this.logError("MainApp is already defined.");
            return;
        }
        _mainApp = this;
        this.log("I am the MainApp.")
    }

    // DISPLAY LIST
    position(x, y) {
        this._x = x;
        this._y = y;
    }
    positionSprite(x, y) {
        if (!this._sprite) {
            this.logError("positionSprite() aborted. Sprite not defined.");
            return;
        }
        this._sprite.x = x;
        this._sprite.y = y;
    }
    createShapeWithBounds(x, y, w, h, graphics) {
        const shape = new createjs.Shape(graphics);
        shape.setBounds(x, y, w, h);
        return shape;
    }
    addSpriteTo(cont) { // Adds the _sprite in a container
        cont.addChild(this._sprite);
    }
    getBounds() {
        return this._sprite.getBounds();
    }
    resizeToSprite(cont, margin, target) {
        if (!margin) margin = 0;
        if (!target) target = this._sprite;
        const w = this._sprite.getBounds().width;
        const h = this._sprite.getBounds().height;
        if (w > cont.getBounds().width) target.scaleY = target.scaleX = (cont.getBounds().width-margin) / w;
        else if (h > cont.getBounds().height) target.scaleY = target.scaleX = (cont.getBounds().height-margin) / h;
    }


    resize(w, h) {
        this.resizeW(w);
        this.resizeH(h);
    }
    resizeW(w) {
        this._w = w;
    }
    resizeH(h) {
        this._h = h;
    }
    log(...rest) {
        if (this._verbose) console.log("[" + PippoAppsJSBase._logCounter + " " + this._id + "] " + rest.join(" "));
        PippoAppsJSBase._logCounter++;
    }
    logObject(obj) {
        if (this._verbose) console.log("[" + PippoAppsJSBase._logCounter + " " + this._id + "] ", obj);
        PippoAppsJSBase._logCounter++;
    }
    logError(...rest) {
        console.log("[" + PippoAppsJSBase._logCounter + " <ERROR> " + this._id + "] " + rest.join(" "));
    }
    logScream(...rest) {
        console.log("-----------------------------------------------------------------");
        console.log("[" + PippoAppsJSBase._logCounter + " <ALERT> " + this._id + "] " + rest.join(" "));
        console.log("-----------------------------------------------------------------");
    }
    // UTILS
    getMouseEventLocalPoint(event) {
        return this._mainContainer.localToGlobal(event.stageX, event.stageY);
    }
   // GETTERS
    get asset() {return this._mainContainer};
    get localMouse() {return this._mainContainer.globalToLocal(this._stage.mouseX, this._stage.mouseY)}
    get mainApp() {return _mainApp};
    // EVENTS
    broadcastEvent(eventName, par0, par1, par2, par3) {
        if (this._listeners) {
            this._listeners.forEach(element => { 
                if (element[eventName]) element[eventName](par0, par1, par2, par3)
                // else this.logError(eventName+"() not found on " + element);
            });
        }
    }
    broadcastMainAppEvent(eventName, par0, par1, par2, par3) {
        if (!_mainApp) this.logError("broadcastMainAppEvent() cannot be launched, MainApp not defined.")
        else _mainApp.broadcastEvent(eventName, par0, par1, par2, par3);
    }
    addListener(listener) {
        if (!this._listeners) this._listeners = [];
        this._listeners.push(listener);
    }
    // UPDATES
    update() {_update = true};
    onEnterFrame() {
        if (_update) {
            _stage.update();
            _update = false;
        }
    }
    // LOADING - IDS
    // loadFileId(id="default", src, )
    // LOADING - SIMPLE
    loadFile(src, callback, interruptPreviousLoad=false, cacheByUrl=false) {
        // Check whether load needs to be interrupted
        if (PippoAppsJSBase._queue && !interruptPreviousLoad) {
            this.logError("There is already a loadFile operation in progress. Load aborted: " + src);
            return;
        }
        // Load needs to be overwritten
        if (PippoAppsJSBase._queue) {
            this.log("Interrupting previous load operation.", PippoAppsJSBase._queue);
            // if (interruptAllLoads || interruptPreviousLoad) _queue.destroy();
            PippoAppsJSBase._queue.destroy();
            PippoAppsJSBase._onFileLoadedCallback = null;
            PippoAppsJSBase._queue = null;
        }
        // Check if file is in cache
        if (cacheByUrl && PippoAppsJSBase._queueFileCacheByUrl[src]) {
            this.log("Requested object in cache. Object exists and is returned without loading.")
            callback(PippoAppsJSBase._queueFileCacheByUrl[src]);
            return;
        }
        // Proceed loading
        PippoAppsJSBase._queue = new createjs.LoadQueue();
        PippoAppsJSBase._queue.addEventListener("fileload", this._onFileLoaded.bind(this), this);
        // }
        PippoAppsJSBase._onFileLoadedCallback = callback;
        PippoAppsJSBase._cacheNextSingleFileLoaded = cacheByUrl;
        this.log("Loading:",src,", callback:", PippoAppsJSBase._onFileLoadedCallback)
        PippoAppsJSBase._queue.loadFile({id:"PippoAppsJSBase", src:src});
    }
    _onFileLoaded(event) {
        this.log("File load complete:",event.item.src)
        // console.log("loaded",PippoAppsJSBase._onFileLoadedCallback)
        let callback = PippoAppsJSBase._onFileLoadedCallback;
        PippoAppsJSBase._onFileLoadedCallback = null; // This is nullified before call so that another load operation can be started in callback
        // console.log("caricato",_queue)
        PippoAppsJSBase._queue.removeEventListener("fileload", this._onFileLoaded.bind(this), this);
        PippoAppsJSBase._queue = null;
        if (PippoAppsJSBase._cacheNextSingleFileLoaded) PippoAppsJSBase._queueFileCacheByUrl[event.item.src] = event.result;
        callback(event.result);
    }


    // Fading
    fadeIn(c, time, onComplete) {
        let t = createjs.Tween.get(c, {override:true}).to({alpha:1}, time);
        if (onComplete) t.call(onComplete);
        t.addEventListener("change", this.update.bind(this));
    }
    fadeOut(c, time, andRemove, onComplete) {
        let t = createjs.Tween.get(c, {override:true}).to({alpha:0}, time);
        if (andRemove) t.call(this._removeAfterFade);
        if (onComplete) t.call(onComplete);
        t.addEventListener("change", this.update.bind(this));
    }
    fadeTo(c, time, alpha, onComplete) {
        let t = createjs.Tween.get(c, {override:true}).to({alpha:alpha}, time);
        if (onComplete) t.call(onComplete);
        t.addEventListener("change", this.update.bind(this));
    }
    fadeSequence(array, interval, time, alpha, onComplete) { // Fades a sequence of items and the callback is used on the last item
        const lastItem = array.last();
        let itemTween;
        for (let i = 0; i < array.length; i++) {
            const item = array[i];
            itemTween = createjs.Tween.get(item, {override:true}).wait(interval*i).to({alpha:alpha}, time);
            if (item == lastItem) itemTween.call(onComplete);
            itemTween.addEventListener("change", this.update.bind(this));

        }
    }


    _removeAfterFade() {
        if (this.parent) this.parent.removeChild(this);
    }
    scaleTo(c, time, scale, onComplete, ease, params) { // ease : createjs.Ease.quartInOut...
        let t = createjs.Tween.get(c, {override:true}).to({scaleX:scale, scaleY:scale}, time, ease);
        if (onComplete) t.call(onComplete, params);
        t.addEventListener("change", this.update.bind(this));
        return t;
    }


    // Align
    alignToCenter(obj, cont, xOff, yOff) {
        let objBounds = obj.getBounds();
        let contBounds = cont.getBounds();
        // this.log("Align to center: ", objBounds, contBounds);
        obj.x = contBounds.x + this._alignGetValueCenter(objBounds.width, contBounds.width); +(xOff ? xOff : 0);
        obj.y = contBounds.y + this._alignGetValueCenter(objBounds.height, contBounds.height) +(yOff ? yOff : 0);
    }
    _alignGetValueCenter(numObj, numCont) {
        return (numCont-numObj)/2;
    }

    // DOM managers
    removeFromDOM(item) {
        if (item.parentNode) {
            // this.log("Removing",item.id,"from",item.parentNode.id)
            this._domParents[item.id] = item.parentNode;
            item.parentNode.removeChild(item);
        }
    }
    addToDOM(item, mode="add", parent) { // add, insert, replace
        // Mode can be add, insert or replace, and it adds at the bottom, inserts at the top, or replaces the entire innerHTML content.
        var p = parent ? parent : this._domParents[item.id];
        if (!item || !p) {
            this.logError("ERROR item and parent must be specified",item, parent);
            return;
        }
        // this.log(mode,item.id,"to",p.id)
        if (mode.charAt(0) == "a") p.appendChild(item);
    }
    createDOMElementFromString(s) {
        let template = document.createElement('template');
        s = s.trim(); // Never return a text node of whitespace as the result
        template.innerHTML = s;
        return template.content.firstChild;
    }
    setDomElementVisible(element, visible=true, ifVisibleFadeIn=true, ifVisibileValue="inline") {
        if (!(element instanceof HTMLElement)) {
            this.logError("Cannot setDomElementVisible() object is not an HTMLElement: " + element);
            return;
        }
        // Fadein di jquery mi incasina i css
    //     if (visible && ifVisibleFadeIn) {
    //         console.log($(element),"FADE IIIN")
    //         $(element).hide().fadeIn(200)
    //     }
    //    else  
       element.style.display = visible ? ifVisibileValue : "none";
    }



    // STRING
    replaceKeyword(s, key, insert) {
        const rep = "["+key+"]";
        // console.log("replace",rep,"in",s)
        return s.split(rep).join(insert);
        // return s.replace(rep, insert); // Replace uses REGEX and replaces only first value.
    }
    replaceKeywords(s, keyObj) {
        for (let key in keyObj) {
            s = this.replaceKeyword(s, key, keyObj[key]);
        }
        return s;
    }


    // DATA
    duplicateDataStructure(data) {
        return JSON.parse(JSON.stringify(data))
    }

    // GETTERS
    get sprite() {return this._sprite}
    get active() {return this._active}  
    get baseUrl() {return _baseUrl}  
    set baseUrl(u) {_baseUrl = u}  

}




// // STATIC VARI
// PippoAppsJSBase._logCounter = 0;

