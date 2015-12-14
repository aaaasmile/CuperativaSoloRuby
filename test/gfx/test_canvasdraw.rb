#file: test_msgboxgfx.rb
#test messagebox control

require 'rubygems'
require 'test_basecontrol_gfx'


class TestMsgboxGfx < GameGfxSkeleton
  def initialize(app)
    @mainwindow = app
    super()
    @border_col = Fox.FXRGB(243, 240, 100)
    @resource_path = "../../res"
    @image_gfx_resource = {}
    @font = FXFont.new(getApp(), "comic", 10)
    @font.create
    load_resource
  end
  
  def load_resource
    res_sym = :back_tile_img
    png_resource =  File.expand_path( File.join(@resource_path ,"images/baize.png"))
    img = FXPNGIcon.new(getApp, nil,IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
    FXFileStream.open(png_resource, FXStreamLoad) { |stream| img.loadPixels(stream) }
    img.create
    @image_gfx_resource[res_sym] = img
  end
  
  def getApp
    return @mainwindow.getApp
  end
  
  def draw_static_scene(dc, width, height)
    # draw the static scene
    draw_texture(dc, width, height)
    dc.foreground = @border_col
    dc.lineWidth = 2
    dc.drawRoundRectangle(10,10, 200, 100, 5, 5 )
    dc.fillRoundRectangle(10,10, 200, 100, 5, 5 )
    dc.font = @font
    dc.foreground = Fox.FXRGB(0, 0, 0)
    dc.drawText(23, 27, "Picule: 5" )
    dc.drawFocusRectangle(200,200, 100, 100)
  end
  
  def draw_texture(dc, width, height)
    img_teil = @image_gfx_resource[:back_tile_img]
    x = 0
    y = 0
    while y <  height
      while x <  width
        dc.drawImage(img_teil, x, y)
        x  += img_teil.width
        #p x,y
      end
      y  += img_teil.height
      x = 0
      #p "y = #{y}"
    end
  end
  
end




if $0 == __FILE__
  theApp = FXApp.new("TestMyCanvasGfx", "FXRuby")
  mainwindow = TestCanvasGfx.new(theApp)
  mainwindow.set_position(0,0,800,600)
  tester = TestMsgboxGfx.new(mainwindow)
  mainwindow.current_game_gfx = tester
  theApp.create
  
  theApp.run
end