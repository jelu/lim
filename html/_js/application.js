(function ($) {
	$(function () {
		window.lim = {
			//
			uri: '',
			module: {},
			//
			init: function () {
				var that = this;
				
				$('.navbar a[href="#"]').click(function () {
					$('.navbar li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadHome();
	    			return false;
				});
				$('.navbar a[href="#settings"]').click(function () {
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
					that.getModules();
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
			display: function (data) {
				if (typeof data === 'object') {
					if (data.content) {
						$('#content').html(data.content);
						return;
					}
				}
				else {
					$('#content').html(data);
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
			getModulesRetryInterval: 10,
			getModulesRetry: 0,
			getModules: function () {
				var that = this;
				
				if (!this.getModulesRetry) {
					$('#modules p').text('Unable to retrieve modules, retrying now please wait ...');
					this.getJSON('/agent/plugins')
					.done(function (data) {
			    		if (data.plugin && data.plugin.length) {
				    		$('#modules').empty();
				    		
				    		data.plugin.sort(function (a, b) {
				    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
				    		});
				    		
				    		$.each(data.plugin, function () {
				    			var mod=this;
				    			
				    			$('#modules').append(
						    		$('<div class="span3"></div>')
						    		.attr('id', 'module-'+mod.name)
						    		.append(
						    			$('<h2></h2>').text(mod.name),
						    			$('<p></p>').text(mod.description),
						    			$('<p></p>').text('Version '+mod.version)
					    			));
				    			$.get(that.uri + '/_'+mod.name.toLowerCase()+'/index.html')
				    			.done(function () {
				    				$('#module-'+mod.name+' .label-warning').remove();
				    				$('#module-'+mod.name).append(
							    		'<p><a class="btn" href="#">Manage &raquo;</a></p>'
				    					);
						    		$('#module-'+mod.name+' a.btn').click(function () {
						    			that.loadModule(mod.name.toLowerCase());
						    			return false;
						    		});
				    			})
				    			.fail(function () {
				    				$('#module-'+mod.name+' .label-warning').remove();
				    				$('#module-'+mod.name).append(
							    		'<p><span class="label label-important">Management Console not available!</span></p>'
				    					);
				    			});
				    			window.setTimeout(function () {
				    				if (!$('#module-'+mod.name+' .btn').length &&
				    					!$('#module-'+mod.name+' .label').length)
				    				{
					    				$('#module-'+mod.name).append(
								    		'<p><span class="label label-warning">Checking availability ...</span></p>'
					    					);
				    				}
				    			}, 600);
				    		});
				    		return;
			    		}
			    		else if (data.plugin && data.plugin.name) {
			    			var mod=data.plugin;
			    			
			    			$('#modules')
			    			.empty()
			    			.append(
					    		$('<div class="span3"></div>')
					    		.attr('id', 'module-'+mod.name)
					    		.append(
					    			$('<h2></h2>').text(mod.name),
					    			$('<p></p>').text(mod.description),
					    			$('<p></p>').text('Version '+mod.version)
				    			));
			    			$.get(that.uri + '/_'+mod.name.toLowerCase()+'/index.html')
			    			.done(function () {
			    				$('#module-'+mod.name+' .label-warning').remove();
			    				$('#module-'+mod.name).append(
						    		'<p><a class="btn" href="#">Manage &raquo;</a></p>'
			    					);
					    		$('#module-'+mod.name+' a.btn').click(function () {
					    			that.loadModule(mod.name.toLowerCase());
					    			return false;
					    		});
			    			})
			    			.fail(function () {
			    				$('#module-'+mod.name+' .label-warning').remove();
			    				$('#module-'+mod.name).append(
						    		'<p><span class="label label-important">Management Console not available!</span></p>'
			    					);
			    			});
			    			window.setTimeout(function () {
			    				if (!$('#module-'+mod.name+' .btn').length &&
			    					!$('#module-'+mod.name+' .label').length)
			    				{
				    				$('#module-'+mod.name).append(
							    		'<p><span class="label label-warning">Checking availability ...</span></p>'
				    					);
			    				}
			    			}, 600);
				    		return;
			    		}
			    		
			    		$('#modules p').text('No modules found, this is a bit strange ...');
			    	})
			    	.fail(function() {
			    		that.getModulesRetry = that.getModulesRetryInterval;
			    		window.setTimeout(function () {
			    			that.getModules();
			    		}, 1000);
			    	});
					return;
				}

	    		$('#modules p').text('Unable to retrieve modules, retry in ' + this.getModulesRetry + ' seconds ...');
	    		this.getModulesRetry--;
	    		window.setTimeout(function () {
	    			that.getModules();
	    		}, 1000);
			},
			loadModule: function (module) {
				this.loadPage('/_'+module+'/index.html')
				.done(function (data) {
					$('#content').html(data);
				})
				.fail(function () {
					$('#content').text('Unable to load module '+module+'!');
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
