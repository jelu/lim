/**
 * lim.helper.edit
 */
(function ($, undefined) {
	$.widget('lim.limHelperEdit', {
		options: {
		},
		_create: function () {
			if (!this.options.lim || typeof this.options.lim !== 'object') {
				return $.error('required option lim not set or invalid');
			}
			this._lim = this.options.lim;
			var self = this.element;
			
			self.addClass('lim-helper-edit').dialog({
				title: 'Edit',
				height: 300,
				width: 400,
				modal: false,
				close: function (event, ui) {
					self.remove();
				}
			});
		},
		_destroy: function () {
		}
	});
})(jQuery);
