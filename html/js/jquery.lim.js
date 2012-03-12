/**
 * lim.lim
 */
(function ($, undefined) {
	$.widget('lim.lim', {
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
			this._console.limConsole('debug', 'call ' + uri);
			$.ajax({
				url: uri,
				data: data,
				dataType: 'json',
				timeout: 5000,
				success: function(data, textStatus, XHR) {
					this._console.limConsole('debug', 'callback success ' + uri);
					callback(data, textStatus, XHR);
				},
				error: function(XHR, textStatus, errorThrown) {
					this._console.limConsole('debug', 'callback error ' + uri);
					callback(null, (errorThrown ? errorThrown : textStatus), XHR);
				}
			});
		}		
	});
})(jQuery);

/**
 * lim.limMenubar
 */
(function ($, undefined) {
	$.widget('lim.limMenubar', {
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
		_create: function () {
			if (!this.options.lim || typeof this.options.lim !== 'object') {
				return $.error('required option lim not set or invalid');
			}
			this._lim = this.options.lim;
			
			this.element.addClass('lim-console').attr('title', 'Console').dialog({
				height: 150,
				width: 400,
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
		_create: function () {
			if (!this.options.lim || typeof this.options.lim !== 'object') {
				return $.error('required option lim not set or invalid');
			}
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
					width: 600,
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
		            { sTitle: 'ID', sClass: 'center' },
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
		},
		_destroy: function () {
			this._dialog.remove();
		},
		connect: function (uri) {
			if (uri === null) {
				this.element.remove();
				return;
			}
			
			this.element.find('#uri').text(uri);
			this.element.dialog('open');
		}
	});
})(jQuery);
