/**
 * lim.limConsole
 */
(function ($, undefined) {
	$.widget('lim.limConsole', {
		options: {
			lim: null
		},
		_create: function () {
			if (!this.options.lim || typeof this.options.lim !== 'object') {
				return $.error('required option lim not set or invalid');
			}
			this._lim = this.options.lim;
			
			this.element.addClass('lim-console').attr('title', 'Console').dialog({
				height: 150,
				width: 500,
				position: [ 'left', 'bottom' ]
			});
		},
		_destroy: function () {
		},
		toggle: function () {
			if (this.element.dialog('isOpen')) {
				this.element.dialog('close');
			}
			else {
				this.element.dialog('open');
			}
		},
		debug: function (message) {
			var date = new Date();
			$('<div/>').text(date.toTimeString() + ' DEBUG: ' + message).appendTo(this.element);
		},
		info: function (message) {
			var date = new Date();
			$('<div/>').text(date.toTimeString() + ' INFO: ' + message).appendTo(this.element);
		},
		warn: function (message) {
			var date = new Date();
			$('<div/>').text(date.toTimeString() + ' WARN: ' + message).appendTo(this.element);
		},
		error: function (message) {
			var date = new Date();
			$('<div/>').text(date.toTimeString() + ' ERROR: ' + message).appendTo(this.element);
		}
	});
})(jQuery);
