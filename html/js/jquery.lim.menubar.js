/**
 * lim.limMenubar
 */
(function ($, undefined) {
	$.widget('lim.limMenubar', {
		options: {
			lim: null
		},
		_create: function () {
			if (!this.options.lim || typeof this.options.lim !== 'object') {
				return $.error('required option lim not set or invalid');
			}
			this._lim = this.options.lim;
			var self = this.element;
			
			self.addClass('lim-menubar').html('<ul>'+
				'<li><a href="#">Lim</a><ul>'+
				'<li><a href="#" action="toggleConsole">Toggle Console</a></li>'+
				'<li><a href="#" action="clearConsole">Clear Console</a></li>'+
				'<li><a href="#" action="preference">Preference</a></li>'+
				'<li><a href="#" action="about">About</a></li>'+
				'</ul></li>'+
				'<li><a href="#">Master</a><ul>'+
				'<li><a href="#" action="connect">Connect</a></li>'+
				'</ul></li>'+
				'</ul>').children('ul').menubar({
					select: function (event, ui) {
						event.preventDefault();
						self.limMenubar($('a', ui.item).first().attr('action'));
					}
				});
		},
		_destroy: function () {
		},
		toggleConsole: function () {
			$(this._lim).lim('console').limConsole('toggle');
		},
		clearConsole: function () {
			$(this._lim).lim('console').limConsole('clear');
		},
		preference: function () {
			alert('preference');
		},
		about: function () {
			alert('about');
		},
		connect: function () {
			$('<div></div>').limMaster({ lim: this._lim });
		}
	});
})(jQuery);
