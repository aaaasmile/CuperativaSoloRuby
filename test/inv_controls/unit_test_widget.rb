# file: unit_test_widget.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../..'

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'test/fakestuff'
require 'test_widget'

include Log4r

class UnitTestWidget < Test::Unit::TestCase
  attr_reader :log
  
  def setup
    @log = Log4r::Logger.new("coregame_log")
  end
  
  def test_events
    @log.debug "Test"
    w1 = TestWidget.new
    click_evnt_1 = 0
    click_evnt_2 = 0
    block1 = w1.connect(:EV_click) do |sender|
      @log.debug "Handle click event 1"
      click_evnt_1 += 1
    end
    w1.raise_click
    assert_equal(1, click_evnt_1)
    
    w1.disconnect(:EV_click, block1)
  
    block2 = w1.connect(:EV_click) do |sender|
      w1.log "Handle click event 2"
      click_evnt_2 += 1
    end
    
    w1.raise_click
    assert_equal(1, click_evnt_2)
    
    w1.disconnect(:EV_click, block2)
    w1.raise_click
    
    assert_equal(1, click_evnt_1)
    assert_equal(1, click_evnt_2)
    
  end
  
end


if $0 == __FILE__
  atest = UnitTestWidget.new('test_events')
  FakeIO.add_a_simple_assert(atest)
  atest.setup
  atest.log.outputters << Outputter.stdout
  atest.test_events
  exit
end