/**
 * @fileoverview
 * <p>This file contains basic client classes and methods to query
 * SeeAlso webservices and display the results in HTML. SeeAlso is 
 * a link server protocol based on OpenSearch Suggestions and unAPI.
 * </p><p>
 * This library is compatible with <a href="http://jquery.com">jQuery</a>
 * but does not need it.
 * <p>You can automatically
 * generate documentation from this file with
 * <a href="http://jsdoc.sourceforge.net/">JSDoc</a>.
 * </p><p>
 * More information and examples on how to use this client can be
 * found in the README file of this distribution.
 * </p><p>
 * Copyright (c) 2008 Jakob Voss (GBV).
 * Dual licensed under the General Public License (GPL.txt)
 * and the license and Affero General Public License (AGPL.txt).
 * </p>
 * @author: Jakob Voss
 * @version: 0.6.41
 */


/**
* Creates a SeeAlso Simple Response (which mostly the same as OpenSearch 
* Suggestions Response).
*
* @param {mixed} value optional value(s), passed to the {@link #set} method.
* @constructor
*/
function SeeAlsoResponse(value) {
    this.set(value);
}

/**
 * Sets the whole response content.
 *
 * <p>You can either set the identifier value only:
 * <pre>response.set("id123");</pre>
 * or pass a JSON string:<br />
 * <pre>response.set("['id123',['label1'],['descr1'],['uri1']");</pre>
 * or pass a JSON array object<br />
 * <pre>response.set(['id123',['label1'],['descr1'],['uri1']);</pre></p>
 *
 * @param {mixed} value either an identifier string or an array or a JSON string
 */
