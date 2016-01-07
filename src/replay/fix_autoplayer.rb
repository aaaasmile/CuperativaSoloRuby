#file: fix_autoplayer.rb

##
# Class used to play a saved game. This can replay a game of an user sending
# automatically all events and forward core callbacks to a gfx engine
class FixAutoplayer < AlgCpuPlayerBase
  attr_accessor :alg_player
  
  def initialize(log, core_game, game_replayer)
    # a :slave don'forward all callback to a gui, a :master forward all callbacks to a gfx
    @cond_auto = :slave
    @log = log
    # instance PlayerOnGame bind
    @alg_player = nil
    @gui_gfx = nil
    # actions queue to be replayed
    @action_queue = []
    # core game
    @core_game = core_game
    # game replayer
    @game_replayer = game_replayer
  end
  
  ##
  # Bind the autoplayer algorithm with a player 
  # player:PlayerOnGame instance
  def bind_player(player)
    @alg_player = player
    @log.info("[#{@alg_player.type}] Autoplayer #{@alg_player.type} bound with #{player.name}. Ignore actions predifined.")
    @action_queue = []
  end
  
  ##
  # Append an action to the action queue
  # action_det: action detail (e.g. {:type=>:cardplayed, :arg=>["Gino B.", :_Cc]})
  def append_action(action_det)
    @log.debug "[#{@alg_player.type}] Append action (#{@alg_player.name}) #{action_det[:arg]}"
    @action_queue << action_det
  end
  
  def onalg_giocataend(best_pl_points)
    @log.info("[#{@alg_player.type}] onalg_giocataend")
  end
   
  def onalg_have_to_play(player,command_decl_avail)
    if player.type == @alg_player.type
      # now we have to play
      @log.info("[#{@alg_player.type}]onalg_have_to_play-> #{player.name}, cmds(#{command_decl_avail.size})")
      if @action_queue.size > 0
        action = @action_queue.slice!(0)
        @log.debug "[#{@alg_player.type}] Prepare action #{action}"
        @game_replayer.submit_core_action(@alg_player, action)
        # if we call here @core we are still on a callback and we execute the game
        # without living the stack. Maybe we get a stack overflow. To solve it
        # we store the action and we execute it when the callback is terminated
      else
        @log.debug("[#{@alg_player.type}] @action_queue for #{player.name} is empty")
      end
    end 
  end
  
end  
