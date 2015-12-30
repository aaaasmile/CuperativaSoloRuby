# file: inv_button.rb

require 'inv_widget'
require 'inv_label'
require 'inv_image'

class InvButton < InvWidget
  attr_reader :content
  
  def initialize(x=0, y=0, w=0, h=0, zord=0, visb=true, rot=false)
    super(x,y,w,h,zord,visb,rot,"InvButton")
    
    @min_width = 70
    @min_height = 30
    check_min_height
    check_min_width
    map_container_callbacks(:CB_LMouseDown, method(:onLMouseDown))
    map_container_callbacks(:CB_LMouseUp, method(:onLMouseUp))
    @state_bt = :normal
  end
  
  def set_content(cont)
    if cont.kind_of?(String)
      @content = InvLabel.new
      @content.set_text(cont, :medium)
    elsif cont.kind_of?(FXPNGIcon)
      @content = InvImage.new
      @content.set_icon(cont)
    end
  end
    
  def draw(dc, theme, width_cont, height_cont)
    return if @content == nil
    logdebug("Draw the button")
    @border_thik = 1
    width_content = @content.calculate_width(theme)
    height_content = @content.calculate_height(theme)
    dc.foreground = theme.border_color
    dc.drawRectangle(@pos_x, @pos_y, @width, @height)
    
    
    dc.foreground = theme.main_color
    dc.foreground = theme.accent_color if @state_bt == :pressed
    
    dc.fillRectangle(@pos_x + @border_thik, @pos_y + @border_thik, 
                     @width - @border_thik * 2, 
                     @height - @border_thik * 2)
    
    @content.pos_x = @pos_x + (@width - width_content) / 2
    @content.pos_y = @pos_y + (@height - height_content) / 2
    if @state_bt == :pressed and @content.respond_to?(:draw_sunken) 
      @content.draw_sunken(dc)
    else
      @content.draw(dc, theme, width_cont, height_cont)
    end
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
    @state_bt = :pressed
    fire_event(:EV_update_partial, self, @pos_x, @pos_y, @width, @height)
  end
  
  def onLMouseUp(x,y)
    logdebug("Button handle mouse up event: x #{x}, y #{y}")
    if @state_bt == :pressed 
      fire_event(:EV_click, self) if point_is_inside?(x,y)
      fire_event(:EV_update_partial, self, @pos_x, @pos_y, @width, @height)
    end
    @state_bt = :normal
  end
  
end

