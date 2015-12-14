# file: alg_cpu_tressettein4.rb
$:.unshift File.dirname(__FILE__) + '/..'


require 'rubygems'
require 'tressette/alg_cpu_tressette'

##
# Class used to play  automatically
class AlgCpuTressettein4 < AlgCpuTressette
  attr_accessor :level_alg, :alg_player
  
  def initialize(player, coregame, game_wnd)
    super(player, coregame, game_wnd)
    @log = Log4r::Logger.new("coregame_log::AlgCpuTressettein4") 
    @log.debug "Created."
  end

  def set_information_formatch(curr_alg)
    @log.debug "set variables from another algorithm" 
    @cards_on_hand = curr_alg.cards_on_hand.dup
    @num_carte_gioc_in_suit = curr_alg.num_carte_gioc_in_suit.dup
    @points_segno = curr_alg.points_segno.dup
    @card_played = curr_alg.card_played.dup
    @players = curr_alg.players.dup
    @opp_names = curr_alg.opp_names.dup
    @team_mates = curr_alg.team_mates.dup
    @num_cards_on_deck = curr_alg.num_cards_on_deck.dup
    @points_player = curr_alg.points_player.dup
  end
  
  
end #end AlgCpuTressettein4

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  require 'core_game_tressettein4'
  
  #require 'ruby-debug' # funziona con 0.9.3, con la versione 0.1.0 no
  #Debugger.start
  #debugger
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  #core = CoreGameBriscolone.new
  # rep = ReplayerManager.new(log)
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
  # rep.replay_match(core, match_info, alg_coll, segno_num)
end
