#file: prepare_nsi_win32_noexe.rb
# Generate a nsi script file to build the setup without using rubyscript2exe

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

dep = DeployLocalVersion.new
# directory where to install the package. 
# Pay attention that we need an app suffix dir
options_filename = 'target_deploy_info.yaml'
opt = YAML::load_file( options_filename )
if opt and opt.class == Hash
  if opt[:root_arch]
    dep.root_arch = get_installerpath(opt[:root_arch])
    dep.read_sw_version(File.expand_path('../../src/cuperativa_gui.rb'))
    dep.create_nsi_installer_noexe(opt[:ruby_package], get_fullapp(opt))
    
    p0 = Pathname.new(dep.root_arch)
    puts "====> Now please create manually the setup.exe file #{p0.to_s}"
    puts "==> To create setup, compile the nsi script  #{p0.to_s}#"
    # questo dovrebbe essere il best compressor:
    # The /SOLID lzma compressor created the smallest installer (9386911 bytes).
  end
end


