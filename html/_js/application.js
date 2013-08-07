(function ($) {
	$(function () {
		window.lim = {
			//
			uri: '',
			plugin: {},
			//
			init: function () {
				var that = this;
				
				$('.navbar li a[href="#"]').click(function () {
					$('.navbar li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadHome();
					return false;
				});
				$('.navbar li a[href="#settings"]').click(function () {
					$('.navbar li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadSettings();
					return false;
				});
				
				this.loadHome();
			},
			//
			loadHome: function () {
				var that = this;
				this.loadPage('/home.html')
				.done(function (data) {
					that.display(data);
					that.getPlugins();
				});
			},
			//
			loadSettings: function () {
				var that = this;
				
				this.loadPage('/settings.html')
				.done(function (data) {
					that.display(data);
					$('#content form').submit(function () {
						if ($('#content #host').val()) {
							that.uri =
								($('#content #protocol').val() ? $('#content #protocol').val() : 'https') + '://' +
								$('#content #host').val() +
								($('#content #port').val() ? ':' + $('#content #port').val() : '');
						}
						that.loadHome();
						return false;
					});
				});
			},
			//
			display: function (data, where) {
				if (typeof data === 'object') {
					if (data.content) {
						$(where ? where : '#content').html(data.content);
						return;
					}
				}
				else {
					$(where ? where : '#content').html(data);
					return;
				}
				$('#content').empty();
				$('<div class="alert alert-error"></div>')
				.text('Something went very wrong ... please check your system logs!')
				.appendTo('#content');
			},
			loadPage: function (page) {
				return $.ajax({
					dataType: (this.uri ? 'jsonp' : 'html'),
					url: this.uri + page,
					type: 'GET',
					jsonp: 'jsonpCallback',
					cache: true
				})
				.fail(function (jqXHR, textStatus, errorThrown) {
					$('#content').empty();
					$('<div class="alert alert-error"></div>')
					.text('Something went very wrong ... please check your system logs!')
					.appendTo('#content');
				});
			},
			getHTML: function (uri, data) {
				return $.ajax({
					dataType: (this.uri ? 'jsonp' : 'html'),
					url: this.uri + uri,
					data: data,
					type: 'GET',
					jsonp: 'jsonpCallback',
					cache: true
				});
			},
			getJSON: function (uri, data) {
				return $.ajax({
					dataType: (this.uri ? 'jsonp' : 'json'),
					url: this.uri + uri,
					data: data,
					type: 'GET',
					jsonp: 'jsonpCallback',
					cache: true
				});
			},
			putJSON: function (uri, data) {
				return $.ajax({
					dataType: (this.uri ? 'jsonp' : 'json'),
					url: this.uri + uri,
					data: data,
					type: 'PUT',
					jsonp: 'jsonpCallback',
					cache: true
				});
			},
			postJSON: function (uri, data) {
				return $.ajax({
					dataType: (this.uri ? 'jsonp' : 'json'),
					url: this.uri + uri,
					data: data,
					type: 'POST',
					jsonp: 'jsonpCallback',
					cache: true
			});
			},
			delJSON: function (uri, data) {
				return $.ajax({
					dataType: (this.uri ? 'jsonp' : 'json'),
					url: this.uri + uri,
					data: data,
					type: 'DELETE',
					jsonp: 'jsonpCallback',
					cache: true
				});
			},
			//
			getXHRError: function (jqXHR) {
				var message;
				
				try {
					message = $.parseJSON(jqXHR.responseText)['Lim::Error'].message+'!';
				}
				catch (dummy) {
				}
				if (!message) {
					message = 'Reason unknown, please check your system logs!';
				}
				
				return message;
			},
			//
			getPluginsRetryInterval: 10,
			getPluginsRetry: 0,
			getPlugins: function () {
				var that = this;
				
				if (!this.getPluginsRetry) {
					$('#plugins p').text('Unable to retrieve plugins, retrying now please wait ...');
					this.getJSON('/agent/plugins')
					.done(function (data) {
						if (data.plugin && data.plugin.length) {
							$('#plugins').empty();
							
							data.plugin.sort(function (a, b) {
								return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
							});
							
							var cnt=0, row;
							$.each(data.plugin, function () {
								var mod=this;
								
								if (!(cnt % 4)) {
									row = $('<div class="row-fluid"></div>');
									$('#plugins').append(row);
								}
								cnt++;
								row.append(
									$('<div class="span3"></div>')
									.attr('id', 'plugin-'+mod.name)
									.append(
										$('<h2></h2>').text(mod.name),
										$('<p></p>').text(mod.description),
										$('<p></p>').text('Version '+mod.version)
									));
								that.getHTML('/_'+mod.name.toLowerCase()+'/index.html')
								.done(function () {
									$('#plugin-'+mod.name+' .label-warning').remove();
									$('#plugin-'+mod.name+' .label-important').remove();
									$('#plugin-'+mod.name).append(
										'<p><a class="btn" href="#">Manage &raquo;</a></p>'
										);
									$('#plugin-'+mod.name+' a.btn').click(function () {
										that.loadPlugin(mod.name.toLowerCase());
										return false;
									});
								})
								.fail(function () {
									$('#plugin-'+mod.name+' .label-warning').remove();
									$('#plugin-'+mod.name+' .label-important').remove();
									$('#plugin-'+mod.name).append(
										'<p><span class="label label-important">Management Console not available!</span></p>'
										);
								});
								window.setTimeout(function () {
									if (!$('#plugin-'+mod.name+' .btn').length &&
										!$('#plugin-'+mod.name+' .label').length)
									{
										$('#plugin-'+mod.name).append(
											'<p><span class="label label-warning">Checking availability ...</span></p>'
											);
									}
								}, 600);
							});
							return;
						}
						else if (data.plugin && data.plugin.name) {
							var mod=data.plugin;
							
							$('#plugins')
							.empty()
							.append(
								$('<div class="row-fluid"></div>')
								.append(
									$('<div class="span3"></div>')
									.attr('id', 'plugin-'+mod.name)
									.append(
										$('<h2></h2>').text(mod.name),
										$('<p></p>').text(mod.description),
										$('<p></p>').text('Version '+mod.version)
									)));
							that.getHTML('/_'+mod.name.toLowerCase()+'/index.html')
							.done(function () {
								$('#plugin-'+mod.name+' .label-warning').remove();
								$('#plugin-'+mod.name).append(
									'<p><a class="btn" href="#">Manage &raquo;</a></p>'
									);
								$('#plugin-'+mod.name+' a.btn').click(function () {
									that.loadPlugin(mod.name.toLowerCase());
									return false;
								});
							})
							.fail(function () {
								$('#plugin-'+mod.name+' .label-warning').remove();
								$('#plugin-'+mod.name).append(
									'<p><span class="label label-important">Management Console not available!</span></p>'
									);
							});
							window.setTimeout(function () {
								if (!$('#plugin-'+mod.name+' .btn').length &&
									!$('#plugin-'+mod.name+' .label').length)
								{
									$('#plugin-'+mod.name).append(
										'<p><span class="label label-warning">Checking availability ...</span></p>'
										);
								}
							}, 600);
							return;
						}
						
						$('#plugins p').text('No plugins found, this is a bit strange ...');
					})
					.fail(function() {
						that.getPluginsRetry = that.getPluginsRetryInterval;
						window.setTimeout(function () {
							that.getPlugins();
						}, 1000);
					});
					return;
				}

				$('#plugins p').text('Unable to retrieve plugins, retry in ' + this.getPluginsRetry + ' seconds ...');
				this.getPluginsRetry--;
				window.setTimeout(function () {
					that.getPlugins();
				}, 1000);
			},
			loadPlugin: function (plugin) {
				var that = this;
				this.loadPage('/_'+plugin+'/index.html')
				.done(function (data) {
					that.display(data);
				})
				.fail(function () {
					$('#content').text('Unable to load plugin '+plugin+'!');
				});
			}
		};
		
		$.ajaxSetup({
			timeout: 30000
		});
		
		window.lim.init();
		prettyPrint();
	});
})(window.jQuery);
