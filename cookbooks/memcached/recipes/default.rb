
if node.memcached[:version]
	package_fixed_version node.memcached.package_name do
		version node.memcached[:version]
	end
else
	package node.memcached.package_name
end

service "memcached" do
	supports :status => true, :restart => true
	action [ :enable, :start ]
end

template "/etc/memcached.conf" do
  source "memcached.conf.erb"
  variables node.memcached.to_hash
  mode '0644'
  owner "root"
  group "root"
  notifies :restart, "service[memcached]"
end
