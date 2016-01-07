# file: core_game_tressettein4.rb


$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../..'
$:.unshift File.dirname(__FILE__) + '/..'

require 'replay/game_replayer'
require 'tressette/core_game_tressette'
require 'alg_cpu_tressettein4'

class CoreGameTressettein4 < CoreGameTressette
  
  def initialize
    super
    @game_opt[:num_of_players] = 4
    
    @log = Log4r::Logger.new("coregame_log::CoreGameTressettein4") 
  end
  
  def owner_name_of_deck(player_name)
    ix = 0
    @players.each do |pl|
      if pl.name == player_name
        return @players[0].name if ix == 2 
        return @players[1].name if ix == 3
      end
      ix += 1
    end
    return player_name
  end
 
  def on_newgiocata_playersinitialized()
    @points_curr_smazzata = {}
    @players[0..1].each do |player|
      #p player.name
      reset_points_newgiocata(player)
    end
    @log.debug "Team 1 (#{@players[0].name} - #{@players[2].name}) vs Team 1 (#{@players[1].name} - #{@players[3].name})"
  end
  
  def alg_player_resign(player, reason)
    if @smazzata_state == :end
      @log.warn "Resign not valid in state #{@smazzata_state} (#{get_curr_stack_call})"
      return :not_allowed
    end
    if reason[:medium] == :network
      @log.info "User #{player.name} leave the game"
      create_substitute_player(player)
    else
      @log.info "alg_player_resign: giocatore perde la partita, ragione #{reason}"
      if @game_opt[:record_game]
        @game_core_recorder.store_player_action(player.name, :resign, player.name, reason)
      end
      @smazzata_state = :end
      # set negative value for segni in order to make player marked as looser
      @points_curr_match[player.name] = -1
      submit_next_event(:match_end)
      return
    end
  end 
  
  def create_substitute_player(player_to_be_changed)
    @log.debug "Create a substitute algorithm for #{player_to_be_changed.name}"
    name = player_to_be_changed.name # usa lo stesso name altrimenti gli hash con le info non vanno più
    position = player_to_be_changed.position
    player_new = PlayerOnGame.new(name, nil, :cpu_alg, position)
    alg_sub = AlgCpuTressettein4.new(player_new, self, nil)
    player_new.algorithm = alg_sub 
    
    @players_name_to_player[name] = player_new
    delete_and_insert( @round_players, player_to_be_changed, player_new)
    delete_and_insert( @players, player_to_be_changed, player_new)
    
    alg_sub.set_information_formatch(player_to_be_changed.algorithm)
    
  end
 
  
  def delete_and_insert(arr_players, old_pl, new_pl)
    ix = arr_players.index(old_pl)
    if ix != nil
      arr_players.insert(new_pl)
      arr_players.delete(old_pl)
    end
  end
  
  def leave_on_less_players?()
    return false
  end
 
end#end CoreGameTressettein4

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  
  #require 'ruby-debug' # funziona con 0.9.3, con la versione 0.1.0 no
  #Debugger.start
  #debugger
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  core = CoreGameTressettein4.new
  rep = ReplayManager.new(log)
  #match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/briscolone/saved_games/test.yaml')
  ##p match_info
  #player = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  #alg_coll = { "Gino B." => nil } 
  #segno_num = 0
  #rep.replay_match(core, match_info, alg_coll, segno_num)
  ##sleep 2
end
