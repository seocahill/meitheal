// Thredded JS Bundle for Propshaft
// Bundled from thredded gem components
(function() {
/** https://unpkg.com/autosize@4.0.2/dist/autosize.js **/
// Modified to always define the autosize global.
// This allows Thredded code to be compatible with both Webpack and Sprockets.
(function (global, factory) {
  var mod = {
    exports: {}
  };
  factory(mod, mod.exports);
  global.autosize = mod.exports;
})(window, function (module, exports) {
  'use strict';

  var map = typeof Map === "function" ? new Map() : function () {
    var keys = [];
    var values = [];

    return {
      has: function has(key) {
        return keys.indexOf(key) > -1;
      },
      get: function get(key) {
        return values[keys.indexOf(key)];
      },
      set: function set(key, value) {
        if (keys.indexOf(key) === -1) {
          keys.push(key);
          values.push(value);
        }
      },
      delete: function _delete(key) {
        var index = keys.indexOf(key);
        if (index > -1) {
          keys.splice(index, 1);
          values.splice(index, 1);
        }
      }
    };
  }();

  var createEvent = function createEvent(name) {
    return new Event(name, { bubbles: true });
  };
  try {
    new Event('test');
  } catch (e) {
    // IE does not support `new Event()`
    createEvent = function createEvent(name) {
      var evt = document.createEvent('Event');
      evt.initEvent(name, true, false);
      return evt;
    };
  }

  function assign(ta) {
    if (!ta || !ta.nodeName || ta.nodeName !== 'TEXTAREA' || map.has(ta)) return;

    var heightOffset = null;
    var clientWidth = null;
    var cachedHeight = null;

    function init() {
      var style = window.getComputedStyle(ta, null);

      if (style.resize === 'vertical') {
        ta.style.resize = 'none';
      } else if (style.resize === 'both') {
        ta.style.resize = 'horizontal';
      }

      if (style.boxSizing === 'content-box') {
        heightOffset = -(parseFloat(style.paddingTop) + parseFloat(style.paddingBottom));
      } else {
        heightOffset = parseFloat(style.borderTopWidth) + parseFloat(style.borderBottomWidth);
      }
      // Fix when a textarea is not on document body and heightOffset is Not a Number
      if (isNaN(heightOffset)) {
        heightOffset = 0;
      }

      update();
    }

    function changeOverflow(value) {
      {
        // Chrome/Safari-specific fix:
        // When the textarea y-overflow is hidden, Chrome/Safari do not reflow the text to account for the space
        // made available by removing the scrollbar. The following forces the necessary text reflow.
        var width = ta.style.width;
        ta.style.width = '0px';
        // Force reflow:
        /* jshint ignore:start */
        ta.offsetWidth;
        /* jshint ignore:end */
        ta.style.width = width;
      }

      ta.style.overflowY = value;
    }

    function getParentOverflows(el) {
      var arr = [];

      while (el && el.parentNode && el.parentNode instanceof Element) {
        if (el.parentNode.scrollTop) {
          arr.push({
            node: el.parentNode,
            scrollTop: el.parentNode.scrollTop
          });
        }
        el = el.parentNode;
      }

      return arr;
    }

    function resize() {
      if (ta.scrollHeight === 0) {
        // If the scrollHeight is 0, then the element probably has display:none or is detached from the DOM.
        return;
      }

      var overflows = getParentOverflows(ta);
      var docTop = document.documentElement && document.documentElement.scrollTop; // Needed for Mobile IE (ticket #240)

      ta.style.height = '';
      ta.style.height = ta.scrollHeight + heightOffset + 'px';

      // used to check if an update is actually necessary on window.resize
      clientWidth = ta.clientWidth;

      // prevents scroll-position jumping
      overflows.forEach(function (el) {
        el.node.scrollTop = el.scrollTop;
      });

      if (docTop) {
        document.documentElement.scrollTop = docTop;
      }
    }

    function update() {
      resize();

      var styleHeight = Math.round(parseFloat(ta.style.height));
      var computed = window.getComputedStyle(ta, null);

      // Using offsetHeight as a replacement for computed.height in IE, because IE does not account use of border-box
      var actualHeight = computed.boxSizing === 'content-box' ? Math.round(parseFloat(computed.height)) : ta.offsetHeight;

      // The actual height not matching the style height (set via the resize method) indicates that
      // the max-height has been exceeded, in which case the overflow should be allowed.
      if (actualHeight < styleHeight) {
        if (computed.overflowY === 'hidden') {
          changeOverflow('scroll');
          resize();
          actualHeight = computed.boxSizing === 'content-box' ? Math.round(parseFloat(window.getComputedStyle(ta, null).height)) : ta.offsetHeight;
        }
      } else {
        // Normally keep overflow set to hidden, to avoid flash of scrollbar as the textarea expands.
        if (computed.overflowY !== 'hidden') {
          changeOverflow('hidden');
          resize();
          actualHeight = computed.boxSizing === 'content-box' ? Math.round(parseFloat(window.getComputedStyle(ta, null).height)) : ta.offsetHeight;
        }
      }

      if (cachedHeight !== actualHeight) {
        cachedHeight = actualHeight;
        var evt = createEvent('autosize:resized');
        try {
          ta.dispatchEvent(evt);
        } catch (err) {
          // Firefox will throw an error on dispatchEvent for a detached element
          // https://bugzilla.mozilla.org/show_bug.cgi?id=889376
        }
      }
    }

    var pageResize = function pageResize() {
      if (ta.clientWidth !== clientWidth) {
        update();
      }
    };

    var destroy = function (style) {
      window.removeEventListener('resize', pageResize, false);
      ta.removeEventListener('input', update, false);
      ta.removeEventListener('keyup', update, false);
      ta.removeEventListener('autosize:destroy', destroy, false);
      ta.removeEventListener('autosize:update', update, false);

      Object.keys(style).forEach(function (key) {
        ta.style[key] = style[key];
      });

      map.delete(ta);
    }.bind(ta, {
      height: ta.style.height,
      resize: ta.style.resize,
      overflowY: ta.style.overflowY,
      overflowX: ta.style.overflowX,
      wordWrap: ta.style.wordWrap
    });

    ta.addEventListener('autosize:destroy', destroy, false);

    // IE9 does not fire onpropertychange or oninput for deletions,
    // so binding to onkeyup to catch most of those events.
    // There is no way that I know of to detect something like 'cut' in IE9.
    if ('onpropertychange' in ta && 'oninput' in ta) {
      ta.addEventListener('keyup', update, false);
    }

    window.addEventListener('resize', pageResize, false);
    ta.addEventListener('input', update, false);
    ta.addEventListener('autosize:update', update, false);
    ta.style.overflowX = 'hidden';
    ta.style.wordWrap = 'break-word';

    map.set(ta, {
      destroy: destroy,
      update: update
    });

    init();
  }

  function destroy(ta) {
    var methods = map.get(ta);
    if (methods) {
      methods.destroy();
    }
  }

  function update(ta) {
    var methods = map.get(ta);
    if (methods) {
      methods.update();
    }
  }

  var autosize = null;

  // Do nothing in Node.js environment and IE8 (or lower)
  if (typeof window === 'undefined' || typeof window.getComputedStyle !== 'function') {
    autosize = function autosize(el) {
      return el;
    };
    autosize.destroy = function (el) {
      return el;
    };
    autosize.update = function (el) {
      return el;
    };
  } else {
    autosize = function autosize(el, options) {
      if (el) {
        Array.prototype.forEach.call(el.length ? el : [el], function (x) {
          return assign(x, options);
        });
      }
      return el;
    };
    autosize.destroy = function (el) {
      if (el) {
        Array.prototype.forEach.call(el.length ? el : [el], destroy);
      }
      return el;
    };
    autosize.update = function (el) {
      if (el) {
        Array.prototype.forEach.call(el.length ? el : [el], update);
      }
      return el;
    };
  }

  exports.default = autosize;
  module.exports = exports['default'];
});

/** https://unpkg.com/textcomplete@0.17.1/dist/textcomplete.min.js **/
!function(e){function t(r){if(n[r])return n[r].exports;var i=n[r]={i:r,l:!1,exports:{}};return e[r].call(i.exports,i,i.exports,t),i.l=!0,i.exports}var n={};t.m=e,t.c=n,t.d=function(e,n,r){t.o(e,n)||Object.defineProperty(e,n,{configurable:!1,enumerable:!0,get:r})},t.n=function(e){var n=e&&e.__esModule?function(){return e.default}:function(){return e};return t.d(n,"a",n),n},t.o=function(e,t){return Object.prototype.hasOwnProperty.call(e,t)},t.p="",t(t.s=5)}([function(e,t,n){"use strict";function r(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}Object.defineProperty(t,"__esModule",{value:!0});var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var r=t[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(e,r.key,r)}}return function(t,n,r){return n&&e(t.prototype,n),r&&e(t,r),t}}(),o=n(2),s=(function(e){e&&e.__esModule}(o),function(){function e(t,n,i){r(this,e),this.data=t,this.term=n,this.strategy=i}return i(e,[{key:"replace",value:function(e,t){var n=this.strategy.replace(this.data);if(null!==n){Array.isArray(n)&&(t=n[1]+t,n=n[0]);var r=this.strategy.matchText(e);if(r)return n=n.replace(/\$&/g,r[0]).replace(/\$(\d)/g,function(e,t){return r[parseInt(t,10)]}),[[e.slice(0,r.index),n,e.slice(r.index+r[0].length)].join(""),t]}}},{key:"render",value:function(){return this.strategy.template(this.data,this.term)}}]),e}());t.default=s},function(e){"use strict";function t(){}function n(e,t,n){this.fn=e,this.context=t,this.once=n||!1}function r(){this._events=new t,this._eventsCount=0}var i=Object.prototype.hasOwnProperty,o="~";Object.create&&(t.prototype=Object.create(null),(new t).__proto__||(o=!1)),r.prototype.eventNames=function(){var e,t,n=[];if(0===this._eventsCount)return n;for(t in e=this._events)i.call(e,t)&&n.push(o?t.slice(1):t);return Object.getOwnPropertySymbols?n.concat(Object.getOwnPropertySymbols(e)):n},r.prototype.listeners=function(e,t){var n=o?o+e:e,r=this._events[n];if(t)return!!r;if(!r)return[];if(r.fn)return[r.fn];for(var i=0,s=r.length,a=new Array(s);i<s;i++)a[i]=r[i].fn;return a},r.prototype.emit=function(e,t,n,r,i,s){var a=o?o+e:e;if(!this._events[a])return!1;var u,l,c=this._events[a],h=arguments.length;if(c.fn){switch(c.once&&this.removeListener(e,c.fn,void 0,!0),h){case 1:return c.fn.call(c.context),!0;case 2:return c.fn.call(c.context,t),!0;case 3:return c.fn.call(c.context,t,n),!0;case 4:return c.fn.call(c.context,t,n,r),!0;case 5:return c.fn.call(c.context,t,n,r,i),!0;case 6:return c.fn.call(c.context,t,n,r,i,s),!0}for(l=1,u=new Array(h-1);l<h;l++)u[l-1]=arguments[l];c.fn.apply(c.context,u)}else{var f,d=c.length;for(l=0;l<d;l++)switch(c[l].once&&this.removeListener(e,c[l].fn,void 0,!0),h){case 1:c[l].fn.call(c[l].context);break;case 2:c[l].fn.call(c[l].context,t);break;case 3:c[l].fn.call(c[l].context,t,n);break;case 4:c[l].fn.call(c[l].context,t,n,r);break;default:if(!u)for(f=1,u=new Array(h-1);f<h;f++)u[f-1]=arguments[f];c[l].fn.apply(c[l].context,u)}}return!0},r.prototype.on=function(e,t,r){var i=new n(t,r||this),s=o?o+e:e;return this._events[s]?this._events[s].fn?this._events[s]=[this._events[s],i]:this._events[s].push(i):(this._events[s]=i,this._eventsCount++),this},r.prototype.once=function(e,t,r){var i=new n(t,r||this,!0),s=o?o+e:e;return this._events[s]?this._events[s].fn?this._events[s]=[this._events[s],i]:this._events[s].push(i):(this._events[s]=i,this._eventsCount++),this},r.prototype.removeListener=function(e,n,r,i){var s=o?o+e:e;if(!this._events[s])return this;if(!n)return 0==--this._eventsCount?this._events=new t:delete this._events[s],this;var a=this._events[s];if(a.fn)a.fn!==n||i&&!a.once||r&&a.context!==r||(0==--this._eventsCount?this._events=new t:delete this._events[s]);else{for(var u=0,l=[],c=a.length;u<c;u++)(a[u].fn!==n||i&&!a[u].once||r&&a[u].context!==r)&&l.push(a[u]);l.length?this._events[s]=1===l.length?l[0]:l:0==--this._eventsCount?this._events=new t:delete this._events[s]}return this},r.prototype.removeAllListeners=function(e){var n;return e?(n=o?o+e:e,this._events[n]&&(0==--this._eventsCount?this._events=new t:delete this._events[n])):(this._events=new t,this._eventsCount=0),this},r.prototype.off=r.prototype.removeListener,r.prototype.addListener=r.prototype.on,r.prototype.setMaxListeners=function(){return this},r.prefixed=o,r.EventEmitter=r,e.exports=r},function(e,t){"use strict";function n(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}function r(e){return e}Object.defineProperty(t,"__esModule",{value:!0});var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var r=t[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(e,r.key,r)}}return function(t,n,r){return n&&e(t.prototype,n),r&&e(t,r),t}}(),o=function(){function e(t){n(this,e),this.props=t,this.cache=t.cache?{}:null}return i(e,[{key:"destroy",value:function(){return this.cache=null,this}},{key:"search",value:function(e,t,n){this.cache?this.searchWithCache(e,t,n):this.props.search(e,t,n)}},{key:"replace",value:function(e){return this.props.replace(e)}},{key:"searchWithCache",value:function(e,t,n){var r=this;this.cache&&this.cache[e]?t(this.cache[e]):this.props.search(e,function(n){r.cache&&(r.cache[e]=n),t(n)},n)}},{key:"matchText",value:function(e){return"function"==typeof this.match?this.match(e):e.match(this.match)}},{key:"match",get:function(){return this.props.match}},{key:"index",get:function(){return"number"==typeof this.props.index?this.props.index:2}},{key:"template",get:function(){return this.props.template||r}}]),e}();t.default=o},function(e,t){"use strict";function n(e){var t=e.getBoundingClientRect(),n=e.ownerDocument,r=n.defaultView,i=n.documentElement,o={top:t.top+r.pageYOffset,left:t.left+r.pageXOffset};return i&&(o.top-=i.clientTop,o.left-=i.clientLeft),o}function r(e){return e>=s&&e<=a}function i(e){var t=window.getComputedStyle(e);return r(t.lineHeight.charCodeAt(0))?r(t.lineHeight.charCodeAt(t.lineHeight.length-1))?parseFloat(t.lineHeight)*parseFloat(t.fontSize):parseFloat(t.lineHeight):o(e.nodeName,t)}function o(e,t){var n=document.body;if(!n)return 0;var r=document.createElement(e);r.innerHTML="&nbsp;",r.style.fontSize=t.fontSize,r.style.fontFamily=t.fontFamily,r.style.padding="0",n.appendChild(r),r instanceof HTMLTextAreaElement&&(r.rows=1);var i=r.offsetHeight;return n.removeChild(r),i}Object.defineProperty(t,"__esModule",{value:!0}),t.calculateElementOffset=n,t.getLineHeightPx=i,t.calculateLineHeightPx=o;var s=(t.createCustomEvent=function(){return"function"==typeof window.CustomEvent?function(e,t){return new document.defaultView.CustomEvent(e,{cancelable:t&&t.cancelable||!1,detail:t&&t.detail||void 0})}:function(e,t){var n=document.createEvent("CustomEvent");return n.initCustomEvent(e,!1,t&&t.cancelable||!1,t&&t.detail||void 0),n}}(),"0".charCodeAt(0)),a="9".charCodeAt(0)},function(e,t,n){"use strict";function r(e){return e&&e.__esModule?e:{default:e}}function i(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}function o(e,t){if(!e)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return!t||"object"!=typeof t&&"function"!=typeof t?e:t}function s(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Super expression must either be null or a function, not "+typeof t);e.prototype=Object.create(t&&t.prototype,{constructor:{value:e,enumerable:!1,writable:!0,configurable:!0}}),t&&(Object.setPrototypeOf?Object.setPrototypeOf(e,t):e.__proto__=t)}Object.defineProperty(t,"__esModule",{value:!0});var a=function(){function e(e,t){for(var n=0;n<t.length;n++){var r=t[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(e,r.key,r)}}return function(t,n,r){return n&&e(t.prototype,n),r&&e(t,r),t}}(),u=n(1),l=r(u),c=n(3),h=n(0),f=(r(h),function(e){function t(){return i(this,t),o(this,(t.__proto__||Object.getPrototypeOf(t)).apply(this,arguments))}return s(t,e),a(t,[{key:"destroy",value:function(){return this}},{key:"applySearchResult",value:function(){throw new Error("Not implemented.")}},{key:"getCursorOffset",value:function(){throw new Error("Not implemented.")}},{key:"getBeforeCursor",value:function(){throw new Error("Not implemented.")}},{key:"emitMoveEvent",value:function(e){var t=(0,c.createCustomEvent)("move",{cancelable:!0,detail:{code:e}});return this.emit("move",t),t}},{key:"emitEnterEvent",value:function(){var e=(0,c.createCustomEvent)("enter",{cancelable:!0});return this.emit("enter",e),e}},{key:"emitChangeEvent",value:function(){var e=(0,c.createCustomEvent)("change",{detail:{beforeCursor:this.getBeforeCursor()}});return this.emit("change",e),e}},{key:"emitEscEvent",value:function(){var e=(0,c.createCustomEvent)("esc",{cancelable:!0});return this.emit("esc",e),e}},{key:"getCode",value:function(e){return 9===e.keyCode?"ENTER":13===e.keyCode?"ENTER":27===e.keyCode?"ESC":38===e.keyCode?"UP":40===e.keyCode?"DOWN":78===e.keyCode&&e.ctrlKey?"DOWN":80===e.keyCode&&e.ctrlKey?"UP":"OTHER"}}]),t}(l.default));t.default=f},function(e,t,n){"use strict";(function(e){function t(e){return e&&e.__esModule?e:{default:e}}var r=n(7),i=t(r),o=n(12),s=t(o),a=void 0;a=e.Textcomplete&&e.Textcomplete.editors?e.Textcomplete.editors:{},a.Textarea=s.default,e.Textcomplete=i.default,e.Textcomplete.editors=a}).call(t,n(6))},function(e){var t;t=function(){return this}();try{t=t||Function("return this")()||(0,eval)("this")}catch(e){"object"==typeof window&&(t=window)}e.exports=t},function(e,t,n){"use strict";function r(e){return e&&e.__esModule?e:{default:e}}function i(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}function o(e,t){if(!e)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return!t||"object"!=typeof t&&"function"!=typeof t?e:t}function s(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Super expression must either be null or a function, not "+typeof t);e.prototype=Object.create(t&&t.prototype,{constructor:{value:e,enumerable:!1,writable:!0,configurable:!0}}),t&&(Object.setPrototypeOf?Object.setPrototypeOf(e,t):e.__proto__=t)}Object.defineProperty(t,"__esModule",{value:!0});var a=function(){function e(e,t){for(var n=0;n<t.length;n++){var r=t[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(e,r.key,r)}}return function(t,n,r){return n&&e(t.prototype,n),r&&e(t,r),t}}(),u=n(8),l=r(u),c=n(4),h=(r(c),n(10)),f=r(h),d=n(2),v=r(d),p=n(0),y=(r(p),n(1)),m=r(y),g=["handleChange","handleEnter","handleEsc","handleHit","handleMove","handleSelect"],b=function(e){function t(e){var n=arguments.length>1&&void 0!==arguments[1]?arguments[1]:{};i(this,t);var r=o(this,(t.__proto__||Object.getPrototypeOf(t)).call(this));return r.completer=new l.default,r.isQueryInFlight=!1,r.nextPendingQuery=null,r.dropdown=new f.default(n.dropdown||{}),r.editor=e,r.options=n,g.forEach(function(e){r[e]=r[e].bind(r)}),r.startListening(),r}return s(t,e),a(t,[{key:"destroy",value:function(){var e=!(arguments.length>0&&void 0!==arguments[0])||arguments[0];return this.completer.destroy(),this.dropdown.destroy(),e&&this.editor.destroy(),this.stopListening(),this}},{key:"hide",value:function(){return this.dropdown.deactivate(),this}},{key:"register",value:function(e){var t=this;return e.forEach(function(e){t.completer.registerStrategy(new v.default(e))}),this}},{key:"trigger",value:function(e){return this.isQueryInFlight?this.nextPendingQuery=e:(this.isQueryInFlight=!0,this.nextPendingQuery=null,this.completer.run(e)),this}},{key:"handleHit",value:function(e){var t=e.searchResults;t.length?this.dropdown.render(t,this.editor.getCursorOffset()):this.dropdown.deactivate(),this.isQueryInFlight=!1,null!==this.nextPendingQuery&&this.trigger(this.nextPendingQuery)}},{key:"handleMove",value:function(e){"UP"===e.detail.code?this.dropdown.up(e):this.dropdown.down(e)}},{key:"handleEnter",value:function(e){var t=this.dropdown.getActiveItem();t?(this.dropdown.select(t),e.preventDefault()):this.dropdown.deactivate()}},{key:"handleEsc",value:function(e){this.dropdown.shown&&(this.dropdown.deactivate(),e.preventDefault())}},{key:"handleChange",value:function(e){null!=e.detail.beforeCursor?this.trigger(e.detail.beforeCursor):this.dropdown.deactivate()}},{key:"handleSelect",value:function(e){this.emit("select",e),e.defaultPrevented||this.editor.applySearchResult(e.detail.searchResult)}},{key:"startListening",value:function(){var e=this;this.editor.on("move",this.handleMove).on("enter",this.handleEnter).on("esc",this.handleEsc).on("change",this.handleChange),this.dropdown.on("select",this.handleSelect),["show","shown","render","rendered","selected","hidden","hide"].forEach(function(t){e.dropdown.on(t,function(){return e.emit(t)})}),this.completer.on("hit",this.handleHit)}},{key:"stopListening",value:function(){this.completer.removeAllListeners(),this.dropdown.removeAllListeners(),this.editor.removeListener("move",this.handleMove).removeListener("enter",this.handleEnter).removeListener("esc",this.handleEsc).removeListener("change",this.handleChange)}}]),t}(m.default);t.default=b},function(e,t,n){"use strict";function r(e){return e&&e.__esModule?e:{default:e}}function i(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}function o(e,t){if(!e)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return!t||"object"!=typeof t&&"function"!=typeof t?e:t}function s(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Super expression must either be null or a function, not "+typeof t);e.prototype=Object.create(t&&t.prototype,{constructor:{value:e,enumerable:!1,writable:!0,configurable:!0}}),t&&(Object.setPrototypeOf?Object.setPrototypeOf(e,t):e.__proto__=t)}Object.defineProperty(t,"__esModule",{value:!0});var a=function(){function e(e,t){for(var n=0;n<t.length;n++){var r=t[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(e,r.key,r)}}return function(t,n,r){return n&&e(t.prototype,n),r&&e(t,r),t}}(),u=n(1),l=r(u),c=n(9),h=r(c),f=n(0),d=(r(f),n(2)),v=(r(d),["handleQueryResult"]),p=function(e){function t(){i(this,t);var e=o(this,(t.__proto__||Object.getPrototypeOf(t)).call(this));return e.strategies=[],v.forEach(function(t){e[t]=e[t].bind(e)}),e}return s(t,e),a(t,[{key:"destroy",value:function(){return this.strategies.forEach(function(e){return e.destroy()}),this}},{key:"registerStrategy",value:function(e){return this.strategies.push(e),this}},{key:"run",value:function(e){var t=this.extractQuery(e);t?t.execute(this.handleQueryResult):this.handleQueryResult([])}},{key:"extractQuery",value:function(e){for(var t=0;t<this.strategies.length;t++){var n=h.default.build(this.strategies[t],e);if(n)return n}return null}},{key:"handleQueryResult",value:function(e){this.emit("hit",{searchResults:e})}}]),t}(l.default);t.default=p},function(e,t,n){"use strict";function r(e){return e&&e.__esModule?e:{default:e}}function i(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}Object.defineProperty(t,"__esModule",{value:!0});var o=function(){function e(e,t){for(var n=0;n<t.length;n++){var r=t[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(e,r.key,r)}}return function(t,n,r){return n&&e(t.prototype,n),r&&e(t,r),t}}(),s=n(0),a=r(s),u=n(2),l=(r(u),function(){function e(t,n,r){i(this,e),this.strategy=t,this.term=n,this.match=r}return o(e,null,[{key:"build",value:function(t,n){if("function"==typeof t.props.context){var r=t.props.context(n);if("string"==typeof r)n=r;else if(!r)return null}var i=t.matchText(n);return i?new e(t,i[t.index],i):null}}]),o(e,[{key:"execute",value:function(e){var t=this;this.strategy.search(this.term,function(n){e(n.map(function(e){return new a.default(e,t.term,t.strategy)}))},this.match)}}]),e}());t.default=l},function(e,t,n){"use strict";function r(e){return e&&e.__esModule?e:{default:e}}function i(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}function o(e,t){if(!e)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return!t||"object"!=typeof t&&"function"!=typeof t?e:t}function s(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Super expression must either be null or a function, not "+typeof t);e.prototype=Object.create(t&&t.prototype,{constructor:{value:e,enumerable:!1,writable:!0,configurable:!0}}),t&&(Object.setPrototypeOf?Object.setPrototypeOf(e,t):e.__proto__=t)}Object.defineProperty(t,"__esModule",{value:!0});var a=function(){function e(e,t){for(var n=0;n<t.length;n++){var r=t[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(e,r.key,r)}}return function(t,n,r){return n&&e(t.prototype,n),r&&e(t,r),t}}(),u=n(1),l=r(u),c=n(11),h=r(c),f=n(0),d=(r(f),n(3)),v="dropdown-menu textcomplete-dropdown",p=function(e){function t(e){i(this,t);var n=o(this,(t.__proto__||Object.getPrototypeOf(t)).call(this));n.shown=!1,n.items=[],n.activeItem=null,n.footer=e.footer,n.header=e.header,n.maxCount=e.maxCount||10,n.el.className=e.className||v,n.rotate=!e.hasOwnProperty("rotate")||e.rotate,n.placement=e.placement,n.itemOptions=e.item||{};var r=e.style;return r&&Object.keys(r).forEach(function(e){n.el.style[e]=r[e]}),n}return s(t,e),a(t,null,[{key:"createElement",value:function(){var e=document.createElement("ul"),t=e.style;t.display="none",t.position="absolute",t.zIndex="10000";var n=document.body;return n&&n.appendChild(e),e}}]),a(t,[{key:"destroy",value:function(){var e=this.el.parentNode;return e&&e.removeChild(this.el),this.clear()._el=null,this}},{key:"render",value:function(e,t){var n=this,r=(0,d.createCustomEvent)("render",{cancelable:!0});if(this.emit("render",r),r.defaultPrevented)return this;var i=e.map(function(e){return e.data}),o=e.slice(0,this.maxCount||e.length).map(function(e){return new h.default(e,n.itemOptions)});return this.clear().setStrategyId(e[0]).renderEdge(i,"header").append(o).renderEdge(i,"footer").show().setOffset(t),this.emit("rendered",(0,d.createCustomEvent)("rendered")),this}},{key:"deactivate",value:function(){return this.hide().clear()}},{key:"select",value:function(e){var t={searchResult:e.searchResult},n=(0,d.createCustomEvent)("select",{cancelable:!0,detail:t});return this.emit("select",n),n.defaultPrevented?this:(this.deactivate(),this.emit("selected",(0,d.createCustomEvent)("selected",{detail:t})),this)}},{key:"up",value:function(e){return this.shown?this.moveActiveItem("prev",e):this}},{key:"down",value:function(e){return this.shown?this.moveActiveItem("next",e):this}},{key:"getActiveItem",value:function(){return this.activeItem}},{key:"append",value:function(e){var t=this,n=document.createDocumentFragment();return e.forEach(function(e){t.items.push(e),e.appended(t),n.appendChild(e.el)}),this.el.appendChild(n),this}},{key:"setOffset",value:function(e){var t=document.documentElement;if(t){var n=this.el.offsetWidth;if(e.left){var r=t.clientWidth;e.left+n>r&&(e.left=r-n),this.el.style.left=e.left+"px"}else e.right&&(e.right-n<0&&(e.right=0),this.el.style.right=e.right+"px");this.isPlacementTop()?this.el.style.bottom=t.clientHeight-e.top+e.lineHeight+"px":this.el.style.top=e.top+"px"}return this}},{key:"show",value:function(){if(!this.shown){var e=(0,d.createCustomEvent)("show",{cancelable:!0});if(this.emit("show",e),e.defaultPrevented)return this;this.el.style.display="block",this.shown=!0,this.emit("shown",(0,d.createCustomEvent)("shown"))}return this}},{key:"hide",value:function(){if(this.shown){var e=(0,d.createCustomEvent)("hide",{cancelable:!0});if(this.emit("hide",e),e.defaultPrevented)return this;this.el.style.display="none",this.shown=!1,this.emit("hidden",(0,d.createCustomEvent)("hidden"))}return this}},{key:"clear",value:function(){return this.el.innerHTML="",this.items.forEach(function(e){return e.destroy()}),this.items=[],this}},{key:"moveActiveItem",value:function(e,t){var n="next"===e?this.activeItem?this.activeItem.next:this.items[0]:this.activeItem?this.activeItem.prev:this.items[this.items.length-1];return n&&(n.activate(),t.preventDefault()),this}},{key:"setStrategyId",value:function(e){var t=e&&e.strategy.props.id;return t?this.el.setAttribute("data-strategy",t):this.el.removeAttribute("data-strategy"),this}},{key:"renderEdge",value:function(e,t){var n=("header"===t?this.header:this.footer)||"",r="function"==typeof n?n(e):n,i=document.createElement("li");return i.classList.add("textcomplete-"+t),i.innerHTML=r,this.el.appendChild(i),this}},{key:"isPlacementTop",value:function(){return"top"===this.placement}},{key:"el",get:function(){return this._el||(this._el=t.createElement()),this._el}}]),t}(l.default);t.default=p},function(e,t,n){"use strict";function r(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}Object.defineProperty(t,"__esModule",{value:!0}),t.DEFAULT_CLASS_NAME=void 0;var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var r=t[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(e,r.key,r)}}return function(t,n,r){return n&&e(t.prototype,n),r&&e(t,r),t}}(),o=n(0),s=(function(e){e&&e.__esModule}(o),t.DEFAULT_CLASS_NAME="textcomplete-item"),a=["onClick","onMouseover"],u=function(){function e(t,n){var i=this;r(this,e),this.searchResult=t,this.active=!1,this.className=n.className||s,this.activeClassName=this.className+" active",a.forEach(function(e){i[e]=i[e].bind(i)})}return i(e,[{key:"destroy",value:function(){this.el.removeEventListener("mousedown",this.onClick,!1),this.el.removeEventListener("mouseover",this.onMouseover,!1),this.el.removeEventListener("touchstart",this.onClick,!1),this.active&&(this.dropdown.activeItem=null),this._el=null}},{key:"appended",value:function(e){this.dropdown=e,this.siblings=e.items,this.index=this.siblings.length-1}},{key:"activate",value:function(){if(!this.active){var e=this.dropdown.getActiveItem();e&&e.deactivate(),this.dropdown.activeItem=this,this.active=!0,this.el.className=this.activeClassName}return this}},{key:"deactivate",value:function(){return this.active&&(this.active=!1,this.el.className=this.className,this.dropdown.activeItem=null),this}},{key:"onClick",value:function(e){e.preventDefault(),this.dropdown.select(this)}},{key:"onMouseover",value:function(){this.activate()}},{key:"el",get:function(){if(this._el)return this._el;var e=document.createElement("li");e.className=this.active?this.activeClassName:this.className;var t=document.createElement("a");return t.innerHTML=this.searchResult.render(),e.appendChild(t),this._el=e,e.addEventListener("mousedown",this.onClick),e.addEventListener("mouseover",this.onMouseover),e.addEventListener("touchstart",this.onClick),e}},{key:"next",get:function(){var e=void 0;if(this.index===this.siblings.length-1){if(!this.dropdown.rotate)return null;e=0}else e=this.index+1;return this.siblings[e]}},{key:"prev",get:function(){var e=void 0;if(0===this.index){if(!this.dropdown.rotate)return null;e=this.siblings.length-1}else e=this.index-1;return this.siblings[e]}}]),e}();t.default=u},function(e,t,n){"use strict";function r(e){return e&&e.__esModule?e:{default:e}}function i(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}function o(e,t){if(!e)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return!t||"object"!=typeof t&&"function"!=typeof t?e:t}function s(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Super expression must either be null or a function, not "+typeof t);e.prototype=Object.create(t&&t.prototype,{constructor:{value:e,enumerable:!1,writable:!0,configurable:!0}}),t&&(Object.setPrototypeOf?Object.setPrototypeOf(e,t):e.__proto__=t)}Object.defineProperty(t,"__esModule",{value:!0});var a=function(){function e(e,t){for(var n=0;n<t.length;n++){var r=t[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(e,r.key,r)}}return function(t,n,r){return n&&e(t.prototype,n),r&&e(t,r),t}}(),u=function e(t,n,r){null===t&&(t=Function.prototype);var i=Object.getOwnPropertyDescriptor(t,n);if(void 0===i){var o=Object.getPrototypeOf(t);return null===o?void 0:e(o,n,r)}if("value"in i)return i.value;var s=i.get;if(void 0!==s)return s.call(r)},l=n(13),c=r(l),h=n(4),f=r(h),d=n(3),v=n(0),p=(r(v),n(14)),y=["onInput","onKeydown"],m=function(e){function t(e){i(this,t);var n=o(this,(t.__proto__||Object.getPrototypeOf(t)).call(this));return n.el=e,y.forEach(function(e){n[e]=n[e].bind(n)}),n.startListening(),n}return s(t,e),a(t,[{key:"destroy",value:function(){return u(t.prototype.__proto__||Object.getPrototypeOf(t.prototype),"destroy",this).call(this),this.stopListening(),this.el=null,this}},{key:"applySearchResult",value:function(e){var t=this.getBeforeCursor();if(null!=t){var n=e.replace(t,this.getAfterCursor());this.el.focus(),Array.isArray(n)&&((0,c.default)(this.el,n[0],n[1]),this.el.dispatchEvent(new Event("input")))}}},{key:"getCursorOffset",value:function(){var e=(0,d.calculateElementOffset)(this.el),t=this.getElScroll(),n=this.getCursorPosition(),r=(0,d.getLineHeightPx)(this.el),i=e.top-t.top+n.top+r,o=e.left-t.left+n.left;return"rtl"!==this.el.dir?{top:i,left:o,lineHeight:r}:{top:i,right:document.documentElement?document.documentElement.clientWidth-o:0,lineHeight:r}}},{key:"getBeforeCursor",value:function(){return this.el.selectionStart!==this.el.selectionEnd?null:this.el.value.substring(0,this.el.selectionEnd)}},{key:"getAfterCursor",value:function(){return this.el.value.substring(this.el.selectionEnd)}},{key:"getElScroll",value:function(){return{top:this.el.scrollTop,left:this.el.scrollLeft}}},{key:"getCursorPosition",value:function(){return p(this.el,this.el.selectionEnd)}},{key:"onInput",value:function(){this.emitChangeEvent()}},{key:"onKeydown",value:function(e){var t=this.getCode(e),n=void 0;"UP"===t||"DOWN"===t?n=this.emitMoveEvent(t):"ENTER"===t?n=this.emitEnterEvent():"ESC"===t&&(n=this.emitEscEvent()),n&&n.defaultPrevented&&e.preventDefault()}},{key:"startListening",value:function(){this.el.addEventListener("input",this.onInput),this.el.addEventListener("keydown",this.onKeydown)}},{key:"stopListening",value:function(){this.el.removeEventListener("input",this.onInput),this.el.removeEventListener("keydown",this.onKeydown)}}]),t}(f.default);t.default=m},function(e,t){"use strict";function n(){if("undefined"!=typeof Event)return new Event("input",{bubbles:!0,cancelable:!0});var e=document.createEvent("Event");return e.initEvent("input",!0,!0),e}Object.defineProperty(t,"__esModule",{value:!0}),t.default=function(e,t,r){for(var i=e.value,o=t+(r||""),s=document.activeElement,a=0,u=0;a<i.length&&a<o.length&&i[a]===o[a];)a++;for(;i.length-u-1>=0&&o.length-u-1>=0&&i[i.length-u-1]===o[o.length-u-1];)u++;a=Math.min(a,Math.min(i.length,o.length)-u),e.setSelectionRange(a,i.length-u);var l=o.substring(a,o.length-u);return e.focus(),document.execCommand("insertText",!1,l)||(e.value=o,e.dispatchEvent(n())),e.setSelectionRange(t.length,t.length),s&&s.focus(),e}},function(e){!function(){function t(e,t,o){if(!r)throw new Error("textarea-caret-position#getCaretCoordinates should only be called in a browser");var s=o&&o.debug||!1;if(s){var a=document.querySelector("#input-textarea-caret-position-mirror-div");a&&a.parentNode.removeChild(a)}var u=document.createElement("div");u.id="input-textarea-caret-position-mirror-div",document.body.appendChild(u);var l=u.style,c=window.getComputedStyle?getComputedStyle(e):e.currentStyle;l.whiteSpace="pre-wrap","INPUT"!==e.nodeName&&(l.wordWrap="break-word"),l.position="absolute",s||(l.visibility="hidden"),n.forEach(function(e){l[e]=c[e]}),i?e.scrollHeight>parseInt(c.height)&&(l.overflowY="scroll"):l.overflow="hidden",u.textContent=e.value.substring(0,t),"INPUT"===e.nodeName&&(u.textContent=u.textContent.replace(/\s/g," "));var h=document.createElement("span");h.textContent=e.value.substring(t)||".",u.appendChild(h);var f={top:h.offsetTop+parseInt(c.borderTopWidth),left:h.offsetLeft+parseInt(c.borderLeftWidth)};return s?h.style.backgroundColor="#aaa":document.body.removeChild(u),f}var n=["direction","boxSizing","width","height","overflowX","overflowY","borderTopWidth","borderRightWidth","borderBottomWidth","borderLeftWidth","borderStyle","paddingTop","paddingRight","paddingBottom","paddingLeft","fontStyle","fontVariant","fontWeight","fontStretch","fontSize","fontSizeAdjust","lineHeight","fontFamily","textAlign","textTransform","textIndent","textDecoration","letterSpacing","wordSpacing","tabSize","MozTabSize"],r="undefined"!=typeof window,i=r&&null!=window.mozInnerScreenX;void 0!==e&&void 0!==e.exports?e.exports=t:r&&(window.getCaretCoordinates=t)}()}]);

//= require timeago

//= require autosize

window.Thredded = window.Thredded || {};

//= require thredded/core/thredded

(() => {
  const isTurbolinks = 'Turbolinks' in window && window.Turbolinks.supported;
  const isTurbolinks5 = isTurbolinks && 'clearCache' in window.Turbolinks;
  const isTurbo = 'Turbo' in window;

  let onPageLoadFiredOnce = false;
  const pageLoadCallbacks = [];
  const triggerOnPageLoad = () => {
    pageLoadCallbacks.forEach((callback) => {
      callback();
    });
    onPageLoadFiredOnce = true;
  };

  // Fires the callback on DOMContentLoaded or a Turbo/Turbolinks page load.
  window.Thredded.onPageLoad = (callback) => {
    pageLoadCallbacks.push(callback);
    // With async script loading, a callback may be added after the DOMContentLoaded event has already triggered.
    if (!onPageLoadFiredOnce && window.Thredded.DOMContentLoadedFired) {
      callback();
    }
  };

  // Hotwire Turbo support
  if (isTurbo) {
    document.addEventListener('DOMContentLoaded', () => {
      triggerOnPageLoad();
    });
    document.addEventListener('turbo:load', () => {
      triggerOnPageLoad();
    });
    document.addEventListener('turbo:frame-load', () => {
      triggerOnPageLoad();
    });
  } else if (isTurbolinks5) {
    if (window.Turbolinks.controller.lastRenderedLocation) {
      document.addEventListener('DOMContentLoaded', () => {
        triggerOnPageLoad();
      });
    }
    document.addEventListener('turbolinks:load', () => {
      triggerOnPageLoad();
    });
  } else {
    // No Turbo/Turbolinks:
    if (!window.Thredded.DOMContentLoadedFired) {
      document.addEventListener('DOMContentLoaded', () => {
        triggerOnPageLoad();
      });
    }
    if (isTurbolinks) {
      document.addEventListener('page:load', () => {
        triggerOnPageLoad();
      })
    }
  }
})();


//= require thredded/core/on_page_load

window.Thredded.onPageLoad(() => {
  if ('Rails' in window) {
    window.Rails.refreshCSRFTokens();
  } else if ('jQuery' in window && 'rails' in window.jQuery) {
    window.jQuery.rails.refreshCSRFTokens();
  }
});

//= require thredded/core/thredded

/**
 * Return a function, that, as long as it continues to be invoked, will
 * not be triggered. The function will be called after it stops being
 * called for `wait` milliseconds. If `immediate` is passed, trigger the
 * function on the leading edge, instead of the trailing.
 * Based on https://john-dugan.com/javascript-debounce/.
 *
 * @param {Function} func
 * @param {Number} wait in milliseconds
 * @param {Boolean} immediate
 * @returns {Function}
 */
window.Thredded.debounce = function(func, wait, immediate) {
  let timeoutId = null;
  return function() {
    const context = this, args = arguments;
    const later = function() {
      timeoutId = null;
      if (!immediate) {
        func.apply(context, args);
      }
    };
    const callNow = immediate && !timeoutId;
    clearTimeout(timeoutId);
    timeoutId = setTimeout(later, wait || 200);
    if (callNow) {
      func.apply(context, args);
    }
  };
};

//= require thredded/core/thredded

window.Thredded.escapeHtml = function(text) {
  const node = document.createElement('div');
  node.textContent = text;
  return node.innerHTML;
};

//= require thredded/core/thredded

window.Thredded.hideSoftKeyboard = () => {
  const activeElement = document.activeElement;
  if (!activeElement || !activeElement.blur) return;
  activeElement.blur();
};

//= require thredded/core/thredded

window.Thredded.serializeForm = (form) => {
  // Can't use new FormData(form).entries() because it's not supported on any IE
  // The below is not a full replacement, but enough for Thredded's purposes.
  return Array.prototype.map.call(form.querySelectorAll('[name]'), (e) => {
    return `${encodeURIComponent(e.name)}=${encodeURIComponent(e.value)}`;
  }).join('&');
};

//= require thredded/core/thredded
//= require thredded/core/on_page_load

(() => {
  const Thredded = window.Thredded;

  const COMPONENT_SELECTOR = '[data-thredded-currently-online]';
  const EXPANDED_CLASS = 'thredded--is-expanded';

  const handleMouseEnter = (evt) => {
    evt.target.classList.add(EXPANDED_CLASS);
  };

  const handleMouseLeave = (evt) => {
    evt.target.classList.remove(EXPANDED_CLASS);
  };

  const handleTouchStart = (evt) => {
    evt.target.classList.toggle(EXPANDED_CLASS);
  };

  const initCurrentlyOnline = (node) => {
    node.addEventListener('mouseenter', handleMouseEnter);
    node.addEventListener('mouseleave', handleMouseLeave);
    node.addEventListener('touchstart', handleTouchStart);
  };

  Thredded.onPageLoad(() => {
    Array.prototype.forEach.call(document.querySelectorAll(COMPONENT_SELECTOR), (node) => {
      initCurrentlyOnline(node);
    });
  });
})();

(() => {
  const COMPONENT_SELECTOR = '[data-thredded-flash-message]';

  document.addEventListener('turbo:before-cache', () => {
    Array.prototype.forEach.call(document.querySelectorAll(COMPONENT_SELECTOR), (node) => {
      node.parentNode.removeChild(node);
    });
  });
})();

//= require thredded/components/user_textcomplete

const ThreddedMentionAutocompletion = {
  MATCH_RE: /(^@|\s@)"?([\w., \-()]+[\w.,\-()])$/,
  // the last letter has to not be a space so it doesn't match after replacement
  DROPDOWN_MAX_COUNT: 6,

  init(form, textarea) {
    const editor = new Textcomplete.editors.Textarea(textarea);
    const textcomplete = new Textcomplete(editor, {
      dropdown: {
        className: Thredded.UserTextcomplete.DROPDOWN_CLASS_NAME,
        maxCount: ThreddedMentionAutocompletion.DROPDOWN_MAX_COUNT
      },
    });
    textcomplete.on('rendered', function() {
      if (textcomplete.dropdown.items.length) {
        textcomplete.dropdown.items[0].activate();
      }
    });
    textcomplete.register([{
      match: ThreddedMentionAutocompletion.MATCH_RE,
      search: Thredded.UserTextcomplete.searchFn({
        url: form.getAttribute('data-autocomplete-url'),
        autocompleteMinLength: parseInt(form.getAttribute('data-autocomplete-min-length'), 10)
      }),
      template: Thredded.UserTextcomplete.formatUser,
      replace  ({name, match}) {
        let prefix = match[1];
        if (/[., ()]/.test(name)) {
          return `${prefix}"${name}" `
        } else {
          return `${prefix}${name} `
        }
      }
    }]);
  }
};

window.ThreddedMentionAutocompletion = ThreddedMentionAutocompletion;

//= require thredded/core/thredded
//= require thredded/dependencies/autosize
//= require thredded/core/on_page_load
//= require thredded/components/mention_autocompletion
//= require thredded/components/preview_area

(() => {
  const Thredded = window.Thredded;
  const ThreddedMentionAutocompletion = window.ThreddedMentionAutocompletion;
  const ThreddedPreviewArea = window.ThreddedPreviewArea;
  const autosize = window.autosize;

  const COMPONENT_SELECTOR = '[data-thredded-post-form]';
  const CONTENT_TEXTAREA_SELECTOR = 'textarea[name$="[content]"]';

  const initPostForm = (form) => {
    const textarea = form.querySelector(CONTENT_TEXTAREA_SELECTOR);
    autosize(textarea);
    new ThreddedPreviewArea(form, textarea);
    ThreddedMentionAutocompletion.init(form, textarea);
  };

  const destroyPostForm = (form) => {
    autosize.destroy(form.querySelector(CONTENT_TEXTAREA_SELECTOR));
  };

  Thredded.onPageLoad(() => {
    Array.prototype.forEach.call(document.querySelectorAll(COMPONENT_SELECTOR), (node) => {
      initPostForm(node);
    });
  });

  document.addEventListener('turbo:before-cache', () => {
    Array.prototype.forEach.call(document.querySelectorAll(COMPONENT_SELECTOR), (node) => {
      destroyPostForm(node);
    });
  });
})();

//= require thredded/core/thredded
//= require thredded/core/debounce
//= require thredded/core/serialize_form
//= require thredded/components/spoilers

(() => {
  const Thredded = window.Thredded;
  const PREVIEW_AREA_SELECTOR = '[data-thredded-preview-area]';
  const PREVIEW_AREA_POST_SELECTOR = '[data-thredded-preview-area-post]';

  class ThreddedPreviewArea {

    constructor(form, textarea) {
      const preview = form.querySelector(PREVIEW_AREA_SELECTOR);
      if (!preview || !textarea) return;
      this.form = form;
      this.preview = preview;
      this.previewPost = form.querySelector(PREVIEW_AREA_POST_SELECTOR);
      this.previewUrl = this.preview.getAttribute('data-thredded-preview-url');

      let prevValue = null;
      const onChange = Thredded.debounce(() => {
        if (prevValue !== textarea.value) {
          this.updatePreview();
          prevValue = textarea.value;
        }
      }, 200, false);

      textarea.addEventListener('input', onChange, false);
      if(textarea.value.trim() !== '') {
        onChange();
      }
      this.requestId = 0;
    }

    updatePreview() {
      this.requestId++;
      const requestId = this.requestId;
      const request = new XMLHttpRequest();
      request.open(this.form.method, this.previewUrl, /* async */ true);
      request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      request.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
      request.onload = () => {
        if (
          // Ignore server errors
          request.status >= 200 && request.status < 400 &&
          // Ignore older responses received out-of-order
          requestId === this.requestId) {
          this.onPreviewResponse(request.responseText);
        }
      };
      request.send(Thredded.serializeForm(this.form));
    }

    onPreviewResponse(data) {
      this.preview.style.display = 'block';
      this.previewPost.innerHTML = data;
      Thredded.spoilers.init(this.previewPost);
    }
  }

  window.ThreddedPreviewArea = ThreddedPreviewArea;
})();

//= require thredded/core/thredded
//= require thredded/core/on_page_load

(function() {
  const Thredded = window.Thredded;

  Thredded.onPageLoad(() => {
    Array.prototype.forEach.call(document.querySelectorAll('[data-thredded-quote-post]'), (el) => {
      el.addEventListener('click', onClick);
    });
  });

  function onClick(evt) {
    // Handle only left clicks with no modifier keys
    if (evt.button !== 0 || evt.ctrlKey || evt.altKey || evt.metaKey || evt.shiftKey) return;
    evt.preventDefault();
    const target = document.getElementById('post_content');
    target.scrollIntoView();
    target.value = '...';
    fetchReply(evt.target.getAttribute('data-thredded-quote-post'), (replyText) => {
      if (!target.ownerDocument.body.contains(target)) return;
      target.focus();
      target.value = replyText;

      const autosizeUpdateEvent = document.createEvent('Event');
      autosizeUpdateEvent.initEvent('autosize:update', true, false);
      target.dispatchEvent(autosizeUpdateEvent);
      // Scroll into view again as the size might have changed.
      target.scrollIntoView();
    }, (errorMessage) => {
      target.value = errorMessage;
    });
  }

  function fetchReply(url, onSuccess, onError) {
    const request = new XMLHttpRequest();
    request.open('GET', url, /* async */ true);
    request.onload = () => {
      if (request.status >= 200 && request.status < 400) {
        onSuccess(request.responseText);
      } else {
        onError(`Error (${request.status}): ${request.statusText} ${request.responseText}`);
      }
    };
    request.onerror = () => {
      onError('Network Error');
    };
    request.send();
  }
})();

//= require thredded/core/thredded
//= require thredded/core/on_page_load

(() => {
  const Thredded = window.Thredded;
  const COMPONENT_SELECTOR = '.thredded--post--content--spoiler';
  const OPEN_CLASS = 'thredded--post--content--spoiler--is-open';

  Thredded.spoilers = {
    init(root) {
      Array.prototype.forEach.call(root.querySelectorAll(COMPONENT_SELECTOR), (node) => {
        node.addEventListener('mousedown', (evt) => {
          evt.stopPropagation();
          this.toggle(evt.currentTarget);
        });
        node.addEventListener('keypress', (evt) => {
          if (event.key === ' ' || event.key === 'Enter') {
            evt.preventDefault();
            evt.stopPropagation();
            this.toggle(evt.currentTarget);
          }
        });
      });
    },

    toggle(node) {
      const isOpen = node.classList.contains(OPEN_CLASS);
      node.classList.toggle(OPEN_CLASS);
      node.setAttribute('aria-expanded', isOpen ? 'false' : 'true');
      node.firstElementChild.setAttribute('aria-hidden', isOpen ? 'false' : 'true');
      node.lastElementChild.setAttribute('aria-hidden', isOpen ? 'true' : 'false');
    }
  };

  Thredded.onPageLoad(() => {
    Thredded.spoilers.init(document);
  });
})();

//= require thredded/core/thredded
(function() {
  const Thredded = window.Thredded;
  Thredded.isSubmitHotkey = (evt) => {
    // Ctrl+Enter.
    return evt.ctrlKey && (evt.keyCode === 13 || evt.keyCode === 10 /* http://crbug.com/79407 */);
  };

  document.addEventListener('keypress', (evt) => {
    if (Thredded.isSubmitHotkey(evt)) {
      const submitButton = document.querySelector('[data-thredded-submit-hotkey] [type="submit"]');
      if (!submitButton) return;
      evt.preventDefault();
      // Focus first for better visual feedback.
      submitButton.focus();
      submitButton.click();
    }
  });
})();

//= require thredded/core/thredded
(() => {
  const COMPONENT_SELECTOR = '#thredded--container [data-time-ago]';
  const Thredded = window.Thredded;
  if ('timeago' in window) {
    const timeago = window.timeago;
    Thredded.onPageLoad(() => {
      const threddedContainer = document.querySelector('#thredded--container');
      if (!threddedContainer) return;
      timeago().render(
        document.querySelectorAll(COMPONENT_SELECTOR),
        threddedContainer.getAttribute('data-thredded-locale').replace('-', '_'));
    });
    document.addEventListener('turbo:before-cache', () => {
      timeago.cancel();
    });
  } else if ('jQuery' in window && 'timeago' in jQuery.fn) {
    const $ = window.jQuery;
    Thredded.onPageLoad(() => {
      const allowFutureWas = $.timeago.settings.allowFuture;
      $.timeago.settings.allowFuture = true;
      $(COMPONENT_SELECTOR).timeago();
      $.timeago.settings.allowFuture = allowFutureWas;
    });
  }
})();

//= require thredded/core/thredded
//= require thredded/dependencies/autosize
//= require thredded/core/on_page_load
//= require thredded/components/mention_autocompletion
//= require thredded/components/preview_area

(() => {
  const Thredded = window.Thredded;
  const ThreddedMentionAutocompletion = window.ThreddedMentionAutocompletion;
  const ThreddedPreviewArea = window.ThreddedPreviewArea;
  const autosize = window.autosize;

  const COMPONENT_SELECTOR = '[data-thredded-topic-form]';
  const TITLE_SELECTOR = '[name$="topic[title]"]';
  const CONTENT_TEXTAREA_SELECTOR = 'textarea[name$="[content]"]';
  const COMPACT_CLASS = 'thredded--is-compact';
  const EXPANDED_CLASS = 'thredded--is-expanded';
  const ESCAPE_KEY_CODE = 27;

  const initTopicForm = (form) => {
    const textarea = form.querySelector(CONTENT_TEXTAREA_SELECTOR);
    if (!textarea) {
      return;
    }
    autosize(textarea);
    new ThreddedPreviewArea(form, textarea);
    ThreddedMentionAutocompletion.init(form, textarea);

    if (!form.classList.contains(COMPACT_CLASS)) {
      return;
    }

    const title = form.querySelector(TITLE_SELECTOR);
    title.addEventListener('focus', () => {
      toggleExpanded(form, true);
    });

    [title, textarea].forEach((node) => {
      // Un-expand on Escape key.
      node.addEventListener('keydown', (evt) => {
        if (evt.keyCode === ESCAPE_KEY_CODE) {
          evt.target.blur();
          toggleExpanded(form, false);
        }
      });

      // Un-expand on blur if the new focus element is outside of the same form and
      // all the form inputs are empty.
      node.addEventListener('blur', () => {
        // This listener will be fired right after the blur event has finished.
        const listener = (evt) => {
          if (!form.contains(evt.target) && !title.value && !textarea.value) {
            toggleExpanded(form, false);
          }
          document.body.removeEventListener('touchend', listener);
          document.body.removeEventListener('mouseup', listener);
        };
        document.body.addEventListener('mouseup', listener);
        document.body.addEventListener('touchend', listener);
      })
    });
  };

  const toggleExpanded = (form, expand) => {
    if (expand) {
      form.classList.remove(COMPACT_CLASS);
      form.classList.add(EXPANDED_CLASS);
    } else {
      form.classList.remove(EXPANDED_CLASS);
      form.classList.add(COMPACT_CLASS);
    }
  };

  const destroyTopicForm = (form) => {
    const textarea = form.querySelector(CONTENT_TEXTAREA_SELECTOR);
    if (!textarea) {
      return;
    }
    autosize.destroy(textarea);
  };

  Thredded.onPageLoad(() => {
    Array.prototype.forEach.call(document.querySelectorAll(COMPONENT_SELECTOR), (node) => {
      initTopicForm(node);
    });
  });

  document.addEventListener('turbo:before-cache', () => {
    Array.prototype.forEach.call(document.querySelectorAll(COMPONENT_SELECTOR), (node) => {
      destroyTopicForm(node);
    });
  });
})();



//= require thredded/core/thredded
//= require thredded/core/on_page_load
//= require thredded/core/serialize_form

// Makes topics in the list appear read as soon as the topic link is clicked,
// iff the topic link leads to the last page of the topic.
(() => {
  const Thredded = window.Thredded;

  const COMPONENT_SELECTOR = '[data-thredded-topics]';
  const TOPIC_UNREAD_CLASS = 'thredded--topic-unread';
  const TOPIC_READ_CLASS = 'thredded--topic-read';
  const POSTS_COUNT_SELECTOR = '.thredded--topics--posts-count';

  function pageNumber(url) {
    const match = url.match(/\/page-(\d)$/);
    return match ? +match[1] : 1;
  }

  function totalPages(numPosts, postsPerPage) {
    return Math.ceil(numPosts / postsPerPage);
  }

  function getAncestorTag(node, ancestorTagName) {
    do {
      node = node.parentNode;
    } while (node && node.tagName !== ancestorTagName);
    return node;
  }

  function getTopicNode(node) {
    return getAncestorTag(node, 'ARTICLE');
  }

  function getUnreadNavItem(unreadFollowedCountElement) {
    return getAncestorTag(unreadFollowedCountElement, 'LI');
  }

  function initTopicsList(topicsList) {
    const postsPerPage = +topicsList.getAttribute('data-thredded-topic-posts-per-page') || 25;
    const isPrivateTopics = topicsList.getAttribute('data-thredded-topics') === 'private';
    const unreadFollowedCountElement = document.querySelector('[data-unread-followed-count]');
    topicsList.addEventListener('click', (evt) => {
      const link = evt.target;
      if (link.tagName !== 'A' || link.parentNode.tagName !== 'H1') return;
      const topic = getTopicNode(link);
      if (pageNumber(link.href) === totalPages(+topic.querySelector(POSTS_COUNT_SELECTOR).textContent, postsPerPage)) {
        if (!isPrivateTopics && unreadFollowedCountElement &&
          topic.hasAttribute('data-followed') && topic.hasAttribute('data-unread')) {
          const count = (+unreadFollowedCountElement.textContent) - 1;
          if (count === 0) {
            const navItem = getUnreadNavItem(unreadFollowedCountElement);
            navItem.parentElement.removeChild(navItem);
          } else {
            unreadFollowedCountElement.textContent = count.toLocaleString();
          }
        }
        topic.classList.add(TOPIC_READ_CLASS);
        topic.classList.remove(TOPIC_UNREAD_CLASS);
        topic.removeAttribute('data-unread');
      }
    });
  }

  Thredded.onPageLoad(() => {
    Array.prototype.forEach.call(document.querySelectorAll(COMPONENT_SELECTOR), initTopicsList);
  });
})();

//= require thredded/core/thredded
//= require thredded/core/on_page_load
//= require thredded/core/serialize_form

// Submit GET forms with turbolinks
(() => {
  const Thredded = window.Thredded;
  const Turbolinks = window.Turbolinks;

  const handleSubmit = (evt) => {
    evt.preventDefault();
    const form = evt.currentTarget;
    Turbolinks.visit(form.action + (form.action.indexOf('?') === -1 ? '?' : '&') + Thredded.serializeForm(form));

    // On mobile the soft keyboard doesn't won't go away after the submit since we're submitting with
    // Turbolinks. Hide it:
    Thredded.hideSoftKeyboard();
  };

  Thredded.onPageLoad(() => {
    if (!Turbolinks || !Turbolinks.supported) return;
    Array.prototype.forEach.call(document.querySelectorAll('[data-thredded-turboform]'), (form) => {
      form.addEventListener('submit', handleSubmit);
    });
  });
})();

//= require thredded/core/thredded
//= require thredded/core/on_page_load

// Reflects the logic of user preference settings by enabling/disabling certain inputs.
(() => {
  const Thredded = window.Thredded;

  const COMPONENT_SELECTOR = '[data-thredded-user-preferences-form]';
  const BOUND_MESSAGEBOARD_NAME = 'data-thredded-bound-messageboard-pref';
  const UPDATE_ON_CHANGE_NAME = 'data-thredded-update-checkbox-on-change';

  class MessageboardPreferenceBinding {
    constructor(form, genericCheckboxName, messageboardCheckboxName) {
      this.messageboardCheckbox = form.querySelector(`[type="checkbox"][name="${messageboardCheckboxName}"]`);
      if (!this.messageboardCheckbox) {
        return;
      }
      this.messageboardCheckbox.addEventListener('change', () => {
        this.rememberMessageboardChecked();
      });
      this.rememberMessageboardChecked();

      this.genericCheckbox = form.querySelector(`[type="checkbox"][name="${genericCheckboxName}"]`);
      this.genericCheckbox.addEventListener('change', () => {
        this.updateMessageboardCheckbox();
      });
      this.updateMessageboardCheckbox();
    }

    rememberMessageboardChecked() {
      this.messageboardCheckedWas = this.messageboardCheckbox.checked;
    }

    updateMessageboardCheckbox() {
      const enabled = this.genericCheckbox.checked;
      this.messageboardCheckbox.disabled = !enabled;
      this.messageboardCheckbox.checked = enabled ? this.messageboardCheckedWas : false;
    }
  }

  class UpdateOnChange {
    constructor(form, sourceElement, targetName) {
      const target = form.querySelector(`[type="checkbox"][name="${targetName}"]`);
      if (!target) return;
      sourceElement.addEventListener('change', () => {
        target.checked = sourceElement.checked;
      });
    }
  }

  class UserPreferencesForm {
    constructor(form) {
      Array.prototype.forEach.call(form.querySelectorAll(`input[${BOUND_MESSAGEBOARD_NAME}]`), (element) => {
        new MessageboardPreferenceBinding(form, element.name, element.getAttribute(BOUND_MESSAGEBOARD_NAME));
      });
      Array.prototype.forEach.call(form.querySelectorAll(`input[${UPDATE_ON_CHANGE_NAME}]`), (element) => {
        new UpdateOnChange(form, element, element.getAttribute(UPDATE_ON_CHANGE_NAME));
      });
    }
  }

  Thredded.onPageLoad(() => {
    Array.prototype.forEach.call(document.querySelectorAll(COMPONENT_SELECTOR), (form) => {
      new UserPreferencesForm(form);
    });
  });
})();

//= require thredded/core/thredded
//= require thredded/core/escape_html
//= require thredded/dependencies/textcomplete

(() => {
  const Thredded = window.Thredded;

  Thredded.UserTextcomplete = {
    DROPDOWN_CLASS_NAME: 'thredded--textcomplete-dropdown',

    formatUser({avatar_url, name, display_name}) {
      return "<div class='thredded--textcomplete-user-result'>" +
        `<img class='thredded--textcomplete-user-result__avatar' src='${Thredded.escapeHtml(avatar_url)}' >` +
        `<span class='thredded--textcomplete-user-result__name'>${Thredded.escapeHtml(name)}</span>` +
        (name !== display_name && display_name ?
          `<span class='thredded--textcomplete-user-result__display_name'>${Thredded.escapeHtml(display_name)}</span>` :
          '') +
        '</div>';
    },

    searchFn({url, autocompleteMinLength}) {
      return function search(term, callback, match) {
        if (term.length < autocompleteMinLength) {
          callback([]);
          return;
        }
        const request = new XMLHttpRequest();
        request.open('GET', `${url}?q=${term}`, /* async */ true);
        request.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
        request.onload = () => {
          // Ignore errors
          if (request.status < 200 || request.status >= 400) {
            callback([]);
            return;
          }
          callback(JSON.parse(request.responseText).results.map(({avatar_url, id, display_name, name}) => {
            return {avatar_url, id, name, display_name, match};
          }));
        };
        request.send();
      }
    }
  };

  document.addEventListener('turbo:before-cache', () => {
    Array.prototype.forEach.call(
      document.getElementsByClassName(Thredded.UserTextcomplete.DROPDOWN_CLASS_NAME), (node) => {
        node.parentNode.removeChild(node);
      });
  });
})();

//= require thredded/core/thredded
//= require thredded/core/on_page_load
//= require thredded/components/user_textcomplete
//= require thredded/dependencies/autosize

(() => {
  const Thredded = window.Thredded;
  const autosize = window.autosize;

  const COMPONENT_SELECTOR = '[data-thredded-users-select]';

  Thredded.UsersSelect = {
    DROPDOWN_MAX_COUNT: 6,
  };

  function parseNames(text) {
    const result = [];
    let current = [];
    let currentIndex = 0;
    let inQuoted = false;
    let inName = false;
    for (let i = 0; i < text.length; ++i) {
      const char = text.charAt(i);
      switch (char) {
        case '"':
          inQuoted = !inQuoted;
          break;
        case ' ':
          if (inName) current.push(char);
          break;
        case ',':
          if (inQuoted) {
            current.push(char);
          } else {
            inName = false;
            if (current.length) {
              result.push({name: current.join(''), index: currentIndex});
              current.length = 0;
            }
          }
          break;
        default:
          if (!inName) currentIndex = i;
          inName = true;
          current.push(char);
      }
    }
    if (current.length) result.current = {name: current.join(''), index: currentIndex};
    return result;
  }

  const initUsersSelect = (textarea) => {
    autosize(textarea);
    // Prevent multiple lines
    textarea.addEventListener('keypress', (evt) => {
      if (evt.keyCode === 13 || evt.keyCode === 10) {
        evt.preventDefault()
      }
    });
    const editor = new Textcomplete.editors.Textarea(textarea);
    const textcomplete = new Textcomplete(editor, {
      dropdown: {
        className: Thredded.UserTextcomplete.DROPDOWN_CLASS_NAME,
        maxCount: Thredded.UsersSelect.DROPDOWN_MAX_COUNT,
      },
    });
    textarea.addEventListener('blur', (evt) => {
      textcomplete.hide();
    });

    const searchFn = Thredded.UserTextcomplete.searchFn({
      url: textarea.getAttribute('data-autocomplete-url'),
      autocompleteMinLength: parseInt(textarea.getAttribute('data-autocomplete-min-length'), 10)
    });
    textcomplete.on('rendered', function() {
      if (textcomplete.dropdown.items.length) {
        textcomplete.dropdown.items[0].activate();
      }
    });
    textcomplete.register([{
      index: 0,
      match: (text) => {
        const names = parseNames(text);
        if (names.current) {
          const {name, index} = names.current;
          const matchData = [name];
          matchData.index = index;
          return matchData;
        } else {
          return null;
        }
      },
      search (term, callback, match) {
        searchFn(term, function(results) {
          const names = parseNames(textarea.value).map(({name}) => name);
          callback(results.filter((result) => names.indexOf(result.name) === -1));
        }, match);
      },
      template: Thredded.UserTextcomplete.formatUser,
      replace  ({name}) {
        if (/,/.test(name)) {
          return `"${name}", `
        } else {
          return `${name}, `
        }
      }
    }]);
  };

  function destroyUsersSelect(textarea) {
    autosize.destroy(textarea);
  }

  window.Thredded.onPageLoad(() => {
    Array.prototype.forEach.call(document.querySelectorAll(COMPONENT_SELECTOR), (node) => {
      initUsersSelect(node);
    });
  });

  document.addEventListener('turbo:before-cache', () => {
    Array.prototype.forEach.call(document.querySelectorAll(COMPONENT_SELECTOR), (node) => {
      destroyUsersSelect(node);
    });
  });

})();

})();
