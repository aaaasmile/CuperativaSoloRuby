# mariazza_gfx.rb
# Handle display for mariazza graphic engine

$:.unshift File.dirname(__FILE__)

if $0 == __FILE__
  # we are testing this gfx, then load all dependencies
  require '../../cuperativa_gui.rb' 
end

require 'gfx/gfx_general/gfx_elements'
require 'gfx/gfx_general/base_engine_gfx'
require 'core_game_mariazza'
require 'games/briscola/briscola_gfx'


##
# Class that manage the mariazza table gui
class MariazzaGfx < BriscolaGfx
  attr_accessor :option_gfx

  INFO_GFX_COORD = { :x_top_opp_lx => 30, :y_top_opp_lx => 60, 
     :y_off_plgui_lx => 15, :y_off_plg_card => 10
  }
  
  DECL_NAMES = {:mar_den => {:name_lbl => "Mariazza di denari"}, 
                     :mar_spa => {:name_lbl => "Mariazza di spade"},
                     :mar_cop => {:name_lbl => "Mariazza di coppe"},
                     :mar_bas => {:name_lbl => "Mariazza di bastoni"},
                     :change_briscola => {:name_lbl => "Cambia birscola"}
                   }
  
  # constructor 
  # parent_wnd : application gui     
  def initialize(parent_wnd)
    super(parent_wnd)
    
    @core_game = nil
    @splash_name = File.join(@resource_path, "icons/mariazza_title_trasp.png")
    @algorithm_name = "AlgCpuMariazza"  
    @core_name_class = 'CoreGameMariazza'
    @log = Log4r::Logger.new("coregame_log::MariazzaGfx") 
    
    init_command_buttons
  end
  
  def init_command_buttons
    @game_cmd_bt_list = []
    @log.debug "Create command buttons"
    bt1 = InvButton.new(10, 10, 140, 50, 0)
    bt1.set_content('uno')
    bt2 = InvButton.new(10, 70, 140, 50, 0)
    bt2.set_content('due')
    bt3 = InvButton.new(10, 130, 140, 50, 0)
    bt3.set_content('tre')
    
    bt_wnd_list = [bt1, bt2, bt3]
    bt_wnd_list.each do |bt_wnd|
      bt_hash = {:bt_wnd => bt_wnd, :status => :not_used}
      @game_cmd_bt_list << bt_hash
    end
  end
   
  ##
  # Free and hide all game specific cmd buttons
  def free_all_btcmd
    container = @model_canvas_gfx.info[:main_container]
    @game_cmd_bt_list.each do |bt| 
      if bt[:status] != :not_used
        @log.debug "Free button #{bt[:name]}"
        container.remove(bt[:bt_wnd])
        block = bt[:bt_wnd_block]
        bt[:bt_wnd].disconnect(:EV_click, block) if block 
      end
      bt[:status] = :not_used
    end
  end
  
  ##
  # Create a new command in the game command pannel
  # params: array of parameters
  # cb_btcmd: callback implemented in the game gfx
  def create_bt_cmd(cmd_name, params, cb_btcmd)
    bt_cmd_created = get_next_btcmd()
    #p bt_cmd_created[:bt_wnd].methods
    #p bt_cmd_created[:bt_wnd].shown?
    bt_cmd_created[:name] = cmd_name
    container = @model_canvas_gfx.info[:main_container]
    
    #p bt_cmd_created[:bt_wnd].shown?
    bt_wnd = bt_cmd_created[:bt_wnd]
    bt_wnd.content.caption = get_declaration_name(cmd_name)
     
    block = bt_wnd.connect(:EV_click) do |sender|
    	@log.debug "Handle command #{cb_btcmd}"
    	bt_wnd.disconnect(:EV_click, block)
    	container.remove(bt_cmd_created[:bt_wnd])
    	bt_cmd_created[:status] = :not_used
      send(cb_btcmd, params)
    end
    bt_cmd_created[:bt_wnd_block] = block
    container.add(bt_wnd)
  end
  
  ##
  # Provides the next free button
  def get_next_btcmd
    @game_cmd_bt_list.each do |bt|
      if bt[:status] == :not_used
        bt[:status] = :used 
        return bt
      end 
    end
    nil
  end
  
  ##
  # Add more components to be displayed
  def add_components_tocompositegraph
    # smazzata end
    @msgbox_smazzataend = MsgBoxComponent.new(self, @app_owner, @core_game, @option_gfx[:timeout_msgbox], @font_text_curr[:medium])
    if @option_gfx[:autoplayer_gfx]
      @msgbox_smazzataend.autoremove = true
    end
    @msgbox_smazzataend.box_pos_x = 300
    @msgbox_smazzataend.box_pos_y = 150
    @msgbox_smazzataend.build(nil)
    @composite_graph.add_component(:smazzata_end, @msgbox_smazzataend)
  end
  
  ##
  # Shows a dilogbox for the end of the smazzata
  def show_smazzata_end(best_pl_points )
    @log.debug "Show smazzata end dialogbox"
    str = "Segno terminato: vince #{best_pl_points.first[0]} col punteggio #{best_pl_points.first[1]} a #{best_pl_points[1][1]}"
    log str
   
    if @option_gfx[:use_dlg_on_core_info]
      @msgbox_smazzataend.show_message_box("Smazzata finita", str, true)
      @msgbox_smazzataend.set_visible(true)
    end
    
  end
 
  ##
  # Notification that on the gui the player has clicke on declaration button
  # params: array of parameters. Expect player as first item and declaration as second.
  def onBtPlayerDeclare(params)
    player = params[0]
    name_decl = params[1]
    @core_game.alg_player_declare(player, name_decl )
  end
  
  ##
  # Notification that on the gui the player has clicked on command
  # change the briscola.
  # params: array of parameters. Expect player as first item. Follow the 
  #         briscola and the card on player hand(only the 7 is allowed) 
  def onBtPlayerChangeBriscola(params)
    player = params[0]
    card_briscola = params[1]
    card_on_hand = params[2]
    @core_game.alg_player_change_briscola(player, card_briscola, card_on_hand )
  end

  ##
  # Provides the name of the mariazza declaration
  # name_decl: mariazza name as label (e.g :mar_den)
  def get_declaration_name(name_decl)
    return DECL_NAMES[name_decl][:name_lbl]
  end
  
  ############### implements methods of AlgCpuPlayerBase
  #############################################
  #algorithm calls (gfx is a kind of algorithm)
  #############################################
 
  def onalg_giocataend(best_pl_points)
    free_all_btcmd()
    super 
  end
  
  ##
  # Player have to play
  # player: player that have to play
  # command_decl_avail: array of commands (hash with :name and :points) 
  # available for declaration
  def onalg_have_to_play(player,command_decl_avail)
    decl_str = ""
    #p command_decl_avail
    if player == @player_on_gui[:player]
      @log.debug("player #{player.name} have to play")
      free_all_btcmd()
      command_decl_avail.each do |cmd| 
        if cmd[:name] == :change_briscola
          # change briscola command
          decl_str += "possibile scambio briscola"
          # create command button to change the briscola
          create_bt_cmd(cmd[:name], 
         [ player, cmd[:change_briscola][:briscola], cmd[:change_briscola][:on_hand]], 
               :onBtPlayerChangeBriscola)
        else
          # mariazza declaration command
          decl_str += "#{get_declaration_name(cmd[:name])}, punti: #{cmd[:points]} "
          # create a button with the declaration of this mariazza
          create_bt_cmd(cmd[:name], [player, cmd[:name]], :onBtPlayerDeclare)
        end
      end
    end
    # mark player that have to play
    player_sym = player.name.to_sym
    @turn_playermarker_gfx[player_sym].visible = true
    
    log "Tocca a: #{player.name}"
    if player == @player_on_gui[:player]
      @player_on_gui[:can_play] = true
       log "#{player.name} comandi: #{decl_str}" if command_decl_avail.size > 0
    else
      @player_on_gui[:can_play] = false
    end
    if @option_gfx[:autoplayer_gfx]
      # store parameters into a stack
      @alg_auto_stack.push(command_decl_avail)
      @alg_auto_stack.push(player)
      # trigger autoplay
      @app_owner.registerTimeout(@option_gfx[:timout_autoplay], :onTimeoutHaveToPLay)
      # suspend core event process untill timeout
      @core_game.suspend_proc_gevents
    end
    
    # refresh the display
    update_dsp
  end
  
  ##
  # Player has changed the briscola on table with a 7
  def onalg_player_has_changed_brisc(player, card_briscola, card_on_hand)
    str_msg =  "#{player.name} ha scambiato [#{nome_carta_ita(card_on_hand)}] " + 
        "con  [#{nome_carta_ita(card_briscola)}]"
    log(str_msg) 
  
    # check if it was gui player
    if @player_on_gui[:player] == player
      log "Scambio briscola OK [#{nome_carta_ita(card_on_hand)}] -> [#{nome_carta_ita(card_briscola)}]"
      player_sym = player.name.to_sym
      @cards_players.swap_card_player(player_sym, card_on_hand,  card_briscola)
    else
      # other player has changed the briscola, shows a dialogbox
      if @option_gfx[:use_dlg_on_core_info]
        @msg_box_info.show_message_box("Briscola in tavola cambiata", str_msg, false)
      end 
    end
    
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_player_has_changed_brisc(player, card_briscola, card_on_hand)
    end
    
    #set the briscola with the card on player hand (the 7) 
    @deck_main.set_briscola(card_on_hand)
    
    # refresh the display
    update_dsp
  end
  
  ##
  # Player has played a card not allowed
  def onalg_player_cardsnot_allowed(player, cards)
    lbl_card = cards[0]
    log "#{player.name} ha giocato una carta non valida [#{nome_carta_ita(lbl_card)}]"
    @player_on_gui[:can_play] = true
  end
  
  
  ##
  # Player has declared a mariazza
  # player: player that has declared
  # name_decl: mariazza declared name (e.g :mar_den)
  # points: points of the declared mariazza
  def onalg_player_has_declared(player, name_decl, points)
    log "#{player.name} ha dichiarato #{get_declaration_name(name_decl)}"
    #if @player_on_gui[:player] == player
      #@app_owner.disable_bt(name_decl)
    #end
    str = "Il giocatore #{player.name} ha accusato la\n#{get_declaration_name(name_decl)}"
    str.concat(" da #{points} punti") if points > 0
    if @option_gfx[:use_dlg_on_core_info]
      @msg_box_info.show_message_box("Mariazza accusata", str, false)
    end
    # adjourn points
    @cards_taken.adjourn_points(player, points)
    
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_player_has_declared(player, name_decl, points)
    end
    
    # refresh the display
    update_dsp
  end
  
  ##
  # Player has become points. This usally when he has declared a mariazza 
  # as a second player 
  def onalg_player_has_getpoints(player,  points)
    log str =  "#{player.name} ha fatto #{points} punti di accusa"
    
    if @option_gfx[:use_dlg_on_core_info]
      @msg_box_info.show_message_box("Punti ricevuti", str, false)
    end
    
    # adjourn points
    @cards_taken.adjourn_points(player, points)
    
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_player_has_getpoints(player, points)
    end
    
    # refresh the display
    update_dsp
  end
  
