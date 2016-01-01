#cuperativa_gui.rb
# Startup file GUI application cuperativa client
# Start file 

$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'fileutils'

require 'fox16'
require 'log4r'
require 'yaml'


require 'gfx/gfx_general/base_engine_gfx'
require 'options/cuperat_options_dlg'
require 'gfx/gfx_general/listgames_dlg'
require 'gfx/gfx_general/about_dlg'
require 'core/info_available_games'
require 'gfx/gfx_general/cup_single_game_win'
require 'gfx/gfx_general/modal_msg_box'
require 'core/sound_manager'
require 'gfx/gfx_general/resource_info'

# other method could be inspect the  Object::PLATFORM or RUBY_PLATFORM
$g_os_type = :win32_system
begin
  require 'win32/sound'
  include Win32
rescue LoadError
  $g_os_type = :linux
  $VERBOSE = nil
end

include Log4r
include Fox

# scommenta le 3 linee seguenti per un debug usando la console
#require 'ruby-debug' # funziona con 0.9.3, con la versione 0.1.0 no
#Debugger.start
#debugger
## oppure per usare rudebug (ma non va)
#Debugger.wait_connection = true
#Debugger.start_remote


#publish a new game <mynewgame>:
# 1) create a new gfx class, core, alg in the sub directory games
# 2) Crea un file yaml game_info.yaml per il nuovo gioco
# 4) ? implement the init function delcared in yaml game_info.yaml (maybe, init_local_game should do it for all)
# 5) modifica il server
# 5.a) In cup_serv_core aggiungi un require nalgames/mynewgame
# 5.b) In cup_serv_core aggiungi il nuovo hash in @@games_available
# 5.c) Crea il file NalServer.... <mynewgame>

