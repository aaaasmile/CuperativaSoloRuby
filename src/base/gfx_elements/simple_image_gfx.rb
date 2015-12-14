#file: simple_image_gfx.rb

class SimpleImageGfx < ClickableGfx
  
  def initialize(creator=nil, x=0, y=0, img=nil, zord=0, visb=true)
    super(x,y,zord,visb,false)
    @creator = creator
    @image = img    
    @z_order = zord
    @vel_x = 0
    @vel_y = 0
    @width = @image.width
    @height = @image.height
    # used to store custom data
    @cd_data = {}
  end
  
  def draw_card(dc)
    return if @visible == false
    dc.drawIcon(@image, @pos_x, @pos_y)
  end
  
  def on_mouse_lclick(x,y)
    if point_is_inside?(x,y)
      @creator.send(:evgfx_click_on_image, self)
      return true
    end
    return false
  end
  
end #end SimpleImageGfx

