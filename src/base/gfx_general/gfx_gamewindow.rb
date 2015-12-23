#file: gfx_gamewindow.rb

$:.unshift File.dirname(__FILE__) + '/..'
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'fox16'

require 'modal_msg_box'

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
    
    @timeout_cb = {:locked => false, :queue => []}
    @cup_gui = owner
    @log = Log4r::Logger["coregame_log"]
    @comment = comment
    
    @sound_manager = @cup_gui.sound_manager
    
    # canvas painting event
    @canvast_update_started = false
    
   
    
    # number of players that play the current game
    @num_of_players = options[:num_of_players]
      
    @main_vertical = FXVerticalFrame.new(self, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    ##### main splitter
    # split up/down
    @splitter = FXSplitter.new(@main_vertical, (LAYOUT_SIDE_TOP|LAYOUT_FILL_X|
                       LAYOUT_FILL_Y|SPLITTER_VERTICAL|SPLITTER_TRACKING))
    center_pan = @splitter
    @canvas_panel_H = FXHorizontalFrame.new(center_pan, FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)
    @canvasFrame = FXVerticalFrame.new(@canvas_panel_H, LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_RIGHT)
    
    
    # canvas for core_gfx
    ### Label for table name
    ##canvas
    @canvas_disp = FXCanvas.new(@canvas_panel_H, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT )
    @canvas_disp.connect(SEL_PAINT, method(:onCanvasPaint))
    @canvas_disp.connect(SEL_LEFTBUTTONPRESS, method(:onLMouseDown))
    @canvas_disp.connect(SEL_CONFIGURE, method(:OnCanvasSizeChange))
    @canvas_disp.connect(SEL_MOTION, method(:onLMouseMotion))
    @canvas_disp.connect(SEL_LEFTBUTTONRELEASE, method(:onLMouseUp))
    @color_backround = Fox.FXRGB(0x22, 0x8a, 0x4c) #Fox.FXRGB(103, 203, 103) #Fox.FXRGB(50, 170, 10) 
    @canvas_disp.backColor = @color_backround
    setIcon(@cup_gui.icons_app[:cardgame_sm])
    
    # double buffer image for canvas
    @imgDbuffHeight = 0
    @imgDbuffWidth = 0
    @image_double_buff = nil

    # *************  BOTTOM part ***************
    bottom_panel = FXHorizontalFrame.new(@splitter, FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)
    
    @tabbook = FXTabBook.new(bottom_panel, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|TABBOOK_LEFTTABS)
     # (1)tab - log
    @tab1 = FXTabItem.new(@tabbook, "Log", nil)
    
    @split_horiz_netw = FXSplitter.new(@tabbook, (LAYOUT_SIDE_TOP|LAYOUT_FILL_X|
                       LAYOUT_FILL_Y|SPLITTER_HORIZONTAL|SPLITTER_TRACKING))
    
    #log text control
    ctrlframe = FXHorizontalFrame.new(@split_horiz_netw, FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    
    @logText = FXText.new(ctrlframe, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @logText.editable = false
    @logText.backColor = Fox.FXRGB(231, 255, 231)
    
    
    # start commands
    start_btframe = FXVerticalFrame.new(ctrlframe, LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)
    # start game button
    @bt_start_game = FXButton.new(start_btframe, "Inizia", icons_app[:icon_start], nil, 0,
             LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT)
    @bt_start_game.iconPosition = (@bt_start_game.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    @bt_start_game.connect(SEL_COMMAND) do |sender, sel, ptr|
      players = create_players
      start_new_game(players, @app_settings)
    end
    
    @tab1.tabOrientation = TAB_LEFT #TAB_BOTTOM
    
    
    self.connect(SEL_CLOSE, method(:on_close_win))
    
    set_splitterpos_initial(@win_width, @win_height)
    if @app_settings_gametype
      @splitter.setSplit(0,@app_settings_gametype[:splitter]) if @app_settings_gametype[:splitter]
    end   
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
    @current_game_gfx.set_canvas_frame(@canvasFrame) if @current_game_gfx
    @split_horiz_netw.setSplit(0, 400)
    
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
  
  def registerTimeout(timeout, met_sym_tocall, met_notifier=@current_game_gfx)
    #@log.debug "register timer for msec #{timeout}, #{met_sym_tocall}"
    @log.error "Timeout is not set in registerTimeout" unless timeout
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
  # Timer expired
  def onTimeout(sender, sel, ptr)
    #p "Timeout"
    #p @timeout_cb
    return unless @timeout_cb[:notifier]
    
    begin
      # timeout callback
      @timeout_cb[:notifier].send(@timeout_cb[:meth])
    rescue => detail
      @log.error "onTimeout error (#{$!})"
      @log.error detail.backtrace.join("\n")
    end
    
    # submit the next timer in the queue
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
  
  
  def start_new_game(palyers, app_settings)
    @app_settings = app_settings
    @current_game_gfx.start_new_game(palyers, @app_settings)
  end
  
  def create_game_gfx(options)
    if options[:gfx_enginename] != nil
      @current_game_gfx =  eval(options[:gfx_enginename]).new(self)
      @current_game_gfx.model_canvas_gfx.info[:canvas] = {:height => @canvas_disp.height, :width => @canvas_disp.width, :pos_x => 0, :pos_y => 0 }
      @current_game_gfx.create_wait_for_play_screen
    end 
  end
 
  ##
  # Update the game canvas display
  def update_dsp
    @canvas_disp.update
  end
  
  def set_splitterpos_initial(ww, hh )
    posy = hh - hh/3 + 3
    @splitter.setSplit(0, posy)
  end
  
  ##
  # Check if the splitter position is conform to the window size
  def set_splitterpos_onsize(ww, hh )
    #@log.debug "Set splitter position to #{ww}, #{hh}"
    splitpos_y = @splitter.getSplit(0)
    ratio_y = hh - hh/3 + 3
    if splitpos_y > hh - 5
      posy = ratio_y 
      @splitter.setSplit(0, posy)
    elsif splitpos_y < ratio_y
      @splitter.setSplit(0, ratio_y)
    end
    
  end
  
  def activate_canvas_frame
    @canvasFrame.show
    @canvasFrame.recalc
    @canvas_disp.recalc
  end

  ##
  # Paint event on canvas
  def onCanvasPaint(sender, sel, event)
    unless @canvast_update_started
      # avoid multiple call of update display until processed
      @canvast_update_started = true
      #@corelogger.debug("onCanvasPaint start")
      dc = FXDCWindow.new(@image_double_buff)
      #dc = FXDCWindow.new(@canvas_disp, event)
      dc.foreground = @canvas_disp.backColor
      #erase canvas
      dc.fillRectangle(0, 0, @image_double_buff.width, @image_double_buff.height)
    
      # draw scene into the picture
      @current_game_gfx.draw_static_scene(dc, @image_double_buff.width, @image_double_buff.height)
      
      dc.end #don't forget this, otherwise  problems on exit
      
      # blit image into the canvas
      dc_canvas = FXDCWindow.new(@canvas_disp, event)
      dc_canvas.drawImage(@image_double_buff, 0, 0)
      dc_canvas.end
      
      @canvast_update_started = false
      #@corelogger.debug("onCanvasPaint stop")
    end
  end
  
  ##
  # Mouse left up event on canvas
  def onLMouseUp(sender, sel, event)
    #p 'onLMouseUp'
    @current_game_gfx.onLMouseUp(event)
  end
  
  ##
  # Mouse left down event on canvas
  def onLMouseDown(sender, sel, event)
     @current_game_gfx.onLMouseDown(event)
  end
  
  def onLMouseMotion(sender, sel, event)
    @current_game_gfx.onLMouseMotion(event)
  end
  
  ##
  # Size of canvas is changing
  def OnCanvasSizeChange(sender, sel, event)
    adapt_to_canvas = false
    
    resolution = 3
    #check height
    if @imgDbuffHeight + resolution < @canvas_disp.height
      adapt_to_canvas = true
    elsif @imgDbuffHeight > @canvas_disp.height + resolution
      adapt_to_canvas = true
    end
    # check width
    if @imgDbuffWidth + resolution < @canvas_disp.width
      adapt_to_canvas = true
    elsif  @imgDbuffWidth > @canvas_disp.width + resolution
      adapt_to_canvas = true
    end
    if adapt_to_canvas
      # need to recreate a new image double buffer 
      @imgDbuffHeight = @canvas_disp.height
      @imgDbuffWidth = @canvas_disp.width
      
      @image_double_buff = FXImage.new(getApp(), nil, 
             IMAGE_SHMI|IMAGE_SHMP, @imgDbuffWidth, @imgDbuffHeight)
      @image_double_buff.create
      #notify change to the current gfx
      begin
        @current_game_gfx.onSizeChange(@imgDbuffWidth, @imgDbuffHeight ) if @current_game_gfx
      rescue => detail
        @log.error "onSizeChange error (#{$!})"
        @log.error detail.backtrace.join("\n")
      end
    end
   
  end
  
  
  def store_settings
    if @app_settings_gametype
      @app_settings_gametype[:ww_mainwin] = self.width
      @app_settings_gametype[:hh_mainwin] = self.height
      @app_settings_gametype[:splitter] = @splitter.getSplit(0)
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
      @timeout_cb[:notifier] = nil
      @cup_gui.game_window_destroyed
      
      @sound_manager.stop_sound(:play_mescola)
      close
    rescue 
      error_msg = "Error on closing. Please fix the do_close routine."
      @log.error error_msg 
      close
    end
  end
  
  
  
end


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
      @options = {:game_network_type => :offline,
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
