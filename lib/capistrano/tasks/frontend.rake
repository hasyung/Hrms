namespace :frontend do
  desc "build and copy static"
  task :build do
    on roles(:web), :except => { :no_release => true } do
      execute "cd /var/www/AirlineHrmsFrontend/ && git pull && rm -rf /var/www/AirlineHrmsFrontend/dist"
      # execute "cd /var/www/AirlineHrmsFrontend/ && bower install && cnpm install && cnpm install gulp-sass && gulp deploy"
      execute "cd /var/www/AirlineHrmsFrontend/ && bower install && npm install && gulp deploy"
      execute "cp -R /var/www/AirlineHrmsFrontend/dist/* #{deploy_to}/current/public/"
      execute "mv #{deploy_to}/current/public/index.html #{deploy_to}/current/app/views/home/index.html.erb"
      #替换script标签
      execute "sed -i \"s/^.*CONFIG_SERVER_CODE.*$/<script><%= render template: 'home\\/metadata' %> <\\/script>/g\" #{deploy_to}/current/app/views/home/index.html.erb"
    end
  end
end
