namespace :nginx do
  desc "reload nginx config"
  task :reload do
    on roles(:web), :except => { :no_release => true } do
      execute "sudo /usr/local/nginx/sbin/nginx -s reload"
    end
  end
end