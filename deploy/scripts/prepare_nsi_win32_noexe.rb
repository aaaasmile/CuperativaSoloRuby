#file: prepare_nsi_win32_noexe.rb
# Generate a nsi script file

require 'rubygems'
require 'deploy_app'
require 'yaml'

############################################### NSI ################

def get_installerpath(app_path)
  p res = File.join(app_path, "Installer")
  return res
end

def get_fullapp(opt)
  return File.join(opt[:root_arch], opt[:app_name])
end

def exec_mycmd(cmd)
  puts "Exec #{cmd}"
  IO.popen(cmd, "r") do |io|
    io.each_line do |line|
      puts line
    end
  end
end

dep = DeployLocalVersion.new
# directory where to install the package. 
# Pay attention that we need an app suffix dir
options_filename = 'target_deploy_info.yaml'
opt = YAML::load_file( options_filename )
if opt and opt.class == Hash
  if opt[:root_arch]
    dep.root_arch = get_installerpath(opt[:root_arch])
    dep.read_sw_version(File.expand_path('../../src/cuperativa_gui.rb'))
    nsi_out_name = dep.create_nsi_installer_noexe(get_fullapp(opt), opt[:ruby_package])
    
    #nsi_cmd = "#{opt[:nsi_exe]} /X\"SetCompressor /FINAL lzma\" #{nsi_out_name}"
    nsi_cmd = "#{opt[:nsi_exe]}  #{nsi_out_name}"
    exec_mycmd(nsi_cmd)
    
  end
end


