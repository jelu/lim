var Lim = {
	config: {
		that: null,
		data: {
			master: {}
		},
		load: function () {
			var val;
			this.that.console.debug('Loading config from cookies');
			if ((val = $.cookie('lim_master_uri'))) {
				this.data.master.uri = val;
			}
		},
		save: function () {
			this.that.console.debug('Saving config to cookies');
			$.cookie('lim_master_uri', this.data.master.uri, 365);
		}
	},
	
	gui: {
		workspace: null,
		menubar: null,
		console: null,
		dialog: {
			connect: null,
			master: null
		}
	},
	
	menubar: {
		that: null,
		init: function () {
			var that = this;

			this.that.gui.menubar.menubar({
				select: function (event, ui) {
					event.preventDefault();
					var f = $('a', ui.item).first().attr('action');
					if (f && typeof that[f] === 'function') {
						that[f](event);
					}
				}
			});

			this.that.gui.dialog.connect.dialog({
				autoOpen: false,
				height: 300,
				width: 350,
				modal: true,
				buttons: {
					Connect: function () {
						$(this).dialog('close');
						that.that.master.connect($(this).find('input#uri').val());
					},
					Cancel: function () {
						$(this).dialog('close');
					}
				}
			});
		},
		toggleConsole: function () {
			this.that.console.toggle();
		},
		connect: function () {
			this.that.gui.dialog.connect.find('input#uri')
				.val(this.that.config.data.master.uri);
			this.that.gui.dialog.connect.dialog('open');
		}
	},
	
	master: {
		that: null,
		init: function () {
		},
		connect: function (uri) {
			if (typeof uri !== 'string' /* TODO: || uri.match(/^https\:/i) */) {
				alert('URI invalid');
				return;
			}
			
			var o = this.that.gui.dialog.master.clone();
			o.dialog({
				title: 'Master '+uri,
				height: 500,
				width: 600,
				modal: false,
				close: function (event, ui) {
					o.remove();
				}
			});
		}
	},

	console: {
		that: null,
		init: function () {
			this.that.gui.console.dialog({
				position: [ 'left', 'bottom' ]
			});
		},
		toggle: function () {
			if (this.that.gui.console.dialog('isOpen')) {
				this.that.gui.console.dialog('close');
			}
			else {
				this.that.gui.console.dialog('open');
			}
		},
		debug: function (message) {
			var date = new Date();
			$('<div/>').text(date.toTimeString() + ': ' + message).appendTo(this.that.gui.console);
		}
	},
	
	ready: function (settings) {
		if (typeof settings === 'object') {
			for (var key in settings) {
				this.gui[key] = settings[key];
			}
		}
		
		// default config
		this.config.data.master.uri = '' + window.location.href;
		this.config.data.master.uri = this.config.data.master.uri.replace(/\/+$/, '');
		
		// Initialize elements
		for (var key in this) {
			if (typeof this[key] === 'object') {
				this[key].that = this;
				if (typeof this[key]['init'] === 'function') {
					this[key].init();
				}
			}
		}

		// load saved config
		this.config.load();
	},
	
	call: function (uri, data, callback) {
		$.ajax({
			url: uri,
			data: data,
			dataType: 'json',
			timeout: 10000,
			success: function(data, textStatus, XHR) {
				callback(data, textStatus, XHR);
			},
			error: function(XHR, textStatus, errorThrown) {
				callback(null, textStatus, XHR);
			}
		});
	}
};
