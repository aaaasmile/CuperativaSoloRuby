#file: create_appdata_zip.rb

require 'rubygems'
require 'deploy_app'
require 'yaml'

def exec_mycmd(cmd)
  puts "Exec #{cmd}"
  IO.popen(cmd, "r") do |io|
    io.each_line do |line|
      puts line
    end
  end
end


dep = DeployLocalVersion.new
options_filename = 'target_deploy_info.yaml'
opt = YAML::load_file( options_filename )
if opt and opt.class == Hash
  dep.read_sw_version(File.expand_path('../../src/cuperativa_gui.rb'))
  app_dir = "app_" + dep.get_version_suffix
  dst_dir = File.join(opt[:root_arch], "src_stuff/#{app_dir}")
  puts "Copy src/res stuff to Target #{dst_dir}"
   
	dep.prepare_src_indeploy(dst_dir)
	
	puts "Create a zip"
	out_zip =  File.join(opt[:root_arch], app_dir + ".zip")
	cmd_zip = "#{opt[:p7zip_exe]} a #{out_zip} #{dst_dir} -tzip"
	exec_mycmd(cmd_zip)
end


