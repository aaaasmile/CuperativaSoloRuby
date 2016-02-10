#!/usr/bin/env ruby
require 'mkmf'

extension_name = 'RubyTre4AlphaBeta'

dir_config(extension_name)



libs = ['-lstdc++']
libs.each do |lib|
  $LOCAL_LIBS << "#{lib} "
end


#create_header
create_makefile(extension_name)