end
 

if $0 == __FILE__
  # test this gfx
  require '../../../test/test_canvas'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  out_log_name = File.join(ResourceInfo.get_dir_appdata(), 'logs/mariazza_test.log')
  FileOutputter.new('coregame_log', :filename=> out_log_name)
  Logger['coregame_log'].add 'coregame_log'
  
  theApp = FXApp.new("TestCanvas", "FXRuby")
  testCanvas = TestCanvas.new(theApp)
  testCanvas.set_position(0,0,950,530)
  
  # start game using a custom deck
  deck =  RandomManager.new
  #deck.set_predefined_deck('_3c,_Ab,_4b,_Cd,_6d,_Fb,_2b,_7s,_4c,_3b,_7c,_3d,_5b,_Ad,_2s,_Rs,_Fd,_2d,_4s,_Cb,_3s,_6b,_5c,_5s,_Cs,_7b,_Fs,_7d,_5d,_6c,_Rb,_Rd,_As,_Fc,_Cc,_Rc,_Ac,_6s,_4d,_2c',0) # mazzo OK
  deck.set_predefined_deck('_3c,_Ab,_4b,_Cd,_6d,_Fb,_2b,_7s,_4c,_3b,_7c,_3d,_5b,_Ad,_2s,_Rs,_Fd,_2d,_4s,_Cb,_3s,_6b,_5c,_5s,_Cs,_7b,_Fs,_7d,_5d,_3d,_Rd,_3b,_Ad,_4d,_Rc,_Fd,_Fb,_Cb,_As,_7d',0) #deck fake to test the first hand alg
  testCanvas.set_custom_deck(deck)
  # end test a custom deck
  
  
  theApp.create()
  players = []
  players << PlayerOnGame.new('me', nil, :human_local, 0)
  players << PlayerOnGame.new('cpu', nil, :cpu_local, 0)
  
  
  #testCanvas.app_settings["autoplayer"][:auto_gfx] = true
  
  testCanvas.init_gfx(MariazzaGfx, players)
  maria_gfx = testCanvas.current_game_gfx
  maria_gfx.option_gfx[:timeout_autoplay] = 50
  maria_gfx.option_gfx[:autoplayer_gfx_nomsgbox] = false
  testCanvas.start_new_game
  
  theApp.run
end