SeeAlsoResponse.prototype.set = function(value) {
    this.identifier = "";
    this.labels = [];
    this.descriptions = [];
    this.uris = [];
    if (typeof value == "object") {
        if (typeof value[0] == "string") 
            this.identifier = value[0];
        if (typeof value[1] == "object") {
            var d = typeof value[2] == "object" ? value[2] : "";
            var u = typeof value[3] == "object" ? value[3] : "";
            if (typeof value[3] != "object") value[3] = [];
            for (var i=0; i<value[1].length; i++) {
                this.add(value[1][i], d ? d[i] : "", u ? u[i] : "");
            }
        }
    } else if (typeof value == "string") {
        if (/^\s*\[/.test(value)) {
            this.set(JSON.parse(value));
        } else {
            this.identifier = value;
        }
    }
};

/**
 * Gives response in JSON format.
 * @returns the response in JSON format, optionally wrapped by
 * a callback method call.
 * @param {String} callback a callback method name (optional)
 * @type String
 */
SeeAlsoResponse.prototype.toJSON = function(callback) {
    if (! /^[a-zA-Z0-9\._\[\]]+$/.test(callback) ) callback = "";
    var json = JSON.stringify( 
        [ this.identifier, this.labels, this.descriptions, this.uris ]
    );
    return callback ? callback + "(" + json + ");" : json;
};

/**
 * Adds an item to the response.
 * @param {String} label a response label (empty string by default)
 * @param {String} description a response description (empty string by default)
 * @param {String} uri a response uri (empty string by default)
 */
SeeAlsoResponse.prototype.add = function(label, description, uri) {
    this.labels.push( typeof label == "string" ? label : "" );
    this.descriptions.push( typeof description == "string" ? description : "" );
    this.uris.push( typeof uri == "string" ? uri : "" );
};

/**
 * Gets an item of the response.
 * <p>The return value is either an object with properties 'label', 
 * 'description', and 'uri', or an empty object.</p>
 * @returns an item (as object) of the <em>n</em>th label, description, and uri
 * @param {Integer} i index, starting from 0
 * @type Object
 */
SeeAlsoResponse.prototype.get = function(i) {
    if (!(i>=0 && i<this.labels.length)) return {};
    return {
        label:       this.labels[i], 
        description: this.descriptions[i],
        uri:         this.uris[i]
    };
};

/**
 * Gives the number of items in the response.
 * @returns the number of items of this response.
 * @type Integer
 */
SeeAlsoResponse.prototype.size = function() { 
    return this.labels.length; 
};


/**
 * Creates an object to process and display a {@link SeeAlsoResponse}.
 * @constructor
 */
function SeeAlsoView(p) {
    p = typeof p == "object" ? p : {};

    this.delimHTML = typeof p.delimHTML == "string" ? p.delimHTML : ", ";
    this.preHTML = (typeof p.preHTML == "string" || typeof p.preHTML == "function")
        ? p.preHTML : "";
    this.postHTML = (typeof p.postHTML == "string" || typeof p.postHTML == "function")
        ? p.postHTML : "";
    this.emptyHTML = (typeof p.emptyHTML != "undefined") ? p.emptyHTML : "";
    this.maxItems = typeof p.maxItems == "number" ? p.maxItems : 10;
    this.moreItems = typeof p.moreItems != "undefined" ? p.moreItems : " ...";

    // TODO: put this in the prototype
    this._itemHTML = function(item) {
        var label = item.label != "" ? item.label : item.url;
        if (label == "") return "";
        var html; // TODO: escape strings and test for empty values!
        if (item.uri) {
            html = '<a href="' + item.uri + '">' + label + "</a>";
        } else {
            html = label;
        }
        return html; 
    }

    this.itemHTML = typeof p.itemHTML == "function" ? p.itemHTML : this._itemHTML;
}

/**
 * @see SeeAlsoResponse#set
 * @returns an HTML string
 * @type String
 */
SeeAlsoView.prototype.makeHTML = function(response) {
    if (!(response instanceof SeeAlsoResponse)) {
        response = new SeeAlsoResponse(response)
    }
    if (!response || !response.size()) {
        return (typeof this.emptyHTML == "function"
            ? this.emptyHTML(response.identifier) : this.emptyHTML);
    }
    var html = typeof this.preHTML == "function"
        ? this.preHTML(response) : this.preHTML;
    for(var i=0; i<response.size(); i++) {
        if (i >= this.maxItems) {
            html += typeof this.moreItems == "function"
                ? this.moreItems(response) : this.moreItems;
            break;
        }
        if (i>0) {
            html += this.delimHTML;
        }
        html += this.itemHTML( response.get(i) );
    }
    html += typeof this.postHTML == "function"
        ? this.postHTML(response) : this.postHTML;
    return html;
};

/**
 * Display a list of response items in a given HTML element.
 * @param element HTML DOM element
 * @param response {@link SeeAlsoResponse} or response string/object
 */
SeeAlsoView.prototype.display = function(element, response) {
    var html = this.makeHTML(response);
    // TODO: IE completely kills leading whitespace when innerHTML is used.
    // if ( /^\s/.test( html ) ) createTextNode( html.match(/^\s*/)[0] ) ...
    element.innerHTML = html;

    // Display all parent containers (may be hidden by default)
    // Note that containers will be shown as block elements only!
    if (response && response.size()) {
        while ((element = element.parentNode)) {
            if (this.getClasses(element)["seealso-container"])
                element.style.display = '';
        }
    }
};


/**
 * Get the CSS classes of a HTML DOM element as hash.
 * @param elem
 */
SeeAlsoView.prototype.getClasses = function(elem) {
    var classes = {};
    if (elem && elem.className) {
        var c = elem.className.split(/\s+/);
        for ( var i = 0, length = c.length; i < length; i++ ) {
            if (c[i].length > 0) {
                classes[c[i]] = c[i];
            }
        }
    }
    return classes;
}


/**
 * A Source that delivers SeeAlsoResponse objects
 * @constructor
 */
function SeeAlsoSource(query) {
    if (typeof query == "function") {
        this._queryMethod = query;
    }

    /**
     * Either return a SeeAlsoResponse or call the callback method
     */
    this.query = function( identifier, callback ) {
        if (!this._queryMethod) return new SeeAlsoResponse();
        if (typeof callback == "function") {
            this._queryMethod(identifier, callback);
            return undefined;
        } else {
            return this._queryMethod(identifier);
        }
    }

    /**
     * Perform a query and display the response with
     * a given view at a given DOM element
     */
    this.queryDisplay = function(identifier, element, view) {
        this.query( identifier,
            function(data) {
                view.display(element, data);
            }
        );
    }
}


/**
* SeeAlsoService wraps a SeeAlso-Server, specified by a base URL.
*
* @param url the base URL
*
* @constructor
*/
function SeeAlsoService( url ) {
    /**
     * The base url of this service
     */
    this.url = url;

    /**
     * Get the query URL for a given identifier (including callback parameter)
     *
     * @todo check whether URL escaping is needed / check identifier
     */
    this.queryURL = function(identifier, callback) {
        var url = this.url + (this.url.indexOf('?') == -1 ? '?' : '&')
                + "format=seealso&id=" + identifier;
        if (callback) url += "&callback=" + callback;
        return url;
    }

    /**
     * Perform a query and run a callback method with the JSON response.
     * You can define the type of JSON request by setting {@link #jsonRequest}.
     * @param {String} identifier
     * @param {Function} callback
     */
    this._queryMethod = function(identifier, callback) {
        this.jsonRequest( this.queryURL(identifier,'?'), callback);
    }
}

SeeAlsoService.prototype = new SeeAlsoSource();

/**
 * Performs a HTTP query to get a SeeAlso Response in JSON format.
 *
 * <p>To get around the cross site scripting limitations of JavaScript 
 * a <tt>&lt;script&gt;</tt> tag is dynamically added to the page. 
 * Please note that this is a serious security problem! The SeeAlso 
 * service that you call may access the content of your page and cookies.
 * Don't call any services that you don't trust. A solution is to
 * either use a proxy at the domain of your page or use an implementation 
 * of <a href="http://www.json.org/JSONRequest.html">JSONRequest</a>
 * like <a href="http://www.json.com/2007/09/10/crosssafe/">CrossSafe</a>.</p>
 *
 * @param {String} url
 * @param {Function} callback
 */
SeeAlsoService.prototype.jsonRequest = function(url, callback) {
    jsc = typeof jsc == "undefined" ? (new Date).getTime() : jsc+1;
    var jsonp = "jsonp" + jsc; // this should also prevent caching

    var jsre = /=\?(&|$)/g; // todo: what if no callback was specified?!
    var head = document.getElementsByTagName("head")[0];
    var script = document.createElement("script");
    script.src = url.replace(jsre, "=" + jsonp + "&");
    script.type = "text/javascript";
    script.charset = "UTF-8";

    window[ jsonp ] = function(data){
        callback( new SeeAlsoResponse(data) );
        window[ jsonp ] = undefined; // GC
        try{ delete window[ jsonp ]; } catch(e){}
        if ( head ) script.parentNode.removeChild( script ); // yet another IE bug
    };

    head.appendChild(script);
};

// if jQuery is included <em>before</em> seealso, it is used to perform
// JSON requests. Support of <tt>JSONRequest.get</tt> will be added.
/*
SeeAlsoService.prototype.jsonRequest = function(url, callback) {
    JSONRequest.get(url, function (id,object,error) { 
        if (object) { callback( new SeeAlsoResponse(object) ); }
    }
};
*/
if (typeof jQuery != "undefined" && typeof jQuery.getJSON == "function") {
    SeeAlsoService.prototype.jsonRequest = function(url, callback) {
        $.getJSON( url, 
            function(data) { callback( new SeeAlsoResponse(data) ); }
        );
    }
};


/**
 * Unordered list
 */
function SeeAlsoUL(p) {
    p = typeof p == "object" ? p : {};
    p.preHTML = "<ul>";
    p.postHTML = "</ul>";
    p.delimHTML = "";
    // TODO: allow another itemHTML inside
    p.itemHTML = function(item) { 
        return "<li>" +  this._itemHTML(item) + "</li>" 
    }
    SeeAlsoView.prototype.constructor.call(this, p);
}

SeeAlsoUL.prototype = new SeeAlsoView;

/**
 * Comma seperated list 
 */
function SeeAlsoCSV(p) {
    p = typeof p == "object" ? p : {};
    SeeAlsoView.prototype.constructor.call(this, p);
}

SeeAlsoCSV.prototype = new SeeAlsoView;


/**
 * A SeeAlsoCollection contains a number of {@link SeeAlsoService}
 * and a number of {@link SeeAlsoView} together with some helper 
 * methods to query the services and display them with views.
 *
 * @constructor
 */
function SeeAlsoCollection() { // TODO: use .prototype syntax
    /**
     * Directory of named services ({@link SeeAlsoService})
     */
    this.services = {};
    /**
     * Directory of named views ({@link SeeAlsoView})
     */
    this.views = {};
    /**
     * Default view ({@link SeeAlsoView}) that is used if no specific view is given.
     */
    this.defaultView = new SeeAlsoCSV();

    // Replace all existing tags by querying all services
    this.replaceTags = function () {
        var all = document.getElementsByTagName('*');
        var i, tags=[], length=all.length;

        // <this is line 412>
        // foo.bar.doz = 1;

        // cycle through all tags in the document that use this service
        for (i = 0; i < length; i++) {
            var elem = all[i];
            if(!elem.className) continue;
            var identifier = elem.getAttribute("title");
            if (!identifier && identifier!="0") continue; // missing title attribute
            identifier = identifier.replace(/^\s+|\s+$/g,""); // trim

            // Cycle through all available services
            for (var serviceClass in this.services) {
                var reg = new RegExp("\\s" + serviceClass + "\\s");
                if (reg.test(" " + elem.className + " ")) {

                    // get the view to use
                    var view = this.defaultView;
                    var classes = SeeAlsoView.prototype.getClasses(elem);

                    for(c in classes) {
                        if (this.views[ c ]) {
                            view = this.views[ c ];
                            break;
                        }
                    }

                    if ( view ) {
                        // because views change the DOM, we first only collect them
                        tags.push(
                            { service: this.services[serviceClass], identifier: identifier, element:elem, view:view }
                        );
                        break; // don't try other services or views
                    }
                }
            }
        }

        // query the services
        for(i in tags) {
            var tag = tags[i];
            tag.service.queryDisplay( tag.identifier, tag.element, tag.view );
        }
    };

    // add onLoad (compatible with <body onload="">)
    this.replaceTagsOnLoad = function() {
        var me = this;
        function callReplaceTags() { me.replaceTags(); }
        if(typeof window.addEventListener != 'undefined') {
            window.addEventListener('load', callReplaceTags, false);
        } else if(typeof document.addEventListener != 'undefined') {
            document.addEventListener('load', callReplaceTags, false);
        } else if(typeof window.attachEvent != 'undefined') {
            window.attachEvent('onload', callReplaceTags);
        }
    }
}


/**
 * SeeAlso needs JSON.stringify and JSON.parse
 */
if (!this.JSON) { var JSON = function () {
    function f(n) { return n < 10 ? '0' + n : n; }
    var m = { '\b': '\\b', '\t': '\\t', '\n': '\\n',
              '\f': '\\f', '\r': '\\r', '"' : '\\"', '\\': '\\\\' };
    Date.prototype.toJSON = function () {
        return this.getUTCFullYear()   + '-' +
                f(this.getUTCMonth() + 1) + '-' +
                f(this.getUTCDate())      + 'T' +
                f(this.getUTCHours())     + ':' +
                f(this.getUTCMinutes())   + ':' +
                f(this.getUTCSeconds())   + 'Z';
    };
    function stringify(value) {
        var a,i,k,l,r = /["\\\x00-\x1f\x7f-\x9f]/g,v;
        switch (typeof value) {
        case 'string':
            return '"' + (r.test(value) ?
                value.replace(r, function (a) {
                    var c = m[a];
                    if (c) return c;
                    c = a.charCodeAt();
                    return '\\u00' + Math.floor(c / 16).toString(16) +
                                            (c % 16).toString(16);
                }) : value) + '"';
        case 'number':
            return isFinite(value) ? String(value) : 'null';
        case 'boolean':
        case 'null':
            return String(value);
        case 'object':
            if (!value) return 'null';
            if (typeof value.toJSON === 'function') {
                return stringify(value.toJSON());
            }
            a = [];
            if (typeof value.length === 'number' &&
                    !(value.propertyIsEnumerable('length'))) {
                l = value.length;
                for (i = 0; i < l; i += 1) {
                    a.push(stringify(value[i]) || 'null');
                }
                return '[' + a.join(',') + ']';
            }
            for (k in value) {
                if (typeof k === 'string') {
                    v = stringify(value[k], whitelist);
                    if (v) {
                        a.push(stringify(k) + ':' + v);
                    }
                }
            }
            return '{' + a.join(',') + '}';
        }
        return '';
    }
    return {
        stringify: stringify,
        parse: function (text) {
            if (/^[\],:{}\s]*$/.test(text.replace(/\\./g, '@').
replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').
replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
                return eval('(' + text + ')');
            }
        }
    };
}(); } // JSON
