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
  ver_suffix = dep.get_version_suffix
  root_version_dir = File.join(opt[:root_deploy], "cuperativa_" + ver_suffix)
  
  puts "-------- Delete current deploy dir"
  if File.directory?(root_version_dir)
    FileUtils.rm_rf(root_version_dir)
    puts "Old deploy dir removed"
  end
  puts "-------- Create deploy directory #{root_version_dir}"
  FileUtils.mkdir_p(root_version_dir)
  
  puts "------- Copy src/res stuff "
  app_dir = "app_#{ver_suffix}"
  dst_dir = File.join(root_version_dir, "src_stuff/#{app_dir}")
	dep.prepare_src_indeploy(dst_dir)
	
	puts "--------- Create a zip"
	out_zip =  File.join(root_version_dir, app_dir + ".zip")
	cmd_zip = "#{opt[:p7zip_exe]} a #{out_zip} #{dst_dir} -tzip"
	exec_mycmd(cmd_zip)
	
	puts "--------- Prepare installer files and compile it"
	installer_dir = File.join(root_version_dir, 'Installer')
	nsi_out_name = dep.create_nsi_installer_noexe(installer_dir, out_zip, opt[:ruby_package])
	nsi_cmd = "#{opt[:nsi_exe]}  #{nsi_out_name}"
  exec_mycmd(nsi_cmd)
	
end


