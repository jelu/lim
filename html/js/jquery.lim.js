/**
 * lim.lim
 */
(function ($, undefined) {
	$.widget('lim.lim', {
		options: {
			timeout: 5000
		},
		_create: function () {
			this._menubar = $('<div></div>').limMenubar({ lim: this.element }).appendTo(this.element);
			this._console = $('<div></div>').limConsole({ lim: this.element });
		},
		_destroy: function () {
			this._menubar = 
				this._console = null;
		},
		menubar: function () {
			return this._menubar;
		},
		console: function () {
			return this._console;
		},
		logDebug: function (message) {
			return this._console.limConsole('debug', message);
		},
		logInfo: function (message) {
			return this._console.limConsole('info', message);
		},
		logWarn: function (message) {
			return this._console.limConsole('warn', message);
		},
		logError: function (message) {
			return this._console.limConsole('error', message);
		},
		call: function (uri, data, callback) {
			var co = this._console;
			
			if (uri === undefined || typeof uri !== 'string') {
				co.limConsole('error', 'call: uri invalid');
				return;
			}
			if (typeof data === 'function') {
				callback = data;
				data = null;
			}
			if (typeof data !== 'null' && typeof data !== 'object') {
				co.limConsole('error', 'call: data invalid');
				return;
			}
			co.limConsole('debug', 'call ' + uri);
			if (typeof callback === 'function') {
				$.ajax({
					url: uri,
					data: data,
					dataType: 'json',
					timeout: this.options.timeout,
					success: function(data, textStatus, XHR) {
						co.limConsole('debug', 'callback success ' + uri);
						if (data === undefined) {
							data = null;
						}
						else if (typeof data !== 'object') {
							data = null;
						}
						callback(data, textStatus, XHR);
					},
					error: function(XHR, textStatus, errorThrown) {
						co.limConsole('debug', 'callback error ' + uri);
						callback(null, (errorThrown ? errorThrown : textStatus), XHR);
					}
				});
			}
			else {
				$.ajax({
					url: uri,
					data: data,
					dataType: 'json',
					timeout: this.options.timeout,
					success: function () {
						co.limConsole('debug', '(no)callback success ' + uri);
					},
					error: function () {
						co.limConsole('debug', '(no)callback error ' + uri);
					}
				});
			}
		}		
	});
})(jQuery);

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
				width: '50%',
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

/**
 * lim.limMaster
 */
