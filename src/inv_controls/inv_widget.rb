#file: inv_widget.rb

require 'rubygems'

class InvWidget
  attr_accessor :pos_x, :pos_y,  :visible, :rotated, :z_order, :verbose
  
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
    @widget_events = {} # widget events
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
  
  #NOTE: &block: captures any passed block into that object
  def connect(symbol, handler = nil, &block) 
    item = handler != nil ? handler : block
    return unless item 
    @widget_events[symbol] = [] unless (@widget_events.has_key?(symbol)) 
    @widget_events[symbol] << item
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
  
  def fire_event(ev_symbol, *args)
    return unless @widget_events.has_key?(ev_symbol)
    logdebug("Fire event #{ev_symbol}")
    @widget_events[ev_symbol].each{|item| call_fn_withargs(item, args)}
  end
  
  def call_fn_withargs(item, args)
    res = nil
    case args.length 
      when 0
        res = item.call()
      when 1  
        res = item.call(args[0])
      when 2 
        res = item.call(args[0], args[1])
      when 3 
        res = item.call(args[0], args[1], args[2])
      when 4
        res = item.call(args[0], args[1], args[2], args[3])
      when 5
        res = item.call(args[0], args[1], args[2], args[3], args[4])
      when 6
        res = item.call(args[0], args[1], args[2], args[3], args[4], args[5])
      else
        raise "Too many arguments for the event handler"
      end
    return res
  end
  
end

if $0 == __FILE__
  require 'log4r'
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  class TestWidget < InvWidget
    def initialize
      super
      @log = Log4r::Logger.new("coregame_log::TestWidget") 
    end
    def raise_click
      @log.debug "fire :EV_click"
      fire_event(:EV_click, self)
    end
  end
  w1 = TestWidget.new
  w1.connect(:EV_click) do |sender|
    log.debug "*** Handle click event 1"
  end
  
  w1.raise_click
  
  w1.connect(:EV_click) do |sender|
    log.debug "*** Handle click event 2"
  end
  
  w1.raise_click
end

