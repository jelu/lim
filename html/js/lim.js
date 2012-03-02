var Lim = {
	config: {
		that: null,
		data: {
			master: {}
		},
		load: function () {
			var val;
			this.that.log.debug('Loading config from cookies');
			if ((val = $.cookie('lim_master_uri'))) {
				this.data.master.uri = val;
			}
		},
		save: function () {
			this.that.log.debug('Saving config to cookies');
			$.cookie('lim_master_uri', this.data.master.uri, 365);
		}
	},
	
	gui: {
		that: null,
		object: {
			menubar: null,
			console: null,
			dialog: {
				connect: null
			}
		},
		toggleConsole: function () {
			if (this.object.console) {
				if (this.object.console.dialog('isOpen')) {
					this.object.console.dialog('close');
				}
				else {
					this.object.console.dialog('open');
				}
			}
		},
		connect: function () {
			if (this.object.dialog.connect) {
				this.object.dialog.connect.find('input#uri')
					.val(this.that.config.data.master.uri);
				this.object.dialog.connect.dialog('open');
			}
		}
	},
	
	log: {
		that: null,
		debug: function (message) {
			if (this.that.gui.object.console) {
				var date = new Date();
				$('<div/>').text(date.toTimeString() + ': ' + message).appendTo(this.that.gui.object.console);
			}
		}
	},
	
	ready: function (settings) {
		var that =
		this.config.that =
		this.gui.that =
		this.log.that =
			this;

		if (typeof settings === 'object') {
			for (var key in settings) {
				this.gui.object[key] = settings[key];
			}
		}
		
		// default config
		
		this.config.data.master.uri = '' + window.location.href;
		this.config.data.master.uri = this.config.data.master.uri.replace(/\/+$/, '');
		
		// load saved config
		
		this.config.load();

		// Initialize gui elements
		
		if (this.gui.object.menubar) {
			this.gui.object.menubar.menubar('option', 'select', function (event, ui) {
				event.preventDefault();
				var f = $('a', ui.item).first().attr('action');
				if (f && typeof that.gui[f] === 'function') {
					that.gui[f](event);
				}
			});
		}
		
		if (this.gui.object.dialog.connect) {
			this.gui.object.dialog.connect.dialog('option', 'buttons', {
				Connect: function () {
					$(this).dialog('close');
					that.connect($(this).find('input#uri').val());
				},
				Cancel: function () {
					$(this).dialog('close');
				}
			});
		}
	},
	
	connect: function (uri) {
		if (typeof uri !== 'string' /* TODO: || uri.match(/^https\:/i) */) {
			alert('URI invalid');
			return;
		}
	}
};
