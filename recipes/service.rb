# Set up the nginx service for this init style

case node['nginx']['init_style']
when 'systemd'
  template '/etc/systemd/system/nginx.service' do
    source 'nginx.service.erb'
    owner  'root'
    group  node['root_group']
    mode   '0755'
  end

  service 'nginx' do
    supports status: true, restart: true, reload: true
    action [:enable, :start]
  end
when 'runit'
  node.set['nginx']['src_binary'] = node['nginx']['binary']
  include_recipe 'runit::default'

  runit_service 'nginx'

  service 'nginx' do
    supports       :status => true, :restart => true, :reload => true
    reload_command "#{node['runit']['sv_bin']} hup #{node['runit']['service_dir']}/nginx"
  end
when 'bluepill'
  include_recipe 'bluepill::default'

  template "#{node['bluepill']['conf_dir']}/nginx.pill" do
    source 'nginx.pill.erb'
    mode   '0644'
  end

  bluepill_service 'nginx' do
    action [:enable, :load]
  end

  service 'nginx' do
    supports       :status => true, :restart => true, :reload => true
    reload_command "[[ -f #{node['nginx']['pid']} ]] && kill -HUP `cat #{node['nginx']['pid']}` || true"
    action         :nothing
  end
when 'upstart'
  # we rely on this to set up nginx.conf with daemon disable instead of doing
  # it in the upstart init script.
  node.set['nginx']['daemon_disable']  = node['nginx']['upstart']['foreground']

  template '/etc/init/nginx.conf' do
    source 'nginx-upstart.conf.erb'
    owner  'root'
    group  node['root_group']
    mode   '0644'
  end

  service 'nginx' do
    provider Chef::Provider::Service::Upstart
    supports :status => true, :restart => true, :reload => true
    action   :nothing
  end
else
  node.normal['nginx']['daemon_disable'] = false

  generate_init = true

  case node['platform']
  when 'gentoo'
    generate_template = false
  when 'debian', 'ubuntu'
    generate_template = true
    defaults_path    = '/etc/default/nginx'
  when 'freebsd'
    generate_init    = false
  else
    generate_template = true
    defaults_path    = '/etc/sysconfig/nginx'
  end

  template '/etc/init.d/nginx' do
    source 'nginx.init.erb'
    owner  'root'
    group  node['root_group']
    mode   '0755'
  end if generate_init

  if generate_template
    template defaults_path do
      source 'nginx.sysconfig.erb'
      owner  'root'
      group  node['root_group']
      mode   '0644'
    end
  end

  service 'nginx' do
    supports :status => true, :restart => true, :reload => true
    action   [:enable, :start]
  end
end
