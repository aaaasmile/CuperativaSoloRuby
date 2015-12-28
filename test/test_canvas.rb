#file: test_canvas.rb
# File used to test gfx game engine into a standalone canvas
# It was created the first time to test spazzino_gfx.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'

require 'rubygems'
require 'fox16'
require 'log4r'

require 'src/inv_controls/inv_container'
require 'src/base/core/sound_manager'

include Fox

##
# Test container for canvas
class TestCanvas < FXMainWindow
  attr_accessor :app_settings, :current_game_gfx, :icons_app, 
  :sound_manager
  
  def initialize(anApp)
    super(anApp, "TestCanvas", nil, nil, DECOR_ALL, 30, 20, 640, 480)
    
    @container = InvContainer.new(self, anApp)
    #canvas_panel = FXHorizontalFrame.new(self, FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)
    #@canvasFrame = FXVerticalFrame.new(canvas_panel, FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)
    #@canvas_disp = FXCanvas.new(canvas_panel, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT )
    #@canvas_disp.connect(SEL_PAINT, method(:onCanvasPaint))
    #@canvas_disp.connect(SEL_LEFTBUTTONPRESS, method(:onLMouseDown))
    #@canvas_disp.connect(SEL_CONFIGURE, method(:OnSizeChange))
    #@color_backround = Fox.FXRGB(0, 170, 0) 
    #@canvas_disp.backColor = @color_backround
    @icons_app = {}
    # double buffer image for canvas
    #@imgDbuffHeight = 0
    #@imgDbuffWidth = 0
    #@image_double_buff = nil
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
    @container = InvContainer.new(self, anApp)
    
    ## specific game commands
    #@buttonFrame = main_vertical
    #matrix = FXMatrix.new(@buttonFrame, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
    #(0..8).each do |ix|
      #bt_wnd = FXButton.new(matrix, "Test#{ix}", nil, nil, 0,FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT,0, 0, 0, 0, 10, 10, 5, 5)
      #bt_wnd.iconPosition = (bt_wnd.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
      #bt_hash = {:bt_wnd => bt_wnd, :status => :not_used}
      #@game_cmd_bt_list << bt_hash
    #end
    #free_all_btcmd # hide all commands buttons
    @log = Log4r::Logger["coregame_log"]
    # idle routine
    @anApp = anApp
    #MyaddChore(:repeat => true) do |sender, sel, data|
    
    
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
  
  def MyaddChore(*args, &block)
    params = {}
    params = args.pop if args.last.is_a? Hash
    tgt, sel = nil, 0
    if args.length > 0
      if args[0].respond_to? :call
        tgt = params[:target] || FXPseudoTarget.new
        tgt.pconnect(SEL_CHORE, args[0], params)
      else
        tgt, sel = args[0], args[1]
      end
    else
      tgt = params[:target] || FXPseudoTarget.new
      tgt.pconnect(SEL_CHORE, block, params)
    end
    @anApp.addChoreOrig(tgt, sel)
    params[:target] = tgt
    params[:selector] = sel
    params
  end
  
  ##
  # Disable button
  # bt_name: button name
  def disable_bt(bt_name)
    @game_cmd_bt_list.each do |bt|
      if bt[:name] == bt_name
        bt[:bt_wnd].disable
        return bt
      end 
    end
  end
  
  def free_all_btcmd
    @game_cmd_bt_list.each do |bt| 
      bt[:bt_wnd].hide
      bt[:bt_wnd].enable
#  bt[:bt_wnd].show #only for test
      bt[:status] = :not_used
    end
  end
  
  def onLMouseDown(sender, sel, event)
    if @state_game == :game_started
      @current_game_gfx.onLMouseDown(event.win_x, event.win_y) if @current_game_gfx
    else
      @current_game_gfx.start_new_game @players_on_table, @app_settings
      @state_game = :game_started
    end
  end
   
 
  def update_dsp
    @canvas_disp.update
  end
  
  def OnSizeChange(sender, sel, event)
    adapt_to_canvas = false
    #check height
    if @imgDbuffHeight + 10 < @canvas_disp.height
      adapt_to_canvas = true
    elsif @imgDbuffHeight > @canvas_disp.height + 20
      adapt_to_canvas = true
    end
    # check width
    if @imgDbuffWidth + 10 < @canvas_disp.width
      adapt_to_canvas = true
    elsif  @imgDbuffWidth > @canvas_disp.width + 20
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
      @current_game_gfx.onSizeChange(@imgDbuffWidth, @imgDbuffHeight ) if @current_game_gfx
    end
  end
  
  def get_resource_path
    res_path = File.dirname(__FILE__) + "../../res"
    return File.expand_path(res_path)
  end
  
  def set_position(a,b,c,d)
    @pos_start_x = a; @pos_start_y = b; @pos_ww = c; @pos_hh = d
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
  
  def create_bt_cmd(cmd_name, params, cb_btcmd)
    # get the cmd button ready to be used
    bt_cmd_created = get_next_btcmd()
    #p bt_cmd_created[:bt_wnd].methods
    #p bt_cmd_created[:bt_wnd].shown?
    bt_cmd_created[:name] = cmd_name
    bt_cmd_created[:bt_wnd].show
    #p bt_cmd_created[:bt_wnd].shown?
    bt_cmd_created[:bt_wnd].text = cmd_name.to_s
    bt_cmd_created[:bt_wnd].connect(SEL_COMMAND) do
      @current_game_gfx.send(cb_btcmd, params)
    end
    
  end
  
  ##
  # Create
  def create
    position(@pos_start_x, @pos_start_y, @pos_ww, @pos_hh)
    super
    show(PLACEMENT_SCREEN)
  end
  
  def deactivate_canvas_frame
    @canvasFrame.hide
    @canvasFrame.recalc 
    @canvas_disp.recalc if @canvas_disp
  end
  
  ##
  # Recalculate the canvas. This is needed when a new control is added
  # and the canvas need to be recalculated
  def activate_canvas_frame
    @canvasFrame.show
    @canvasFrame.recalc
    @canvas_disp.recalc
  end
  
  def init_gfx(gfx_class, players)
    if $g_os_type == :win32_system
      submit_idle_handler
    else
      anApp.addChore(:repeat => true) do |sender, sel, data|
      #anApp.addChore() do |sender, sel, data|
        #p 'chore is called'
        if @current_game_gfx
          @current_game_gfx.do_core_process
        end
      end
    end
    deactivate_canvas_frame
    @current_game_gfx = gfx_class.new(self)
    @current_game_gfx.color_backround = @color_backround
    
    @players_on_table = players
    @current_game_gfx.set_canvas_frame(@canvasFrame)
    @current_game_gfx.create_wait_for_play_screen
     
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
 
  ##
  # Paint
  def onCanvasPaint(sender, sel, event)
    dc = FXDCWindow.new(@image_double_buff)
    dc.foreground = @canvas_disp.backColor
    dc.fillRectangle(0, 0, @image_double_buff.width, @image_double_buff.height)
    if @current_game_gfx
      @current_game_gfx.draw_static_scene(dc, @image_double_buff.width, @image_double_buff.height)
    end
    dc.end #don't forget this, otherwise  problems on exit

    # blit image into the canvas
    dc_canvas = FXDCWindow.new(@canvas_disp, event)
    dc_canvas.drawImage(@image_double_buff, 0, 0)
    dc_canvas.end
    
  end #end onCanvasPaint
  
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
  