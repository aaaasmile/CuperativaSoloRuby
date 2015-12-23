# file: inv_panel.rb

require 'inv_theme'
require 'inv_button'

class InvPanel
  attr_accessor :verbose
    
  def initialize(owner, fxapp, theme=nil)
    @log = Log4r::Logger.new("coregame_log::InvPanel")
    @verbose = false
    @fxapp = fxapp
    @canvas_disp = FXCanvas.new(owner, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT )
    @canvas_disp.connect(SEL_PAINT, method(:onCanvasPaint))
    @canvas_disp.connect(SEL_CONFIGURE, method(:onCanvasSizeChange))
    @canvas_disp.connect(SEL_LEFTBUTTONPRESS, method(:onLMouseDown))
    @canvast_update_started = false
    @imgDbuffHeight = 0
    @imgDbuffWidth = 0
    @image_double_buff = nil
    @theme = theme
    @theme = InvTheme.create_default(fxapp) if theme == nil
    @widgets = []
  end
  
  def add(widget)
    @widgets << widget 
    @widgets.sort! {|x,y| y.z_order <=> x.z_order}
  end
  
private   
  def onCanvasSizeChange(sender, sel, event)
    logdebug("onCanvasSizeChange")
    adapt_to_canvas = false
    resolution = 3
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
      @imgDbuffHeight = @canvas_disp.height
      @imgDbuffWidth = @canvas_disp.width
      @image_double_buff = FXImage.new(@fxapp, nil, 
             IMAGE_SHMI|IMAGE_SHMP, @imgDbuffWidth, @imgDbuffHeight)
      @image_double_buff.create
    end
  end
    
  def onCanvasPaint(sender, sel, event)
    unless @canvast_update_started
      @canvast_update_started = true
      logdebug("onCanvasPaint start")
      dc = FXDCWindow.new(@image_double_buff)
      dc.foreground = @theme.back_color
      dc.fillRectangle(0, 0, @image_double_buff.width, @image_double_buff.height)
      
      @widgets.each{|item| item.draw(dc, @theme)}
      
      dc.end
      dc_canvas = FXDCWindow.new(@canvas_disp, event)
      dc_canvas.drawImage(@image_double_buff, 0, 0)
      dc_canvas.end
      @canvast_update_started = false
      logdebug("onCanvasPaint stop")
    end
  end
  
  def onLMouseDown(sender, sel, event)
    x = event.win_x
    y = event.win_y
    event_sym = :CB_LMouseDown 
    @widgets.each do |item|
      if item.visible and item.point_is_inside?(x,y) and item.has_handler?(event_sym)
        handled = item.handle_callback(event_sym, x, y)
        if handled != false
          logdebug("Event #{event_sym} handled")
          return
        end
      end
    end
  end
  
  def logdebug(txt)    
     @log.debug(txt) if @verbose
  end
end


if $0 == __FILE__
  $:.unshift File.dirname(__FILE__) + '/../..'
  
  require 'test/gfx/test_dialogbox' 
  
  class MyPanelContainer < FXDialogBox
    
    def initialize(owner)
      super(owner, "Panel Tester", DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE|DECOR_CLOSE,
          0, 0, 300, 300, 0, 0, 0, 0, 4, 4)
      @log = Log4r::Logger.new("coregame_log::MyPanelContainer")
      @log.debug "MyButtonContainer initialized"
      @panel = InvPanel.new(self, owner.main_app)
      @panel.verbose = true
      button = InvButton.new(20, 20, 100, 50)
      button.set_content("Play!")
      button.verbose = true
      button.connect(:click) {
        |x,y| puts "Click is here!!!!"
      }
      @panel.add(button)
    end
    
    def run
      @log.debug "Run it!"
      execute()
    end
  end
  
  
  TestRunnerDialogBox.create_app(MyPanelContainer)
  
end
