# briscola_gfx.rb
# Handle display for briscola graphic engine

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../..'

if $0 == __FILE__
  # we are testing this gfx, then load all dependencies
  require '../../cuperativa_gui.rb' 
end

require 'gfx/gfx_general/base_engine_gfx'
require 'gfx/gfx_general/gfx_elements'
require 'core_game_briscola'

##
# Briscola Gfx implementation
class BriscolaGfx < BaseEngineGfx
  attr_accessor :option_gfx
  
  # constructor 
  # parent_wnd : application gui     
  def initialize(parent_wnd)
    super(parent_wnd)
    @core_game = nil
    @splash_name = File.join(@resource_path, "icons/briscola_title_trasp.png")
    
    @model_canvas_gfx.info[:canvas] = {}
    # information about canvas layout offset
    @model_canvas_gfx.info[:info_gfx_coord] = { 
      :x_top_opp_lx => 30, :y_top_opp_lx => 60, 
      :y_off_plgui_lx => 15, :y_off_plg_card => 10
    } 
    
    @splash_image = nil
    # draw handler for each state
    @graphic_handler[:on_splash] = :on_draw_splash
    @graphic_handler[:on_game] = :on_draw_game_scene
    @graphic_handler[:game_end] = :on_draw_game_scene
    
    # store information about player that it is using this gui
    @player_on_gui = {
      # player object
      :player => nil,
      # can player using the gui flag
      :can_play => false,
      # mano index (0 = initial, incremented when a player has correctly played )
      :mano_ix => 0
    }
    # array of opponents
    @opponents_list = []
    # array of all players
    @players_on_match = []
    ## briscola card
    #@card_briscola_todisp = nil
    # turn markers, used to mark player that have to play
    @turn_playermarker_gfx = {}
    # infos on gfx_elements
    @canvas_gfx_info = {}
    # cards taken by players as small deck image with points
    #@holddecks_todisp = {}
    # resource gfx loaded only for this game (e.g. :points_deck_img)
    @image_gfx_resource = {}
    # information about segni points
    @segni_status = {}
    # player that wons the mano
    @mano_end_player_taker = nil
    # dialogbox
    @msg_box_info = nil
    # color to display when the game is terminated
    @canvas_end_color = Fox.FXRGB(128, 128, 128)
    # points shower
    @points_image = nil
    # gfx elements (widget) stored on each player    
    # Widget stored are: :lbl_name, :lbl_status, :taken_card, :rectturn
    @player_gfx_info = {}
    # reversed card clitted
    @card_reversed_gfx = nil
    # composite graphical
    @composite_graph = nil 
    @color_back_table = Fox.FXRGB(0x22, 0x8a, 0x4c) #Fox.FXRGB(103, 203, 103)
    # cards on table played
    @table_cards_played = nil
    #algorith instance name
    @algorithm_name = "AlgCpuBriscola"  
    #core game name (created on base class)
    @core_name_class = 'CoreGameBriscola'
    # smazzata end messagebox
    @msgbox_smazzataend = nil
    @show_opponent_cards = false
    @num_of_check_start_ani = 0
    @log = Log4r::Logger.new("coregame_log::BriscolaGfx") 
    # NOTE: don't forget to initialize variables also in on_gui_start_new_game
  end
 
  ##
  # Shows a splash screen
  def create_wait_for_play_screen
    @state_gfx = :on_splash
    unless @splash_image
      # load the splash
      img = FXPNGIcon.new(getApp, nil, IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
      FXFileStream.open(@splash_name, FXStreamLoad) { |stream| img.loadPixels(stream) }
      img.create
      @splash_image = img    
    end
    update_dsp
  end 
  
 
  ##
  # Draw splash screen
  def on_draw_splash(dc, width, height)
    dc.drawImage(@splash_image, width / 2 - @splash_image.width / 2 , height / 2 - @splash_image.height / 2 )
  end
  
  ##
  # Overwrite background
  def on_draw_backgrounfinished(dc)
    img = @image_gfx_resource[:sfondo_tavolo]
    dc.drawIcon(img, 0, 0)
  end
  
  ##
  # Draw static scene during game
  def on_draw_game_scene(dc,width, height)
    if @state_gfx == :game_end
      # game is terminated, make the background monochrome
      dc.foreground = @canvas_end_color
      dc.fillRectangle(0, 0, @model_canvas_gfx.info[:canvas][:width], @model_canvas_gfx.info[:canvas][:height])
    else
      on_draw_backgrounfinished(dc)
    end
    
    #draw name of players and all other labels
    dc.foreground = @color_text_label 
    @labels_to_disp.each_value do |label|
      label.draw_label(dc)
    end
    
    #draw points
    if @points_image
      @points_image.draw_points(dc)
    end
    
    #draws player marker
    @turn_playermarker_gfx.each_value do |marker|
      marker.draw_marker(dc)
    end
    
    # using composite pattern
    @composite_graph.draw(dc)

  end #end on_draw_game_scene
  
  ##
  # Canvas size has changed
  # width: new width
  # height: new height
  def onSizeChange(width,height)
    #@log.debug "onSizeChange: w = #{width} h = #{height}"
    @model_canvas_gfx.info[:canvas] = {:height => height, :width => width, :pos_x => 0, :pos_y => 0 }
    
    if @state_gfx == :on_game
      load_table_background
      @image_gfx_resource[:sfondo_tavolo].create
      
      # change place for elements in game
      # cards on table resize
      players_to_resize = []
      #resize player on sud first
      @players_on_match.each do |player_for_sud|
        if player_for_sud.position == :sud
          resize_player(player_for_sud)
        else
          players_to_resize << player_for_sud
        end
        #players_to_resize << player_for_sud
      end
      players_to_resize.each do |player|
        resize_player(player)
      end #end @players_on_match
      @table_cards_played.resize_with_info
      @deck_main.resize(nil)
      @cards_players.init_position_ani_distrcards
      
      resize_gfxlabel_briscola
    end
  end
  
  ##
  # resize all element of the player
  def resize_player(player)
    # cards on player hand
    @cards_players.resize(player)
    player_sym = player.name.to_sym
    pl_type =  player.type
  
    # player name label 
    resize_gfxlabel_player(player_sym, pl_type)
    # cards taken small symbol
    @cards_taken.resize(player)
    # player turn marker
    resize_gfxmarker_player(player_sym, pl_type)
  end
  
  ##
  # User click on card
  # card: cardgfx clicked on
  def evgfx_click_on_card(card)
    if @player_on_gui[:can_play] == true and card.visible and card.lbl != :vuoto
      #click admitted
      card.blit_reverse = false
      allow = @core_game.alg_player_cardplayed(@player_on_gui[:player], card.lbl)
      if allow == :allowed
        @log.debug "gfx: submit card played #{card.lbl}"
        @sound_manager.play_sound(:play_click4)
        @player_on_gui[:can_play] = false
        return # card clicked  was played correctly
      end
    end
    
    # if we reach this code, we have clicked on a card that is not allowed to be played
    @log.debug "Ignore click #{card.lbl}"
    unless @card_reversed_gfx
      # we have clicked on card that we can't play
      @card_reversed_gfx = card
      card.blit_reverse = true
      @card_reversed_gfx = card
      registerTimeout(@option_gfx[:timeout_reverseblit], :onTimeoutRverseBlitEnd, self)
      update_dsp
    end    
  end #end click_on_card
  
  def get_zord_ofcardplayed
    return @player_on_gui[:mano_ix]
  end
  
  ##
  # The player on the gui has played a card. Start the animation process
  def start_guiplayer_card_played_animation( player, lbl_card)
    @log.debug("user card is played animation start #{lbl_card}")
    ix = @player_on_gui[:mano_ix]
    player_sym = player.name.to_sym
    @cards_players.card_invisible(player_sym, lbl_card)
    
    z_ord = get_zord_ofcardplayed
    init_x = @cards_players.last_cardset_info[:pos_x]
    init_y = @cards_players.last_cardset_info[:pos_y]
    @table_cards_played.card_is_played2_incirc(lbl_card, player.position, z_ord, init_x,  init_y)
    
    
    # update index of mano
    @player_on_gui[:mano_ix] += 1
    
    update_dsp
  end
  
  ##
  # Reversed blit tmed on card is elapsed
  def onTimeoutRverseBlitEnd
    if @state_gfx == :on_game and @card_reversed_gfx
      @card_reversed_gfx.blit_reverse = false
      @card_reversed_gfx = nil
      update_dsp
    end
  end
 
  ##
  # Briscola is started. Notification from base class that gui want to start
  # a new game
  # players: array  of players. Players are PlayerOnGame instance
  # options: hash with game options, @app_settings from cuperativa gui
  def on_gui_start_new_game(players, options)
    @log.debug "gfx: on_gui_start_new_game"
    @card_reversed_gfx = nil
    @opponents_list = []
    @players_on_match = []
    @labels_to_disp = {}
    @turn_playermarker_gfx = {}
    @canvas_gfx_info = {}
    @segni_status = {}
    @player_gfx_info = {}
    
    @show_opponent_cards ||= @option_gfx[:cards_opponent]

    unless @model_canvas_gfx.info[:canvas][:height] 
      raise("ERROR: Canvas information not set")
    end

    card_coperto_gfx = get_cardsymbolimage_of(:coperto)
    if @show_opponent_cards
      @model_canvas_gfx.info[:opponent_info][:is_like_human] = true
      @model_canvas_gfx.info[:opponent_info][:x_offset] = (card_coperto_gfx.width / 5) * 3
    end
    
    # composite object
    @composite_graph = GraphicalComposite.new(self)
   
     # cards on table played
    @table_cards_played = TablePlayedCardsGraph.new(@app_owner, self, players.size)
    @table_cards_played.set_resource(:coperto, card_coperto_gfx)
    @composite_graph.add_component(:table_cardsplayed, @table_cards_played)
     
    # card players
    @cards_players = CardsPlayersGraph.new(@app_owner, self, @core_game.num_of_cards_onhandplayer)
    @cards_players.set_resource(:coperto, get_cardsymbolimage_of(:coperto))
    @cards_players.set_resource(:card_opp_img, @image_gfx_resource[:card_opp_img])
    @composite_graph.add_component(:cards_players, @cards_players)
    
    # message box
    @msg_box_info = MsgBoxComponent.new(self, @app_owner, @core_game, @option_gfx[:timeout_msgbox], @font_text_curr[:medium])
    if @option_gfx[:autoplayer_gfx]
      @msg_box_info.autoremove = true
    end 
    @composite_graph.add_component(:msg_box, @msg_box_info)
    
    # cards taken
    @cards_taken = CardsTakenGraph.new(@app_owner, self, @font_text_curr[:big], players.size )
    @cards_taken.set_resource(:coperto, get_cardsymbolimage_of(:coperto))
    @cards_taken.set_resource(:points_deck_img, @image_gfx_resource[:points_deck_img])
    @composite_graph.add_component(:cards_taken, @cards_taken)
    
    # deck
    deck_factor = 2
    real_cards_ondeck_num = get_real_numofcards_indeck_initial(players.size)
    num_gfxcards_ondeck = real_cards_ondeck_num / deck_factor
    num_gfxcards_ondeck += 1 if real_cards_ondeck_num % 2 == 1 # on odd number need to increment deck
    
    #p num_gfxcards_ondeck 
    @deck_main = DeckMainGraph.new(@app_owner, self, @font_text_curr[:small], num_gfxcards_ondeck, deck_factor )
    @deck_main.realgame_num_cards = get_real_numofcards_indeck_initial(players.size)
    @deck_main.set_resource(:card_opp_img, @image_gfx_resource[:card_opp_img])
    @composite_graph.add_component(:deck_main, @deck_main)
    
    
    # eventually add other components for inherited games
    add_components_tocompositegraph() if respond_to?(:add_components_tocompositegraph)
    
    # we have a dependence with the player gui, we need to create it first
    player_for_sud = build_player_sud(players)
    if player_for_sud
      player_for_sud.algorithm.connect(:EV_onalg_pesca_carta, method(:onalg_pesca_carta))
    end
    add_additional_eventhandlers(player_for_sud) if respond_to?(:add_additional_eventhandlers)
  
    # set players algorithm
    pos_names = [:nord]
    players.each do |player|
      player_label = player.name.to_sym
      # prepare info, an empty hash for gfx elements on the player
      @player_gfx_info[player_label] = {}
      if player.type == :cpu_local
        player.position = pos_names.pop
        # create cards gfx for the player
        @cards_players.build(player)
        player.algorithm = eval(@algorithm_name).new(player, @core_game, method(:registerTimeout))
        @opponents_list << player
        if @show_opponent_cards
          player.algorithm.connect(:EV_onalg_pesca_carta, method(:opp_onalg_pesca_carta))
          player.algorithm.connect(:EV_onalg_new_giocata, method(:opp_onalg_new_giocata))
        end
      elsif player.type == :human_local
        # already done above
      end
      # create the label for the player
      build_gfxlabel_player(player_label, player.type)
      # set the player name
      set_playername_onlabel(player)
     
      # create turn marker
      build_gfxmarker_player(player_label, player.type)
      
      # create taken cards images
      @cards_taken.build(player)
      
      # reset information about nr segni
      @segni_status[player_label] = 0
      
      @players_on_match << player
    end
    @state_gfx = :on_game
     
    # create cards on table
    @table_cards_played.build_with_info(
        {:x => {:type => :center_anchor_horiz, :offset => 0},
         :y => {:type => :center_anchor_vert, :offset => -40},
         :anchor_element => :canvas,
         :max_num_cards => 2, :intra_card_off => 0, 
         :img_coperto_sym => :coperto, :type_distr => :circular,
         :player_positions => [:nord, :sud]})
    
    # create points shower
    build_points_shower
    
    # create message box
    @msg_box_info.build(nil)
    
    # start the match
    @core_game.gui_new_match(players)
  end
  
  def get_real_numofcards_indeck_initial(num_of_players)
    return 40 -  1 - ( @core_game.num_of_cards_onhandplayer * num_of_players)
  end
  

  ##
  # Set the player name on the label
  # player: instance of PlayerOnGame
  def set_playername_onlabel(player)
    player_label = player.name.to_sym
    lbl_plname = get_player_lbl_symbol(player_label)
    @labels_to_disp[lbl_plname].text = player.name
    @labels_to_disp[lbl_plname].visible = true
  end
  
  ###
  # Load specific resource, like special image, for briscola
  def load_specific_resource
    #@log.debug "*** load_specific_resource briscola"
    # load only once
    if @image_gfx_resource.size == 0
      png_resource =  File.join(@resource_path ,"images/taken.png")
      res_sym = :points_deck_img
      
      # points
      img = FXPNGIcon.new(getApp, nil,
              IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
      FXFileStream.open(png_resource, FXStreamLoad) { |stream| img.loadPixels(stream) }
      @image_gfx_resource[res_sym] = img
      
      # sfondo tavolo
      load_table_background
      
      # opponent cards
      png_resource =  File.join(@resource_path ,"images/avvers_coperto.png")
      res_sym = :card_opp_img
      
      img = FXPNGIcon.new(getApp, nil,IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
      FXFileStream.open(png_resource, FXStreamLoad) { |stream| img.loadPixels(stream) }
      
      @image_gfx_resource[res_sym] = img
      
      # now create all resources
      @image_gfx_resource.each_value{|v| v.create}
    end
  end
  
  ##
  # Unload all specific resources. Called from base class detach
  def detach_specific_resources
    @image_gfx_resource.each_value{|v| v.detach}
  end
  
  ##
  # Build a marker for player that have to play
  def build_gfxmarker_player(player_sym, pl_type)
    color = Fox.FXRGB(255, 150, 0)
    marker_gfx_created =  TurnMarkerGfx.new(0,0, 40, 8, color, false)
    #p player_sym
    @turn_playermarker_gfx[player_sym]  = marker_gfx_created
    @player_gfx_info[player_sym][:rectturn] = marker_gfx_created
    # reset marker for player that have to play
    @turn_playermarker_gfx.each_value{|ele| ele.visible = false}
    
    # adjoust position
    resize_gfxmarker_player(player_sym, pl_type)
  end
  
  ##
  # Resize marker for player on turn
  def resize_gfxmarker_player(player_sym, pl_type)
    info_lbl = @canvas_gfx_info["#{player_sym}_label_pl".to_sym]
    y_lbl = info_lbl[:y] + 5
    x_lbl = info_lbl[:x]
    
    marker_gfx_created =  @player_gfx_info[player_sym][:rectturn] 
    marker_gfx_created.pos_x = x_lbl
    marker_gfx_created.pos_y = y_lbl
  end

  ##
  # Build points shower
  def build_points_shower()
    img = @image_gfx_resource[:notes_points_shower]
    color = Fox.FXRGB(0, 0, 0)
    # set background
    @points_image = PointsShowerGfx.new(7,10, img,0,true)
    # set teams name
    @points_image.set_name_teams(@players_on_match.first.name, 
                 @players_on_match.last.name, @font_text_curr[:big], color)
    #set tot num of segni
    segni_info = calculate_segni_info
    @points_image.set_segni_info(segni_info[:tot_segni], segni_info[:segni_pl1], 
                                 segni_info[:segni_pl2])
    
  end

  ##
  # Build a label with the player name
  # player_sym: user name as symbol
  def build_gfxlabel_player(player_sym, pl_type)
    # label username
    # prefix player string beacuse we have also other strings 
    # that need not to be confused with player name
    lbl_displ_pl = get_player_lbl_symbol(player_sym)
    color = Fox.FXRGB(0, 0, 0)
    lbl_gfx_created  =  LabelGfx.new(0,0, "", @font_text_curr[:big], color,  false)
    @labels_to_disp[lbl_displ_pl]  = lbl_gfx_created
    @player_gfx_info[player_sym][:lbl_name] = lbl_gfx_created 
    
    # label for status
    color = Fox.FXRGB(2, 10, 200)
    lbl_gfx_status  =  LabelGfx.new(0,0, "pronto", @font_text_curr[:small], color, false)
    @labels_to_disp["#{lbl_displ_pl}status".to_sym] = lbl_gfx_status
    @player_gfx_info[player_sym][:lbl_status] = lbl_gfx_status
    
    # adjust position
    resize_gfxlabel_player(player_sym, pl_type)
  end
  
  ##
  # Resize player label
  def resize_gfxlabel_player(player_sym, pl_type)
    #player name label
    x_lbl =  @model_canvas_gfx.info[:info_gfx_coord][:x_top_opp_lx]
    y_lbl =  @model_canvas_gfx.info[:info_gfx_coord][:y_top_opp_lx]
    info_deck = @model_canvas_gfx.info[:deck_gui_pl]
    
    img_coperto = get_cardsymbolimage_of(:coperto)
    xoffset = img_coperto.width + 5  
    left_pl1_card = 10
    x_lbl = info_deck[:x] + info_deck[:w] + 20
    
    if pl_type == :human_local
      x_lbl = info_deck[:x] + info_deck[:w] + 20
      y_lbl = info_deck[:y] + info_deck[:h] - 17
    end
    
    # label username
    info_hash_lbl_tmp = {:x => x_lbl, :y => y_lbl} 
    @canvas_gfx_info["#{player_sym}_label_pl".to_sym] = info_hash_lbl_tmp
    @model_canvas_gfx.info_label_player_set(player_sym, info_hash_lbl_tmp)
    # prefix player string beacuse we have also other strings 
    # that need not to be confused with player name
    lbl_displ_pl = get_player_lbl_symbol(player_sym)
    lbl_gfx_created  = @labels_to_disp[lbl_displ_pl]  
    lbl_gfx_created.pos_x = x_lbl
    lbl_gfx_created.pos_y = y_lbl
    # label for status
    y_lbl -= 20
    lbl_gfx_status  =  @player_gfx_info[player_sym][:lbl_status]
    lbl_gfx_status.pos_x = x_lbl
    lbl_gfx_status.pos_y = y_lbl
  end
  
  ##
  # Provides the symbol for a player in game to be used for generating LabelGfx
  def get_player_lbl_symbol(player_sym)
    # prefix player string beacuse we have also other strings 
    # that need not to be confused with player name
    return lbl_displ_pl = "0#{player_sym}".to_sym
  end
  
  ##
  # Provides information about segni
  def calculate_segni_info
    pl1 = @players_on_match.first
    pl2 = @players_on_match.last
    tot_segni = @core_game.game_opt[:num_segni_match]
    s1 = @segni_status[pl1.name.to_sym]
    s2 = @segni_status[pl2.name.to_sym]
    return {:tot_segni => tot_segni, :segni_pl1 => s1, :segni_pl2 => s2 }
  end
  
  def ani_card_played_end
    @log.debug("gfx: ani_card_played_end")
    registerTimeout(@option_gfx[:timeout_animation_cardtaken], :onTimeoutPlayer, self)
  end
  
  def ani_card_taken_end
    @log.debug("gfx: ani_card_taken_end")
    registerTimeout(@option_gfx[:timeout_manoend_continue], :onTimeoutManoEndContinue, self)
  end
  
  ##
  # Mano end timeout
  def onTimeoutManoEnd
    @log.debug("gfx: onTimeoutManoEnd")
    if @state_gfx == :on_game
      # prepare animation cards taken
      if @mano_end_player_taker
        @table_cards_played.all_card_played_tocardtaken2(@mano_end_player_taker) 
      end
      update_dsp
    end
  end
  
  ##
  # Now continue the game
  def onTimeoutManoEndContinue
    @log.debug("gfx: onTimeoutManoEndContinue")
    # restore event process
    @core_game.continue_process_events if @core_game
  end
  
  ##
  # Player on gui played timeout
  def onTimeoutPlayer
    @log.debug("gfx: onTimeoutPlayer")
    @core_game.continue_process_events if @core_game
  end

  def build_deck_on_newgiocata
    @log.debug "gfx: build_deck_on_newgiocata"
    @deck_main.build(nil)
    @deck_main.realgame_num_cards = 40 - 1 -  ( @core_game.num_of_cards_onhandplayer * (@players_on_match.size))  
  end
  
  def set_briscola_on_deckmain(carte_player)
    brisc_carte_pl = carte_player[@core_game.num_of_cards_onhandplayer]
    str_briscola_testo = "Briscola: #{nome_carta_ita(brisc_carte_pl)}"
    log " #{str_briscola_testo}"
    @deck_main.set_briscola(brisc_carte_pl)
    # label for briscola name
    unless @labels_to_disp[:__briscola__]
      color = Fox.FXRGB(255, 255, 255)
      lbl_gfx_briscola  =  LabelGfx.new(0,0, "", @font_text_curr[:small], color, false)
      @labels_to_disp[:__briscola__] = lbl_gfx_briscola
    end
    @labels_to_disp[:__briscola__].visible = false
    @labels_to_disp[:__briscola__].text = str_briscola_testo
    resize_gfxlabel_briscola
  end
  
  def resize_gfxlabel_briscola
    if @labels_to_disp[:__briscola__]
      y_lbl =  @model_canvas_gfx.info[:canvas][:height] - 20
      x_lbl = 20
      lbl_gfx_created  = @labels_to_disp[:__briscola__]
      lbl_gfx_created.pos_x = x_lbl
      lbl_gfx_created.pos_y = y_lbl
      #@log.debug "gfx: briscola label resized on #{lbl_gfx_created.pos_x}, #{lbl_gfx_created.pos_y}"
    end
  end

  ##
  # Shows a dilogbox for the end of the smazzata
  def show_smazzata_end(best_pl_points )
    str = "Vince il segno: #{best_pl_points.first[0]} col punteggio #{best_pl_points.first[1]} a #{best_pl_points[1][1]}"
    if best_pl_points[0][1] == best_pl_points[1][1]
      str = "Partita finita in pareggio"
    end 
    log str
   
    @msg_box_info.show_message_box("Smazzata finita", str.gsub("** ", ""))
    
  end
  
  #############################################
  #algorithm event handlers, raised by AlgCpuPlayerBase
  #############################################
  
  # opponent algorithm events
   
  def opp_onalg_pesca_carta(carte_player, algcpu_player)
    player_sym = algcpu_player.alg_player.name.to_sym
    @cards_players.set_anempty_with_image(player_sym, carte_player.first)
  end
  
  def opp_onalg_new_giocata(carte_player, algcpu_player)
    @log.debug "Opponent - new giocata, #{carte_player}"
    @cards_players.init_position_ani_distrcards
    player_sym = algcpu_player.alg_player.name.to_sym
    @cards_players.set_cards_player(player_sym, carte_player)

    check_for_start_distr_animation
  end
 
   # human algorithm events
  
  def onalg_new_match(players)
    @num_of_check_start_ani = players.size
    #p players.serialize 
    log "Nuova partita. Numero gioc: #{players.size}"
    players.each{|pl| log " Nome: #{pl.name}"}
  end

  ##
  # New giocata notification
  # carte_player: array of card as symbol (e.g :bA, :c2 ...)
  def onalg_new_giocata(carte_player, algcpu_player)
    @log.debug "Human - New giocata: #{carte_player}"
   
    # set static elements that need to be update on each giocata
    build_deck_on_newgiocata

    @cards_players.init_position_ani_distrcards
    
    @turn_playermarker_gfx.each do |k,v|
      v.visible = false
    end

    #set cards of the gui player
    player_sym = @player_on_gui[:player].name.to_sym
    @cards_players.set_cards_player(player_sym, carte_player)
    
    # last card taken state
    @cards_taken.init_state(@players_on_match)
   
    if !@show_opponent_cards
       #set cards of opponent (assume it is only one opponent)
      player_opp = @opponents_list.first.name.to_sym
      @cards_players.set_all_playercards_decked(player_opp, :card_opp_img)
    end
      
    set_briscola_on_deckmain(carte_player)

    # animation distribution cards
    @composite_graph.bring_component_on_front(:cards_players)
    
    check_for_start_distr_animation
  
    update_dsp
  end

  def check_for_start_distr_animation
    start_anim = !@show_opponent_cards
    if !start_anim
      @num_of_check_start_ani -= 1
      start_anim = @num_of_check_start_ani <= 0
    end
    if start_anim 
      @num_of_check_start_ani = @players_on_match.size
      @cards_players.start_animadistr
      # suspend core event process untill animation_cards_distr_end is called
      @core_game.suspend_proc_gevents
    end
  end
  
  ##
  # New mano
  # player: player che deve cominciare la mano
  def onalg_newmano(player) 
    @log.debug "Nuova mano. Comincia: #{player.name}"
    @player_on_gui[:mano_ix] = 0
    @mano_end_player_taker = nil
    
  end
  
  ##
  # Mano end
  # player_best: player who wons  the hand
  # carte_prese_mano: cards taken on this hand
  # punti_presi: points collectd in this hand
  def onalg_manoend(player_best, carte_prese_mano, punti_presi)
    log "Mano finita. Vinta: #{player_best.name}, punti: #{punti_presi}"
    @mano_end_player_taker = player_best
    
    # adjourn points in the view
    @cards_taken.adjourn_points(player_best, punti_presi)
    
    # last cards taken
    @cards_taken.set_lastcardstaken(player_best, carte_prese_mano)
  
    
    # start a timer to give a user a chance to see the end
    registerTimeout(@option_gfx[:timeout_manoend], :onTimeoutManoEnd, self)
    
    # suspend core event process untill timeout
    @core_game.suspend_proc_gevents
    
  end
   
  ##
  # Player has pick a card from deck
  # carte_player: array of card picked
  def onalg_pesca_carta(carte_player, algcpu_player)
    #expect only one card
    log "Carta pescata: [#{nome_carta_ita(carte_player.first)}]"
    #search the first free card on player gui
    player_sym = @player_on_gui[:player].name.to_sym
    @cards_players.set_anempty_with_image(player_sym, carte_player.first)
    
    if !@show_opponent_cards
      # opponent card, simulate on the gui that he has also picked a card
      player_opp_sym = @opponents_list.first.name.to_sym
      @cards_players.set_anempty_with_deck(player_opp_sym, :card_opp_img)
    end
    
    # reduce deck on 1 cards because we display only an half deck
    @deck_main.pop_cards(1)
    @deck_main.realgame_num_cards -= @players_on_match.size
    if @deck_main.realgame_num_cards <= 0
      @labels_to_disp[:__briscola__].visible = true
    end
   
    update_dsp
  end
  
  ##
  # Giocata end notification
  # best_pl_points: array of couple name->points sorted by max points
  # e.g. [["rudy", 45], ["zorro", 33]]
  def onalg_giocataend(best_pl_points)
    winner = best_pl_points.first
    loser =  best_pl_points[1]
   
    if winner[1] >= @core_game.game_opt[:target_points_segno]
      @segni_status[winner[0].to_sym] += 1
    end
    segni_info = calculate_segni_info
    @points_image.set_segni_info(segni_info[:tot_segni], segni_info[:segni_pl1], 
                                 segni_info[:segni_pl2])
    
    
    show_smazzata_end(best_pl_points )
    update_dsp
    
    # continue the game
    @core_game.gui_new_segno
  end
  
  ##
  # Match end notification
  # best_pl_segni: array of pairs name->segni
  # e.g [["rudy", 4], ["zorro", 1]]
  def onalg_game_end(best_pl_segni)
    winner = best_pl_segni.first
    loser =  best_pl_segni[1]
    str = "Vince la partita: #{winner[0]}\n" 
    str += "#{winner[0]} punti #{winner[1]}\n"
    if loser[1] == -1
      str += "#{loser[0]} abbandona"
    else
      str += "#{loser[0]} punti #{loser[1]}"
    end 
    log str
    @msg_box_info.show_message_box("Partita finita", str, false)
    
    game_end_stuff
  end
  
  ##
  # Player have to play
  # player: player that have to play
  def onalg_have_to_play(player)
    decl_str = ""
    if player == @player_on_gui[:player]
      @log.debug("player #{player.name} have to play")
      #@app_owner.free_all_btcmd()
    end
    # mark player that have to play
    player_sym = player.name.to_sym
    @turn_playermarker_gfx[player_sym].visible = true
    
    log "Tocca a: #{player.name}"
    if player == @player_on_gui[:player]
      @player_on_gui[:can_play] = true
    else
      @player_on_gui[:can_play] = false
    end
    update_dsp
  end
 
  ##
  # Player has played a card not allowed
  def onalg_player_cardsnot_allowed(player, cards)
    lbl_card = cards[0]
    log "#{player.name} ha giocato una carta non valida [#{nome_carta_ita(lbl_card)}]"
    @player_on_gui[:can_play] = true
    player_sym = player.name.to_sym
    @cards_players.set_anempty_with_image(player_sym, lbl_card)
    @table_cards_played.rollback_card_played(player.position, lbl_card)
  end
  
  ##
  # Player has played a card
  # lbl_card: label of card played
  # player: player that have played
  def onalg_player_has_played(player, lbl_card)
    @log.debug("onalg_player_has_played: #{player.name}, #{lbl_card}")
    
    # check card on player hand
    player_sym = player.name.to_sym
    @turn_playermarker_gfx[player_sym].visible = false
      
    # check if it was gui player
    if @player_on_gui[:player] == player
      @log.debug "Carta giocata correttamente #{lbl_card}"  
      @player_on_gui[:can_play] = false
      start_guiplayer_card_played_animation( @player_on_gui[:player], lbl_card)
      @core_game.suspend_proc_gevents
      # nothing to do until animation end
      return
    end
    
    # opponent player cards
    if !@show_opponent_cards
      @cards_players.card_invisible_rnd_decked(player_sym)
    else
      @cards_players.card_invisible(player_sym, lbl_card)
    end
    @sound_manager.play_sound(:play_click4)
    
    z_ord = get_zord_ofcardplayed
    init_x = @cards_players.last_cardset_info[:pos_x]
    init_y = @cards_players.last_cardset_info[:pos_y]
    @table_cards_played.card_is_played2_incirc(lbl_card, player.position, z_ord, init_x,  init_y)
    
    # update index of mano
    @player_on_gui[:mano_ix] += 1
    update_dsp
    
    @core_game.suspend_proc_gevents
    
    # here is not better to insert a delay, beacuse we make the player turn slow
    # Delay is better on mano end and when opponent is on turn
    ## little delay to process other events to give time to look the card played
   
  end
  
end #end BriscolaGfx

##############################################################################
##############################################################################

if $0 == __FILE__
  # test this gfx
  require '../../../test/test_canvas'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  
  theApp = FXApp.new("TestCanvas", "FXRuby")
  testCanvas = TestCanvas.new(theApp)
  testCanvas.set_position(0,0,800,630)
  
  # start game using a custom deck
  #deck =  RandomManager.new
  #deck.set_predefined_deck('_Ab,_2c,_Ad,_Ac,_5b,_7b,_3c,_2d,_Rb,_3b,_5s,_2s,_3d,_5d,_Cd,_5c,_As,_Fs,_Fc,_Rc,_Fd,_2b,_4s,_Cb,_6b,_3s,_Rd,_6s,_4c,_6c,_7c,_4d,_Cc,_Fb,_Cs,_7s,_4b,_7d,_Rs,_6d',1)
  #testCanvas.set_custom_deck(deck)
  # end test a custom deck
  
  #testCanvas.app_settings["autoplayer"][:auto_gfx] = true
  testCanvas.app_settings["all_games"][:cards_opponent] = true
  
  theApp.create()
  players = []
  players << PlayerOnGame.new('me', nil, :human_local, 0)
  players << PlayerOnGame.new('cpu', nil, :cpu_local, 1)
  
  testCanvas.init_gfx(BriscolaGfx, players)
  gfx = testCanvas.current_game_gfx
  testCanvas.start_new_game

  theApp.run
end



 

