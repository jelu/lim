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
		}		
	});
})(jQuery);
