# base_engine_gfx.rb
# Generic class for each game grafic engine
$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__)+ '/..'
$:.unshift File.dirname(__FILE__)+ '/../..'

require 'rubygems'
require 'gfx_comp/graphical_composite'
require 'core/deck_info'
require 'yaml'
require 'inv_controls/inv_widget'
require 'core/resource_info'

##
# Graphic related to a generic card game
class BaseEngineGfx < InvWidget
  attr_accessor :color_backround, :curr_canvas_info
  attr_reader :nal_client_gfx_name, :model_canvas_gfx
  
  SYMBIMAGE_CARD = {
    :coperto => {:ix => 0, :nome => 'mazzo coperto'},
    :zero => {:ix => 1, :nome => 'mazzo vuoto con lo zero'},
    :xxxx => {:ix => 2, :nome => 'mazzo vuoto con la X'},
    :vuoto => {:ix => 3, :nome => 'mazzo vuoto'}
  }
  ##
  # wnd: windows owner
  def initialize(wnd)
    begin
    super(0,0, 100, 100, 1000)
    @app_owner = wnd
    @resource_path = ResourceInfo.get_resource_path
    @color_backround = Fox.FXRGB(255, 255, 255) #dummy color
    # deck information
    @deck_information = GamesDeckInfo.new
    @nomi_simboli = CoreGameBase.nomi_simboli
    @nomi_semi =  CoreGameBase.nomi_semi
    @current_deck_type = ""
    @cards = []
    @cards_rotated = []
    @symbols_card = []
    # graphic engine state
    @state_gfx = :on_splash
    # holds symbols tobe used in send for children callbacks
    @graphic_handler = {}
    
    # text font
    @font_text_curr = {}
    @font_text_curr[:big] = FXFont.new(getApp(), "arial", 14, FONTWEIGHT_BOLD)
    @font_text_curr[:small] = FXFont.new(getApp(), "arial", 10)
    @font_text_curr[:medium] = FXFont.new(getApp(), "arial", 12)
    @font_text_curr.each_value{|e| e.create}
    
    @color_text_label = Fox.FXRGB(0, 0, 0)
    # hash with key the user_name and value the class LabelGfx 
    @labels_to_disp = {}
    # logger for debug
    @log = Log4r::Logger.new("coregame_log::BaseEngineGfx") 
    # nal client gfx class name
    @nal_client_gfx_name = 'NalClientGfx'
    # rotated deck also
    @using_rotated_card = true
    # french cards 
    @deck_france = false
    # resource hash
    @image_gfx_resource = {}
    # options
    @option_gfx = { 
      :timeout_msgbox => 3000,
      :autoplayer_gfx => false,
      :autoplayer_gfx_nomsgbox => false
    }
    # extra frame near to the canvas
    @extra_frame = nil
    # scaled cards
    @cards_scaled = {}
    # scaled card info. expect something like {:lblname => {:w => width, :h => height}}
    @cards_scaled_info = {}
    # information about canvas
    @model_canvas_gfx = ModelCanvasGfx.new
    # sound manager
    @sound_manager = @app_owner.sound_manager
    #mouse events from container
    map_container_callbacks(:CB_LMouseDown, method(:onLMouseDown))
  rescue => detail
    @log.error "base gfx error (#{$!})"
    @log.error detail.backtrace.join("\n")
  end
  end
  
  def game_end_stuff
    
  end
  
  ##
  # Set information about the scaled card collection
  def set_scaled_info(lbl, width, height)
    @cards_scaled_info[lbl] = {:w => width, :h => height}
  end
  
  def deactivate_game
    if @extra_frame
      @extra_frame.hide
    end
  end
  
  ##
  # Draw the widget
  # dc: Canvas to draw
  # theme: current theme
  # width: canvas width
  # height: canvas height
  def draw(dc, theme, width, height)
    meth_handl = @graphic_handler[@state_gfx]
    send(meth_handl, dc, width, height) if meth_handl
  end
  
  ##
  # Provides card name in italian
  def nome_carta_ita(lbl_card)
    return @deck_information.nome_carta_completo(lbl_card)
  end
  
  ##
  # Provides a resource
  # res_symb: symbolic resource to find
  def get_resource_img(res_symb)
    res = @image_gfx_resource[res_symb]
    unless res
      res = get_cardsymbolimage_of(res_symb)
    end
    return res
  end
  
  ##
  # Carica il mazzo delle carte da gioco
  # folder: subfolder name
  def load_cards(folder)
    num_cards_onsuit = 10
    card_fname = ""
    if @deck_france
      num_cards_onsuit = 13
      @nomi_simboli = ['simbo', 'simbo', 'simbo' ]
      @nomi_semi = ["fiori", "quadr", "cuori", "picch"]
    end
    @log.debug "Load cards in #{folder}, current deck is #{@current_deck_type}"  
    if @current_deck_type == folder
      @log.debug "Avoid to load a new card deck"
      return
    end 
    begin
      # Il modo di caricare le immagini con una linea l'ho copiato dall'esempio FxGui dctest.rb
      # In quell'esempio l'immagine png era gi� trasperente di per se. Non dimenticare di chiamare create prima di usare drawimage
      # dctest.rb � un esempio fake, in quanto l'immagine viene riprodotta col suo background originale bianco, che � anche lo sfondo del canvas
      # Per rendere l'immmagine veramente trasparente bisogna usare il metodo blend prima di create
      @cards = []
      @cards_rotated = []
      folder_fullpath = File.join(@resource_path, "carte/#{folder}")
      deck_info_yaml = File.join(folder_fullpath, 'mazzo_info')
      if File.exist?(deck_info_yaml)
        opt_deck = YAML::load_file( deck_info_yaml )
        if opt_deck[:num_carte] != nil
          num_cards_onsuit = opt_deck[:num_carte] / 4
        end 
      end
      folder = folder_fullpath.strip
      @foldercards_fullpath = folder
      @log.debug "Load all cards..."
      if num_cards_onsuit == 13
        # abbiamo un mazzo da 52 carte, bisogna aggiustare i simboli
        @deck_information.mazzo52
      else
        @deck_information.mazzo40
      end
      4.times do |seed| 
        (1..num_cards_onsuit).each do |index|
          card_fname = File.join(folder, "%02d_#{@nomi_semi[seed]}.png" % index)
          #img = FXPNGImage.new(getApp(), nil, IMAGE_KEEP|IMAGE_ALPHACOLOR)
          #img = FXPNGIcon.new(getApp(), nil, Fox.FXRGB(0, 128, 0), IMAGE_KEEP|IMAGE_ALPHACOLOR )
          #img = FXPNGIcon.new(getApp, File.open(card_fname).read,
          #                     IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
          img = FXPNGIcon.new(getApp, nil,
                               IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
          FXFileStream.open(card_fname, FXStreamLoad) { |stream| img.loadPixels(stream) }
          #p card_fname
          #p img.hasAlpha?
          #p img.transparentColor
          #img.blend(@color_backround) # molto importante, altrimenti le immagini pgn trasparenti non vengono affatto riprodotte come tali
          #@cards <<  FXPNGImage.new(getApp(), File.open(card_fname, "rb").read)
          @cards << img
          
          #rotated image
          if @using_rotated_card
            #img_rotated = FXPNGIcon.new(getApp(), nil, Fox.FXRGB(0, 128, 0), IMAGE_KEEP|IMAGE_ALPHACOLOR )
            #FXFileStream.open(card_fname, FXStreamLoad) { |stream| img_rotated.loadPixels(stream) }
            #img_rotated.blend(@color_backround)
            img_rotated = FXPNGIcon.new(getApp, nil, IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
            FXFileStream.open(card_fname, FXStreamLoad) { |stream| img_rotated.loadPixels(stream) }
            img_rotated.rotate 90
            @cards_rotated << img_rotated
          end
        end
      end
    
      #symbols
      @symbols_card = []
      @log.debug "Load all symbols..."
      num_of_symbols = @nomi_simboli.size
      num_of_symbols.times do |seed| 
        card_fname = File.join(folder, "%02d_#{@nomi_simboli[seed]}.png" % 1)
        #img = FXPNGIcon.new(getApp(), nil, Fox.FXRGB(0, 128, 0), IMAGE_KEEP|IMAGE_ALPHACOLOR )
        #FXFileStream.open(card_fname, FXStreamLoad) { |stream| img.loadPixels(stream) }
        #img.blend(@color_backround) # molto importante, altrimenti le immagini pgn trasparenti non vengono affatto riprodotte come tali
        # invece blend non e' alpha color, basta caricare il ogn trasparente in questo modo
        # poi bisogna disegnare la carta usando drawicon
        img = FXPNGIcon.new(getApp, nil,
              IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
        FXFileStream.open(card_fname, FXStreamLoad) { |stream| img.loadPixels(stream) }
        #p img
        @symbols_card << img
      end
    
      # create cards
      create_cards
      # store the value of deck to avoid double load
      @current_deck_type = folder
    rescue
      str = "Errore nel caricare l'immagine delle carte: #{$!}\n"
      str += "Mazzo subdir utilizzato: #{folder}\n"
      str +=  "File: #{card_fname}\n"
      str += "Controllare l'opzione \"deck_name\" e che la subdir del mazzo siano corrette\n"
      @log.error str
      log_critical_error str
    end
  end
  
  def load_table_background
    img = FXPNGIcon.new(getApp, nil,
              IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
    FXFileStream.open(File.join(@resource_path ,"images/table/table.png"), FXStreamLoad) { |stream| img.loadPixels(stream) }
    if @model_canvas_gfx.info[:canvas] and
       @model_canvas_gfx.info[:canvas][:width] and
       @model_canvas_gfx.info[:canvas][:height]
      img.scale(@model_canvas_gfx.info[:canvas][:width],  @model_canvas_gfx.info[:canvas][:height], 1 )
    end
    @image_gfx_resource[:sfondo_tavolo] = img      
  end
  
  ##
  # Load and create a scaled image image
  def load_create_scaled_img(scale_lbl, lbl)
    unless @cards_scaled_info[scale_lbl]
      @log.error "Scaled information not set, unable to load card"
      return
    end
    card_width = @cards_scaled_info[scale_lbl][:w]
    card_height = @cards_scaled_info[scale_lbl][:h]
    
    name = get_cardfname_of(lbl)
    @log.debug "Load image of card #{lbl}, filename #{name}"
    card_fname = File.join(@foldercards_fullpath, name)
    img = FXPNGIcon.new(getApp, nil,
                            IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
    FXFileStream.open(card_fname, FXStreamLoad) { |stream| img.loadPixels(stream) }
    img.scale(card_width, card_height, 1 )
      
    img.create
    return img
  end
  
  ##
  # Provides the card resource filename.
  # lbl: card label,e.g :_Ab
  def get_cardfname_of(lbl)
    card_info = @deck_information.get_card_info(lbl)
    unless card_info 
      @log.error "Card filename not found on #{lbl}"
      return
    end
    position = card_info[:pos] 
    seed = card_info[:seed_ix]
    res = "%02d_#{@nomi_semi[seed]}.png" % position
    return res
  end
  
  ##
  # Create a screen that wait for the game begin
  def create_wait_for_play_screen
    @log.error "create_wait_for_play_screen: not implemented\n"
  end
  
  def onLMouseDown(x,y)
    @composite_graph.on_mouse_lclick(x,y) if @composite_graph
  end
  
  ##
  # Animation for card distribution is terminated
  def animation_cards_distr_end
    @log.debug "END Animation distrubite cards"
    @composite_graph.bring_component_on_front(nil)
    @core_game.continue_process_events if @core_game
  end
  
  def do_core_process
    #@core_game.process_next_gevent if @core_game
    @core_game.process_only_one_gevent if @core_game
  end
  
  
  def player_leave(user_name)
    @log.error "player_leave should be implemented on GFX\n"
  end
  
  ##
  # Provides the card image using label definition
  def get_card_image_of(lbl)
    index = get_card_index(lbl) 
    return @cards[index]
  end
  
  def get_card_imagerotated_of(lbl)
    index = get_card_index(lbl) 
    return @cards_rotated[index]
  end
  
  def get_card_index(lbl)
    card_info = @deck_information.get_card_info(lbl)
    index = 0 
    if card_info
      index = card_info[:ix]
    else
      @log.warn "Card info on #{lbl} not found"
    end 
    return index
  end
  
  ##
  # Provide a scaled image. scale_lbl is the label for the scale information.
  # If an image is not found in the scaled array, it is load and created.
  def get_card_imagescaled_of(scale_lbl,lbl)
    unless @cards_scaled_info[scale_lbl]
      @log.warn("get_card_imagescaled_of no scale inforrmation found")
      return get_card_image_of(lbl)
    end
    unless @cards_scaled[scale_lbl]
      # intialize hash to store all reduced cards. Use the card label to get it.
      @cards_scaled[scale_lbl] = {}
    end
    unless @cards_scaled[scale_lbl][lbl]
      # first time that this scaled image is accessed, create it
      @cards_scaled[scale_lbl][lbl] = load_create_scaled_img(scale_lbl, lbl)
    end
    return @cards_scaled[scale_lbl][lbl]
  end
  
  ##
  # Provides the card symbol image using label definition
  def get_cardsymbolimage_of(lbl)
    index = 0
    index = SYMBIMAGE_CARD[lbl][:ix] if SYMBIMAGE_CARD[lbl]
    return @symbols_card[index]
  end
  
  ##
  # Canvas is going to be detached
  def detach
    @cards.each{|e| e.detach}
    @symbols_card.each{|e| e.detach}
    @cards_rotated.each{|e| e.detach}
    detach_specific_resources
  end
  
  ##
  # Create images after loading
  def create_cards
    @cards.each{|e| e.create}
    @symbols_card.each{|e| e.create}
    @cards_rotated.each{|e| e.create}
  end
  
  def getApp()
    @app_owner.getApp()
  end
  
  ##
  # Start a  game
  # players: array  of players. Players are instance of PlayerOnGame
  # options: hash with game options
  def start_new_game(players, options)
    # load cards
    #p options
    deck_name = options["deck_name"].to_s
    if @deck_france
      # we have to use the france deck 
      deck_name = 'francesi'
    end
    load_cards(deck_name)
    
    #call custom game implementation on child view
    ntfy_base_gui_start_new_game(players, options)
    
    update_dsp
  end
  
  def log(str)
    @log.debug(str)
  end
  
  ##
  # Log a critical error message. This is usually an exit error condition
  def log_critical_error(str)
    @app_owner.mycritical_error(str)
  end
  
  def draw_with_texture_img(dc, img_teil, width, height)
    x = 0
    y = 0
    while y <  height
      while x <  width
        dc.drawImage(img_teil, x, y)
        x  += img_teil.width
        #p x,y
      end
      y  += img_teil.height
      x = 0
      #p "y = #{y}"
    end
  end
  
  
  ##
  # Create the core instance
  def create_instance_core
    return eval(@core_name_class).new
  end
  
  ##
  # Initialize a new core game. This depends which option is defined
  def init_core_game(options)
    if options[:netowk_core_game]
      # we are on network game, use NAL class for core game
      @core_game = options[:netowk_core_game]
      @core_game.set_custom_core( create_instance_core() )
      @core_game.custom_core.create_deck
      @log.debug "using network  core game"
    elsif  options[:custom_deck]
      @core_game = create_instance_core()
      @log.debug "using local cpu core CUSTOM deck"
      @core_game.rnd_mgr = options[:custom_deck][:deck]
      # say to the core we need to use a custom deck
      @core_game.game_opt[:replay_game] = true 
    else
      # local game
      @core_game = create_instance_core()
      @core_game.set_specific_options(options)
      @log.debug "using local cpu core"
      @mnu_salva_part.enable if @mnu_salva_part
    end
  end
  
  def update_dsp
    fire_event(:EV_update, self)
  end
  
  def point_is_inside?(x,y)
    true
  end
end 








