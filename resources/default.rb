resource_name :nginx_site

default_action :enable

property :name, kind_of: String, name_attribute: true
property :source, kind_of: String, default: nil
property :timing, kind_of: Symbol, default: :delayed
property :variables, kind_of: Hash, default: {}

action :enable do
  include_recipe 'nginx'

  template "#{node['nginx']['dir']}/sites-available/#{name}" do
    owner node['nginx']['user']
    group node['nginx']['user']
    source new_resource.source
    variables new_resource.variables
    not_if { new_resource.source.nil? }
  end

  execute "nxensite #{new_resource.name}" do
    command "#{node['nginx']['script_dir']}/nxensite #{new_resource.name}"
    notifies :reload, 'service[nginx]', new_resource.timing
    not_if do
      ::File.symlink?("#{node['nginx']['dir']}/sites-enabled/#{name}") ||
      ::File.symlink?("#{node['nginx']['dir']}/sites-enabled/000-#{name}")
    end
  end
end

action :disable do
  include_recipe 'nginx'

  execute "nxdissite #{name}" do
    command "#{node['nginx']['script_dir']}/nxdissite #{name}"
    notifies :reload, 'service[nginx]', new_resource.timing
    only_if do
      ::File.symlink?("#{node['nginx']['dir']}/sites-enabled/#{name}") ||
      ::File.symlink?("#{node['nginx']['dir']}/sites-enabled/000-#{name}")
    end
  end
end
