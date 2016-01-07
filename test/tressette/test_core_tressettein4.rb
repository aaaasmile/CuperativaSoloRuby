#file test_core_tressettein4.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'
$:.unshift File.dirname(__FILE__) + '/../../src'

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'
require 'fakestuff'

require 'core/core_game_base'
require 'games/tressettein4/core_game_tressettein4'
require 'games/tressettein4/alg_cpu_tressettein4'



include Log4r

##
# Test suite for testing 
class Test_Tressettein4_core < Test::Unit::TestCase
 
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameTressettein4.new
  end
  
  ######################################### TEST CASES ########################
  
#=begin #this is the begin of a multiline comment, used to isolate a single testcase
  ##
  # Test a full match
  def test_simulated_game
    # set the custom logger
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    
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
    player1.algorithm = AlgCpuTressettein4.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuTressettein4.new(player2, @core, nil)
    player2.algorithm.level_alg = :master
    player1.algorithm.level_alg = :dummy
    
    player3 = PlayerOnGame.new("Pl3", nil, :cpu_alg, 2)
    player3.algorithm = AlgCpuTressettein4.new(player3, @core, nil)
    player4 = PlayerOnGame.new("Pl4", nil, :cpu_alg, 3)
    player4.algorithm = AlgCpuTressettein4.new(player4, @core, nil)
    
    arr_players = [player1,player2,player3,player4]
    # start the match
    # execute only one event pro step to avoid stack overflow
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
        event_num = @core.process_only_one_gevent
    end
    ## here segno is finished, 
    ## trigger a new one or end of match
    while @core.gui_new_segno == :new_giocata
      event_num = @core.process_only_one_gevent
      while event_num > 0
        event_num = @core.process_only_one_gevent
      end
    end
    # match terminated
    puts "Match terminated"
  end
     
end
