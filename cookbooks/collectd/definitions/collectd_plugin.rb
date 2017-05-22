
define :collectd_plugin, {
  :config => nil,
  :plugin_name => nil,
} do

  collectd_plugin_params = params

  template "#{node.collectd.config_directory}/#{collectd_plugin_params[:name]}.conf" do
    cookbook "collectd"
    source "plugin.conf.erb"
    owner "collectd"
    mode '0644'
    variables({
    	:plugin_name => collectd_plugin_params[:plugin_name] || collectd_plugin_params[:name],
    	:config => collectd_plugin_params[:config],
    })
    notifies :restart, "service[collectd]"
  end

end
