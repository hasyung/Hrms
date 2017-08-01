set :deploy_user, 'avatar'

set :repo_url, 'git@code.cdavatar.com:wangbo/AirlineHrmsServer.git'
set :stage, :production
set :branch, 'online_hotfixes'

#server '10.211.55.8', user: 'ubuntu', roles: %w{web app db}

server '192.1.1.148',
  user: 'avatar',
  roles: %w{web app db},
  ssh_options: {
    user: 'ubuntu', # overrides user setting above
    #keys: %w(/home/ubuntu/.ssh/id_rsa),
    keys: %w(~/.ssh/id_rsa),
    forward_agent: false,
    # auth_methods: %w(publickey password)
    auth_methods: %w(publickey)
    # password: 'please use keys'
  }

set :deploy_to, "/var/www/hrms"
set :rails_env, :production
set :enable_ssl, false

after 'deploy:publishing', 'frontend:build'
after 'deploy:publishing', 'deploy:restart'

namespace :deploy do
  task :start do
    invoke 'puma:start'
  end

  task :restart do
    invoke 'puma:restart'
  end
end
