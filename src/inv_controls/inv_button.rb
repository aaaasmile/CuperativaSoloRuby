# file: inv_button.rb

require 'inv_widget'

class InvButton < InvWidget
  attr_accessor :caption, :font 
  
  def initialize(x=0, y=0, w=0, h=0, zord=0, visb=true, rot=false)
    super(x,y,w,h,zord,visb,rot)
    @caption = ""
    @min_width = 70
    @min_height = 10
    check_min_height
    check_min_width
  end
  
  def set_content(cont)
    if cont.kind_of?(String)
      @caption = cont
    end
  end
  
  def set_style(style)
    if style == :auto
      calculate_width
      calculate_height
    end
  end
  
  def draw(dc, theme)
    @font = theme.fonts_text[:medium]
    @text_col = theme.fore_color
    width_text = @font.getTextWidth(@caption)
    dc.font = @font
    dc.foreground = @text_col
    dc.drawText(@pos_x + (@width - width_text) / 2, @pos_y + @height - 5, @caption)
  end
  
private
  def calculate_width
    @width = @font.getTextWidth(@caption) + 10
    check_min_width
  end
  
  def check_min_width
    @width = @min_width if @width < @min_width
  end
  
  def calculate_height
    @height = @font.getTextHeight(@caption) + 10
    check_min_height
  end
  
  def check_min_height
    @height = @min_height if @min_height < @min_height
  end
  
end

