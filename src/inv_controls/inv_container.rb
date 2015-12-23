# file: inv_container.rb

require 'inv_theme'
require 'inv_button'

class InvContainer
  attr_accessor :verbose
    
  def initialize(owner, fxapp, theme=nil)
    @log = Log4r::Logger.new("coregame_log::InvContainer")
    @verbose = false
    @fxapp = fxapp
    @canvas_disp = FXCanvas.new(owner, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT )
    @canvas_disp.connect(SEL_PAINT, method(:onCanvasPaint))
    @canvas_disp.connect(SEL_CONFIGURE, method(:onCanvasSizeChange))
    @canvas_disp.connect(SEL_LEFTBUTTONPRESS){|sender, sel, event|
      check_mouse_callback(:CB_LMouseDown, event.win_x, event.win_y)
    }
    @canvas_disp.connect(SEL_LEFTBUTTONRELEASE){|sender, sel, event|
      check_mouse_callback(:CB_LMouseUp, event.win_x, event.win_y){|widget, event_sym| 
        widget.visible && widget.has_handler?(event_sym)
      }
    }
    @canvast_update_started = false
    @imgDbuffHeight = 0
    @imgDbuffWidth = 0
    @image_double_buff = nil
    @theme = theme
    @theme = InvTheme.create_default(fxapp) if theme == nil
    @widgets = []
  end
  
  def add(widget)
    widget.connect(:EV_update_partial) {|sender, x,y,w,h| 
      @canvas_disp.update(x,y,w,h)
    }
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
      p "paint", event.rect.x, event.rect.y, event.rect.w, event.rect.h 
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
  
  def check_mouse_callback(event_sym, x, y, &block)
    @widgets.each do |item|
      #NOTE: brackets needed because 'condition = true and false' is different from 'condition = (true and false)'. Using && instead of 'and' does not needs brackets.
      condition = block != nil ? yield(item, event_sym) :  
        (item.visible && item.point_is_inside?(x,y) && item.has_handler?(event_sym)) 
      if condition == true
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
  
  class SimpleContainerTest < FXDialogBox
    
    def initialize(owner)
      super(owner, "Container Tester", DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE|DECOR_CLOSE,
          0, 0, 300, 300, 0, 0, 0, 0, 4, 4)
      @log = Log4r::Logger.new("coregame_log::SimpleContainerTest")
      @log.debug "Initialized"
      @container = InvContainer.new(self, owner.main_app)
      @container.verbose = true
      button = InvButton.new(20, 20, 100, 50)
      button.set_content("Play!")
      button.verbose = true
      button.connect(:EV_click) {
        |sender| puts "Click is here!!!!"
      }
      @container.add(button)
    end
    
    def run
      @log.debug "Run it!"
      execute()
    end
  end
  
  
  TestRunnerDialogBox.create_app(SimpleContainerTest)
  
end
