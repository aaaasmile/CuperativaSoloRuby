# file: inv_panel.rb

class InvPanel
    
  def initialize(owner, fxapp)
    @log = Log4r::Logger.new("coregame_log::InvPanel")
    @log.debug "InvPanel initialized"
    @fxapp = fxapp
    @canvas_disp = FXCanvas.new(owner, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT )
    @canvas_disp.connect(SEL_PAINT, method(:onCanvasPaint))
    @canvas_disp.connect(SEL_CONFIGURE, method(:onCanvasSizeChange))
    @color_backround = Fox.FXRGB(0xff, 0x00, 0x00)  
    @canvas_disp.backColor = @color_backround
    @canvast_update_started = false
    @imgDbuffHeight = 0
    @imgDbuffWidth = 0
    @image_double_buff = nil
  end
    
  def onCanvasSizeChange(sender, sel, event)
    @log.debug("onCanvasSizeChange")
    p @imgDbuffHeight = @canvas_disp.height
    p @imgDbuffWidth = @canvas_disp.width
    @image_double_buff = FXImage.new(@fxapp, nil, 
           IMAGE_SHMI|IMAGE_SHMP, @imgDbuffWidth, @imgDbuffHeight)
    @image_double_buff.create
  end
    
  def onCanvasPaint(sender, sel, event)
    unless @canvast_update_started
      @canvast_update_started = true
      @log.debug("onCanvasPaint start")
      dc = FXDCWindow.new(@image_double_buff)
      dc.foreground = @canvas_disp.backColor
      dc.fillRectangle(0, 0, @image_double_buff.width, @image_double_buff.height)
      dc.end
      dc_canvas = FXDCWindow.new(@canvas_disp, event)
      dc_canvas.drawImage(@image_double_buff, 0, 0)
      dc_canvas.end
      @canvast_update_started = false
      @log.debug("onCanvasPaint stop")
    end
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
    end
    
    def run
      @log.debug "Run it!"
      execute()
    end
  end
  
  
  TestRunnerDialogBox.create_app(MyPanelContainer)
  
end
