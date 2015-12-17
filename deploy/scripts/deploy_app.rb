# file: deploy_app.rb
# script used to deploy source files, zip archive and extra windows files
$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'
$:.unshift File.dirname(__FILE__) + '/../..'

require 'rubygems'
require 'erubis'
require 'fileutils'
require 'zlib'
require 'pathname'
require 'yaml'
require 'src/base/core/gameavail_hlp'
require 'filescandir'

########################################################
#######################################  DeployLocalVersion

##
# Make all steps to generate artefact for publishing a new 
# software version
class DeployLocalVersion
  
  attr_accessor :root_arch, :filtered_files, :filtered_dir, :filtered_extensions
  
  def initialize
    @fscd = FileScanDir.new
    @dest_app_root = "."
    # software application version
    @ver_sw = [0,0,0]
    # script where to find a sw version
    @scrpt_with_sw_version = '../src/cuperativa_gui.rb'
    # directories  excluded during packaging
    @filtered_dir = ["CVS", ".svn", "b5","invido","doc", "server", "deploy", "tmp"]
    # files  excluded during packaging
    @filtered_files = ["carte.tar.gz", "app_options.yaml", "curr_saved_game.yaml", "game_terminated_last.yaml"]
    @filtered_extensions = []
    #deployment package target
    @deploy_pack_out = "../platform"
    # root archive
    @root_arch = File.join( File.dirname(__FILE__), 'tmp_deploy/app')
    # manifest file name
    @manifest_fname = 'manifest'
  end
  
  ##
  # Provides the exe filename of the platform. This name is stored in the script
  # make_cup_exe 
  def read_exe_name_of_platform
    script_fname = File.join( File.dirname(__FILE__), '../platform/make_cup_exe.rb')
    File.open(script_fname, "r").each_line do |line|
      #p line
      # search line with exe_out = 'cup_platform.exe'
      if line =~ /exe_out(.*)/
        arr_tmp =  $1.split("=")
        arr_tmp.each do |tmp_str|
          if tmp_str =~ /(.*).exe/
            # we expect here something like "cip_platform.exe"
            target_name = tmp_str.strip.gsub("'", "")
            log "recognized exe name: #{target_name}"
            return target_name
          end
        end
        log("Error on parsing exe_out")
        return ""
      end
    end
    log("Error exe_out not found")
  end
  
  ##
  # Provides as array of string the list of app files
  # This list is also put inside the nsi script
  # name_to_cut: path to be cut in the result beacuse we need a releative filename list
  def list_of_app_deployed_files(root_dir, name_to_cut)
    @fscd = FileScanDir.new
    @fscd.add_dir_filter( @filtered_dir )
    @fscd.scan_dir(root_dir)
    res_names = []
    #each file need to be specified like without keyword File:
    #   File "app\\src\\cuperativa_gui.rb"
    old_rel_dir_path = nil
    @fscd.result_list.each do |file_src|
      name =  file_src.gsub(name_to_cut, "")
      rel_dir_path = File.dirname(name) # note: not work with \ intead of / on the path
      
      name.gsub!('/', "\\")
      puts str_path_file = "#{name}"
      if rel_dir_path != old_rel_dir_path
        puts "Path changed to: #{rel_dir_path}"
        adptrel_dir_path = "\\#{rel_dir_path.gsub('/', "\\")}" # need: \app\src\network
        res_names << { :filename => str_path_file, :out_path => adptrel_dir_path, 
                       :delete_path => old_rel_dir_path  }
        old_rel_dir_path = rel_dir_path
      else
        res_names << { :filename => str_path_file }
      end
    end
    p res_names.last[:delete_path] = old_rel_dir_path
    return res_names
  end
  
  ##
  # Create a nsi file to install deck
  def create_nsideck_script(opt)
    license_name = "License.txt"
    
    @deck_name =opt[:custom_deck_name]
    p0 = Pathname.new(@root_arch)
    target_dir = p0.to_s
    list_app_files = list_of_app_deployed_files(target_dir, target_dir + '/')
    file_to_be_installed = []
    strout_nsi_name = "#{@deck_name}.nsi"
    list_app_files.each do |item|
      if item[:filename] =~ /\.nsi/
        p "***** ignore nsi file #{item}"
      else
        file_to_be_installed << item
      end
    end
    
    # copy license file
    file_src = File.join(File.dirname(__FILE__), "win32_installer/#{license_name}")
    dest_full = File.join(target_dir, license_name)
    FileUtils.cp(file_src, dest_full)
    
    
    # generate nsi using template
    template_name = 'win32_installer/setup_customdeck.nsi_tm'
    nsi_out_name = File.join(target_dir, strout_nsi_name)
    
    aString = ""
    # use template and eruby
    File.open(template_name, "r") do |file|
      input = file.read
      eruby_object= Erubis::Eruby.new(input)
      aString = eruby_object.result(binding)
      File.open(nsi_out_name, "w"){|f| f << aString } 
    end
    puts "File created: #{nsi_out_name}"
  end
  
  ##
  # Create the nsi file for using the directory where also ruby is included
  def create_nsi_installer_noexe(app_data_fullpath, rubypackage_fullpath)
    p0 = Pathname.new(@root_arch)
    target_dir = p0.to_s
    FileUtils.mkdir_p(target_dir) unless File.directory?(target_dir)
    
    # copy some extra file
    license_name = "License.txt"
    manual_filename = "cuperativa.chm"
    readme_filename = "Readme.txt"
    ruby_dirname = 'Ruby'
    app_dirname = 'App'
    # copy license file
    log "Copy license"
    file_src = File.join(File.dirname(__FILE__), "../artifacts/#{license_name}")
    dest_full = File.join(target_dir, license_name)
    FileUtils.cp(file_src, dest_full)
    # copy manual file
    log "Copy manual"
    file_src = File.join(File.dirname(__FILE__), "../../res/help/#{manual_filename}")
    dest_full = File.join(target_dir, manual_filename)
    FileUtils.cp(file_src, dest_full)
    # copy readme file
    log "Copy Readme"
    file_src = File.join(File.dirname(__FILE__), "../artifacts/#{readme_filename}")
    dest_full = File.join(target_dir, readme_filename)
    FileUtils.cp(file_src, dest_full)
    # copy starter files
    log "Copy starter"
    scanner = FileScanDir.new
    scanner.is_silent = true
    scanner.scan_dir(File.join(File.dirname(__FILE__), "../artifacts/starter"))
    scanner.result_list.each do |file_src|
      tmp = File.split(file_src)
      base_name = tmp[1]
      ext = File.extname(base_name)
      if(ext == ".dll" || ext == ".exe")
        log "Copy starter part: #{base_name}"
      	dest_full = File.join(target_dir, base_name)
      	FileUtils.cp(file_src, dest_full)
      end
    end
    #copy ruby
    @ruby_package = copy_package(File.join(target_dir, ruby_dirname), rubypackage_fullpath)
    #copy app
    copy_package(File.join(target_dir, app_dirname), app_data_fullpath)
     
    # list of all files
    list_app_files = list_of_app_deployed_files(target_dir, target_dir + '/')
    # merge with app file list
    file_to_be_installed = list_app_files
    
    # get info about installed games
    #str_giochi_avail = "Briscola in 2, Mariazza"
    # parse yaml file with game information
    map_game_info = InfoAvilGames.info_supported_games(nil)
    arr_giochi_avail = []
    map_game_info.each_value do |game_info|
      if game_info[:enabled] == true
        p game_info[:name]
        arr_giochi_avail << game_info[:name]
      end
    end
    str_giochi_avail = arr_giochi_avail.join(", ")
    
    # generate nsi using template
    template_name = 'nsi_install/setup_muster.nsi_tm'
    nsi_out_name = File.join(target_dir, 'cuperativa_gen.nsi')
    
    aString = ""
    # use template and eruby
    File.open(template_name, "r") do |file|
      input = file.read
      eruby_object= Erubis::Eruby.new(input)
      aString = eruby_object.result(binding)
      File.open(nsi_out_name, "w"){|f| f << aString } 
    end
    return nsi_out_name
  end
  
  def copy_package(out_dir, full_sr)
    FileUtils.mkdir_p(out_dir) unless File.directory?(out_dir)
    tmp = File.split(full_sr)
    dest_full = File.join(out_dir, tmp[1])
    FileUtils.cp(full_sr, dest_full)
    log "Copy #{dest_full}"
    return tmp[1]
  end
  
  
  ##
  # Parse a script filename and search version number to fill @ver_sw
  def read_sw_version(script_fname)
    File.open(script_fname, "r").each_line do |line|
      #p line
      # search line with VER_PRG_STR it is something like:
      # VER_PRG_STR = \"Ver 0.5.4 14042008\"
      if line =~ /VER_PRG_STR(.*)/
        arr_tmp =  $1.split("\"")
        arr_tmp.each do |tmp_str|
          if tmp_str =~ /Ver(.*)/
            # we expect here something like " 0.5.4 14042008"
            p ver_str_arr = $1.strip.split(" ")
            @ver_sw =  ver_str_arr[0].split(".")
            log "recognized version: #{@ver_sw[0]}-#{@ver_sw[1]}-#{@ver_sw[2]}"
            return 
          end
        end
        log("Error on parsing VER_PRG_STR")
        return 
      end
    end
    log("Error VER_PRG_STR not found")
  end
  
  ##
  # Create manifest
  # options: manifest options
  def create_manifest(options_custom)
    opt = {}
    if options_custom[:new_dir]
      opt[:new_dir] = options_custom[:new_dir]
    end
    opt[:new_file] = [{:src => '/Readme.txt', :dst => '/Readme.txt'}]
    opt[:version_title] = "patch to version #{@ver_sw[0]}.#{@ver_sw[1]}.#{@ver_sw[2]}"
    opt[:version_str] = "#{@ver_sw[0]}.#{@ver_sw[1]}.#{@ver_sw[2]}" 
    
    mni_fullname = File.join(@root_arch, @manifest_fname)
    File.open(mni_fullname, 'w'){|out| out << YAML.dump( opt) }
  end
  
  ##
  # Copy readme file
  def copy_readme_file
    readme_file = 'Readme.txt'
    file_src  = File.join(File.dirname(__FILE__), "../doc/#{readme_file}")
    dest_full = File.join(@root_arch, readme_file )
    FileUtils.cp(file_src, dest_full)
  end
  
  ##
  # Create the tarball of the update package
  def create_tarball_update_pack
    root_archdir = @root_arch
    p0 = Pathname.new(@root_arch)
    arch_full_name = File.join(p0.parent.to_s, "#{File.basename(@root_arch)}_#{@ver_sw[0]}_#{@ver_sw[1]}_#{@ver_sw[2]}.tar.gz")
    # need a list of all files
    @fscd = FileScanDir.new
    @fscd.scan_dir(@root_arch)
    file_list_arr  = []
    # pick relative filename
    @fscd.result_list.each do |file_src|
      fname_rel = file_src.gsub(@root_arch,"") 
      fname_rel.slice!(0) if fname_rel[0] == "/"[0]
      file_list_arr << fname_rel
    end
    make_tarball(root_archdir, arch_full_name, file_list_arr)
  end
  
  ##
  # Create a directory with only a source to be packed into a tgz
  def create_src_update_pack(option_custom)
    #opt = {}
    option_custom[:new_dir] = ['src']
    read_sw_version(File.expand_path(@scrpt_with_sw_version))
    create_source_pkg
    create_manifest(option_custom)
    copy_readme_file
    create_tarball_update_pack
  end
  
  ##
  # Create a directory with resource and source to be packed into a tgz
  def create_full_update_pack(option_custom)
    read_sw_version(File.expand_path(@scrpt_with_sw_version))
    create_source_pkg
    create_resource_pkg
    create_manifest(option_custom)
    copy_readme_file
    create_tarball_update_pack
  end
  
  ##
  # Create all source and resource packages for deployment
  # In the root_arch will be copied the /app subfolder with
  # sources and resources.
  def create_all_current_packages
    read_sw_version(File.expand_path(@scrpt_with_sw_version))
    create_resource_pkg
    create_source_pkg
  end
  
  def copy_app_subdir(sub_dir, target_dir)
    fscd = FileScanDir.new
    fscd.add_extension_filter([".yaml", ".yml", ".log"])
    fscd.is_silent = true
    start_dir = File.join( File.dirname(__FILE__), "../../#{sub_dir}")
    start_dir = File.expand_path(start_dir)
    target_res = File.join( target_dir, sub_dir)
    fscd.scan_dir(start_dir)
    copy_appl_to_dest(fscd.result_list, start_dir, target_res)
    
  end
  
  def prepare_src_indeploy(target_dir)
    FileUtils.rm_rf(target_dir)
    FileUtils.mkdir_p(target_dir) unless File.directory?(target_dir)
    copy_app_subdir("res", target_dir)
    copy_app_subdir("src", target_dir)
  end
  
  def create_appdata_zip(copy_file,zip_dir,move_zip,arch_name )
    log "Create app data zip, used in c# cup starter"
    
    if copy_file == true
      log "Copy stuff"
      if File.directory?(@root_arch) and zip_dir
        log("Delete dir #{@root_arch}")
        FileUtils.rm_r(@root_arch) 
      end
      create_updater_pkg
      create_resource_pkg
      create_source_pkg
    end
    if zip_dir == true
      log("Zip stuff")
      dir_to_zip = File.expand_path(File.join( @root_arch, '..'))
      full_out_zip_path = arch_name
      log("Zip directory #{dir_to_zip} in file #{arch_name}")
      fscd = FileScanDir.new
      log("calculate files to zip")
      fscd.is_silent = true
      fscd.scan_dir(dir_to_zip)
      packer = PackFileList.new
      log("Zip it")
      packer.import_filelist_array(fscd.result_list, dir_to_zip + "/")
      File.delete(full_out_zip_path) if File.exist?(full_out_zip_path)
    
      packer.create_archive(arch_name, dir_to_zip)
    end
    if move_zip
      arch_dest = File.expand_path(File.join(File.dirname(__FILE__), 'SplashStarter/SplashStarter'))
      arch_dest = File.join(arch_dest, arch_name)
      log("Move archive #{arch_name} to #{arch_dest}")
      FileUtils.mv(arch_name, arch_dest)
    end
  end
  
  ##
  # Copy rest files in order to prepare execution of rubyscript2exe
  def finishing_deploy
    p0 = Pathname.new(@root_arch)
    target_dir = p0.parent.to_s
    deploy_platform_dir = File.join(target_dir, 'cup_platform')
    FileUtils.mkdir_p(deploy_platform_dir) unless File.directory?(deploy_platform_dir)
    
    start_dir = File.join(File.dirname(__FILE__), '../platform/cup_platform')
    @fscd = FileScanDir.new
    @fscd.add_dir_filter( @filtered_dir )
    @fscd.scan_dir(start_dir)
    # copy only allowed files of cup_platform
    @fscd.result_list.each do |file_src|
      dest_full = File.join(deploy_platform_dir, File.basename(file_src))
      FileUtils.cp(file_src, dest_full)
      puts "Copy #{file_src} to #{dest_full}"
    end
    # now copy script for running rubyscript2exe
    script_fname = 'make_cup_exe.rb'
    file_src = File.join(File.dirname(__FILE__), "../platform/#{script_fname}")
    dest_full = File.join(target_dir, script_fname)
    FileUtils.cp(file_src, dest_full)
    puts "Copy #{file_src} to #{dest_full}"
  end
  
  ##
  # Create resource package
  def create_resource_pkg
    start_dir = File.join( File.dirname(__FILE__), "../../res")
    start_dir = File.expand_path(start_dir)
    options = {}
    options[:filter_dir] =  @filtered_dir
    options[:filter_extensions] = @filtered_extensions
    options[:filter_files] = @filtered_files
    options[:app_name] = "client_res#{@ver_sw[0]}-#{@ver_sw[1]}-#{@ver_sw[2]}.tgz"
    options[:pub_app_name] = File.join( File.dirname(__FILE__), @deploy_pack_out)
    options[:deploy_dir] = File.join( @root_arch, 'res')
    options[:root_archdir] = @root_arch
    options[:start_dir] = start_dir
    options[:make_tar] = false
    
    create_items_archive(options)
  end
  
  ##
  # Create a package of the updater directory
  def create_updater_pkg
    start_dir = File.join( File.dirname(__FILE__), "updater")
    start_dir = File.expand_path(start_dir)
    options = {}
    options[:filter_dir] =  @filtered_dir
    options[:filter_files] = @filtered_files
    options[:filter_extensions] = @filtered_extensions
    options[:app_name] = "client_upd#{@ver_sw[0]}-#{@ver_sw[1]}-#{@ver_sw[2]}.tgz"
    options[:pub_app_name] = File.join( File.dirname(__FILE__), @deploy_pack_out)
    options[:deploy_dir] = File.expand_path(File.join( @root_arch, '../updater'))
    options[:root_archdir] = @root_arch 
    options[:start_dir] = start_dir
    options[:make_tar] = false
    
    create_items_archive(options)
  end
  
  ##
  # Create source package
  def create_source_pkg
    start_dir = File.join( File.dirname(__FILE__), "../../src")
    start_dir = File.expand_path(start_dir)
    options = {}
    options[:filter_dir] =  @filtered_dir
    options[:filter_files] = @filtered_files
    options[:filter_extensions] = @filtered_extensions
    options[:app_name] = "client_src#{@ver_sw[0]}-#{@ver_sw[1]}-#{@ver_sw[2]}.tgz"
    options[:pub_app_name] = File.join( File.dirname(__FILE__), @deploy_pack_out)
    options[:deploy_dir] = File.join( @root_arch, 'src')
    options[:root_archdir] = @root_arch 
    options[:start_dir] = start_dir
    options[:make_tar] = false
    
    create_items_archive(options)
  end
  
  ##
  # Create an archive where the content could be source files or resource items 
  # First create a temp directory where to copy sources, than create a tgz archive
  # Than copy result in a destination directory
  def create_items_archive(options)
    @fscd = FileScanDir.new
    start_directory = options[:start_dir]
    log "Create an archive on root #{start_directory}"
    filter_dir = options[:filter_dir]
    filter_files = options[:filter_files]
    filter_extension = options[:filter_extensions]
    deploy_dir = options[:deploy_dir]
    start_dir = options[:start_dir]
    root_archdir = options[:root_archdir]
    app_name = options[:app_name]
    make_tar_flag = options[:make_tar]
    arch_full_name = File.expand_path(options[:pub_app_name])
    arch_full_name = File.join(arch_full_name, app_name)
    
    #delte old/current deploy dir
    FileUtils.rm_rf(deploy_dir)
    
    # prepare a source file list
    @fscd.add_dir_filter( filter_dir )
    @fscd.add_file_filter(filter_files)
    @fscd.add_extension_filter(filter_extension)
    @fscd.scan_dir(start_dir)
    
    # we can also use the function copy_appl_to_dest, but I get it when I was ready 
    num_of_files  = 0
    num_of_src = 0
    file_list_arr  = []
    prefix = deploy_dir.gsub(root_archdir, "")
    @fscd.result_list.each do |file_src|
      #p file_src
      dest_rel = file_src.gsub(start_directory,"")  
      # collect relative filenames to be used on tar archive
      fname_rel = File.join(prefix, dest_rel)
      fname_rel.slice!(0) if fname_rel[0] == "/"[0]
      #p fname_rel
      file_list_arr << fname_rel
      dest_full = File.join(deploy_dir, dest_rel)
      dir_dest = File.dirname(dest_full)
      FileUtils.mkdir_p(dir_dest) unless File.directory?(dir_dest)
      # copy src into destination
      FileUtils.cp(file_src, dest_full)
      log("Copy src: #{file_src} into #{dest_full}")
      num_of_src += 1 if File.extname(file_src) == ".rb"
      num_of_files += 1 
    end
    log "Num of files copied #{num_of_files}, number of ruby source files #{num_of_src}"
    # Now create the archive using the deploy directory
    if make_tar_flag
      make_tarball(root_archdir, arch_full_name, file_list_arr)
    end
  end
  
  ##
  # Make a tar archive and compress it into a zip (.tgz)
  # root_dir: root dir to be packed
  # destination: destination archive
  # file_list_arr: array of files name relative to the root dir
  def make_tarball(root_dir, destination, file_list_arr)
    log "Change directory to #{root_dir}"
    log "Creating archive: #{destination}"
    old_dir = Dir.pwd
    Dir.chdir(root_dir)
    Zlib::GzipWriter.open(destination) do |gzip|
      out = Archive::Tar::Minitar::Output.new(gzip)
      file_list_arr.each do |file|
        log "Packing #{file}"
        Archive::Tar::Minitar.pack_file(file, out)
      end
      out.close
    end
    log "File created #{destination}"
    # restore previous path 
    Dir.chdir(old_dir)
  end

  def log(str)
    puts str
  end
  
  ##
  # Calculate the root directory of deployment
  def calc_pub_root_path(options)
    version =  options[:version]
    deploy_dir = options[:deploy_dir]
    pub_root_dir = version.downcase.gsub(/ |\./, "_")
    pub_root_path = File.join(deploy_dir, pub_root_dir)
    pub_root_path = File.expand_path(pub_root_path)
    return pub_root_path
  end
  
  ##
  # Deploy new version on win32
  def deploy_version_onwin32(options)
    filter_dir = options[:filter_dir]
    filter_files = options[:filter_files]
    start_directory = options[:start_dir]
    version =  options[:version]
    deploy_dir = options[:deploy_dir]
    start_dir = options[:start_dir]
    app_name = options[:app_name]
    
    # prepare a source file list
    @fscd.add_dir_filter( filter_dir )
    @fscd.add_file_filter(filter_files)
    @fscd.scan_dir(start_dir)
    
    
    # create deploy path
    pub_root_dir = version.downcase.gsub(/ |\./, "_")
    pub_root_path = File.join(deploy_dir, pub_root_dir)
    pub_root_path = File.expand_path(pub_root_path) 
    #create_pub_dir(pub_root_path) # si puo' usare FileUtils.mkdir_p
    FileUtils.mkdir_p(pub_root_path)
    
    # create subfolder for application
    #create_app_subfolder(pub_root_path)
    pub_root_path_src = File.join( pub_root_path, "src")
    dest_app_root = File.join( pub_root_path_src, app_name)
    FileUtils.mkdir_p(dest_app_root)
    
    # create a zip archive with source
    tmp = version.split(" ")
    num_ver = tmp[1].gsub(".", "_")
    # calculate archive name
    zip_arch_name = "#{app_name}_#{num_ver}_src.zip"
    zip_arch_name_fullpath = File.join(pub_root_path, zip_arch_name)
    # create package
    create_zip_src(@fscd.result_list, start_dir, zip_arch_name_fullpath) 
    #p @fscd.result_list
       
    # copy all source file in application folder
    #FileUtils.cp_r @fscd.result_list, @dest_app_root
    copy_appl_to_dest(@fscd.result_list, start_dir, dest_app_root)
    
    # for deployment on win32 we need extra files
    copy_extrafiles_forwin32(pub_root_path_src, dest_app_root )
  end
  
  ##
  # Create a zip archive using PackFileList, a zipper that works only on windows
  def create_zip_src(input_file_list, root_dir, full_out_zip_path)
    packer = PackFileList.new
    packer.import_filelist_array(input_file_list, root_dir + "/")
    #p packer.files_topack
    # out archive
    out_zip = File.basename(full_out_zip_path)
    File.delete(full_out_zip_path) if File.exist?(full_out_zip_path)
    packer.create_archive(out_zip, root_dir)
    log "Archive created #{out_zip}"
    # move archive in to publ directory
    FileUtils.mv(out_zip, full_out_zip_path)
  end
    
  ##
  # Copy src file list in to destination directory
  # file_list: file list with complete path
  # start_dir: directory root on source
  # dst_dir: full path of destination directory
  def copy_appl_to_dest(file_list, start_dir, dst_dir)
    file_list.each do |src_file|
      # name without start_dir
      p rel_file_name = src_file.gsub(start_dir, "")
      log "Copy #{rel_file_name}"
      # calculate destination name
      p dest_name_full = File.join(dst_dir, rel_file_name)
      p dir_dest = File.dirname(dest_name_full)
      # make sure that a directory destination exist because cp don't create a new dir
      FileUtils.mkdir_p(dir_dest) unless File.directory?(dir_dest)
      FileUtils.cp(src_file, dest_name_full)
    end
  end
  
  ##
  # mkdir_p meglio
  # Into the publisher directory we need some sub folders
  # pub_root_path: root publisher path
  def create_app_subfolder(pub_root_path)
    src_dir = File.join(pub_root_path, "src")
    Dir.mkdir(src_dir) unless File.directory?(src_dir)
    # now cuperativa folder
    app_folder = File.join(src_dir, "cuperativa")
    Dir.mkdir(app_folder) unless File.directory?(app_folder)
    @dest_app_root = app_folder
  end
  
 
  
