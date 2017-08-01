require 'capistrano/rvm'
# config valid only for Capistrano 3.1
lock '3.4.0'

set :application, 'Sichuan_Airline_Hrms'

set :scm, :git
set :repo_url, 'git@code.cdavatar.com:wangbo/AirlineHrmsServer.git'
set :branch, 'master'

# rbenv
# set :rbenv_type, :user
# set :rbenv_ruby, '2.1.1'
# set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
# set :rbenv_map_bins, %w{rake gem bundle ruby rails}

#rbrvm
set :rvm_type, :system                # Defaults to: :auto
# set :rvm_ruby_version, '2.1.1@hrms'   # Defaults to: 'default'
set :rvm_ruby_version, 'ruby-2.1.5@rails-4.2.0'
set :rvm_custom_path, '~/.rvm'   # only needed if not detected

# how many old releases do we want to keep, not much
set :keep_releases, 3

# files we want symlinking to specific entries in shared
set :linked_files, %w{config/config.yml config/shards.yml config/database.yml config/secrets.yml config/push_server.yml}

# dirs we want symlinking to shared
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/export public/uploads}

set :log_level, :debug

set :pty,  false

# SSHKit.config.command_map[:rake] = "bundle exec rake"

namespace :deploy do
  after :finishing, 'deploy:cleanup'
  after :finishing, 'fix_job:fix'
end

# role :app, %w{ubuntu@10.211.55.8}
# role :web, %w{ubuntu@10.211.55.8}
# role :db,  %w{ubuntu@10.211.55.8}
#
# server 'ubuntu@10.211.55.8', user: 'ubuntu', roles: %w{web app db}
