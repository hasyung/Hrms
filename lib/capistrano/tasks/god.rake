namespace :god do
  desc "load god monitor"
  task :load do
    on roles(:web), :except => { :no_release => true } do
      execute "sudo god -c #{deploy_to}/current/config/config.god"
    end
  end

  desc "restart by god"
  task :restart do
    on roles(:web), :except => { :no_release => true } do
      execute "god restart hrms"
    end
  end
end