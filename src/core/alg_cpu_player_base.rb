#file: alg_cpu_player_base.rb

$:.unshift File.dirname(__FILE__) + '/..'
$:.unshift File.dirname(__FILE__) 

require 'replay/replay_manager'
require 'mod_simple_event_publisher'

# To check  if all interfaces are right use the test case on Test_Botbase
# Note: if you change the meaning of members of this interface,
# i.e carte_player becomes an hash instead of an array, you have
# to redifine NAL_Srv_Algorithm, so better is to implement a new function
class AlgCpuPlayerBase
  
  include SimpleEventPublisher

  def initialize(player, coregame, reg_timeout)
     # set algorithm player
    @alg_player = player
    # core game
    @core_game = coregame
    # registerTimeout method
    @registerTimeout = reg_timeout
    #delay before play 
    @timeout_haveplay = 700
    # actions queue to be replayed
    @action_queue = []
    # published events
    @pub_events = {}
  end
  
  ## Core callbacks

  def onalg_new_match(players)
    fire_event(:EV_onalg_new_match, players) 
  end
  def onalg_game_end(best_pl_segni) 
    fire_event(:EV_onalg_game_end, best_pl_segni)
  end
  def onalg_new_giocata(carte_player) 
    fire_event(:EV_onalg_new_giocata, carte_player)
  end
  def onalg_giocataend(best_pl_points)
    fire_event(:EV_onalg_giocataend, best_pl_points) 
  end
  def onalg_newmano(player) 
    fire_event(:EV_onalg_newmano, player)
  end
  def onalg_manoend(player_best, carte_prese_mano, punti_presi)
    fire_event(:EV_onalg_manoend, player_best, carte_prese_mano, punti_presi) 
  end
  def onalg_player_has_played(player, card) 
    fire_event(:EV_onalg_player_has_played, player, card)
  end
  def onalg_player_has_declared(player, name_decl, points) 
    fire_event(:EV_onalg_player_has_declared, player, name_decl, points)
  end
  def onalg_pesca_carta(carte_player) 
    fire_event(:EV_onalg_pesca_carta, carte_player)
  end
  def onalg_player_pickcards(player, cards_arr)
    fire_event(:EV_onalg_player_pickcards, player, cards_arr) 
  end
  def onalg_player_has_changed_brisc(player, card_briscola, card_on_hand) 
    fire_event(:EV_onalg_player_has_changed_brisc, player, card_briscola, card_on_hand)
  end
  def onalg_player_has_getpoints(player, points) 
    fire_event(:EV_onalg_player_has_getpoints, player, points)
  end
  def onalg_player_cardsnot_allowed(player, cards) 
    fire_event(:EV_onalg_player_cardsnot_allowed, player, cards)
  end
  def onalg_player_has_taken(player, cards) 
    fire_event(:EV_onalg_player_has_taken, player, cards)
  end
  def onalg_new_mazziere(player) 
    fire_event(:EV_onalg_new_mazziere, player)
  end
  def onalg_gameinfo(info) 
    fire_event(:EV_onalg_gameinfo, info)
  end
  def onalg_have_to_play_with_cmd(player, command_decl_avail)
    if player == @alg_player && @alg_player.type != :human_local
      if @registerTimeout
        @registerTimeout.call(@timeout_haveplay, :onTimeoutAlgorithmHaveToPlay, self)
        # suspend core event process until timeout
        # this is used to slow down the algorithm play
        @core_game.suspend_proc_gevents
        @log.debug("onalg_have_to_play_with_cmd cpu alg: #{player.name}")
      else
        # no wait for gfx stuff, continue immediately to play
        alg_check_cmds_play_acard(command_decl_avail)
      end
      # continue on onTimeoutHaveToPlay
    end
    fire_event(:EV_onalg_have_to_play_with_cmd, player, command_decl_avail)
  end
  def onalg_have_to_play(player)
    if player == @alg_player && @alg_player.type != :human_local
      if @registerTimeout
        @registerTimeout.call(@timeout_haveplay, :onTimeoutAlgorithmHaveToPlay, self)
        # suspend core event process until timeout
        # this is used to slow down the algorithm play
        @core_game.suspend_proc_gevents
        @log.debug("onalg_have_to_play cpu alg: #{player.name}")
      else
        # no wait for gfx stuff, continue immediately to play
        alg_play_acard
      end
      # continue on onTimeoutHaveToPlay
    end
    fire_event(:EV_onalg_have_to_play, player) 
  end
  
  ###### Other stuff

  ##
  # onTimeoutHaveToPlay: after wait a little for gfx purpose the algorithm play a card
  def onTimeoutAlgorithmHaveToPlay
    alg_play_acard
    # restore event process
    @core_game.continue_process_events if @core_game
  end

  def do_queued_action_to_core
    if @action_queue.size > 0
      action = @action_queue.slice!(0)
      @log.debug("[Predef] onalg_have_to_play action: #{action.inspect}")
      ReplayManager.action_to_core(@alg_player, action, @core_game)
      return true
    end
    return false
  end
  
  def append_action(action_det)
    @action_queue << action_det
  end

  ##
  # Provides the card to play in a very dummy way
  def play_like_a_dummy
    # very brutal algorithm , always play the first card
    card = @cards_on_hand.pop
    return card
  end

  def inform_core_cardplayed(card)
    #card = play_like_a_master
    # notify card played to core game
    @log.error "No cards on hand - programming error" unless card
    @core_game.alg_player_cardplayed(@alg_player, card)
  end

end