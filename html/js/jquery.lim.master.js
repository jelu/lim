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

			this._contextMenu = $('<div class="lim-master-context-menu"></div>')
				.mouseleave(function () {
					$(this).hide();
				})
				.appendTo('body');
			
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
					width: 700,
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
		        ],
		        bAutoWidth: false
		    }).find('tbody tr').live('contextmenu', function (e) {
		    	that._contextMenu
		    		.html('<ul><li><a href="#" action="refreshAgents">Refresh</a></li></ul>')
		    		.find('ul')
		    		.menu({
		    			select: function (event, ui) {
							event.preventDefault();
							that._contextMenu.hide();
							self.limMaster($('a', ui.item).first().attr('action'));
						}
		    		});
	    		that._contextMenu.css({
		    			top: (e.pageY-8)+'px',
		    			left: (e.pageX-8)+'px'
		    		}).show();
				return false;
			});
			self.find('#manage').dataTable({
				bJQueryUI: true,
		        sPaginationType: 'full_numbers',
		        aoColumns: [
		            { bVisible: false, bSearchable: false, bUseRendered: false },
		            { bVisible: false, bSearchable: false, bUseRendered: false },
		            { sTitle: 'Agent', sClass: 'center' },
		            { sTitle: 'Plugin' },
		            { sTitle: 'Name' },
		            { sTitle: 'Type', sClass: 'center' }
		        ],
		        bAutoWidth: false
		    }).find('tbody tr').live('contextmenu', function (e) {
		    	var oTable = self.find('#manage').dataTable();
		    	var aPos = oTable.fnGetPosition(this);
		    	var data = oTable.fnSettings().aoData[aPos]._aData;
		    	
		    	var agent = that._agents[data[0]];
		    	if (agent) {
		    		var manage = agent.manage[data[1]];
		    		if (manage) {
    					var html = '';
    					
    					for (var i = 0, len = manage.action.length; i < len; i++) {
    						html += '<li><a href="#" helper="'+ manage.action[i].helper +'" uri="' + that.options.uri+'/master/agent/'+encodeURIComponent(agent.id)+'/manage/'+encodeURIComponent(manage.type)+'/'+encodeURIComponent(manage.name)+'/'+encodeURIComponent(manage.plugin)+'/'+encodeURIComponent(manage.action[i].name) + '">' + manage.action[i].displayName + '</a></li>';
    					}
    					
				    	that._contextMenu
			    		.html('<ul>'+html+'</ul>')
			    		.find('ul')
			    		.menu({
			    			select: function (event, ui) {
								event.preventDefault();
								that._contextMenu.hide();
								$(that._lim).lim('callHelper', $('a', ui.item).first().attr('helper'), {
									uri: $('a', ui.item).first().attr('uri')
								});
							}
			    		});
				    	that._contextMenu.css({
			    			top: (e.pageY-8)+'px',
			    			left: (e.pageX-8)+'px'
			    		}).show();
		    		}
		    	}
		    	return false;
			});
			
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
			if (this._contextMenu) {
				this._contextMenu.remove();
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
		refreshAgents: function () {
			this.loadAgents(true);
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
				
				var that = this;
				$(this._lim).lim('call', this.options.uri+'/master/agents', function (data, status) {
					if (data && typeof data === 'object' && data.agent) {
						that._agents = data.agent;
						
						var dtAgent = el.find('#agents').dataTable(),
							dtManage = el.find('#manage').dataTable();
						for (var iAgent = 0, lenAgent = data.agent.length; iAgent < lenAgent; iAgent++) {
							var agent = data.agent[iAgent];
							dtAgent.fnAddData([ agent.id, agent.name, agent.host, agent.port, agent.status ], false);
							
							if (typeof agent.manage === 'object' && agent.manage.length) {
								for (var iManage = 0, lenManage = agent.manage.length; iManage < lenManage; iManage++) {
									var manage = agent.manage[iManage];
									dtManage.fnAddData([ iAgent, iManage, agent.name, manage.plugin, manage.name, manage.type ], false);
									
									for (var iAction = 0, lenAction = manage.action.length; iAction < lenAction; iAction++) {
										var action = manage.action[iAction];
										$(that._lim).lim('loadHelper', that.options.uri, action.helper);
									}
								}
							}
						}
						
						dtAgent.fnDraw();
						dtManage.fnDraw();
					}
					that._agentCall = false;
				});
			}
		},
		dummy: function () {
		}
	});
})(jQuery);
