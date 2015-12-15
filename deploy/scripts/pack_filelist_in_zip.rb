# file: pack_filelist_in_zip.rb
# script to create a zip file using a file list file
# The list file format is: each line is an entry, exclude line wich start with #

# this is the rubyzip, to install it use:
# gem install rubyzip
# execute also the install.rb in the gems installed dir
begin 
  require 'zip/zip'
rescue LoadError
  puts "gem zip/zip not found: Platform #{RUBY_PLATFORM}"
end 

##
# Class used to crate a zip archive from a file list
class PackFileList
  attr_accessor :files_topack
  
  def initialize
    @files_topack = []
  end
  
  ##
  # Import the file list, exclude commented lines
  def import_filelist( filename, root_dir )
    File.open(filename, "r").each_line do |line|
      check_input_line(line,root_dir)
    end
  end
  
  ##
  # Check the line
  def check_input_line(line,root_dir)
    unless line =~ /#/
      #valid line
      line.gsub!("\n", "")
      line.gsub!(root_dir, "")
      @files_topack.push(line)
    end
  end
  
  ##
  # Import the file list as array of filenames
  def import_filelist_array(arr, root_dir)
    pack_inparr = [] 
    # attention: dup array may only copy string pointers into a new array
    # we want duplicate the string content
    arr.each{|ele| pack_inparr << ele.dup }
    pack_inparr.each do |line|
      check_input_line(line,root_dir)
    end
  end
  
  ##
  # Create the zip file
  # param <arch_name>: generated zip file
  # param <root_dir>: root directory
  def create_archive(arch_name, root_dir)
    Zip::ZipFile.open(arch_name, Zip::ZipFile::CREATE) {
      |zipfile|
      @files_topack.each do |item|
        # add the file to the zip archive
        zipfile.get_output_stream(item){
          |zipnewentry|
          # we fill the new entry with the content of the file
          File.open(root_dir + "/" + item, "rb").each {|f| zipnewentry << f}       
        }
      end
    }
  end
end


if $0 == __FILE__
  script_dir = File.dirname(__FILE__)
  checkout_dir = "G:/Projects/eVision/tressetteCVS"
  root_dir = checkout_dir + "/" + "out"
  input_file_list = "out_file_list.txt"
  input_src_file_list = "src_file_list.txt"
  out_zip = "37_ver_0_69.zip"
  src_zip = "37_ver_0_69_src.zip"

  ####
  packer = PackFileList.new
  packer.import_filelist(input_file_list, root_dir + "/")
  #p packer.files_topack
  # out archive
  File.delete(script_dir + "/" + out_zip) if File.exist?(out_zip)
  packer.create_archive(out_zip, root_dir)
  puts "Archive created #{out_zip}"
  # source archive
  packer.files_topack.clear
  packer.import_filelist(input_src_file_list, checkout_dir + "/")
  File.delete(script_dir + "/" + src_zip) if File.exist?(src_zip)
  packer.create_archive(src_zip, checkout_dir)
  puts "Archive created #{src_zip}"
end

