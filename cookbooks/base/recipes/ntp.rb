
if node[:ntp_servers] && ! node[:disable_ntp]

  package "ntp"
  package "ntpdate"

  service "ntp" do
    supports :status => true, :reload => true, :restart => true
    action auto_compute_action
  end

  template "/etc/ntp.conf" do
    source "ntp.conf.erb"
    variables :servers => node.ntp_servers, :local_stratum => node.ntp_local_stratum, :interfaces => node[:ntp_interfaces],
              :server => node.ntp.server
    mode '0644'
    notifies :restart, "service[ntp]"
  end

end
