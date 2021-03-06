
if node.platform == "centos"

  add_yum_repository "http://s3tools.org/repo/RHEL_6/s3tools.repo"

  ["make", "gcc", "gcc-c++"].each do |p|
    package p
  end

end

if node.platform == "debian" || node.platform == "ubuntu"

  package "build-essential"

end

package "s3cmd"

include_recipe "java"
include_recipe "sudo"

base_user "build"

warp_install "build" do
  rbenv true
  nvm true
end

sudo_sudoers_file "build" do
  content "build ALL=(ALL) NOPASSWD:ALL"
end

template "#{get_home "build"}/upload.sh" do
  owner "build"
  mode '0755'
  source "upload.sh.erb"
  variables :bucket => "warp-repo"
end