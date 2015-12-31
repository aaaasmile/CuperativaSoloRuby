# file: inv_label.rb


class InvLabel < InvWidget
  attr_accessor :caption

  def initialize(x=0, y=0, w=0, h=0, zord=0, visb=true, rot=false)
    super(x,y,w,h,zord,visb,rot)
    @caption = ""
  end
  
  def set_text(text, size)
    @caption = text
    @font_size_class = size
  end
  
  def calculate_width(theme)
    @font = theme.fonts_text[@font_size_class]
    @width = @font.getTextWidth(@caption)
    return @width
  end
  
  def calculate_height(theme)
    @font = theme.fonts_text[@font_size_class]
    @height = @font.getTextHeight(@caption)
    return @height
  end
  
  def draw(dc, theme, width_cont, height_cont)
    @font = theme.fonts_text[@font_size_class]
    @text_col = theme.fore_color
    @pos_y = @pos_y + @height * 3 / 4 # draw text start near to the bottom
    dc.font = @font
    dc.foreground = @text_col
    dc.drawText(@pos_x, @pos_y, @caption)
  end
  
end

