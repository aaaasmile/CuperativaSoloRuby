#cuperativa_gui.rb
# Startup file GUI application cuperativa client
# Start file 

$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'fileutils'

require 'fox16'
require 'log4r'
require 'singleton' 
require 'socket'
require 'yaml'


require 'base/gfx_general/base_engine_gfx'
require 'base/options/cuperat_options_dlg'
require 'base/gfx_general/listgames_dlg'
require 'base/gfx_general/about_dlg'
require 'base/core/gameavail_hlp'
require 'base/gfx_general/gfx_gamewindow'
require 'base/gfx_general/modal_msg_box'
require 'base/core/sound_manager'
require 'base/gfx_general/swupdate_dlg'

# other method could be inspect the  Object::PLATFORM or RUBY_PLATFORM
$g_os_type = :win32_system
begin
  require 'win32/sound'
  include Win32
rescue LoadError
  $g_os_type = :linux
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
  attr_accessor :restart_need, :corelogger, :last_selected_gametype, :banned_words, :main_app
  
  
  include ModalMessageBox
  
  # aplication name
  APP_CUPERATIVA_NAME = "Cuperativa"
  # version string (if you change format, spaces points..., chenge also parser)
  VER_PRG_STR = "Ver 1.0.1 14122015"
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
                                           :splitter_log_network => 358,
                                           :splitter_network => 138,
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
  
  def self.get_dir_appdata
    if $g_os_type == :win32_system
      puts "We are on windows"
	    res = File.join(ENV['APPDATA'], "cuperativa")
	  else
		  puts "We are on linux"
		  res = "~/.cuperativa"
	  end
	  if !File.directory?(res)
		  Dir.mkdir(res)
	  end
		
 	  return res
	end
 
  ##
  # Init controls
  def initialize(anApp)
    super(anApp, APP_CUPERATIVA_NAME, nil, nil, DECOR_ALL, 30, 20, 640, 480)
    @main_app = anApp 
    @app_settings = {}
    @settings_filename =  File.join(CuperativaGui.get_dir_appdata(), FILE_APP_SETTINGS)
    # initialize logger
    @log = Log4r::Logger.new("coregame_log")
    # restart needed flag
    @restart_need = false
  
    @logger_mode_filename = File.join(CuperativaGui.get_dir_appdata(), LOGGER_MODE_FILE)
    @log_detailed_info = load_loginfo_from_file(@logger_mode_filename)
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
      #out_log_name = File.expand_path(File.dirname(__FILE__) + "/../../#{mylogfname}")
      Log4r::Logger['coregame_log'].level = INFO
      FileOutputter.new('coregame_log', :filename=> out_log_name) 
      Log4r::Logger['coregame_log'].add 'coregame_log'
    end
    
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
    @updatemenu = FXMenuPane.new(self)
    helpmenu = FXMenuPane.new(self)
    
    # Menu Giochi
    # Defined in custom menu of gfx engine
    @menu_giochi_list = FXMenuCommand.new(@giochimenu, "Lista giochi...")
    @menu_giochi_list.connect(SEL_COMMAND, method(:mnu_giochi_list ))
    @menu_giochi_save = FXMenuCommand.new(@giochimenu, "Salva Partita")
    @menu_giochi_save.connect(SEL_COMMAND, method(:mnu_giochi_savegame ))
    @menu_giochi_end = FXMenuCommand.new(@giochimenu, "Fine Partita")
    @menu_giochi_end.connect(SEL_COMMAND, method(:mnu_maingui_fine_part ))
      
    # Menu Update 
    @menu_update_patch = FXMenuCommand.new(@updatemenu, "Applica nuova versione...")
    @menu_update_patch.connect(SEL_COMMAND, method(:mnu_update_applypatch))
     
    #Menu Help
    @menu_help = FXMenuCommand.new(helpmenu, "&Help")
    @menu_help.connect(SEL_COMMAND, method(:mnu_cuperativa_help))
    @menu_info = FXMenuCommand.new(helpmenu, "Sulla #{APP_CUPERATIVA_NAME}...")
    @menu_info.connect(SEL_COMMAND, method(:mnu_cuperativa_info))
    
    #@menu_test = FXMenuCommand.new(helpmenu, "Test")
    #@menu_test.connect(SEL_COMMAND, method(:mnu_cuperativa_test))
    
    # Titles on menupanels 
    FXMenuTitle.new(@menubar, "&Giochi", nil, @giochimenu)
    
    FXMenuTitle.new(@menubar, "Aggiorna", nil, @updatemenu)
    FXMenuTitle.new(@menubar, "&Info", nil, helpmenu)
    
    ###  toolbar
    FXHorizontalSeparator.new(self, SEPARATOR_GROOVE|LAYOUT_FILL_X)
    vv_main = self
    toolbarShell = FXToolBarShell.new(self)
    toolbar = FXToolBar.new(vv_main, toolbarShell,LAYOUT_SIDE_TOP|LAYOUT_FILL_X, 0, 0, 0, 0, 3, 3, 0, 0)
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
    
    ##### Toolbar buttons
    # options button
    @btoptions= FXButton.new(toolbar, "\tOpzioni\tOptioni", @icons_app[:options], nil,0,ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED,0,0,0,0,10,10,3,3)#,0, 0, 0, 0, 10, 10, 5, 5)
    @btoptions.connect(SEL_COMMAND, method(:mnu_cuperativa_options))
    # info button
    @btinfo= FXButton.new(toolbar, "\tInfo\tInfo", @icons_app[:info], nil,0,ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED,0,0,0,0,10,10,3,3)#,0, 0, 0, 0, 10, 10, 5, 5)
    @btinfo.connect(SEL_COMMAND, method(:mnu_cuperativa_info))
    
    # try to set a label on in the midlle of the toolbar
    @lbl_table_title = FXLabel.new(toolbar, "", nil, JUSTIFY_CENTER_X|LAYOUT_FILL_X|JUSTIFY_CENTER_Y|LAYOUT_FILL_Y)
    
    # buttons for network and table
    @bt_net_viewselect = FXButton.new(toolbar, "Rete", @icons_app[:netview_sm],nil, 0,ICON_BEFORE_TEXT|FRAME_RAISED,0, 0, 0, 0, 10, 10, 5, 5)
    @bt_net_viewselect.connect(SEL_COMMAND, method(:view_select_network))
    @bt_table_viewselect = FXButton.new(toolbar, "Inizio", @icons_app[:start_sm],nil, 0,ICON_BEFORE_TEXT|FRAME_RAISED,0, 0, 0, 0, 10, 10, 5, 5)
    @bt_table_viewselect.connect(SEL_COMMAND, method(:view_select_table))
    ###### Toolbar end
    
    #--------------------- tabbook - start -----------------
    # Switcher
    @tabbook = FXTabBook.new(vv_main, nil, 0, FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABBOOK_LEFTTABS)#TABBOOK_BOTTOMTABS)
    @tabbook.connect(SEL_COMMAND, method(:tab_table_clicked))
    # (1)tab - chat table
    @tab1 = FXTabItem.new(@tabbook, "", @icons_app[:start_sm])
    
    # presentation zone
    # buttons
    center_pan = FXVerticalFrame.new(@tabbook, LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)
    
    btdetailed_frame = FXVerticalFrame.new(center_pan, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)
    
    
    # local game
    @btstart_button = FXButton.new(btdetailed_frame, "Gioca contro il computer", icons_app[:icon_start], self, 0,
              LAYOUT_CENTER_X | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    @btstart_button.connect(SEL_COMMAND, method(:mnu_start_offline_game))
    @btstart_button.iconPosition = (@btstart_button.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    # change game
    @btgamelist = FXButton.new(btdetailed_frame, "Cambia gioco contro il computer", icons_app[:listgames], self, 0,
              LAYOUT_CENTER_X | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    @btgamelist.connect(SEL_COMMAND, method(:mnu_giochi_list))
    @btgamelist.iconPosition = (@btgamelist.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    
    # network game
    if @network_enabled == true
    	@btnetwork_button = FXButton.new(btdetailed_frame, "Gioca in Internet", icons_app[:icon_network], self, 0,
              LAYOUT_CENTER_X | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    	@btnetwork_button.connect(SEL_COMMAND, method(:mnu_network_con))
    	@btnetwork_button.iconPosition = (@btnetwork_button.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    end
    
    # logger
    log_panel = FXHorizontalFrame.new(center_pan, FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT)
    @logText = FXText.new(log_panel, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @logText.editable = false
    @logText.backColor = Fox.FXRGB(231, 255, 231)
        
    # (2)tab - chat lobby network
    if @network_enabled == true
      @tab2 = FXTabItem.new(@tabbook, "", @icons_app[:netview_sm])
      @split_horiz_netw = FXSplitter.new(@tabbook, (LAYOUT_SIDE_TOP|LAYOUT_FILL_X|
                         LAYOUT_FILL_Y|SPLITTER_HORIZONTAL|SPLITTER_TRACKING))
    
    
      sunkenFrame = FXHorizontalFrame.new(@split_horiz_netw, FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
      group2 = FXVerticalFrame.new(sunkenFrame, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
      @txtrender_lobby_chat = FXText.new(group2, self, 3, TEXT_WORDWRAP|LAYOUT_FILL_X|LAYOUT_FILL_Y) #FXTextField.new(group2,2, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
      @txtrender_lobby_chat.backColor = Fox.FXRGB(255, 250, 205)
      @txtrender_lobby_chat.textColor = Fox.FXRGB(0, 0, 0)
    
      matrix = FXMatrix.new(group2, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
      @txtchat_lobby_line = FXTextField.new(matrix, 2, nil, 0, (FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
      @txtchat_lobby_line.connect(SEL_COMMAND, method(:onBtSend_chat_lobby_text))
    end
    
    # MODEL / VIEW / CONTROLLER
    
    # network control
    if @network_enabled == true
    	@control_net_conn = ControlNetConnection.new(self)
    	# network state model
    	@model_net_data = ModelNetData.new
    	# network cockpit view
    	group3 = FXVerticalFrame.new(@split_horiz_netw, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    	@splitter_ntw_log = FXSplitter.new(group3, (LAYOUT_SIDE_TOP|LAYOUT_FILL_X|
                       LAYOUT_FILL_Y|SPLITTER_VERTICAL|SPLITTER_TRACKING))
    
    	@network_cockpit_view = NetworkCockpitView.new("Giochi disponibili sul server", 
             @splitter_ntw_log, self, @control_net_conn, @model_net_data)
    	@control_net_conn.set_model_view(@model_net_data, @network_cockpit_view) 
    	# add observer for network state change notification
    	@model_net_data.add_observer("cuperativa_gui", self)
    	@model_net_data.add_observer("control_net", @control_net_conn)
    	@model_net_data.add_observer("network_cockpit_view", @network_cockpit_view)
    
     	# logger network
    	log_panel_ntw = FXHorizontalFrame.new(@splitter_ntw_log, FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT)
    	@logTextNtw = FXText.new(log_panel_ntw, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    	@logTextNtw.editable = false
    	@logTextNtw.backColor = Fox.FXRGB(231, 255, 231)
    	@tab2.tabOrientation = TAB_LEFT #TAB_BOTTOM
    end
    
    @tab1.tabOrientation = TAB_LEFT #TAB_BOTTOM
    @tabbook.setCurrent(0)
    @bt_table_viewselect.state = STATE_DOWN
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
    
    @dialog_sw = DlgSwUpdate.new(self, "Aggiorna software", "")
    
    @sound_manager = SoundManager.new
    
    if $g_os_type == :win32_system
      submit_idle_handler # on fxruby 1.6.6 on windows repeat => true is not available
    else
      # idle routine
      anApp.addChore(:repeat => true) do |sender, sel, data|
       
      end
    end
    
  end #end  initialize
  
  def self.prgversion
    return VER_PRG_STR
  end
  
  def submit_idle_handler
    tgt = FXPseudoTarget.new
    tgt.pconnect(SEL_CHORE, nil, method(:onChore))
    @main_app.addChoreOrig(tgt, 0)
  end
  
  def onChore(sender, sel, data)
    #p 'chore is called'
   
    submit_idle_handler
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
  
  ##
  # game_network_type: :offline or :online
  def create_new_singlegame_window(game_network_type)
    game_info = @supported_game_map[@last_selected_gametype]
    options = {:game_network_type => game_network_type, :app_options => @app_settings,
        :model_data => @model_net_data,
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
  # Provides modaless dialogbox for update progress
  def get_sw_dlgdialog
    return @dialog_sw
  end
  
  
  ##
  # Load all supported games
  def load_supported_games
    @supported_game_map = InfoAvilGames.info_supported_games(@log)
    #p @supported_game_map
    # execute require 'mygame'
    SETTINGS_DEFAULT_APPGUI[:games_opt] = {}
    @supported_game_map.each do |k, game_item|
      if game_item[:enabled] == true
        # game enabled
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
  
  ##
  # Notification from current gfx that game is started
  def ntfy_gfx_gamestarted 
    hide_startbutton
  end
  ##
  # Hide the start button
  def hide_startbutton
    @btstart_button.disable
  end
  
  # shows start button
  def show_startbutton
    @btstart_button.enable
  end
  
  ##
  # Register a timer. Register only one timer, all other are queued and submitted
  # after timeout
  # timeout: timeout time in milliseconds
  # met_sym_tocall: method to be called after timeout
  # met_notifier: object that implement method after timeout event
  #def registerTimeout(timeout, met_sym_tocall, met_notifier=@current_game_gfx)
  def registerTimeout(timeout, met_sym_tocall, met_notifier)
    #p "register timer for msec #{timeout}"
    unless @timeout_cb[:locked]
      # register only one timeout at the same time
      @timeout_cb[:meth] = met_sym_tocall
      @timeout_cb[:notifier] = met_notifier
      @timeout_cb[:locked] = true
      getApp().addTimeout(timeout, method(:onTimeout))
    else
      #@log.debug("registerTimeout on timeout pending, put it on the queue")
      # store info about timeout in order to submit after  a timeout
      @timeout_cb[:queue] << {:timeout => timeout, 
                              :meth => met_sym_tocall, 
                              :notifier => met_notifier, 
                              :started => Time.now
      }
    end
  end
  
  ##
  # Timer exausted
  def onTimeout(sender, sel, ptr)
    #p "Timeout"
    #p @timeout_cb
    #@current_game_gfx.send(@timeout_cb)
    @timeout_cb[:notifier].send(@timeout_cb[:meth])
    # pick a queued timer
    next_timer_info = @timeout_cb[:queue].slice!(0)
    if next_timer_info
      # submit the next timer
      @timeout_cb[:meth] = next_timer_info[:meth]
      @timeout_cb[:notifier] = next_timer_info[:notifier]
      @timeout_cb[:locked] = true
      timeout_orig = next_timer_info[:timeout]
      # remove already elapsed time
      already_elapsed_time_ms = (Time.now - next_timer_info[:started]) * 1000
      timeout_adjusted = timeout_orig - already_elapsed_time_ms
      # minimum timeout always set
      timeout_adjusted = 10 if timeout_adjusted <= 0
      getApp().addTimeout(timeout_adjusted, method(:onTimeout))
      #@log.debug("Timer to register found in the timer queue (Resume with timeout #{timeout_adjusted})")
    else
      # no more timer to submit, free it
      #@log.debug("onTimeout terminated ok")
      @timeout_cb[:locked] = false
      @timeout_cb[:queue] = []
    end
    return 1
  end
 
  
  ##
  # Update the game canvas display
  def update_dsp
    #@canvas_disp.update
  end
  
  ##
  # Recalculate the canvas. This is needed when a new control is added
  # and the canvas need to be recalculated
  def activate_canvas_frame
    #@canvasFrame.show
    #@canvasFrame.recalc
    #@canvas_disp.recalc
  end
  
  def deactivate_canvas_frame
    #@canvasFrame.hide
    #@canvasFrame.recalc 
    #@canvas_disp.recalc if @canvas_disp
  end
  
  ##
  # Paint event on canvas
  def onCanvasPaint(sender, sel, event)
    
  end
  
  ##
  # Mouse left up event on canvas
  def onLMouseUp(sender, sel, event)
    #p 'onLMouseUp'
    #@current_game_gfx.onLMouseUp(event)
  end
  
  ##
  # Mouse left down event on canvas
  def onLMouseDown(sender, sel, event)
    #log_sometext("onLMouseDown\n")
    # @current_game_gfx.onLMouseDown(event)
  end
  
  def onLMouseMotion(sender, sel, event)
    #@current_game_gfx.onLMouseMotion(event)
  end
  
  ##
  # Size of canvas is changing
  def OnCanvasSizeChange(sender, sel, event)
    
  end
  
  # Load the named icon from a file
  def loadIcon(filename)
    begin
      #dirname = File.join(File.dirname(__FILE__), "/../res/icons")
      dirname = File.join(get_resource_path, "icons")
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
  #
  def detach
    super
    #@current_game_gfx.detach
  end
  
  ##
  # Load debug info from yaml file.
  # return the shortcut mode (:debug, :default, :nothing)
  def load_loginfo_from_file(fname)
    base_dir_log = File.join(CuperativaGui.get_dir_appdata(), "clientlogs")
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
    @split_horiz_netw.setSplit(0, gfxgui_settings[:splitter_network]) if @split_horiz_netw
    @splitter_ntw_log.setSplit(0, gfxgui_settings[:splitter_log_network]) if @splitter_ntw_log
    
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
    if @model_net_data != nil  
    	log_sometext("Ora puoi giocare a carte in internet oppure giocare contro il computer.\n")
    	@model_net_data.event_cupe_raised(:ev_gui_controls_created)
    end
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
  # Terminate current game
  def mnu_maingui_fine_part(sender, sel, ptr)
  end
  
  ##
  # Gui button state for table selected
  def tab_table_clicked(sender, sel, ptr)
    if ptr == 0
      # on table tab
      @bt_table_viewselect.state = STATE_DOWN
      @bt_net_viewselect.state = STATE_UP
    elsif ptr == 1
      # on network tab
      @bt_table_viewselect.state = STATE_UP
      @bt_net_viewselect.state = STATE_DOWN
    end
  end
  
  ##
  # Select view network
  def view_select_network(sender, sel, ptr)
    tab_table_clicked(0,0,1)
    @tabbook.setCurrent(1)
  end
  
  ##
  # Select view table
  def view_select_table(sender, sel, ptr)
    tab_table_clicked(0,0,0)
    @tabbook.setCurrent(0)
  end
  
  ##
  # Save the current match
  def mnu_giochi_savegame (sender, sel, ptr)
  end
  
  ##
  # Select the current game from all game list
  def mnu_giochi_list (sender, sel, ptr)
    dlg = DlgListGames.new(self,@supported_game_map, @last_selected_gametype, @app_settings)
    if dlg.execute != 0
      k = dlg.get_activatedgame_key
      if @app_settings[:games_opt] != nil and @app_settings[:games_opt][k] != nil
        @app_settings[:games_opt][k] = dlg.get_curr_options
        @log.debug("opzioni del gico #{k}: #{@app_settings[:games_opt][k]} ")
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
  
  #def mnu_cuperativa_test2(sender, sel, ptr)
    #@net_chat_table_view.hide_panel
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
  # Check on remote server if a new udate is available
  def mnu_update_check(sender, sel, ptr)
    nomeprog = APP_CUPERATIVA_NAME
    ver_prog = CuperativaGui.sw_version_to_int
  end
  
  ##
  # Apply a local patch 
  def mnu_update_applypatch(sender, sel, ptr)
    loadDialog = FXFileDialog.new(self, "Applica aggiornamento")
    patterns = [ "Tgz (*.tar.gz)", "Cup (*.cup)", "All Files (*)"  ]
    loadDialog.setPatternList(patterns)
  end
  
  # Provides the resource path
  def get_resource_path
    res_path = File.dirname(__FILE__) + "/../res"
    return File.expand_path(res_path)
  end
  
  def get_app_data_folder
    return CuperativaGui.get_dir_appdata()
  end
  
  def OnAppSizeChange(sender, sel, event)
    #set_splitterpos_onsize(width , height)
  end
  
  def login_error(info_str)
    modal_errormessage_box("Errore nel collegamento", info_str)
    log_sometext("<Server ERRORE>:#{info_str}\n")
  end

  ##
  # Quit the application
  def onCmdQuit(sender, sel, ptr)
    if @singe_game_win != nil
      if !modal_yesnoquestion_box("Termina la Cuperativa?", "Partita in corso, vuoi davvero terminare il programma?")
        log_sometext "Utente non vuole terminare la partita\n" 
        #@current_game_gfx.game_end_stuff
        return 1
      else
        @singe_game_win.user_isgoing_toexit
      end
    end
    
    
    #p self.methods
    begin
      @log.debug("onCmdQuit is called")
    rescue
    end
    @app_settings['guigfx'][:ww_mainwin] = self.width
    @app_settings['guigfx'][:hh_mainwin] = self.height
    if @splitter_ntw_log != nil
    	@app_settings['guigfx'][:splitter_log_network] =  @splitter_ntw_log.getSplit(0)
    end
    
    @app_settings["curr_game"] = @last_selected_gametype
   
    # avoid write test code options
    @app_settings[:custom_deck] = nil
    # yaml file version
    @app_settings["versionyaml"] = CUP_YAML_FILE_VERSION
    
    #save settings in a yaml file
    #p @settings_filename
    File.open( @settings_filename, 'w' ) do |out|
      YAML.dump( @app_settings, out )
    end
    getApp().exit(0)
  end
  
  def MainApp
    return getApp()
  end
 
  ##
  # Log text in the top window
  def log_sometext(msg)
    logCtrl = @logTextNtw
    logCtrl = @logText if @tabbook.getCurrent == 0
    log_msg_onctrl(msg, logCtrl)
  end
  
  def log_msg_onctrl(msg, logCtrl)
    if(logCtrl)
    	logCtrl.text += msg
    	logCtrl.makePositionVisible(logCtrl.rowStart(logCtrl.getLength))
    end
  end
  
  def log_network(msg)
    log_msg_onctrl(msg, @logTextNtw)
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
