#file: inv_widget.rb


class InvWidget
  attr_accessor :pos_x, :pos_y,  :visible, :rotated, :z_order
  
  def initialize(x=0, y=0, w=0, h=0, zord=0, visb=true, rot=false )
    @pos_x = x       
    @pos_y = y       
    @visible = visb  
    @rotated = rot   
    @z_order = zord
    @width = w
    @height = h
    @map_handlers = {}
  end
  
  def has_handler?(symbol)
    return @map_handlers.has_key?(symbol)
  end
  
  def raise_event(symbol, *args)
    res = false
    if(@map_handlers.has_key?(symbol))
      handler = @map_handlers[symbol]
      handler.send(symbol, args)
    end
    return res
  end
  
  def connect(symbol, handler = nil)
    @map_handlers[symbol] = handler
  end
  
  def point_is_inside?(x,y)
    if x > @pos_x && x < (@pos_x + @width) &&
       y > @pos_y && y < (@pos_y + @height)
      binside = true
    else
      binside = false
    end
    return binside
  end
  
end

