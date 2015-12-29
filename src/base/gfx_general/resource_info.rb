# file: resource_info

class ResourceInfo
  def self.get_resource_path
    res_path = File.dirname(__FILE__) + "/../../../res"
    return File.expand_path(res_path)
  end

  def self.get_dir_appdata
    res = ""
    if $g_os_type == :win32_system
      path_data = ENV['LOCALAPPDATA'] ? ENV['LOCALAPPDATA'] : ENV['APPDATA'] # Note: in XP LOCALAPPDATA does not exist.
      res = File.join(path_data, "Invido_it")
      if !File.directory?(res)
        Dir.mkdir(res)
      end
      res = File.join(res, "CupUserData")
    else
      res = File.expand_path("~/.cuperativa")
      puts "We are on linux, data dir #{res}"
    end
    if !File.directory?(res)
      Dir.mkdir(res)
    end
    puts "Dir app data is: #{res}"
    return res
  end

end


if $0 == __FILE__
  p ResourceInfo.get_resource_path
  p File.exist?(ResourceInfo.get_resource_path)
end