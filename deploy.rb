#################################
## Exécute automatiquement bundle install --deployment --without development test 
################################
require "bundler/capistrano"

################
# Compte AD
################
set :user, "[=>user_name<=]"
set :application, "[=>app_name<=]"
set :domain, "ssh.alwaysdata.com"
server domain, :app, :web
role :db, domain, :primary => true

################
# Git
################
ssh_options[:forward_agent] = true
set :scm, :git
set :repository, "ssh://#{user}@ssh.alwaysdata.com/~/git/[=>git_name<=].git"
set :branch, "master"
set :deploy_via, :remote_cache
# set :git_enable_submodules, 1
set :deploy_to, "/home/#{user}/www/#{application}"
set :keep_releases, 4
default_run_options[:pty] = true
set :use_sudo, false

################
# Taches
################
after 'deploy:assets:precompile' do
  
  puts "------------- symlinks"
  
  run <<-CMD
    ln -nfs #{shared_path}/config/database.yml #{latest_release}/config/database.yml
  CMD
  %w(sitemap.xml robots.txt).each do |file|
    run <<-CMD
      ln -nfs #{shared_path}/public/#{file} #{latest_release}/public/#{file}
    CMD
  end
  
end
# Migre la base de données
after "deploy", "deploy:migrate"
# Supprime les anciennes version (:keep_releases)
after "deploy", "deploy:cleanup"


################
# Passenger
################
namespace :deploy do
  
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end