include_attribute "cloudfoundry"
default[:deployment][:name] = "devbox"
default[:deployment][:user] = ENV["USER"]
default[:deployment][:group] = "vcap"
default[:deployment][:home] = File.join(node[:cloudfoundry][:home], ".deployments", deployment[:name])
default[:deployment][:config_path] = File.join(deployment[:home], "config")
default[:deployment][:info_file] = File.join(deployment[:config_path], "deployment_info.json")
default[:deployment][:domain] = "vcap.me"
default[:deployment][:log_path] = File.join(deployment[:home], "log", "$TS")
default[:deployment][:profile] = File.expand_path(File.join(ENV["HOME"], ".cloudfoundry_deployment_profile"))

default[:deployment][:is_micro] = false
#Force the local IP to something else.
#default[:cloudfoundry][:local_ip] = 127.0.0.1