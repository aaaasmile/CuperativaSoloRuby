#file: inv_widget.rb

$:.unshift File.dirname(__FILE__) + '/..'

require 'core/mod_simple_event_publisher'

class InvWidget
  attr_accessor :pos_x, :pos_y,  :visible, :rotated, :z_order, :verbose
  
  include SimpleEventPublisher

  def initialize(x=0, y=0, w=0, h=0, zord=0, visb=true, rot=false, nameclass="InvWidget")
    @log = Log4r::Logger.new("coregame_log::#{nameclass}")
    @pos_x = x       
    @pos_y = y       
    @visible = visb  
    @rotated = rot   
    @z_order = zord
    @width = w
    @height = h
    @map_handler = {} #panel callbacks
    @pub_events = {} # widget events
    @verbose = false
  end
  
  def has_handler?(symbol)
    return @map_handler.has_key?(symbol)
  end
  
  def handle_callback(symbol, *args)
    logdebug "Callback for #{symbol}"
    res = false
    if(@map_handler.has_key?(symbol))
      res = call_fn_withargs(@map_handler[symbol], args)
    end
    return res
  end
  
  def point_is_inside?(x,y)
    binside = false
    if x >= @pos_x && x <= (@pos_x + @width) &&
       y >= @pos_y && y <= (@pos_y + @height)
      binside = true
    end
    return binside
  end
  
  def is_rect_inside?(x,y,w,h)
    top = point_is_inside?(x, y)
    bottom_right = point_is_inside?(x + w, y + h)
    return top && bottom_right
  end
  
private

  def logdebug(txt)    
     @log.debug(txt) if @verbose
  end
  
  def map_container_callbacks(symbol, handler = nil, &block)
    @map_handler[symbol] = handler != nil ? handler : block
  end
  
  
  
end

if $0 == __FILE__
  $:.unshift File.dirname(__FILE__) + '/../..'
  require 'test/inv_controls/test_widget'
  
  w1 = TestWidget.new
  block1 = w1.connect(:EV_click) do |sender|
    w1.log "*** Handle click event 1"
  end
  
  w1.raise_click
  
  w1.disconnect(:EV_click, block1)
  
  block2 = w1.connect(:EV_click) do |sender|
    w1.log "*** Handle click event 2"
  end
  
  w1.raise_click
  w1.disconnect(:EV_click, block2)
  
  w1.raise_click
end

