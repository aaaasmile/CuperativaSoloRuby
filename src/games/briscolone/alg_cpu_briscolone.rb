# -*- coding: ISO-8859-1 -*-
# file: alg_cpu_briscolone.rb

$:.unshift File.dirname(__FILE__) + '/../..'

require 'rubygems'
require 'core/core_game_base'

##################################################### 
##################################################### AlgCpuBriscolone
#####################################################

##
# Class used to play  automatically
class AlgCpuBriscolone < AlgCpuBriscola
  attr_accessor :level_alg, :alg_player
  ##
  # Initialize algorithm of player
  # player: player that use this algorithm instance
  # coregame: core game instance used to notify game changes
  def initialize(player, coregame, reg_timeout=nil)
    super(player, coregame, reg_timeout)
  end

  def calculate_cards_on_deck
    return 40 - 5 * @players.size 
  end
  
  
end #end AlgCpuBriscola

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  require 'core_game_briscolone'
  
  #require 'ruby-debug' # funziona con 0.9.3, con la versione 0.1.0 no
  #Debugger.start
  #debugger
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  core = CoreGameBriscolone.new
  # rep = ReplayManager.new(log)
  # match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/briscola/saved_games/alg_flaw_02.yaml')
  # #p match_info
  # player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  # alg_cpu1 = AlgCpuBriscola.new(player1, core)
  
  # player2 = PlayerOnGame.new("Toro", nil, :cpu_alg, 0)
  # alg_cpu2 = AlgCpuBriscola.new(player2, core)
  # alg_cpu2.level_alg = :master
  
  # alg_coll = { "Gino B." => alg_cpu1, "Toro" => alg_cpu2 } 
  # segno_num = 0
  # rep.alg_cpu_contest = true
  # rep.replay_match(core, match_info, alg_coll, segno_num, 1)
end
