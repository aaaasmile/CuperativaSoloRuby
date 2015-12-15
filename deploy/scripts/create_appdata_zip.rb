#file: create_appdata_zip.rb
# script usato per creare lo zip da mettere nel target del .net watchdog e setup
# Dalla versione 0.9 del 2012 uso come starter un applicazione .net
# per far partire la cuperativa. Il software in ruby compreso ruby stesso, viene
# impacchettato in un file appdata.zip che può essere usato direttamente
# dallo starter e dall'installer.
# La procedura di zip è lunga e crea diversi file temporanei in questa directory
# che vengono poi cancellati


require 'rubygems'
require 'deploy_app'
require 'yaml'

#info = {:appdata_zip => { 
        #:root_arch => '<deploy dir path>',
        #:arch_name => 'appdata.zip', 
        #:copy_file => true, 
        #:zip_dir => false, 
        #:move_zip => false } }

#info={:connhandler_opt => {
  #:version_to_package => {
    #:server_name => 'http://kickers.fabbricadigitale.it',
    #:src => { :file => '/cuperativa/update_packages/ver_0_8_2_onlycode.tar.gz',
              #:size => '0,341 Mb'},
    #:fullapp => { :file => '/cuperativa/update_packages/ver_0_8_2_full.tar.gz',
               #:size => '4,8 Mb'},
    #:link_plat => 'http://rubyforge.org/frs/download.php/73230/cuperativa_082_setup.exe',
    #:descr => 'Corretto errore salvataggio settings. In caso di problemi: http://cuperativa.invido.it'
    #}
  #}
#}        
        
#puts YAML.dump(info); exit


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


