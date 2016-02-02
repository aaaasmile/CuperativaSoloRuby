#file: test_canvas.rb
# File used to test gfx game engine into a standalone canvas
# It was created the first time to test spazzino_gfx.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'

require 'rubygems'
require 'fox16'
require 'log4r'

require 'src/inv_controls/inv_container'
require 'src/core/sound_manager'

include Fox

##
# Test container for canvas
class TestCanvas < FXMainWindow
  attr_accessor :app_settings, :current_game_gfx, :icons_app, 
  :sound_manager
  
  def initialize(anApp)
    super(anApp, "TestCanvas", nil, nil, DECOR_ALL, 30, 20, 640, 480)
    
    @icons_app = {}
    @state_game = :splash
    @players_on_table = []
    @app_settings = {
      "deck_name" => :piac,
      "cpualgo" => {},
      "players" => [],
      "session" => {},
      "autoplayer" => {:auto_gfx => false},
      "web_http" => {},
      "sound" => {},
      "all_games" => {:cards_opponent => false},
      "games" => {:briscola_game => {},:tressette_game =>{:jump_distr_cards => true},
                  :mariazza_game => {}, :scopetta_game => {}, 
                  :spazzino_game =>{}, :tombolon_game =>{}, 
                  :scacchi_game => {}, :briscolone_game => {}}
    }
    @timeout_cb = {:locked => false, :queue => []}
    @pos_start_x = 30; @pos_start_y = 20; @pos_ww = 640; @pos_hh = 480
    # array of button for command panel
    @game_cmd_bt_list = []
    
    @sound_manager = SoundManager.new
    @sound_manager.disable_sound
    @container = InvContainer.new(self, anApp)
    
    @log = Log4r::Logger["coregame_log"]
    # idle routine
    @anApp = anApp
    
  end
  
  def submit_idle_handler
    tgt = FXPseudoTarget.new
    tgt.pconnect(SEL_CHORE, nil, method(:onChore))
    @anApp.addChoreOrig(tgt, 0)
  end
  
  def onChore(sender, sel, data)
    #p 'chore is called'
    if @current_game_gfx
      @current_game_gfx.do_core_process
    end
    submit_idle_handler
  end
 
  def get_resource_path
    res_path = File.dirname(__FILE__) + "../../res"
    return File.expand_path(res_path)
  end
  
  def set_position(a,b,c,d)
    @pos_start_x = a; @pos_start_y = b; @pos_ww = c; @pos_hh = d
  end
  
  ##
  # Create
  def create
    position(@pos_start_x, @pos_start_y, @pos_ww, @pos_hh)
    super
    show(PLACEMENT_SCREEN)
  end
   
  def init_gfx(gfx_class, players)
    if $g_os_type == :win32_system
      submit_idle_handler
    else
      anApp.addChore(:repeat => true) do |sender, sel, data|
        #p 'chore is called'
        if @current_game_gfx
          @current_game_gfx.do_core_process
        end
      end
    end
    @current_game_gfx = gfx_class.new(self)
    @container.add(@current_game_gfx)
    @current_game_gfx.model_canvas_gfx.info[:canvas] = {:height => @container.height, :width => @container.width, :pos_x => 0, :pos_y => 0 }
    @current_game_gfx.model_canvas_gfx.info[:main_container] = @container
    @players_on_table = players
    @current_game_gfx.create_wait_for_play_screen
    @log.debug "Game #{gfx_class} initialized" 
  end

  def start_new_game
    @current_game_gfx.start_new_game(@players_on_table, @app_settings)
  end
  
  def ntfy_gfx_gamestarted() end
  def ntfygfx_game_end() end
  def log_sometext(str) end
  def free_all_btcmd() end
  
  def registerTimeout(timeout, met_sym_tocall, met_notifier=@current_game_gfx)
    #@log.debug "register timer for msec #{timeout}, #{met_sym_tocall}"
    #p "register timer for msec #{timeout}"
    unless timeout
      p met_sym_tocall
      p timeout
      crash
    end
    unless @timeout_cb[:locked]
      # register only one timeout at the same time
      @timeout_cb[:meth] = met_sym_tocall
      @timeout_cb[:notifier] = met_notifier
      @timeout_cb[:locked] = true
      getApp().addTimeout(timeout, method(:onTimeout))
    else
      #@log.debug("registerTimeout on timeout pending, put it on the queue")
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
      #@corelogger.debug("Timer to register found in the timer queue (Resume with timeout #{timeout_adjusted})")
    else
      # no more timer to submit, free it
      #@corelogger.debug("onTimeout terminated ok")
      @timeout_cb[:locked] = false
      @timeout_cb[:queue] = []
    end
    return 1
  end
     
  ## 
  # Set a custom deck information. Used for testing code without changing source code
  def set_custom_deck(deck_info)
    @app_settings[:custom_deck] = { :deck => deck_info }
  end
 
  def mycritical_error(str)
    FXMessageBox.error(self, MBOX_OK, "Errore applicazione", str)
    exit
  end
  
end#end TestCanvas


if $0 == __FILE__
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  theApp = FXApp.new("TestCanvas", "FXRuby")
  mainwindow = TestCanvas.new(theApp)
  mainwindow.set_position(0,0,950,530)
  
  theApp.create()
  theApp.run
end
  