require "capistrano/ext/multistage"
require "capistrano_colors"
require "railsless-deploy"
require "aws-sdk"
require "rubygems"

# デプロイアプリケーションの基本設定
set :application, "cap_deploy_application"
set :user, "capistrano"
set :deploy_to, "/var/www/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, true
ssh_options[:keys] = "#{ENV['HOME']}/.ssh/capistrano.pem" 
# 起動時にlocalhostにdeployするときに、fingerprintエラーになるため
ssh_options[:paranoid] = false

# git設定
default_run_options[:pty] = true
set :scm, :git
set :git_enable_submodules, true
set :copy_exclude, %w(
	.git
	.gitignore
)
set :repository,  "git@github.com:twingo-b/#{application}.git"

# autoscaling設定
set :autoscaling_group_name, fetch(:autoscaling_group_name, "autoscaling_group_name")

namespace :autoscale do
	desc "create ami"
	task :create_ami do
		run <<-CMD
			export AWS_CONFIG_FILE=#{Dir.pwd}/aws-cli/aws.config;

			ec2-metadata -i |\
			awk '{print $NF}' |\
			xargs -I% \
				aws ec2 create-image \
					--instance-id % \
					--name "#{application}-`date '+%Y%m%d%H%M%S'`" \
					--no-reboot	
		CMD
	end
	desc "create userdata"
	task :create_userdata do
		run <<-CMD
			cd #{Dir.pwd}/cloud-init-user-data;
			write-mime-multipart --output=combined-userdata.txt \
				cloud-boothook.txt:text/cloud-boothook \
				x-shellscript.txt:text/x-shellscript \
				cloud-config.txt
		CMD
	end
end

namespace :setup do
	task :fix_permissions do
		sudo "chown -R #{user}:#{user} #{deploy_to}"
	end
end
after "deploy:setup" do
	setup.fix_permissions
end
after "deploy:update" do
	deploy.cleanup
end
