namespace :fix_job do
  desc "init and fix"
  task :fix do
    on roles(:web), :except => { :no_release => true } do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "init:permission"
        end
      end
    end
  end
end