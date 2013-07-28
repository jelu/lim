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
				})
				.fail(function () {
					$('#content').text('Something went very wrong ...');
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
				})
				.fail(function () {
					$('#content').text('Something went very wrong ...');
				});
			},
			getPlugins: function () {
				window.lim.getJSON('/agent/plugins')
				.done(function (data) {
		    		if (data.plugin && data.plugin.length) {
		    			$('#agent-content table tbody').empty();
			    		
			    		$.each(data.plugin, function () {
			    			$('#agent-content table tbody').append(
			    				'<tr>'+
			    				'<td>'+this.name+'</td>'+
			    				'<td>'+this.version+'</td>'+
			    				'<td>'+(this.loaded ? 'Loaded' : 'Not loaded')+'</td>'+
			    				'<td>'+this.module+'</td>'+
			    				'</tr>'
			    				);
			    		});
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
