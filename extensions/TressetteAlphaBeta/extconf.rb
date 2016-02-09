#!/usr/bin/env ruby
require 'mkmf'

extension_name = 'RubyTre4AlphaBeta'

dir_config(extension_name)

create_header
create_makefile(extension_name)
