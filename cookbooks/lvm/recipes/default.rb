
package "lvm2"
package "parted"

if node[:lvm][:fs_packages]
  node[:lvm][:fs_packages].each do |x|
    package x
  end
end

if node.has_key?(:partitions)
  node[:partitions].each do |name, config|
    partition name do
      fs_type config[:fs_type]
    end
  end
end

if node.has_key?(:raid)
  package "mdadm"

  node[:raid].each do |name, config|
    raid name do
      disks config[:disks]
      level config[:level]
    end
  end
end

node[:lvm].each do |group, lvm|
  next if status.match(/#{group} Cwi/)

  lvm[:physical_volumes].each do |dev|
    lvm_physical_volume dev
  end
  
  lvm_volume_group group do
    physical_volumes lvm[:physical_volumes]
  end

  lvm[:logical_volumes].each do |name, lv|
    lvm_logical_volume name do
      volume_group group
      size lv[:size]
      fs_type lv[:fs_type] if lv[:fs_type]
    end
  end
  
  if lvm.has_key?(:cache)
    include_recipe 'lvm::lvmcache'

    status = %x{lvs #{cache_volume} || true}.strip
    execute "link cache and metadata for #{lvm_cache_params[:name]}" do
      command "lvconvert -y --type cache-pool --cachemode writeback --chunksize 64k --poolmetadata #{group}/metadata #{group}/cache"
    end
  end

  execute "link cache to main volume for #{lvm[:cache][:storage]}" do
    command "lvconvert --type cache --cachepool #{group}/cache #{group}/#{lvm[:cache][:storage]}"
    not_if "lvs -o pool_lv /dev/#{group}/#{lvm[:cache][:storage]} | grep cache"
  end
  
end

node[:mount_new_path].each do |device, config|
  mount_new_path device do
    target config[:target]
    fstype config[:fstype] if config[:fstype]
    format_fs true if config[:format_fs]
    options config[:options] if config[:options]
    mkfs_options config[:mkfs_options] if config[:mkfs_options]
    owner config[:owner] if config[:owner]
    mode config[:mode] if config[:mode]
  end
end
