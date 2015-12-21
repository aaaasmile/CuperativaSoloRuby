#file: test_basecontrol_gfx.rb
# base class used to test some dialogbox

$:.unshift File.dirname(__FILE__) + '/../..'

require 'rubygems'
require 'fox16'
require 'src/base/core/sound_manager'

include Fox

class TestRunnerDialogBox < FXMainWindow
  attr_accessor :runner
  attr_reader :icons_app, :main_app, :sound_manager
    
  def initialize(anApp)
    @main_app = anApp 
    super(anApp, "TestRunnerDialogBox", nil, nil, DECOR_ALL, 30, 20, 640, 480)
    @runner = nil
    @sound_manager = SoundManager.new
    @conn_button = FXButton.new(self, "Go", nil, self, FXDialogBox::ID_ACCEPT,
              LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    @conn_button.connect(SEL_COMMAND, method(:go_test))
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
    @icons_app[:icon_update] = loadIcon("update.png")
    
    # timeout callback info hash
    @timeout_cb = {:locked => false, :queue => []}
  end
  
  # Provides the resource path
  def get_resource_path
    res_path = File.dirname(__FILE__) + "/../../res"
    return File.expand_path(res_path)
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
  
  def go_test(sender, sel, ptr)
    runner.run if runner
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
  
  def registerTimeout(timeout, met_sym_tocall, met_notifier)
    #p "register timer for msec #{timeout}"
    unless @timeout_cb[:locked]
      # register only one timeout at the same time
      @timeout_cb[:meth] = met_sym_tocall
      @timeout_cb[:notifier] = met_notifier
      @timeout_cb[:locked] = true
      getApp().addTimeout(timeout, method(:onTimeout))
    else
      #@corelogger.debug("registerTimeout on timeout pending, put it on the queue")
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
      #@corelogger.debug("Timer to register found in the timer queue (Resume with timeout #{timeout_adjusted})")
    else
      # no more timer to submit, free it
      #@corelogger.debug("onTimeout terminated ok")
      @timeout_cb[:locked] = false
      @timeout_cb[:queue] = []
    end
    return 1
  end
  
  def onCmdQuit(sender, sel, ptr)
    getApp().exit(0)
  end
   
end

######################################################




if $0 == __FILE__
  require 'log4r'
  include Log4r
  theApp = FXApp.new("TestMyCanvasGfx", "FXRuby")
  mainwindow = TestRunnerDialogBox.new(theApp)
  mainwindow.set_position(0,0,800,600)
  theApp.create
  
  theApp.run
end