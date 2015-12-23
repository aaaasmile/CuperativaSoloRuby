#file: inv_widget.rb


class InvWidget
  attr_accessor :pos_x, :pos_y,  :visible, :rotated, :z_order, :verbose
  
  def initialize(x=0, y=0, w=0, h=0, zord=0, visb=true, rot=false )
    @log = Log4r::Logger.new("coregame_log::InvWidget")
    @pos_x = x       
    @pos_y = y       
    @visible = visb  
    @rotated = rot   
    @z_order = zord
    @width = w
    @height = h
    @map_handlers = {}
    @verbose = false
  end
  
  def has_handler?(symbol)
    return @map_handlers.has_key?(symbol)
  end
  
  def raise_event(symbol, *args)
    logdebug "Event raised #{symbol}"
    res = false
    if(@map_handlers.has_key?(symbol))
      handlers = @map_handlers[symbol]
      handlers.each do |item|
        case args.length 
        when 1  
          item.call(args[0])
        when 2 
          item.call(args[0], args[1])
        when 3 
          item.call(args[0], args[1], args[2])
        when 4
          item.call(args[0], args[1], args[2], args[3])
        else
          raise "Too many arguments for the event handler"
        end
      end
    end
    return res
  end
  
  
  def connect(symbol, handler = nil, &block) #&block: captures any passed block into that object
    @map_handlers[symbol] = [] unless (@map_handlers.has_key?(symbol))
    @map_handlers[symbol] << handler == nil ? handler : block
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
private
  def logdebug(txt)    
     @log.debug(txt) if @verbose
  end
end

