#file: mod_simple_event_handler.rb

module SimpleEventHandler
  
  #NOTE: &block: captures any passed block into that object
  def connect(symbol, handler = nil, &block) 
    item = handler != nil ? handler : block
    return unless item 
    @pub_events[symbol] = [] unless (@pub_events.has_key?(symbol)) 
    @pub_events[symbol] << item
    return item #provided to be used with disconnect
  end
  
  def disconnect(symbol, item) 
    return unless item and @pub_events[symbol]
    @pub_events[symbol].delete(item)
  end
  
  private
  
  def fire_event(ev_symbol, *args)
    return unless @pub_events.has_key?(ev_symbol)
    logdebug("Fire event #{ev_symbol}")
    @pub_events[ev_symbol].each{|item| call_fn_withargs(item, args)}
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