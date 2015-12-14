#file: alg_cpu_dummy.rb

class AlgCpuChessDummy
  
  def initialize(player, coregame, timeout_handler)
    @timeout_handler = timeout_handler
    @alg_player = player
    @log = Log4r::Logger.new("coregame_log::AlgCpuChessDummy") 
    @core_game = coregame
  end
 
  # players_info: {:white =>@player_white, :black => @player_black }
  def onalg_new_match(players_info)
    players_info.each do |k,v|
      if v == @alg_player
        @alg_color = k
      else
        @opponent_name = v.name    
      end
    end
    @log.debug "New match, my color is #{@alg_color} and opponent is #{@opponent_name}"
    @board_core = Board.new
    @board_core.create_new_match
  end
  
  def onalg_match_end(match_end_info)
    @log.debug "Match end"
  end
  
  def onalg_have_to_move(player)
    if player == @alg_player
      @log.debug("onalg_have_to_move cpu alg: #{@alg_player.name}")
      if @timeout_handler
        @timeout_handler.registerTimeout(@option_gfx[:timeout_haveplay], :onTimeoutAlgorithmHaveToPlay, self)
        # suspend core event process until timeout
        # this is used to sloow down the algorithm play
        @core_game.suspend_proc_gevents
        
      else
        # no wait for gfx stuff, continue immediately to play
        alg_make_move
      end
      # continue on onTimeoutHaveToPlay
    end 
  end
  
  ##
  # onTimeoutHaveToPlay: after wait a little for gfx purpose the algorithm make a move
  def onTimeoutAlgorithmHaveToPlay
    alg_make_move
    # restore event process
    @core_game.continue_process_events if @core_game
  end
  
  def alg_make_move
    @log.debug "alg_make_move: #{@alg_color}"
    @log.debug "Board BEFORE the move"
    @board_core.print_board(@alg_color)
    @board_core.set_player_on_turn(@alg_color)
    num_moves =  @board_core.all_available_moves.size
    if num_moves > 0
      ix_move = rand(num_moves)
      move = @board_core.all_available_moves[ix_move]
      @log.debug "on possible #{num_moves} moves, select the #{ix_move}: #{move.move_to_str}"
      @core_game.alg_player_move(@alg_player, move)
    else
      @log.debug "NO move available, match should be terminated"
    end
  end
  
  def onalg_player_has_moved(player, move )
    @log.debug "Player move #{player.name}: #{move.move_to_str}" 
    if @board_core.do_the_move(move) == :invalid
      raise "error on code move invalid"
    end
    curr_fen = @board_core.calculate_current_fen
    if move.fen_after_move != curr_fen
      raise "Invalid fen: core fen is #{move.fen_after_move}, but alg fen is #{curr_fen}"
    end
    if @alg_player == player
      @log.debug "Board AFTER the move"
      @board_core.print_board(@alg_color)
    end
  end
  
end


if $0 == __FILE__
end