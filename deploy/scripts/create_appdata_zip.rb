#file: create_appdata_zip.rb

require 'rubygems'
require 'deploy_app'
require 'yaml'


dep = DeployLocalVersion.new
options_filename = 'target_deploy_info.yaml'
opt = YAML::load_file( options_filename )
if opt and opt.class == Hash
  dst_dir = File.join(opt[:root_arch], 'src_stuff')
	dep.prepare_src_indeploy(dst_dir)
end


