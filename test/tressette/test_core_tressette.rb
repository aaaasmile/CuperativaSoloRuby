#file test_core_spazzino.rb
# Test some core spazzino functions

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'
$:.unshift File.dirname(__FILE__) + '/../../src'

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'
require 'fakestuff'


require 'core/core_game_base'
require 'games/tressette/core_game_tressette'
require 'games/tressette/alg_cpu_tressette'



include Log4r

##
# Test suite for testing 
class Test_Tressette_core < Test::Unit::TestCase
  attr_reader :log
  
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameTressette.new
    @io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', @io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
  end
  
  ######################################### TEST CASES ########################
  
  ##
  # Test a full match
  def test_simulated_game
    # ---- custom deck begin
    # set a custom deck
    #deck =  RandomManager.new
    #deck.set_predefined_deck('_2d,_6b,_7s,_Fc,_Cd,_Rd,_Cb,_5d,_Ab,_4s,_Fb,_Cc,_7b,_As,_5s,_6d,_Fs,_Fd,_6c,_5b,_Cs,_6s,_3d,_3b,_4d,_3c,_2b,_7c,_Rs,_4c,_Rb,_2c,_4b,_2s,_Rc,_3s,_5c,_Ad,_7d,_Ac',0)
    #@core.rnd_mgr = deck 
    ## say to the core we need to use a custom deck
    #@core.game_opt[:replay_game] = true
    # ---- custum deck end
    
    # need two dummy players
    player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
    player1.algorithm = AlgCpuTressette.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuTressette.new(player2, @core, nil)
    player2.algorithm.level_alg = :master
    player1.algorithm.level_alg = :dummy
    arr_players = [player1,player2]
    # start the match
    # execute only one event pro step to avoid stack overflow
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
        event_num = @core.process_only_one_gevent
    end
    
    while @core.gui_new_segno == :new_giocata
      event_num = @core.process_only_one_gevent
      while event_num > 0
        event_num = @core.process_only_one_gevent
      end
    end
   
    @log.debug "Match terminated"
    
    assert_equal(0, @io_fake.error_count, "Errors")
    assert_equal(0, @io_fake.warn_count, "Warnings")
  end
     
end



if $0 == __FILE__
  # use this file to run only one single test case
  tester = Test_Tressette_core.new('test_simulated_game')
  FakeIO.add_a_simple_assert(tester)
  
  tester.setup
  tester.log.outputters << Outputter.stdout
  tester.test_simulated_game
  
  exit
end