##
# Class for a fox gui Cuperativa 
class CuperativaGui < FXMainWindow
  attr_accessor :giochimenu, :settings_filename, :icons_app, :app_settings, :sound_manager
  attr_accessor :restart_need, :corelogger, :last_selected_gametype, :main_app
  
  
  include ModalMessageBox
  
  # aplication name
  APP_CUPERATIVA_NAME = "Cuperativa"
  # version string (if you change format, spaces points..., chenge also parser)
  VER_PRG_STR = "Ver 1.2.8 01012016"
  # yaml version, useful for restoring old version
  CUP_YAML_FILE_VERSION = '6.20'   # to be changed only when SETTINGS_DEFAULT_APPGUI structure is changed            
  # settings file
  FILE_APP_SETTINGS = "app_options.yaml"
  # logger mode
  LOGGER_MODE_FILE = "log_mode.yaml"
  LOGGER_MODE_FILE_VERSION = '1.1'
  
  # NOTE: changes on this structure (not value) also need a change  in versionyaml
  #       otherwise it could happens that after an update we load a yaml file with
  #       an incorrect layout
  SETTINGS_DEFAULT_APPGUI = { "guigfx" =>{ :ww_mainwin => 800,
                                           :hh_mainwin => 520,
                                           :splitter => 0,
                                           :splitter_horiz => 0}, 
                              "deck_name" => :piac,   # note:
                              "versionyaml" => CUP_YAML_FILE_VERSION, # change this version 
                                                      #if you change SETTINGS_DEFAULT_APPGUI
                              "curr_game" => :briscola_game, 
                              "players" => [
                                  {:name => "Toro", :type => :human_local },  #1
                                  {:name => "Gino B.", :type => :cpu_local }, #2
                                  {:name => "Galu", :type => :cpu_local },    #3
                                  {:name => "Svarz", :type => :cpu_local },   #4
                                  {:name => "Piopa", :type => :cpu_local },   #5
                                  {:name => "Mario", :type => :cpu_local },   #6
                                  {:name => "Mino", :type => :cpu_local },    #7
                                  {:name => "Ricu", :type => :cpu_local },    #8
                                  {:name => "Torace", :type => :cpu_local },  #9
                                  {:name => "Miliu", :type => :cpu_local },    #10
                                  {:name => "Cavallin", :type => :cpu_local }    #11
                                  ],
                              "autoplayer" =>{
                                :auto_gfx => false,
                                :auto_gamename_gfx => :mariazza_game ,
                              },
                              "cpualgo" => {:predefined => false, :saved_game => '', :giocata_num => 0, :player_name => '' },
                              "sound" => {:play_intro_netwgamestart => true, :use_sound_ongame => true},
                              "games" => {
                                  :briscola_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 541},
                                  :mariazza_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 541},
                                  :scopetta_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 590},
                                  :spazzino_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 590},
                                  :tombolon_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 590},
                                  :scacchi_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 541},
                                  :briscolone_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 541},
                                  :tressette_game =>
                                  { :ww_mainwin => 997, :hh_mainwin => 701, :splitter => 544, :jump_distr_cards => false},
                                  :briscola5_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 541},
                              },
  }
  
  
   
  ##
  # Init controls
  def initialize(anApp)
    super(anApp, APP_CUPERATIVA_NAME, nil, nil, DECOR_ALL, 30, 20, 640, 480)
    @main_app = anApp 
    @app_settings = {}
    @log = Log4r::Logger.new("coregame_log")
    appdata_dir = ResourceInfo.get_dir_appdata()
    @settings_filename =  File.join(appdata_dir, FILE_APP_SETTINGS)
    
    @restart_need = false
  
    @logger_mode_filename = File.join(ResourceInfo.get_dir_appdata(), LOGGER_MODE_FILE)
    @log_detailed_info = load_log_info_from_file(@logger_mode_filename)
    @log_device_output = :default
    @log_device_output = @log_detailed_info[:shortcut][:val] if @log_detailed_info[:shortcut][:is_set]
    
    # don't use stdout because dos popup in windows is not pretty
    mylogfname = "cuperativa_app#{Time.now.strftime("%Y_%m_%d_%H_%M_%S")}.log" 
    curr_day = Time.now.strftime("%Y_%m_%d")
    log_base_dir_set = @log_detailed_info[:base_dir_log]
    base_dir_log = "#{log_base_dir_set}/#{curr_day}"
    FileUtils.mkdir_p(base_dir_log)
    
    if @log_device_output == :debug
      @log.outputters << Outputter.stdout
      ## nei miei test voglio un log anche sul file
      out_log_name = File.join(base_dir_log,  mylogfname )
      FileOutputter.new('coregame_log', :filename=> out_log_name) 
      Logger['coregame_log'].add 'coregame_log'
    elsif @log_device_output == :nothing
      @log.outputters.clear
    elsif @log_device_output == :default
      out_log_name = File.join(base_dir_log,  mylogfname )
      Log4r::Logger['coregame_log'].level = INFO
      FileOutputter.new('coregame_log', :filename=> out_log_name) 
      Log4r::Logger['coregame_log'].add 'coregame_log'
    end
    @log.debug "App data is #{appdata_dir}"
    # load supported games
    @supported_game_map = {}
    load_supported_games()
    
    load_application_settings()
    
    # canvas painting event
    @canvast_update_started = false
    
    # array of button for command panel
    @game_cmd_bt_list = []
    
    # Menubar
    @menubar = FXMenuBar.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    
    @giochimenu = FXMenuPane.new(self)
    helpmenu = FXMenuPane.new(self)
    
    # Menu Giochi
    # Defined in custom menu of gfx engine
    @menu_giochi_list = FXMenuCommand.new(@giochimenu, "Lista giochi con opzioni...")
    @menu_giochi_list.connect(SEL_COMMAND, method(:mnu_game_list ))
        
    #Menu Help
    @menu_help = FXMenuCommand.new(helpmenu, "&Help")
    @menu_help.connect(SEL_COMMAND, method(:mnu_cuperativa_help))
    @menu_info = FXMenuCommand.new(helpmenu, "Sulla #{APP_CUPERATIVA_NAME}...")
    @menu_info.connect(SEL_COMMAND, method(:mnu_cuperativa_info))
    
    #@menu_test = FXMenuCommand.new(helpmenu, "Test")
    #@menu_test.connect(SEL_COMMAND, method(:mnu_cuperativa_test))
    
    # Titles on menupanels 
    FXMenuTitle.new(@menubar, "&Giochi", nil, @giochimenu)
    
    FXMenuTitle.new(@menubar, "&Info", nil, helpmenu)
    
    #incons
    @icons_app = {}
    @icons_app[:icon_app] = loadIcon("icona_asso_trasp.png")
    @icons_app[:icon_start] = loadIcon("start2.png")
    @icons_app[:icon_close] = loadIcon("stop.png")
    @icons_app[:card_ass] = loadIcon("asso_ico.png")
    @icons_app[:crea] = loadIcon("crea.png")
    @icons_app[:nomi] = loadIcon("nomi2.png")
    @icons_app[:options] = loadIcon("options2.png")
    @icons_app[:icon_network] = loadIcon("connect.png")
    @icons_app[:disconnect] = loadIcon("disconnect.png")
    @icons_app[:leave] = loadIcon("leave.png")
    @icons_app[:perde] = loadIcon("perde.png")
    @icons_app[:revenge] = loadIcon("revenge.png")
    @icons_app[:gonext] = loadIcon("go-next.png")
    @icons_app[:apply] = loadIcon("apply.png")
    @icons_app[:giocatori_sm] = loadIcon("giocatori.png")
    @icons_app[:netview_sm] = loadIcon("net_view.png")
    @icons_app[:cardgame_sm] = loadIcon("cardgame.png")
    @icons_app[:start_sm] = loadIcon("star.png")
    @icons_app[:listgames] = loadIcon("listgames.png")
    @icons_app[:info] = loadIcon("documentinfo.png")
    @icons_app[:ok] = loadIcon("ok.png")
    @icons_app[:forum] = loadIcon("forum.png")
    @icons_app[:home] = loadIcon("home.png")
    @icons_app[:mail] = loadIcon("mail.png")
    @icons_app[:help] = loadIcon("help_index.png")
    @icons_app[:lock] = loadIcon("lock.png")
    @icons_app[:rainbow] = loadIcon("rainbow.png")
    @icons_app[:icon_update] = loadIcon("update.png")
    @icons_app[:rosette] = loadIcon("rosette.png")
    @icons_app[:computer] = loadIcon("computer.png")
    @icons_app[:user] = loadIcon("user.png")
    @icons_app[:numero_uno] = loadIcon("digit_1_icon.gif")
    @icons_app[:numero_due] = loadIcon("digit_2_icon.gif")
    @icons_app[:numero_tre] = loadIcon("digit_3_icon.gif")
    @icons_app[:user_female] = loadIcon("user_female.png")
    @icons_app[:eye] = loadIcon("eye.png")
    setIcon(@icons_app[:icon_app])
    
    ###  toolbar
    FXHorizontalSeparator.new(self, SEPARATOR_GROOVE|LAYOUT_FILL_X)
    vv_main = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)
    toolbarShell = FXToolBarShell.new(self)
    toolbar = FXToolBar.new(vv_main, toolbarShell,LAYOUT_SIDE_TOP|LAYOUT_FILL_X, 0, 0, 0, 0, 3, 3, 0, 0)
    
    
    ##### Toolbar buttons
    # options button
    @btoptions= FXButton.new(toolbar, "\tOpzioni\tOptioni", @icons_app[:options], nil,0,ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED,0,0,0,0,10,10,3,3)#,0, 0, 0, 0, 10, 10, 5, 5)
    @btoptions.connect(SEL_COMMAND, method(:mnu_cuperativa_options))
    # info button
    @btinfo= FXButton.new(toolbar, "\tInfo\tInfo", @icons_app[:info], nil,0,ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED,0,0,0,0,10,10,3,3)#,0, 0, 0, 0, 10, 10, 5, 5)
    @btinfo.connect(SEL_COMMAND, method(:mnu_cuperativa_info))
    
    # try to set a label on in the midlle of the toolbar
    @lbl_table_title = FXLabel.new(toolbar, "", nil, JUSTIFY_CENTER_X|LAYOUT_FILL_X|JUSTIFY_CENTER_Y|LAYOUT_FILL_Y)
    
    ###### Toolbar end
    
    #--------------------- tabbook - start -----------------
    
    # presentation zone
    # buttons
    fullwin = FXHorizontalFrame.new(vv_main, FRAME_THICK | LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_CENTER_Y | LAYOUT_CENTER_X )
    center_vpan = FXVerticalFrame.new(fullwin, LAYOUT_FILL_X | LAYOUT_FILL_Y) #needed to separate the btdetailed_frame with uniform width and log_panel
    
    btdetailed_frame = FXVerticalFrame.new(center_vpan,  LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_CENTER_X | PACK_UNIFORM_WIDTH  )
    
 
    # local game
    @btstart_button = FXButton.new(btdetailed_frame, "Gioca", icons_app[:icon_start], self, 0,
              LAYOUT_CENTER_X | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    @btstart_button.connect(SEL_COMMAND, method(:mnu_start_offline_game))
    @btstart_button.iconPosition = (@btstart_button.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    # change game
    @btgamelist = FXButton.new(btdetailed_frame, "Setta il gioco (opzioni e tipo)", icons_app[:listgames], self, 0,
              LAYOUT_CENTER_X | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    @btgamelist.connect(SEL_COMMAND, method(:mnu_game_list))
    @btgamelist.iconPosition = (@btgamelist.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    # logger
    log_panel = FXHorizontalFrame.new(center_vpan, FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_FILL_X)
    @logText = FXText.new(log_panel, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @logText.editable = false
    @logText.backColor = Fox.FXRGB(231, 255, 231)
 
    #--------------------- tabbook - END -----------------
    
    
    # Make a tool tip
    FXToolTip.new(getApp(), TOOLTIP_NORMAL)
    
    # container of all installed gfx games
    @coll_game_gfx = {}
    
    # quit callback also when the user close the application using the window menu
    self.connect(SEL_CLOSE, method(:onCmdQuit))
    
    # last selected game type
    @last_selected_gametype = nil
    # timeout callback info hash
    @timeout_cb = {:locked => false, :queue => []}
    
    srand(Time.now.to_i)
    
    @sound_manager = SoundManager.new
    
  end #end  initialize
  
  def self.prgversion
    return VER_PRG_STR
  end
 
  ##
  # Shows username on the title
  def show_username(str_name)
    self.title =  "#{APP_CUPERATIVA_NAME} - Utente: #{str_name}" 
    #@lbl_username.text = "#{@comment_init} - Utente: #{str_name}" 
  end
  
  def show_prg_name
    self.title =  "#{APP_CUPERATIVA_NAME} - #{VER_PRG_STR}"
  end
  ##
  # Button Start game was clicked
  # start the current offline selected game
  def mnu_start_offline_game(sender, sel, ptr)
    initialize_current_gfx(@last_selected_gametype)
    create_new_singlegame_window(:offline)
  end
  
  def save_settings_in_yaml
    File.open( @settings_filename, 'w' ) do |out|
      YAML.dump( @app_settings, out )
    end
    @log.debug("Settings saved to #{@settings_filename}")
  end
  
  ##
  # game_network_type: :offline or :online
  def create_new_singlegame_window(game_network_type)
    game_info = @supported_game_map[@last_selected_gametype]
    options = {:game_network_type => game_network_type, :app_options => @app_settings,
        :game_type => @last_selected_gametype,
        :owner => self, :comment => game_info[:desc], 
        :num_of_players => game_info[:num_of_players],
        :gfx_enginename =>game_info[:class_name].to_s 
    }
    
    @singe_game_win =  CupSingleGameWin.new(options)
    @singe_game_win.create
    return @singe_game_win
  end
    
  ##
  # Load all supported games
  def load_supported_games
    @supported_game_map = InfoAvailableGames.info_supported_games(@log)
    #p @supported_game_map
    SETTINGS_DEFAULT_APPGUI[:games_opt] = {}
    @supported_game_map.each do |k, game_item|
      if game_item[:enabled] == true
        require game_item[:file_req]
        @log.debug("Game #{game_item[:name]} is enabled")
        SETTINGS_DEFAULT_APPGUI[:games_opt][k] = game_item[:opt]
      end
    end
  end #end load_supported_games
  
  ##
  # Provides info about supported game
  def get_supported_games
    return @supported_game_map
  end
 
  ##
  # Set an initial text on table
  def initial_board_text
    @lbl_table_title.text = "Gioco selezionato: "
  end
  
  ##
  # Generic funtion for gfx game initialization
  def init_local_game(game_type)
    game_info = @supported_game_map[game_type]
    @lbl_table_title.text += game_info[:name]
    @num_of_players = game_info[:num_of_players]
  end
 
    
  # Load the named icon from a file
  def loadIcon(filename)
    begin
      dirname = File.join(ResourceInfo.get_resource_path, "icons")
      filename = File.join(dirname, filename)
      icon = nil
      File.open(filename, "rb") { |f|
        if File.extname(filename) == ".png"
          icon = FXPNGIcon.new(getApp(), f.read)
        elsif File.extname(filename) == ".gif"
          icon = FXGIFIcon.new(getApp(), f.read)
        end
      }
      icon
    rescue
      raise RuntimeError, "Couldn't load icon: #{filename}"
    end
  end
 
  ##
  # Load debug info from yaml file.
  # return the shortcut mode (:debug, :default, :nothing)
  def load_log_info_from_file(fname)
    base_dir_log = File.join(ResourceInfo.get_dir_appdata(), "clientlogs")
    info_hash = {:is_set_by_user => false, 
         :stdout => false, :logfile => false,
         :base_dir_log => base_dir_log, 
         :version => LOGGER_MODE_FILE_VERSION ,
         :level => INFO, :shortcut => {:is_set => true, :val =>  :debug}}
    
    yamloptions = {}
    prop_options = {}
    yaml_need_to_be_created = true
    if File.exist?( fname )
      yamloptions = YAML::load_file(fname)
      if yamloptions.class == Hash
        if yamloptions[:version] == LOGGER_MODE_FILE_VERSION
          prop_options = yamloptions
          yaml_need_to_be_created = false
        end
      end
    end
    if yaml_need_to_be_created
      File.open( fname, 'w' ) do |out|
        YAML.dump( info_hash, out )
      end
    end
    
    log_info_detailed = {}
    info_hash.each do |k,v|
      if prop_options[k] != nil
        # use settings from yaml
        log_info_detailed[k] = prop_options[k]
      else
        # use default settings
        log_info_detailed[k] = v
      end
    end
     
    return log_info_detailed
  end
  
  def load_application_settings
    yamloptions = {}
    prop_options = {}
    yamloptions = YAML::load_file(@settings_filename) if File.exist?( @settings_filename )
    if yamloptions.class == Hash
      # check if the yaml file is up to date
      #p yamloptions["versionyaml"]
      #p SETTINGS_DEFAULT_APPGUI["versionyaml"]
      if yamloptions["versionyaml"] == SETTINGS_DEFAULT_APPGUI["versionyaml"]
        @log.debug("Yaml file is uptodate")
        prop_options = yamloptions
      else
        # una nuova versione solo per avere il default dei settings senza alcun merge
        @log.debug("Yaml file is NOT for this client version, merge default with it")
        yamloptions["versionyaml"] = SETTINGS_DEFAULT_APPGUI["versionyaml"] 
      end 
    end
    SETTINGS_DEFAULT_APPGUI.each do |k,v|
      #@log.debug("k: #{k}, v: #{ObjTos.stringify(v)}")
      # quando si arriva qui viene fatto il merge tra il contenuto di default e quello proveniente dal file
      if (v.class == Hash or v.class == Array) and prop_options[k] != nil
        @app_settings[k] = merge_options(v, prop_options[k])
        next
      end
      
      if prop_options[k] != nil
        # use settings from yaml
        @app_settings[k] = prop_options[k]
      else
        # use default settings
        @app_settings[k] = v
      end
    end
    #@log.debug("settings: #{ObjTos.stringify(@app_settings)}")
    # p @app_settings
  end
  
  def merge_options(default_settings, yamloptions)
    if default_settings.class == Array
        res = []
        if yamloptions.class == Array
            count = 0
            default_settings.each do |arr_item|
                merged_arritem = arr_item
                if yamloptions.class == Array and count < yamloptions.size
                    yaml_item = yamloptions[count]
                    merged_arritem = merge_options(arr_item, yaml_item)
                end
                #p merged_arritem
                res << merged_arritem
                count += 1
            end
        else
            res = default_settings
        end
        return res
    end
    res = {}
    default_settings.each do |k,v|
      #p k
      if yamloptions[k] != nil 
        if v.class != Hash and v.class != Array
          res[k] = yamloptions[k]
        else
          sub_key = merge_options(v, yamloptions[k])
          res[k] = sub_key 
        end 
      else
        res[k] = v
      end
    end
    return res
  end
  
  def refresh_settings
    @sound_manager.set_local_settings(@app_settings)
  end
  
  ##
  # Create the window and load initial settings
  def create
    @icons_app.each do |k,v|
      v.create
    end
    # local variables
    
    refresh_settings
       
    #splitter position
    gfxgui_settings = @app_settings['guigfx']
    
    # window size
    ww = gfxgui_settings[:ww_mainwin]
    hh = gfxgui_settings[:hh_mainwin]
    
    # continue to insert item into giochi menu
    FXMenuSeparator.new(@giochimenu)
    FXMenuCommand.new(@giochimenu, "Opzioni").connect(SEL_COMMAND, method(:mnu_cuperativa_options))
    FXMenuSeparator.new(@giochimenu)
    FXMenuCommand.new(@giochimenu, "&Esci").connect(SEL_COMMAND, method(:onCmdQuit))
    
    # Reposition window to specified x, y, w and h
    position(0, 0, ww, hh)
    
    # Create the main window and canvas
    super 
    # Show the main window
    show(PLACEMENT_SCREEN)
    
    # default game or last selected
    game_type = @app_settings["curr_game"]
    #p @supported_game_map
    # initialize only an enabled game. An enabled game is a supported game.
    # Game disabled are not in the @supported_game_map. This to avoid to build poperties and
    # custom widgets
    if @supported_game_map[game_type]
      if @supported_game_map[game_type][:enabled]
        initialize_current_gfx(game_type)
      end
    else
      # default game is not supported, initialize the first enable game
      @log.debug("Default game not enabled, look for the first enabled one")
      @supported_game_map.each do |k, game_info_h|
        game_type = k
        if game_info_h[:enabled]
          initialize_current_gfx(game_type)
          break
        end
      end
    end
    log_sometext("Benvenuta/o nella Cuperativa versione #{VER_PRG_STR}\n")
    @log.info("TheApp Create OK")  
  end
  
  def game_window_destroyed
    @log.debug "Game window is destroyed"
    @singe_game_win = nil
  end
  
  ## 
  # Set a custom deck information. Used for testing code without changing source code
  def set_custom_deck(deck_info)
    @app_settings[:custom_deck] = { :deck => deck_info }
  end
  
  ##
  # Initialize current gfx selected. Current gfx is stored
  # into application settings
  # game_type: game type label (e.g :mariazza_game)
  def initialize_current_gfx(game_type)
    @last_selected_gametype = game_type
    # reset the title
    initial_board_text
    
    ##initialize a current local game
    init_local_game(game_type)
  end
 
 
  ##
  # Select the current game from all game list
  def mnu_game_list (sender, sel, ptr)
    dlg = DlgListGames.new(self,@supported_game_map, @last_selected_gametype, @app_settings)
    if dlg.execute != 0
      k = dlg.get_activatedgame_key
      if @app_settings[:games_opt] != nil and @app_settings[:games_opt][k] != nil
        @app_settings[:games_opt][k] = dlg.get_curr_options
        @app_settings["curr_game"] = k
        @log.debug("opzioni del gioco #{k}: #{@app_settings[:games_opt][k].inspect} ")
        save_settings_in_yaml()
      end
      initialize_current_gfx(k)
      log_sometext("Attivato il gioco #{@supported_game_map[k][:name]}\n") 
    end
  end
  
  ##
  # Shows Info dialogbox
  def mnu_cuperativa_info(sender, sel, ptr)
    #CRASH___________
    dlg = DlgAbout.new(self, APP_CUPERATIVA_NAME, VER_PRG_STR)
    dlg.execute
  end
  
  #def mnu_cuperativa_test(sender, sel, ptr)
    #@net_chat_table_view.show_panel
  #end

  ##
  # Provides the help file path
  def get_help_path
    str_help_cmd = File.join(File.dirname(__FILE__), "../res/help/cuperativa.chm")
    return str_help_cmd
  end
  
  ##
  # Shows cuperativa manual
  def mnu_cuperativa_help(sender, sel, ptr)
    str_help_cmd = get_help_path
    target = File.expand_path(str_help_cmd)
    if $g_os_type == :win32_system
      target.gsub!("/", "\\")
      Thread.new{
        system "start \"test\" \"#{target}\""
      }
    else
      LanciaApp::Browser.run(str_help_cmd)
    end
  end
  
  ##
  # Shows options menu
  def mnu_cuperativa_options(sender, sel, ptr)
    dlg = CuperatOptionsDlg.new(self, @app_settings)
    dlg.execute
    refresh_settings
  end
  
  ##
  # Provides an array of integer parsing the string VER_PRG_STR
  # Expect similar to :VER_PRG_STR = "Ver 0.5.4 14042008"  
  def self.sw_version_to_int
    arr_str =  VER_PRG_STR.split(" ")
    ver_arr = arr_str[1].split(".")
    ver_arr.collect!{|x| x.to_i}
    return ver_arr
  end
  
  ##
  # Provides name of program and software version
  def get_nameprog_swversion
    nomeprog = APP_CUPERATIVA_NAME
    ver_prog = CuperativaGui.sw_version_to_int
    return nomeprog, ver_prog
  end
   
  ##
  # Quit the application
  def onCmdQuit(sender, sel, ptr)
    
    #p self.methods
    begin
      @log.debug("onCmdQuit is called")
    rescue
    end
    @app_settings['guigfx'][:ww_mainwin] = self.width
    @app_settings['guigfx'][:hh_mainwin] = self.height
   
    
    @app_settings["curr_game"] = @last_selected_gametype
   
    # avoid write test code options
    @app_settings[:custom_deck] = nil
    # yaml file version
    @app_settings["versionyaml"] = CUP_YAML_FILE_VERSION
    
    save_settings_in_yaml()

    getApp().exit(0)
  end
  
  def log_sometext(msg)
    logCtrl = @logText
    log_msg_onctrl(msg, logCtrl)
  end
  
  def log_msg_onctrl(msg, logCtrl)
    if(logCtrl)
      logCtrl.text += msg
      logCtrl.makePositionVisible(logCtrl.rowStart(logCtrl.getLength))
    end
  end

end


if $0 == __FILE__
  theApp = FXApp.new("CuperativaGui", "FXRuby")
  mainwindow = CuperativaGui.new(theApp)
  Log4r::Logger['coregame_log'].level = DEBUG
  if ARGV.size > 0
    nome = ARGV[0]
    mainwindow.login_name = nome
  end
  # test target, need always stdoutput
  #mainwindow.corelogger.outputters << Outputter.stdout 
  # start game using a custom deck
  #deck =  RandomManager.new
  #deck.set_predefined_deck('_6b,_Rc,_5d,_5s,_Rb,_7b,_5b,_As,_7c,_4b,_2b,_Cc,_Fc,_Cs,_4d,_Rs,_Rd,_Cb,_Ab,_2c,_Fs,_3b,_Fd,_Ad,_Ac,_3d,_6s,_6c,_7d,_2d,_2s,_6d,_3s,_Fb,_Cd,_4s,_7s,_4c,_3c,_5c',0)
  #mainwindow.set_custom_deck(deck)
  # end test a custom deck
    
  # Handle interrupts to terminate program gracefully
  theApp.addSignal("SIGINT", mainwindow.method(:onCmdQuit))

  theApp.create
  
  theApp.run
  # scommenta questa parte se vuoi avere un log quando applicazione crash
  #begin
    #theApp.run
  #rescue => detail
    #err_name = Time.now.strftime("%Y_%m_%d_%H_%M_%S")
    #fname = File.join(File.dirname(__FILE__), "err_app_#{err_name}.log")
    #File.open(fname, 'w') do |out|
      #out << "Program aborted on #{$!} \n"
      #out << detail.backtrace.join("\n")
    #end
  #end
end
