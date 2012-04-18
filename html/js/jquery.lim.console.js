/**
 * lim.limConsole
 */
(function ($, undefined) {
	$.widget('lim.limConsole', {
		options: {
			lim: null,
			scrollbackLines: 2000
		},
		_create: function () {
			if (!this.options.lim || typeof this.options.lim !== 'object') {
				return $.error('required option lim not set or invalid');
			}
			this._lim = this.options.lim;
			this._scrollbackLines = 0;
			
			this.element.addClass('lim-console').dialog({
				title: 'Console',
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
		clear: function () {
			this.element.empty();
		},
		scrollback: function () {
			this._scrollbackLines++;
			while (this._scrollbackLines > this.options.scrollbackLines) {
				$('div:first', this.element).remove();
				this._scrollbackLines--;
			}
			this.element.prop('scrollTop', this.element.prop('scrollHeight') - this.element.height());
		},
		debug: function (message) {
			var date = new Date();
			$('<div/>').text(date.toTimeString() + ' DEBUG: ' + message).appendTo(this.element);
			this.scrollback();
		},
		info: function (message) {
			var date = new Date();
			$('<div/>').text(date.toTimeString() + ' INFO: ' + message).appendTo(this.element);
			this.scrollback();
		},
		warn: function (message) {
			var date = new Date();
			$('<div/>').text(date.toTimeString() + ' WARN: ' + message).appendTo(this.element);
			this.scrollback();
		},
		error: function (message) {
			var date = new Date();
			$('<div/>').text(date.toTimeString() + ' ERROR: ' + message).appendTo(this.element);
			this.scrollback();
		}
	});
})(jQuery);
