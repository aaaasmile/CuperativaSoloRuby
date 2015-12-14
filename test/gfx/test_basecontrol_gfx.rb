#file: test_basecontrol_gfx.rb
# base class used to test some graphics

require 'rubygems'
require 'fox16'

include Fox

class TestCanvasGfx < FXMainWindow
  attr_accessor :current_game_gfx
  
  def initialize(anApp)
    super(anApp, "TestCanvasGfx", nil, nil, DECOR_ALL, 30, 20, 640, 480)
    @canvas_disp = FXCanvas.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT )
    @canvas_disp.connect(SEL_PAINT, method(:onCanvasPaint))
    @canvas_disp.connect(SEL_LEFTBUTTONPRESS, method(:onLMouseDown))
    @canvas_disp.connect(SEL_CONFIGURE, method(:OnSizeChange))
    @color_backround = Fox.FXRGB(50, 170, 10) 
    @canvas_disp.backColor = @color_backround
    # double buffer image for canvas
    @imgDbuffHeight = 0
    @imgDbuffWidth = 0
    @image_double_buff = nil
    @canvast_update_started = false
    @current_game_gfx = GameGfxSkeleton.new
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
  
  ##
  # Size of canvas is changing
  def OnSizeChange(sender, sel, event)
    #log_sometext("OnSizeChange w:#{@canvas_disp.width}, h:#{@canvas_disp.height}\n")
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
      dc.fillRectangle(0, 0, @image_double_buff.width, @image_double_buff.height)
    
      # draw scene into the picture
      @current_game_gfx.draw_static_scene(dc, @image_double_buff.width, @image_double_buff.height)
      
      dc.end #don't forget this, otherwise  problems on exit
      
      # blit image into the canvas
      dc_canvas = FXDCWindow.new(@canvas_disp, event)
      dc_canvas.drawImage(@image_double_buff, 0, 0)
      dc_canvas.end
      
      @canvast_update_started = false
    end
  end
  
  ##
  # Mouse left down event on canvas
  def onLMouseDown(sender, sel, event)
    @current_game_gfx.onLMouseDown(event)
  end
  
  def mycritical_error(str)
    FXMessageBox.error(self, MBOX_OK, "Errore applicazione", str)
    exit
  end
   
end

######################################################

class GameGfxSkeleton
  def onLMouseDown(event)
  end
  
  def draw_static_scene(dc, width, height)
    # draw the static scene
    
  end
  
  def onSizeChange(width,height)
  end
  
end


if $0 == __FILE__
  theApp = FXApp.new("TestMyCanvasGfx", "FXRuby")
  mainwindow = TestCanvasGfx.new(theApp)
  mainwindow.set_position(0,0,800,600)
  theApp.create
  
  theApp.run
end