#file: build_the_setup

require 'rubygems'
require 'yaml'
require 'setup_creator'


if $0 == __FILE__
  # Create the setup.exe in one step:
  # - copy the app code into the deploy dir (cuperativa version is used implicitely)
  # - zip the app
  # - copy othe stuff like ruby package and create the nsis file
  # - copile the nsis file
  # Requisites: 7zip (version used 9.20), nsis (version used 2.48). 
  #             Ruby package: a zip with an essential ruby distribution that can execute the cuperativa application
  # Write those full paths into the target_deploy_info.yaml
  
  dep = SetupCreator.new
  options_filename = 'target_deploy_info.yaml'
  opt = YAML::load_file( options_filename )
  if opt == nil or opt.class != Hash
    puts "Target file not recognized"
    exit
  end
  dep.read_sw_version()
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
  dep.prepare_src_in_deploy(dst_dir)

  puts "--------- Create a zip"
  out_zip =  File.join(root_version_dir, app_dir + ".zip")
  cmd_zip = "#{opt[:p7zip_exe]} a #{out_zip} #{dst_dir} -tzip"
  dep.exec_mycmd(cmd_zip)

  puts "--------- Prepare installer files and compile it"
  installer_dir = File.join(root_version_dir, 'Installer')
  nsi_out_name = dep.create_nsi_installer_script(installer_dir, out_zip, opt[:ruby_package])
  nsi_cmd = "#{opt[:nsi_exe]}  #{nsi_out_name}"
  dep.exec_mycmd(nsi_cmd)
  
end