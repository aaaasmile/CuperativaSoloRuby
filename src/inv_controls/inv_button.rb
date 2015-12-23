# file: inv_button.rb

require 'inv_widget'
require 'inv_label'

class InvButton < InvWidget
  
  def initialize(x=0, y=0, w=0, h=0, zord=0, visb=true, rot=false)
    super(x,y,w,h,zord,visb,rot)
    
    @min_width = 70
    @min_height = 30
    check_min_height
    check_min_width
    map_container_callbacks(:CB_LMouseDown, method(:onLMouseDown))
  end
  
  def set_content(cont)
    if cont.kind_of?(String)
      @content = InvLabel.new
      @content.set_text(cont, :medium)
    end
  end
    
  def draw(dc, theme)
    return if @content == nil
    @border_thik = 1
    width_content = @content.calculate_width(theme)
    height_content = @content.calculate_height(theme)
    dc.foreground = theme.border_color
    dc.drawRectangle(@pos_x, @pos_y, @width, @height)
    
    dc.foreground = theme.main_color
    dc.fillRectangle(@pos_x + @border_thik, @pos_y + @border_thik, 
                     @width - @border_thik * 2, 
                     @height - @border_thik * 2)
    
    @content.pos_x = @pos_x + (@width - width_content) / 2
    @content.pos_y = @pos_y + (@height - height_content) / 2
    @content.draw(dc, theme)
  end
  
private
  def check_min_height
    @height = @min_height if @min_height < @min_height
  end
  
  def check_min_width
    @width = @min_width if @width < @min_width
  end
  
  def onLMouseDown(x,y)
    logdebug("Button handle mouse down event: x #{x}, y #{y}")
    return true
  end
  
end

