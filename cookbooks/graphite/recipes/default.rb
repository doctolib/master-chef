
package "python-cairo"
package "python-django"
package "python-django-tagging"
package "python-twisted"
package "python-setuptools"

include_recipe "apache2"

apache2_enable_module "alias"
apache2_enable_module "authz_host"

apache2_enable_module "python" do
  install true
end

apache2_enable_module "wsgi" do
  install true
end

execute "install whisper" do
  command "cd /tmp && wget #{node.graphite.packages.whisper_url} -O whisper.tar.gz && tar xvzf whisper.tar.gz && cd #{File.basename(node.graphite.packages.whisper_url)[0..-8]} && python setup.py install"
  not_if "[ -f /usr/local/bin/whisper-info.py ]"
end

execute "install carbon" do
  command "cd /tmp && wget #{node.graphite.packages.carbon_url} -O carbon.tar.gz && tar xvzf carbon.tar.gz && cd #{File.basename(node.graphite.packages.carbon_url)[0..-8]} && python setup.py install"
  not_if "[ -f /opt/graphite/bin/carbon-cache.py ]"
end

execute "configure carbon" do
  command "cd /opt/graphite/conf && cp carbon.conf.example carbon.conf && cp storage-schemas.conf.example storage-schemas.conf"
  not_if "[ -f /opt/graphite/conf/carbon.conf ]"
end

execute "install graphite webapp" do
  command "cd /tmp && wget #{node.graphite.packages.graphite_web_url} -O graphite-web.tar.gz && tar xvzf graphite-web.tar.gz && cd #{File.basename(node.graphite.packages.graphite_web_url)[0..-8]} && python setup.py install"
  not_if "[ -f /opt/graphite/bin/run-graphite-devel-server.py ]"
end

directory "#{node.apache2.server_root}/wsgi" do
  owner "www-data"
  mode 0755
end

execute "create db" do
  command "cd /opt/graphite/webapp/graphite && python manage.py syncdb --noinput"
  not_if "[ -f /opt/graphite/storage/graphite.db ]"
end

execute "change storage owner" do
  command "chown -R www-data /opt/graphite/storage"
  not_if "ls -al /opt/graphite/storage | grep www-data"
end
execute "change plugins owner" do
  command "chown -R www-data /opt/graphite/lib/twisted/plugins"
  not_if "ls -al /opt/graphite/lib/twisted/plugins | grep www-data"
end

execute "configure wsgi" do
  command "cd /opt/graphite/conf && cp graphite.wsgi.example graphite.wsgi"
  not_if "[ -f /opt/graphite/conf/graphite.wsgi ]"
end

apache2_vhost "graphite:graphite" do
  options :graphite_directory => "/opt/graphite", :wsgi_socket_prefix => "#{node.apache2.server_root}/wsgi"
end

template "/etc/init.d/carbon" do
  source "carbon_init_d.erb"
  mode 0755
end

service "carbon" do
  supports :status => true
  action [ :enable, :start ]
end

template "/opt/graphite/conf/carbon.conf" do
  source "carbon.conf.erb"
  mode 0644
  notifies :restart, resources(:service => "carbon")
end

template "/opt/graphite/conf/storage-aggregation.conf" do
  source "storage-schemas.conf.erb"
  mode 0644
  variables :default_retention => node.graphite.default_retention
  notifies :restart, resources(:service => "carbon")
end

template "/opt/graphite/conf/storage-schemas.conf" do
  source "storage-schemas.conf.erb"
  mode 0644
  variables :default_retention => node.graphite.default_retention
  notifies :restart, resources(:service => "carbon")
end

execute "install bucky" do
  command "cd /tmp && wget #{node.graphite.packages.bucky_url} -O bucky.tar.gz && tar xvzf bucky.tar.gz && cd #{File.basename(node.graphite.packages.bucky_url)[0..-8]} && python setup.py install"
  not_if "[ -x /usr/local/bin/bucky ]"
end

directory "/etc/bucky" do
  mode 0755
end

basic_init_d "bucky" do
  daemon "/usr/local/bin/bucky"
  options "/etc/bucky/bucky.conf"
  file_check "/etc/bucky/bucky.conf"
  user "www-data"
end

template "/etc/bucky/bucky.conf" do
  source "bucky.conf.erb"
  mode 0644
  notifies :restart, resources(:service => "bucky")
end

template "/opt/graphite/webapp/graphite/local_settings.py" do
  source "local_settings.py.erb"
  mode 0644
  variables :timezone => node.graphite.timezone
  notifies :restart, resources(:service => "apache2")
end
