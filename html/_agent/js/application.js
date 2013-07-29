(function ($) {
	$(function () {
		window.lim.module.agent = {
			init: function () {
				var that = this;
				
				$('.sidebar-nav a[href="#sysinfo"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadSystemInformation();
	    			return false;
				});
				$('.sidebar-nav a[href="#plugins"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadPlugins();
	    			return false;
				});

				this.loadSystemInformation();
			},
			//
			loadSystemInformation: function () {
				var that = this;

				window.lim.loadPage('/_agent/system_information.html')
				.done(function (data) {
					$('#agent-content').html(data);
					that.getSystemInformation();
				});
			},
			getSystemInformation: function () {
				window.lim.getJSON('/agent/version')
				.done(function (data) {
					if (data.version) {
						$('#agent-version').text(data.version);
					}
					else {
						$('#agent-version i').text('failed');
					}
				})
				.fail(function () {
					$('#agent-version i').text('failed');
				});
			},
			//
			loadPlugins: function () {
				var that = this;

				window.lim.loadPage('/_agent/plugins.html')
				.done(function (data) {
					$('#agent-content').html(data);
					that.getPlugins();
				});
			},
			getPlugins: function () {
				window.lim.getJSON('/agent/plugins')
				.done(function (data) {
		    		if (data.plugin && data.plugin.length) {
		    			$('#agent-content table tbody').empty();

			    		data.plugin.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name > b.name) ? -1 : 0);
			    		});

			    		$.each(data.plugin, function () {
			    			$('#agent-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.name),
			    					$('<td></td>').text(this.version),
			    					$('<td></td>').text(this.loaded ? 'Loaded' : 'Not loaded'),
			    					$('<td></td>').text(this.module)
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.plugin && data.plugin.name) {
		    			$('#agent-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.plugin.name),
		    					$('<td></td>').text(data.plugin.version),
		    					$('<td></td>').text(data.plugin.loaded ? 'Loaded' : 'Not loaded'),
		    					$('<td></td>').text(data.plugin.module)
	    					));
			    		return;
		    		}
		    		
		    		$('#agent-content table td i').text('No modules found, this is a bit strange ...');
				})
				.fail(function () {
					$('#agent-content table td i').text('failed');
				});
			}
		};
		window.lim.module.agent.init();
	});
})(window.jQuery);
