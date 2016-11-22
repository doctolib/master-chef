
define :warp_install, {
  :nvm => false,
  :rbenv => false,
} do

  warp_install_params = params

  git_clone "#{get_home warp_install_params[:name]}/.warp" do
    user warp_install_params[:name]
    reference node.warp[:reference]
    repository "git://github.com/doctolib/warp.git"
  end

  if node.warp[:warp_src]

    file "#{get_home warp_install_params[:name]}/.warp_src" do
      owner warp_install_params[:name]
      content node.warp[:warp_src]
    end

  end

  install_env = get_proxy_environment("HOME" => get_home(warp_install_params[:name]))
  install_env.merge!({"git_protocol" => "http"}) if node.git.auto_use_http_for_github && (ENV['BACKUP_http_proxy'] || node[:no_external_ssh])

  if warp_install_params[:nvm]

    home = get_home warp_install_params[:name]
    execute "install nvm for user #{warp_install_params[:name]}" do
      user warp_install_params[:name]
      environment install_env
      command "#{home}/.warp/common/node/install_nvm.sh"
    end

  end

  if warp_install_params[:rbenv]

    home = get_home warp_install_params[:name]
    execute "install rbenv for user #{warp_install_params[:name]}" do
      user warp_install_params[:name]
      environment install_env
      command "#{home}/.warp/common/ruby/install_rbenv.sh"
    end

    file "#{get_home warp_install_params[:name]}/.gemrc" do
      owner warp_install_params[:name]
      content "gem: --no-ri --no-rdoc"
    end

  end

end
