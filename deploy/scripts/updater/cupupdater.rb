#file: cupupdater.rb

require 'rubygems'
require 'log4r'
require 'yaml'
require 'fileutils'


include Log4r

class CupUpdater
  
  def initialize
    @log = Log4r::Logger.new("updater_log")
    out_log_name = File.join(File.dirname(__FILE__), 'myupdater.log')
    FileOutputter.new('updater_log', :filename=> out_log_name) 
    Log4r::Logger['updater_log'].add 'updater_log'
    @log.outputters << Outputter.stdout
    # command yaml from cuperativa main program
    @cupcmd_fname = 'updater_process'
    # manifest file name
    @manifest_fname = 'manifest'
    # directory where to find the manifest
    @manifest_dir = ""
    @target_app_root_path = File.expand_path(File.join( File.dirname(__FILE__), '..'))
    # application destination root subfolder
    @app_root_subfolder = 'app'
  end
  
  ##
  # Process a file to be installed in app sub directory 
  # new_file_hash: hash with :src and :dst key for source and destination 
  def proc_file_toinst(new_file_hash, root_new_files)
    new_file = new_file_hash[:src]
    dst_file = new_file_hash[:dst]
    @log.debug("Processing file: #{new_file}")
    app_dir_dst = File.join(@target_app_root_path, @app_root_subfolder)
    old_dst_file = File.join(app_dir_dst, dst_file)
    src_file =  File.join(root_new_files, new_file)
    # copy file
    FileUtils.cp_r(src_file, old_dst_file)
    @log.debug("Copy file #{src_file} to #{old_dst_file}")
  rescue
    @log.error("proc_file_toinst error #{$!}")
  end
  
  ##
  # Process a new directory to install in app subdirectory
  # new_dir: forlder into untarred package
  # root_new_files: untar root directory
  def proc_dir_toinst(new_dir, root_new_files)
    @log.debug("Processing dir: #{new_dir}")
    app_dir_dst = File.join(@target_app_root_path, @app_root_subfolder)
    old_dest_dir = File.join(app_dir_dst, new_dir)
    if File.directory?(old_dest_dir)
      # old dir backup
      time_form = Time.now.strftime("%y%m%d%H%M%S")
      old_dest_bckdir = "#{old_dest_dir}_#{time_form}"
      FileUtils.mv(old_dest_dir, old_dest_bckdir)
      @log.info("moved directory #{old_dest_dir} to backup dir #{old_dest_bckdir}")
    else
      @log.debug("#{old_dest_dir} not a directory")
    end
    # copy source directory in to destination recursively
    src_dir = File.join(root_new_files, new_dir)
    FileUtils.cp_r(src_dir ,old_dest_dir)
    @log.debug("Copy dir #{src_dir} to #{old_dest_dir}")
  end
  
  
  ##
  # When the package is extracted, we need to install new files.
  # Load and parse manifest file in order to install new package
  def execute_manifest
    # load manifest, it is on the root dir of the package
    root_new_files = @manifest_dir
    @log.debug("execute_manifest, search manifest in dir #{root_new_files}")
    mani_filename = File.join(root_new_files, @manifest_fname)
    opt = YAML::load_file( mani_filename )
    if opt
      if opt.class == Hash
        arr_newdir =  opt[:new_dir]
        version_title = opt[:version_title]
        arr_newfiles = opt[:new_file]
        @new_version_str = opt[:version_str]
        if version_title
          @log.info("Update description: #{version_title}")
        end
        if arr_newdir
          # process all directories
          arr_newdir.each{|x| proc_dir_toinst(x, root_new_files)}
        end
        if arr_newfiles
          # process all single files
          arr_newfiles.each{|x| proc_file_toinst(x, root_new_files)}
        end
      else
        @log.error("Malformed manifest")
      end
    else
      @log.error("Manifest file #{mani_filename} not found")
    end
  rescue
    @log.error("Error on execute_manifest #{$!}")
    raise("Errore nell'esecuzione del manifesto")
  end
  
  ###
  # Entry point when the updater is called
  def DoUpdate
    @log.debug "Run DoUpdate"
    begin
      cmd_yaml = File.join(File.dirname(__FILE__), @cupcmd_fname)
      cmds = YAML::load_file( cmd_yaml )
      if cmds
        if cmds.class == Hash
          if cmds[:process_manifest] == true
            @manifest_dir = cmds[:manifest_dir] 
            # process the update manifest
            execute_manifest
            # yaml processed
            
            cmds[:process_manifest] = false
            cmds[:manifest_dir] = ""
            # write it back
            File.open( cmd_yaml, 'w' ) do |out|
              YAML.dump( cmds, out )
            end
          end
        end
      end
      @log.debug "update routine terminated OK!"
    rescue
      @log.error("Error on DoUpdate: #{$!}")
  end
  
end

end
#section executed from start.exe

log = Log4r::Logger.new("updater_log")
  
updater = CupUpdater.new
updater.DoUpdate()
  