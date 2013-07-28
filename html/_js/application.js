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
					that.loadHome();
	    			return false;
				});
				
				this.loadHome();
			},
			//
			loadHome: function () {
				this.loadPage('/home.html')
				.done(function (data) {
					$('#content').html(data);
					lim.getModules();
				});
			},
			//
			loadPage: function (page) {
				return $.get(this.uri + page)
				.fail(function () {
					$('#content').empty();
					$('<div class="alert alert-error"></div>')
					.text('Something went very wrong ... please check your system logs!')
					.appendTo('#content');
				});
			},
			getJSON: function (uri) {
				return $.getJSON(this.uri + uri);
			},
			putJSON: function (uri, data) {
				return $.ajax({
					dataType: "json",
					url: this.uri + uri,
					data: data,
					type: 'PUT'
				});
			},
			postJSON: function (uri, data) {
				return $.ajax({
					dataType: "json",
					url: this.uri + uri,
					data: data,
					type: 'POST'
				});
			},
			delJSON: function (uri, data) {
				return $.ajax({
					dataType: "json",
					url: this.uri + uri,
					data: data,
					type: 'DELETE'
				});
			},
			//
			getModulesRetryInterval: 10,
			getModulesRetry: 0,
			getModules: function () {
				var that = this;
				
				if (!this.getModulesRetry) {
					$.getJSON(this.uri + '/agent/plugins')
			    	.done(function (data) {
			    		if (data.plugin && data.plugin.length) {
				    		$('#modules').empty();
				    		
				    		data.plugin.sort(function (a, b) {
				    			return (a.name > b.name) ? 1 : ((a.name > b.name) ? -1 : 0);
				    		});
				    		
				    		$.each(data.plugin, function () {
				    			var mod=this;
				    			
				    			$('#modules').append(
						    		'<div id="module-'+mod.name+'" class="span3">'+
						    		'<h2>'+mod.name+'</h2>'+
						    		'<p>'+mod.description+'</p>'+
						    		'<p>Version '+mod.version+'</p>'+
						    		'</div>'
				    				);
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
			    		else if (data.plugin.name) {
			    			var mod=data.plugin;
			    			
			    			$('#modules')
			    			.empty()
			    			.append(
					    		'<div id="module-'+mod.name+'" class="span3">'+
					    		'<h2>'+mod.name+'</h2>'+
					    		'<p>'+mod.description+'</p>'+
					    		'<p>Version '+mod.version+'</p>'+
					    		'</div>'
			    				);
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
				$.get(this.uri + '/_'+module+'/index.html')
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
	    window.prettyPrint && prettyPrint();
	});
})(window.jQuery);
