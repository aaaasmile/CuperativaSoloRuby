#file test_core_briscola5.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'
require 'fakestuff'

PATH_TO_CLIENT = File.expand_path(File.dirname(__FILE__) + '/../../src')

require File.join( PATH_TO_CLIENT, 'base/core_game_base')
require File.join( PATH_TO_CLIENT, 'games/briscola5/core_game_briscola5')
require File.join( PATH_TO_CLIENT, 'games/briscola5/alg_cpu_briscola5')

include Log4r

##
# Test suite for testing 
class Test_Briscola5 < Test::Unit::TestCase
   
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameBriscola5.new
  end
  
  def test_match
    # set the custom logger
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    
    ## ---- custom deck begin
    ## set a custom deck
    #deck =  RandomManager.new
    #deck.set_predefined_deck('_2d,_6b,_7s,_Fc,_Cd,_Rd,_Cb,_5d,_Ab,_4s,_Fb,_Cc,_7b,_As,_5s,_6d,_Fs,_Fd,_6c,_5b,_Cs,_6s,_3d,_3b,_4d,_3c,_2b,_7c,_Rs,_4c,_Rb,_2c,_4b,_2s,_Rc,_3s,_5c,_Ad,_7d,_Ac',0)
    #@core.rnd_mgr = deck 
    ## say to the core we need to use a custom deck
    #@core.game_opt[:replay_game] = true
    ## ---- custum deck end
    
    # need 5 players players
    arr_players = []
    5.times do |pl_ix|
      player = PlayerOnGame.new("Test_#{pl_ix + 1}", nil, :cpu_alg, 0)
      player.algorithm = AlgCpuBriscola5.new(player, @core, nil)
      arr_players << player
    end
  
    # start the match
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
      event_num = @core.process_only_one_gevent
    end
    ## trigger a new one or end of match
    #while @core.gui_new_segno == :new_giocata
    #  event_num = @core.process_only_one_gevent
    #  while event_num > 0
    #    event_num = @core.process_only_one_gevent
    #  end
    #end
    # match terminated
    puts "Match terminated"
    assert_equal(0, io_fake.warn_count)
    assert_equal(0, io_fake.error_count)
  end
  
  
end
