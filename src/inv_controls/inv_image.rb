#file: inv_image.rb


class InvImage < InvWidget
  
  def initialize(x=0, y=0, w=0, h=0, zord=0, visb=true, rot=false)
    super(x,y,w,h,zord,visb,rot)
    @image = nil
  end
  
  def set_icon(icon)
    @image = icon
    @image_type = :icon
  end
  
  def calculate_width(theme)
    @width = @image.width
    return @width
  end
  
  def calculate_height(theme)
    @height = @image.height
    return @height
  end
  
  def draw(dc, theme, width_cont, height_cont)
    if @image_type == :icon
      dc.drawIcon(@image, @pos_x, @pos_y)
    else
      raise "Image type #{@image_type} not yet supported "
    end
  end
  
  def draw_sunken(dc)
    if @image_type == :icon
      dc.drawIconSunken(@image, @pos_x, @pos_y)
    else
      raise "Image type #{@image_type} not yet supported "
    end
  end
end