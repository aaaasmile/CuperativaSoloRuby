#file: core_game_base.rb
#Common card game basic handling

$:.unshift File.dirname(__FILE__)

require 'mod_core_queue'
require 'player_on_game'
require 'deck_info'
require 'alg_cpu_player_base'

##
# Class used to avoid reentrant code in core
class PlayerInputHandler
  
  def initialize(core)
    @actions_queue = []
    @core = core
    @blocked = 0
    @log = Log4r::Logger.new("coregame_log::PlayerInputHandler")
  end
  
  def block_start
    @blocked += 1
    @log.debug "block_start (#{@blocked})"
  end
  
  def is_input_blocked?(arg)
    if @blocked > 0
      @log.debug "Queue action #{arg[:mth]}"
      @actions_queue << arg
      return true
    end
    return false
  end
  
  def block_end
    @blocked -= 1
    @log.debug "block_end (#{@blocked}):"
    return if @blocked > 0
    return if @actions_queue.size == 0
    @log.debug "playerinput is now free, queue size: #{@actions_queue.size}"

    @actions_queue.each do |arg|
      @core.send(:alg_was_called, arg)
    end
    @actions_queue.clear
  end
end

##
# Interface used on player to call the core
class CoreOnPlayer
  
  def initialize
    @player_input_hdl =  PlayerInputHandler.new(self)
  end
  
  def alg_player_cardplayed(player, lbl_card)
    return @player_input_hdl.is_input_blocked?(
       {:mth =>:alg_player_cardplayed, :player => player, :lbl_card => lbl_card })
  end
  
  def alg_player_cardplayed_arr(player, arr_lbl_card)
    return @player_input_hdl.is_input_blocked?(
       {:mth =>:alg_player_cardplayed_arr, :player => player, :arr_lbl_card => arr_lbl_card })
  end
  
  def alg_player_declare(player, name_decl)
    return @player_input_hdl.is_input_blocked?(
       {:mth =>:alg_player_declare, :player => player, :name_decl => name_decl })
  end
  
  def alg_player_change_briscola(player, card_briscola, card_on_hand )
     return @player_input_hdl.is_input_blocked?(
       {:mth =>:alg_player_change_briscola, :player => player, :card_briscola => card_briscola, :card_on_hand => card_on_hand })
  end
  
  def alg_player_resign(player, reason)
    return @player_input_hdl.is_input_blocked?(
       {:mth =>:alg_player_resign, :player => player, :reason => reason })
  end
  
  def gui_new_segno
    return @player_input_hdl.is_input_blocked?(
       {:mth =>:gui_new_segno })
  end
  
  def gui_new_match(players)
    return @player_input_hdl.is_input_blocked?(
       {:mth =>:gui_new_match, :players => players })
  end
  
  def alg_player_gameinfo(arg)
    return @player_input_hdl.is_input_blocked?(
      {:mth =>alg_player_gameinfo, :arg => arg })
  end
  
  def alg_was_called(arg)
    mth = arg[:mth]
    case mth
      when :alg_player_cardplayed
        alg_player_cardplayed(arg[:player], arg[:lbl_card])
      when :alg_player_cardplayed_arr
        alg_player_cardplayed_arr(arg[:player], arg[:arr_lbl_card])
      when :alg_player_declare
        alg_player_declare(arg[:player], arg[:name_decl])
      when :alg_player_resign
        alg_player_resign(arg[:player], arg[:reason])
      when :alg_player_change_briscola
        alg_player_change_briscola(arg[:player], arg[:card_briscola], arg[:card_on_hand])
      when :gui_new_segno
        gui_new_segno()
      when :gui_new_match
        gui_new_match(arg[:players])
      when :alg_player_gameinfo
        alg_player_gameinfo(arg[:arg])
      else
        @log.error "Queued input method #{mth} not recognized"
    end
  end
  
end #end CoreOnPlayer

##
#Manage the basic of core game
class CoreGameBase < CoreOnPlayer
  alias :super_alg_player_change_briscola :alg_player_change_briscola
  alias :super_alg_player_declare :alg_player_declare
  alias :super_alg_player_gameinfo :alg_player_gameinfo
  
  # array constant throw warnings. Use static variable to avoid warnings.
  @@NOMI_SEMI = ["basto", "coppe", "denar", "spade"]
  @@NOMI_SYMB = ["cope", "zero", "xxxx", "vuot"]
  
  include CoreGameQueueHandler
  
  ##
  # constructor
  def initialize
    super
    # simple state machine processor, use it as stack, the last event
    # submitted is the first processed 
    @proc_queue = []
    # suspend queue event flags - used if gui have timeouts to delay the game
    @suspend_queue_proc = false
    # count number of suspend because they can stay overlapped
    @num_of_suspend = 0
    @mazzo_gioco = []
    # viewers
    @viewers = {}
    # logger
    @log = Log4r::Logger["coregame_log"]
    
    @deck_information = GamesDeckInfo.new
  end
  
  def get_curr_stack_call
    str = "Stack trace:\n"
    begin
      crash__
    rescue => detail
      str = detail.backtrace.join("\n")
    end
    return str
  end
  
  def add_viewer(the_viewer)
    @viewers[the_viewer.name] = the_viewer
    info = on_viewer_get_state()
    the_viewer.game_state(info)
  end
  
  def on_viewer_get_state()
    return {}
  end
  
  def remove_viewer(name)
    @viewers.delete(name)
  end
  
  def inform_viewers(*args)
    @viewers.each{|k,viewer| viewer.game_action(args)}
  end
  
  def set_specific_options(options)
    @log.warn("Ignore specific options")
  end
  
  def num_cards_on_mazzo
    return @mazzo_gioco.size
  end

  
  def self.nomi_semi
    @@NOMI_SEMI
  end
  
  def self.nomi_simboli
    @@NOMI_SYMB
  end
  
  def is_matchsuitable_forscore?
    return true
  end
  
  ##
  # Provides the player index before the provided
  def player_ix_beforethis(num_players, ix_player)
    ix_res = ix_player - 1
    if ix_res < 0
      ix_res = num_players - 1
    end
    return  ix_res
  end
  
  ##
  # Provides the player index after the provided
  def player_ix_afterthis(num_players, ix_player)
    ix_res = ix_player + 1
    if ix_res >=  num_players
      ix_res = 0
    end
    return  ix_res
  end
  
  ##
  # Calculate round players order
  # arr_players: array of players
  # first_ix: first player index
  def calc_round_players(arr_players, first_ix)
    ins_point = -1
    round_players = []
    onlast = true
    arr_players.each_index do |e|
      if e == first_ix
        ins_point = 0
        onlast = false
      end 
      round_players.insert(ins_point, arr_players[e])
      ins_point =  onlast ?  -1 : ins_point + 1         
    end
    return round_players
  end
  
  ##
  # Provides a complete card name
  def nome_carta_completo(lbl_card)
    return @deck_information.nome_carta_completo(lbl_card)
  end
  
  def get_card_logical_symb(card_lbl)
    return @deck_information.get_card_logical_symb(card_lbl)
  end
 
  def get_deck_info
    return @deck_information
  end

  def leave_on_less_players?()
    return true
  end

end

##
# Algorithm cpu base. Used to define algorithm notifications
# Please consider that a change done here has an impact with:
# Add a new message in ParserCmdDef
# - prot_parsmsg
#  ==> On the server:
# - NAL_Srv_Algorithm
#  ==> On the client:
# - ControlNetConnection
# - NalClientGfx
# - every class that inherit BaseEngineGfx if necessary
# - GameBasebot



class ViewerGameBase
  def alg_changed(info) end
  def current_state(info) end
end