(function ($, undefined) {
	$.widget('lim.limMaster', {
		options: {
			lim: null,
			uri: null
		},
		_create: function () {
			if (!this.options.lim || typeof this.options.lim !== 'object') {
				return $.error('required option lim not set or invalid');
			}
			
			this._online = false;
			this._agents = null;
			this._agentCall = false;
			this._checkStatusTimer = null;
			this._lim = this.options.lim;
			var self = this.element, that = this;

			self.html(
				'<div class="lim-master-header">'+
				'<div><div>URI:</div><div><span id="uri"></span></div></div>'+
				'<div><div>Status:</div><div><span id="status">Unkown</span></div></div>'+
				'</div>'+
				'<div id="tabs">'+
				'<ul>'+
				'<li><a href="#tabs-1">Agents</a></li>'+
				'<li><a href="#tabs-2">Manage</a></li>'+
				'</ul>'+
				'<div id="tabs-1"><table id="agents" class="display" cellpadding="0" cellspacing="0" border="0"></table></div>'+
				'<div id="tabs-2"><table id="manage" class="display" cellpadding="0" cellspacing="0" border="0"></table></div>'+
				'</div>').dialog({
					autoOpen: false,
					title: 'Master',
					dialogClass: 'lim-master',
					height: 'auto',
					width: '80%',
					modal: false,
					close: function (event, ui) {
						self.remove();
					}
				});
			self.find('#tabs').tabs();
			self.find('#agents').dataTable({
				bJQueryUI: true,
		        sPaginationType: 'full_numbers',
		        aoColumns: [
		            { sTitle: 'Id', sClass: 'center' },
		            { sTitle: 'Name' },
		            { sTitle: 'Host', sClass: 'center' },
		            { sTitle: 'Port', sClass: 'center' },
		            { sTitle: 'Status', sClass: 'center' }
		        ]
		    }).find('tbody tr').live('contextmenu', function (e) {
		    	$(that._lim).lim('logDebug', 'contextmenu');
				return false;
			});
			self.find('#manage').dataTable({
				bJQueryUI: true,
		        sPaginationType: 'full_numbers',
		        aoColumns: [
		            { sTitle: 'Agent Id', sClass: 'center' },
		            { sTitle: 'Agent Name' },
		            { sTitle: 'Plugin' },
		            { sTitle: 'Name' },
		            { sTitle: 'Type', sClass: 'center' },
		            { sTitle: 'Actions' }
		        ]
		    }).find('tbody tr').live('contextmenu', function (e) {
		    	$(that._lim).lim('logDebug', 'contextmenu');
				return false;
			});
			
			this._contextMenu = $('<div class="lim-master-context-menu"><ul>'+
				'<li><a href="#" action="toggleConsole">Toggle Console</a></li>'+
				'<li><a href="#" action="preference">Preference</a></li>'+
				'<li><a href="#" action="about">About</a></li>'+
				'</ul></div>').mouseleave(function () {
					$(this).hide();
				})
				.children('ul').menu();
			
			if (this.options.uri) {
				this.connect();
			}
			else {
				this._dialog = $('<div>'+
				'<p class="validateTips">All form fields are required.</p>'+
				'<form>'+
				'<fieldset><label for="uri">URI</label><input type="text" name="uri" id="uri" class="text ui-widget-content ui-corner-all" /></fieldset>'+
				'</form>'+
				'</div>').dialog({
					title: 'Connect to a Lim Master',
					dialogClass: 'lim-master-dialog',
					height: 300,
					width: 350,
					modal: true,
					buttons: {
						Connect: function () {
							self.limMaster('connect', $(this).find('input#uri').val());
							$(this).dialog('close');
						},
						Cancel: function () {
							self.limMaster('connect', null);
							$(this).dialog('close');
						}
					}
				});
			}
		},
		_destroy: function () {
			$(this._lim).lim('console').limConsole('debug', 'limMaster destroyed');
			if (this._checkStatusTimer) {
				clearTimeout(this._checkStatusTimer);
				this._checkStatusTimer = null;
			}
			if (this._dialog) {
				this._dialog.remove();
			}
		},
		connect: function (uri) {
			if (!uri && !this.options.uri) {
				this.element.remove();
				return;
			}
			if (uri) {
				this.options.uri = uri;
			}
			
			this.element.find('#uri').text(this.options.uri);
			this.element.dialog('open');
			this.checkStatus(true);
		},
		checkStatus: function (now) {
			var el = this.element, that = this;
			
			if (now) {
				if (this._checkStatusTimer) {
					clearTimeout(this._checkStatusTimer);
					this._checkStatusTimer = null;
				}
				
				el.find('#status')
					.css('font-style', 'italic')
					.css('font-weight', 'normal')
					.text('Checking status ...');
				
				$(this._lim).lim('call', this.options.uri+'/lim', function (data, status) {
					if (data) {
						if (typeof data === 'object' &&
							typeof data.lim === 'object' &&
							data.lim.type == 'master' &&
							data.lim.version)
						{
							el.find('#status')
							.css('font-style', 'normal')
							.css('font-weight', 'normal')
							.text('Online (version ' + data.lim.version + ')');

							that._online = true;
							el.limMaster('loadAgents');
						}
						else {
							el.find('#status')
							.css('font-style', 'normal')
							.css('font-weight', 'bold')
							.text('Error: Invalid data return or not a master');
							that._online = false;
						}
					}
					else {
						el.find('#status')
							.css('font-style', 'normal')
							.css('font-weight', 'bold')
							.text('Error: ' + status);
						that._online = false;
					}
					
					el.limMaster('checkStatus');
				});
			}
			else if (!this._checkStatusTimer) {
				this._checkStatusTimer = setTimeout(function () {
					el.limMaster('checkStatus', true);
				}, 10000);
			}
		},
		loadAgents: function (reload) {
			var el = this.element;
			
			$(this._lim).lim('console').limConsole('debug', 'loadAgents '+ this._online +' '+ this._agents +' '+ this._agentCall);
			
			if (this._online && (this._agents === null || reload) && !this._agentCall) {
				this._agentCall = true;
				
				if (reload) {
					el.find('#agents').dataTable().fnClearTable();
					el.find('#manage').dataTable().fnClearTable();
				}
				
				$(this._lim).lim('call', this.options.uri+'/master/agents', function (data, status) {
					if (typeof data === 'object' && data.agent) {
						this._agents = data.agent;
						
						var dtAgent = el.find('#agents').dataTable(),
							dtManage = el.find('#manage').dataTable();
						for (var iAgent = 0, lenAgent = data.agent.length; iAgent < lenAgent; iAgent++) {
							var agent = data.agent[iAgent];
							dtAgent.fnAddData([ agent.id, agent.name, agent.host, agent.port, agent.status ]);
							
							if (typeof agent.manage === 'object' && agent.manage.length) {
								for (var iManage = 0, lenManage = agent.manage.length; iManage < lenManage; iManage++) {
									var manage = agent.manage[iManage];
									dtManage.fnAddData([ agent.id, agent.name, manage.plugin, manage.name, manage.type, manage.actions.join(', ') ]);
								}
							}
						}
					}
					this._agentCall = false;
				});
			}
		}
	});
})(jQuery);
