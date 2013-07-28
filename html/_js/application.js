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
				$.get(this.uri + '/home.html')
				.done(function (data) {
					$('#content').html(data);
					lim.getModules();
				})
				.fail(function () {
					$('#content').text('Something went very wrong ...');
				});
			},
			//
			loadPage: function (page) {
				return $.get(this.uri + page);
			},
			getJSON: function (uri) {
				return $.getJSON(this.uri + uri);
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
				    		
				    		$.each(data.plugin, function () {
				    			$('#modules').append(
						    		'<div class="span3">'+
						    		'<h2>'+this.name+'</h2>'+
						    		'<p>'+this.description+'</p>'+
						    		'<p>Version '+this.version+'</p>'+
						    		'<p><a class="btn" href="#" module="'+this.name.toLowerCase()+'">Manage &raquo;</a></p>'+
						    		'</div>'
				    				);
				    		});
				    		$('#modules a.btn').click(function () {
				    			that.loadModule($(this).attr('module'));
				    			return false;
				    		});
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
		
		window.lim.init();
	    window.prettyPrint && prettyPrint();
	});
})(window.jQuery);
