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
    @canvas_disp.connect(SEL_LEFTBUTTONPRESS, method(:onLMouseDown))
    @canvas_disp.connect(SEL_LEFTBUTTONRELEASE, method(:onLMouseUp))
    
    @canvast_update_started = false
    @imgDbuffHeight = 0
    @imgDbuffWidth = 0
    @image_double_buff = nil
    @theme = theme
    @theme = InvTheme.create_default(fxapp) if theme == nil
    @widgets = []
    @updates_req = []
  end
  
  def add(widget)
    widget.connect(:EV_update_partial) {|sender, x,y,w,h| 
      @updates_req << {:x => x, :y => y, :w => w ,:h => h, :type => :EV_update_partial}
    }
    widget.connect(:EV_update) {|sender| 
      @updates_req << {:type => :EV_update}
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
  
  def drawPartial(event, x,y,w,h)
    @canvast_update_started = true
    logdebug("Canvas Paint partial")
    dc = FXDCWindow.new(@image_double_buff)
    @widgets.each do |item|
      if item.is_rect_inside?(x,y,w,h)
        item.draw(dc, @theme)
      end
    end
    dc.end
    
    dc_canvas = FXDCWindow.new(@canvas_disp, event)
    dc_canvas.drawImage(@image_double_buff, 0, 0)
    dc_canvas.end
    @updates_req = [] 
    @canvast_update_started = false
  end
    
  def onCanvasPaint(sender, sel, event)
    unless @canvast_update_started
      if @updates_req.size == 1 and @updates_req[0][:type] == :EV_update_partial
        drawPartial(event, event.rect.x, event.rect.y, event.rect.w, event.rect.h)
        return
      end
      @updates_req = [] 
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
          logdebug("Event #{event_sym} L mouse down handled")
          break
        end
      end
    end
    check_for_canvas_update
  end
  
  def onLMouseUp(sender, sel, event)
    x = event.win_x
    y = event.win_y
    event_sym = :CB_LMouseUp
    @widgets.each do |item|
      if item.visible and item.has_handler?(event_sym)
        item.handle_callback(event_sym, x, y)
      end
    end
    check_for_canvas_update
  end
  
  def check_for_canvas_update
    if @updates_req.size == 1 and @updates_req[0][:type] == :EV_update_partial
      @canvas_disp.update(@updates_req[0][:x], @updates_req[0][:y], @updates_req[0][:w], @updates_req[0][:h])
    elsif @updates_req.size > 0
      @canvas_disp.update
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
      button.set_content("Gooo!")
      button.verbose = true
      button.connect(:EV_click) {
        |sender| puts "Click GOOOO is here!!!!"
      }
      @container.add(button)
      
      button2 = InvButton.new(20, 90, 100, 50)
      button2.set_content("Stop")
      button2.connect(:EV_click) {
        |sender| puts "Click STOOOOP is here!"
      }
      @container.add(button2)
      
      button3 = InvButton.new(20, 170, 100, 50)
      button3.set_content(owner.icons_app[:ok])
      button3.verbose = true
      button3.connect(:EV_click) {
        |sender| puts "Click OOOK is here!"
      }
      @container.add(button3)
    end
    
    def run
      @log.debug "Run it!"
      execute()
    end
  end
  
  
  TestRunnerDialogBox.create_app(SimpleContainerTest)
  
end
