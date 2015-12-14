#file: chess_core.rb

$:.unshift File.dirname(__FILE__)

require 'rubygems'

require File.dirname(__FILE__) + '/../../base/core/core_game_base'
require 'Board'
require 'alg_cpu_dummy'



class ChessCore
  attr_reader :board_core
  
  include CoreGameQueueHandler
  
  def initialize
    # board information core
    @board_core = nil
    @proc_queue = []
    @suspend_queue_proc = false
    @num_of_suspend = 0
    @log = Log4r::Logger.new("coregame_log::ChessCore")
    @player_input_hdl =  PlayerInputHandler.new(self)
  end
  
  ##
  # Main app inform about starting a new match
  # players: array of PlayerOnGame
  def gui_new_match(players, options)
    @match_state = :match_started
    @board_core = Board.new
    @board_core.create_new_match
    @players = players
    @all_notifiers = []
    @players.each{|pl| @all_notifiers << pl } 
    submit_next_event(:gs_new_match)
  end
  
  def gs_new_match
    @log.debug "new_match"
    
    @player_white = @players[0]
    @player_black = @players[1]
    @players_on_color = {:white =>@player_white, :black => @player_black }
    
    @all_notifiers.each{|pl| pl.algorithm.onalg_new_match(@players_on_color) }
    #@player_white.algorithm.onalg_new_match(:white, @player_black.name)
    #@player_black.algorithm.onalg_new_match(:black, @player_white.name)
    
    @log.debug "#{@player_white.name} (white) - #{@player_black.name} (black)"
    
    
    #name_players = []
    #@players.each {|pl| name_players << pl.name}
    #inform_viewers(:onalg_new_match, @players.size, name_players)
    
    submit_next_event(:gs_request_player_to_move)
  end
  
  def gs_request_player_to_move
    @log.debug "request_player_to_move START"
    @player_input_hdl.block_start
    @last_moved_info = nil
    player = get_player_onturn(@board_core.color_on_turn)
    @player_on_turn = player
    @log.debug "Player on turn: #{@player_on_turn.name}, color: #{@board_core.color_on_turn} "
    @all_notifiers.each{|pl| pl.algorithm.onalg_have_to_move(player)}
    @log.debug "request_player_to_move END"
    @player_input_hdl.block_end
  end
  
  def gs_has_moved
    @log.debug "Player #{@player_on_turn.name} has moved: #{@last_moved_info.move_to_str}"
    
    @all_notifiers.each{|pl| pl.algorithm.onalg_player_has_moved(@player_on_turn, @last_moved_info)}    
    
    @board_core.swap_color_on_turn
    
    if is_match_terminated?
      submit_next_event(:gs_match_end)
    else
      submit_next_event(:gs_request_player_to_move)
      return
    end
  end
  
  def gs_match_end
    @log.debug "match terminated"
    match_end_info = {}
    @all_notifiers.each{|pl| pl.algorithm.onalg_match_end(match_end_info)}
  end
  
  def is_match_terminated?
    if @board_core.moves_in_match.size >= 12
      return true
    end
    return false
  end
  
  def get_player_onturn(color)
    return @players_on_color[color]
  end
  
  def alg_was_called(arg)
    mth = arg[:mth]
    case mth
      when :alg_player_move
        alg_player_move(arg[:player], arg[:move])
      else
        @log.error "Queued input method #{mth} not recognized"
    end
  end
   
  # move: an instance of BoardMove
  def alg_player_move(player, move)
    return if @player_input_hdl.is_input_blocked?(
       {:mth =>:alg_player_move, :player => player, :move => move })
    
    if player != @player_on_turn
      @log.debug("Invalid move #{move.move_to_str}, player is not on turn")
      player.algorithm.on_alg_hasmoved_invalid(move, :not_in_turn)
      return 
    end
    
    if @board_core.do_the_move(move) == :invalid
      @log.debug("Invalid move #{move.move_to_str}")
      @player_on_turn.algorithm.on_alg_hasmoved_invalid(move, :invalid_move)
      @player_on_turn.algorithm.onalg_have_to_move(@player_on_turn)
      return
    end
    
    @log.debug("Player #{player.name}, move #{move.move_to_str}, fen after move #{move.fen_after_move}")
    
    @last_moved_info = move
    submit_next_event(:gs_has_moved)
  end
    
end

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  core = ChessCore.new
  player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
  player1.algorithm = AlgCpuChessDummy.new(player1, core, nil)
  player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
  player2.algorithm = AlgCpuChessDummy.new(player2, core, nil)
  arr_players = [player1,player2]
  
  options = {}  
  core.gui_new_match(arr_players, options)
  event_num = core.process_only_one_gevent
  while event_num > 0
    event_num = core.process_only_one_gevent
  end
end
