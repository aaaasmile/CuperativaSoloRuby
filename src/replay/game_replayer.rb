#file: game_replayer.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../core'

require 'core_game_base'


require 'fix_autoplayer'
require 'game_core_recorder'
require 'random_manager'
require 'replay_manager'

