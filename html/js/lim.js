var Lim = {
	config: {
		that: null,
		data: {
			master: {}
		},
		load: function () {
			var val;
			this.that.console.debug('loading config from cookies');
			if ((val = $.cookie('lim_master_uri'))) {
				this.data.master.uri = val;
			}
		},
		save: function () {
			this.that.console.debug('saving config to cookies');
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
		},
		menu: {
			agents: null
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
			var that = this;
			this.that.gui.menu.agents
				.mouseleave(function () {
					that.that.gui.menu.agents.hide();
				})
				.find('ul').menu();
		},
		connect: function (uri) {
			var that = this;
			
			if (typeof uri !== 'string' /* TODO: || uri.match(/^https\:/i) */) {
				alert('URI invalid');
				return;
			}
			
			var o = this.that.gui.dialog.master.clone();
			o.find('#tabs').tabs();
			o.lim = {
				uri: uri,
				online: false,
				agents: false
			};
			o.find('#uri').text(uri);
			o.find('#agents').dataTable({
				bJQueryUI: true,
		        sPaginationType: 'full_numbers',
		        aoColumns: [
		            { sTitle: 'ID', sClass: 'center' },
		            { sTitle: 'Name' },
		            { sTitle: 'Host', sClass: 'center' },
		            { sTitle: 'Port', sClass: 'center' },
		            { sTitle: 'Status', sClass: 'center' }
		        ]
		    });
			o.find('#agents tbody tr').live('contextmenu', function (e) {
				that.that.gui.menu.agents.css({
			        top: (e.pageY-10)+'px',
			        left: (e.pageX-10)+'px'
			    }).show();
				return false;
			});
			o.find('#manage').dataTable({
				bJQueryUI: true,
		        sPaginationType: 'full_numbers',
		        aoColumns: [
		            { sTitle: 'Plugin' },
		            { sTitle: 'Name' },
		            { sTitle: 'Type', sClass: 'center' },
		            { sTitle: 'Actions' }
		        ]
		    });
			o.dialog({
				title: 'Master',
				height: 'auto',
				width: 600,
				modal: false,
				close: function (event, ui) {
					that.close(o);
					o.remove();
				}
			});
			this.checkStatus(o);
		},
		checkStatus: function (o) {
			var that = this;
			
			o.find('#status')
				.css('font-style', 'italic')
				.css('font-weight', 'normal')
				.text('Checking status ...');
			
			this.that.call(o.lim.uri+'/lim', null, function (data, status, xhr) {
				if (data) {
					if (typeof data === 'object' &&
						typeof data.lim === 'object' &&
						data.lim.type == 'master' &&
						data.lim.version)
					{
						o.find('#status')
						.css('font-style', 'normal')
						.css('font-weight', 'normal')
						.text('Online (version ' + data.lim.version + ')');

						if (!o.lim.online) {
							o.lim.online = true;
							that.loadAgents(o);
						}
					}
					else {
						o.find('#status')
						.css('font-style', 'normal')
						.css('font-weight', 'bold')
						.text('Error: Invalid data return or not a master');
						o.lim.online = false;
					}
				}
				else {
					o.find('#status')
						.css('font-style', 'normal')
						.css('font-weight', 'bold')
						.text('Error: ' + status);
					o.lim.online = false;
				}
				
				o.lim.statusTimer = setTimeout(function () {
					that.checkStatus(o);
				}, 10000);
			});
		},
		loadAgents: function (o) {
			var that = this;
			
			if (o.lim.online && !o.lim.agents) {
				o.lim.agents = true;
				this.that.call(o.lim.uri+'/master/agents', null, function (data, status, xhr) {
					if (typeof data === 'object' && data.agent) {
						var dt = o.find('#agents').dataTable();
						var dt2 = o.find('#manage').dataTable();
						
						for (var i = 0, len = data.agent.length; i < len; i++) {
							var agent = data.agent[i];
							dt.fnAddData([ agent.id, agent.name, agent.host, agent.port, agent.status ]);
							
							if (agent.manage) {
								for (var i2 = 0, len2 = agent.manage.length; i2 < len2; i2++) {
									var manage = agent.manage[i2];
									dt2.fnAddData([ manage.plugin, manage.name, manage.type, manage.actions.join(', ') ]);
								}
							}
						}
					}
				});
			}
		},
		close: function (o) {
			if (o.lim.statusTimer) {
				clearTimeout(o.lim.statusTimer);
			}
			o.lim = {};
		}
	},

	console: {
		that: null,
		init: function () {
			this.that.gui.console.dialog({
				height: 150,
				width: 400,
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
		var that = this;
		that.console.debug('call ' + uri);
		$.ajax({
			url: uri,
			data: data,
			dataType: 'json',
			timeout: 10000,
			success: function(data, textStatus, XHR) {
				that.console.debug('callback success ' + uri);
				callback(data, textStatus, XHR);
			},
			error: function(XHR, textStatus, errorThrown) {
				that.console.debug('callback error ' + uri);
				callback(null, (errorThrown ? errorThrown : textStatus), XHR);
			}
		});
	}
};
