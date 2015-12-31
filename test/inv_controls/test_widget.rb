# file: test_widget

$:.unshift File.dirname(__FILE__) + '/../..'

require 'rubygems'
require 'log4r'
require 'src/inv_controls/inv_widget'


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
  
  def log(txt)
    @log.debug txt
  end
end