/**
 * lim.helper.view
 */
(function ($, undefined) {
	$.widget('lim.limHelperView', {
		options: {
			lim: null,
			uri: null
		},
		_create: function () {
			if (!this.options.lim || typeof this.options.lim !== 'object') {
				return $.error('required option lim not set or invalid');
			}
			this._lim = this.options.lim;
			var self = this.element;
			
			$('<pre>Loading...</pre>').appendTo(self);
			self.addClass('lim-helper-view').dialog({
				title: 'View',
				height: 300,
				width: 400,
				modal: false,
				close: function (event, ui) {
					self.remove();
				}
			});
			
			$(this._lim).lim('call', this.options.uri, function (data, status) {
				if (data && typeof data === 'object' &&
					data.helper && typeof data.helper === 'object' &&
					data.helper.name === 'view' && data.helper.data)
				{
					$('pre', self).text(data.helper.data);
				}
				else {
					$('pre', self).text('Failed to load text: '+status);
				}
			});
		},
		_destroy: function () {
		}
	});
})(jQuery);
