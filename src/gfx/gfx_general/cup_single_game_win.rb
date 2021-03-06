#file: cup_single_game_win.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'
$:.unshift File.dirname(__FILE__) + '/../..'


require 'rubygems'
require 'fox16'

require 'modal_msg_box'
require 'inv_controls/inv_container'

include Fox

class CupSingleGameWin < FXMainWindow 
  attr_reader :current_game_gfx, :icons_app, :sound_manager, :cup_gui
  
  
  include ModalMessageBox
  
  def initialize(options)
    @win_height = 600
    @win_width = 800
    @state_model = :undefined
    owner = options[:owner]
    @icons_app = owner.icons_app
    comment = options[:comment]
    @game_type = options[:game_type]
    @app_settings = options[:app_options]
    @app_settings_gametype = @app_settings["games"][@game_type]
    @win_width = @app_settings_gametype[:ww_mainwin] if @app_settings_gametype
    @win_height = @app_settings_gametype[:hh_mainwin] if @app_settings_gametype
    
    super(owner.main_app, comment, nil, nil, DECOR_ALL, 50,50, @win_width, @win_height)
    
    
    @cup_gui = owner
    @log = Log4r::Logger["coregame_log"]
    @comment = comment
    
    @sound_manager = @cup_gui.sound_manager
    
    # canvas painting event
    #@canvast_update_started = false
   
    # number of players that play the current game
    @num_of_players = options[:num_of_players]
    
      
  
    setIcon(@cup_gui.icons_app[:cardgame_sm])
    
    @container = InvContainer.new(self, owner.main_app)
    #@container.verbose = true
    bt_start_game = InvButton.new(10, 10, 100, 50, 0)
    bt_start_game.set_content(owner.icons_app[:icon_start])
    bt_start_game.connect(:EV_click) do |sender|
      @container.remove(bt_start_game)
      players = create_players
      start_new_game(players, @app_settings)
    end
    @container.add(bt_start_game)
    
    self.connect(SEL_CLOSE, method(:on_close_win))
    
    create_game_gfx(options)
    
    ## idle routine
    if $g_os_type == :win32_system
      submit_idle_handler
    else
      owner.main_app.addChore(:repeat => true) do |sender, sel, data|
        if @current_game_gfx
          @current_game_gfx.do_core_process
        end
      end
    end
    
  end
    
  def submit_idle_handler
    tgt = FXPseudoTarget.new
    tgt.pconnect(SEL_CHORE, nil, method(:onChore))
    @cup_gui.main_app.addChoreOrig(tgt, 0)
  end
  
  def onChore(sender, sel, data)
    if @current_game_gfx
      @current_game_gfx.do_core_process
    end
    submit_idle_handler
  end
  
  def create
    super
    # players on the table
    set_players_ontable
    
    show(PLACEMENT_SCREEN)
  end
  
  ##
  # Defines players on table
  def set_players_ontable
    @players_on_table = []
    players_default = @app_settings["players"]
    players_default.each do |hash_player|
      # add the defined player
      @players_on_table << PlayerOnGame.new(hash_player[:name], nil, hash_player[:type], 0)
    end
  end
  
  def create_players
    players = []
    # create an array of index
    ix_coll_shuffled = Array.new(@players_on_table.size - 1){|i| i + 1}
    ix_coll_shuffled =  ix_coll_shuffled.sort_by{ rand }
    # firts player is the gui player, not rnd but fix
    players << @players_on_table[0]
    (0..@num_of_players - 2).each do |ix|
      ix_rnd = ix_coll_shuffled.pop
      pl = @players_on_table[ix_rnd]
      if pl
        players << pl
      else
        players = @players_on_table[0..(@num_of_players-1)]
        @log.error("Player random name not found: programming error")
      end 
    end
    return players
  end
  
  
  
  def start_new_game(players, app_settings)
    @app_settings = app_settings
    @current_game_gfx.start_new_game(players, @app_settings)
  end
  
  def create_game_gfx(options)
    if options[:gfx_enginename] != nil
      @current_game_gfx =  eval(options[:gfx_enginename]).new(self)
      @container.add(@current_game_gfx)
      @current_game_gfx.model_canvas_gfx.info[:canvas] = {:height => @container.height, :width => @container.width, :pos_x => 0, :pos_y => 0 }
      @current_game_gfx.model_canvas_gfx.info[:main_container] = @container
      @current_game_gfx.create_wait_for_play_screen
    end 
  end
  
  def store_settings
    if @app_settings_gametype
      @app_settings_gametype[:ww_mainwin] = self.width
      @app_settings_gametype[:hh_mainwin] = self.height
    end
    @app_settings["players"] = []
    @players_on_table.each_index do |ix|
      name = @players_on_table[ix].name
      type = @players_on_table[ix].type
      @app_settings["players"] << {:name => name, :type => type} 
    end
  end
  
  def on_close_win(sender, sel, ptr)
    @log.debug "Game window is closing"
    if @state_model == :state_on_localgame
      if modal_yesnoquestion_box("Termina partita?", "Partita in corso, vuoi davvero abbandonarla?")
        @log.debug "Utente termina la partita"
        do_close()
      end
    else
      do_close()
    end
  end
 
  def do_close()
    begin
      store_settings 
      @current_game_gfx.game_end_stuff
      @cup_gui.game_window_destroyed
      
      @sound_manager.stop_sound(:play_mescola)
      close
    rescue => detail
      error_msg = "Error on closing. Please fix the do_close routine."
      @log.error error_msg
      @log.error "do_close error (#{$!})"
      @log.error detail.backtrace.join("\n")
      close
    end
  end
  
end #end CupSingleGameWin


if $0 == __FILE__
  $:.unshift File.dirname(__FILE__) + '/../../..'
  
  require 'test/gfx/test_dialogbox' 
  require 'src/games/briscola/briscola_gfx'
  
  ##
  # Launcher of the dialogbox
  class DialogboxCreator
    attr_accessor :main_app
    
    def initialize(app)
      @main_app = app 
      @options = {:game_network_type => :offline, :game_type => :briscola_game, 
        :owner => app, :comment => "Gioco", :gfx_enginename =>'BriscolaGfx', :num_of_players => 2,
        :app_options => {"games" => { :briscola_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 541}}, 
                         "players" => [{:name => "Toro", :type => :human_local }, {:name => "Gino B.", :type => :cpu_local }],
                         :games_opt => {},
                         "deck_name" => :piac
                       } 
      }
      @log = Log4r::Logger.new("coregame_log::DialogboxCreator")
      @log.debug "DialogboxCreator initialized"
    end
    
    ##
    # Method called from TestRunnerDialogBox when go button is pressed
    def run
      @log.debug "Run the tester..."
      @dlg_box = CupSingleGameWin.new(@options)
      @dlg_box.create
    end
  end
  
  # create the runner: a window with one button that call runner.run
  TestRunnerDialogBox.create_app(DialogboxCreator)
  
end