end #end DeployLocalVersion


if $0 == __FILE__
  puts "CAUTION: Use this section only at development stage"
  puts "Do you need to deploy a new version? then use the script prepare_app_totmp.rb"
  #dep = DeployLocalVersion.new
  # use sw version defined into cuperativa gui
  #dep.read_sw_version(File.expand_path('../src/cuperativa_gui.rb'))
  # create a package with resource and source files 
  # CAUTION: I am not using external options, look on it
  #dep.create_resource_pkg
  #dep.create_source_pkg
  #dep.create_all_current_packages
  #dep.finishing_deploy
  #dep.read_exe_name_of_platform
  #dep.create_nsi_installer
  
  #start_dir = File.join( File.dirname(__FILE__), "../src")
  #start_dir = File.expand_path(start_dir)
  #options = {}
  #options[:filter_dir] = ["CVS", ".svn", "b5","invido","doc", "server", "deploy", "tmp"] 
  #options[:filter_files] = ["app_options.yaml", "curr_saved_game.yaml", "game_terminated_last.yaml"]
  #options[:deploy_dir] = "../../rubyforge/published"
  #options[:version] = "Ver 0.5.0 06032008"
  #options[:start_dir] = start_dir
  #options[:app_name] = "cuperativa"
  #options[:svn_rubyforge_co] = "/home/igor/Projects/rubyforge/src_svn_rubyforge/briscola"
  
  # create zips for application deployment
  # usa questa funzione solo sotto windows. Questo e' il primo passo per creare cuperativa.exe
  #dep.deploy_version_onwin32(options)
  # usa copy installer per copiare l'exe generato e tutti i files necessari per l'installer
  #dep.copy_installer_forwin32(options)
  
  # copy source files into rubyforge checkout dir 
  #dep.deploy_for_svn_rubyforge(options) 
  
  #fscd.scan_dir(start_dir)
  #fscd.write_filelist(out_file_list)
  
end

