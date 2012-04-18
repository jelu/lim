/**
 * lim.helper.none
 */
(function ($, undefined) {
	$.widget('lim.limHelperNone', {
		options: {
		},
		_create: function () {
			this.element.remove();
		},
		_destroy: function () {
		}
	});
})(jQuery);
