/**
 * lim.helper.edit
 */
(function ($, undefined) {
	$.widget('lim.limHelperEdit', {
		options: {
			lim: null,
			uri: null
		},
		_create: function () {
			if (!this.options.lim || typeof this.options.lim !== 'object') {
				return $.error('required option lim not set or invalid');
			}
			this._lim = this.options.lim;
			var self = this.element,
				that = this;
			
			self.css({ padding: 0 });
			$('<pre>Loading...</pre>').appendTo(self);
			self.dialog({
				title: 'Edit',
				height: 400,
				width: 500,
				modal: false,
				close: function (event, ui) {
					self.remove();
				},
				resize: function (event, ui) {
					if (that._cm) {
						$(that._cm.getScrollerElement()).height(self.height() - $('#menubar', self).outerHeight(true));
						that._cm.refresh();
					}
				},
			});

			$(this._lim).lim('call', this.options.uri, function (data, status) {
				if (data && typeof data === 'object' &&
					data.helper && typeof data.helper === 'object' &&
					data.helper.name === 'edit' && data.helper.data)
				{
					self.empty();
					self.dialog('option', 'buttons', {
						Save: function () {
							var data = that._cm.getValue();
							self.empty();
							that._cm = null;
							$('<pre>Saving...</pre>').appendTo(self);
							$(that._lim).lim('call', that.options.uri, data, function (data, status) {
								// TODO check error
								self.remove();
							});
						},
						Cancel: function () {
							self.remove();
						}
					});
					$('<div id="editor"></div>').appendTo(self);
					if (CodeMirror !== undefined) {
						that._cm = CodeMirror($('#editor', self).get(0), {
							value: data.helper.data,
							lineNumbers: true,
							mode: 'properties'
						});
						$(that._cm.getScrollerElement()).height(self.height() - $('#menubar', self).outerHeight(true));
						that._cm.refresh();
					}
				}
				else {
					$('pre', self).text('Failed to load text');
				}
			});
		},
		_destroy: function () {
		}
	});
})(jQuery);
