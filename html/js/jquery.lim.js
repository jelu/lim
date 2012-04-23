/**
 * lim.lim
 */
(function ($, undefined) {
	$.widget('lim.lim', {
		options: {
			timeout: 5000
		},
		_create: function () {
			this._menubar = $('<div></div>').limMenubar({ lim: this.element }).appendTo(this.element);
			this._console = $('<div></div>').limConsole({ lim: this.element });
			this._helpers = {};
			this._helperCall = {};
		},
		_destroy: function () {
			this._menubar = 
				this._console = null;
		},
		menubar: function () {
			return this._menubar;
		},
		console: function () {
			return this._console;
		},
		logDebug: function (message) {
			return this._console.limConsole('debug', message);
		},
		logInfo: function (message) {
			return this._console.limConsole('info', message);
		},
		logWarn: function (message) {
			return this._console.limConsole('warn', message);
		},
		logError: function (message) {
			return this._console.limConsole('error', message);
		},
		call: function (uri, data, callback) {
			var co = this._console;
			
			if (uri === undefined || typeof uri !== 'string') {
				co.limConsole('error', 'call: uri invalid');
				return;
			}
			if (typeof data === 'function') {
				callback = data;
				data = null;
			}
			if (typeof data !== 'null' && typeof data !== 'object') {
				co.limConsole('error', 'call: data invalid');
				return;
			}
			co.limConsole('debug', 'call ' + uri);
			if (typeof callback === 'function') {
				$.ajax({
					url: uri,
					data: data,
					type: data === null ? 'GET' : 'POST',
					dataType: 'json',
					timeout: this.options.timeout,
					success: function(data, textStatus, XHR) {
						co.limConsole('debug', 'callback success ' + uri);
						if (data === undefined) {
							data = null;
						}
						else if (typeof data !== 'object') {
							data = null;
						}
						callback(data, textStatus, XHR);
					},
					error: function(XHR, textStatus, errorThrown) {
						co.limConsole('debug', 'callback error ' + uri);
						callback(null, (errorThrown ? errorThrown : textStatus), XHR);
					}
				});
			}
			else {
				$.ajax({
					url: uri,
					data: data,
					type: data === null ? 'GET' : 'POST',
					dataType: 'json',
					timeout: this.options.timeout,
					success: function () {
						co.limConsole('debug', '(no)callback success ' + uri);
					},
					error: function () {
						co.limConsole('debug', '(no)callback error ' + uri);
					}
				});
			}
		},
		loadHelper: function (uri, helper, callback) {
			if (callback === undefined) {
				callback = function () {};
			}
			if (typeof callback !== 'function') {
				return false;
			}
			
			if (this._helpers[helper] !== undefined) {
				callback(true);
				return true;
			}
			
			if (this._helperCall[helper] === true) {
				return false;
			}
			this._helperCall[helper] = true;
			
			this._console.limConsole('debug', 'loading helper '+helper);
			
			var that = this;
			this.call(uri+'/helpers/helper/'+helper, function (data, status) {
				if (data && typeof data === 'object' && data.helper) {
					for (var i = 0, len = data.helper.length; i < len; i++) {
						if (data.helper[i].name == helper) {
							that._console.limConsole('debug', 'retrieved helper '+helper);
							try {
								eval(data.helper[i].code);
								that._console.limConsole('debug', 'loaded helper '+helper);
								that._helpers[helper] = data.helper[i];
								callback(true);
								that._helperCall[helper] = false;
								return;
							}
							catch (err) {
								that._console.limConsole('debug', 'failed to eval() helper '+helper+': '+err.message);
							}
							break;
						}
					}
				}
				that._console.limConsole('debug', 'failed to load helper '+helper);
				callback(false);
				that._helperCall[helper] = false;
			});
			return true;
		},
		callHelper: function (helper, options) {
			if (helper === undefined || typeof options !== 'object') {
				return false;
			}
			
			if (this._helpers[helper] === undefined) {
				return false;
			}
			
			this._console.limConsole('debug', 'calling helper '+helper);
			var object = $('<div></div>');
			options.lim = this.element;
			return object[this._helpers[helper].widget](options);
		}
	});
})(jQuery);
