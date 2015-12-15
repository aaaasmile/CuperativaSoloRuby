#file: create_appdata_zip.rb



require 'rubygems'
require 'deploy_app'
require 'yaml'


dep = DeployLocalVersion.new
options_filename = 'target_deploy_info.yaml'
opt_deploy = YAML::load_file( options_filename )
if opt_deploy and opt_deploy.class == Hash
  if opt_deploy[:appdata_zip]
    opt = opt_deploy[:appdata_zip]
    dep.filtered_extensions << ".log"
    dep.filtered_extensions << ".yml"
    dep.filtered_extensions << ".yaml"
    dep.root_arch = opt[:root_arch]
    copy_file = opt[:copy_file]
    zip_dir = opt[:zip_dir]
    move_zip = opt[:move_zip]
    arch_name = opt[:arch_name]
    
    dep.create_appdata_zip(copy_file,zip_dir,move_zip,arch_name )
    
  end
end


