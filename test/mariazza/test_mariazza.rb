#file: test_mariazza.rb
# unit test for mariazza game

$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'


$:.unshift File.dirname(__FILE__) + '/../../src'
$:.unshift File.dirname(__FILE__) + '/../..'

require 'core/core_game_base'
require 'games/mariazza/core_game_mariazza'
require 'games/mariazza/alg_cpu_mariazza'

require 'test/fakestuff'

include Log4r

##
# Test suite for testing 
class Test_mariazza_core < Test::Unit::TestCase
  attr_reader :log
  
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameMariazza.new
    @io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', @io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    
  end
  
  def test_createdeck
    @core.create_deck
    deck_info = @core.get_deck_info
    assert_equal(11, deck_info.get_card_info(:_Ab)[:points])
    assert_equal(10, deck_info.get_card_info(:_3d)[:points])
    assert_equal(0, deck_info.get_card_info(:_7c)[:points])
  end

  ##
  # Test a game where cpu algorithm try to change the 7 with briscola
  def test_cpu_change7
    rep = ReplayManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/mariaz_sett_cam_brisc.yaml')
    rep.replay_match(@core, match_info, {}, 0)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
  ##
  # G2 gioca per secondo. dichiara mariazza, g1 prende dichiara mariazza
  # g2 prende ma non gli venfono assegnati 20 punti
  def test_decl20after_marzdecl
    rep = ReplayManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/2008_05_08_20_21_15-3-no20pt.yaml')
    # replay the game
    alg_coll = { "Parma" => nil, "igor0500" => nil } 
    rep.replay_match(@core, match_info, alg_coll, segno_toplay = 1, max_num_segni_to_play = 1)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
    # check the fixed end result
    assert_equal(true, @io_fake.punteggio_raggiunto("igor0500 = 47 Parma = 39 "))
  end
  
  def test_match
    
    ## ---- custom deck begin
    ## set a custom deck
    #deck =  RandomManager.new
    #deck.set_predefined_deck('_2d,_6b,_7s,_Fc,_Cd,_Rd,_Cb,_5d,_Ab,_4s,_Fb,_Cc,_7b,_As,_5s,_6d,_Fs,_Fd,_6c,_5b,_Cs,_6s,_3d,_3b,_4d,_3c,_2b,_7c,_Rs,_4c,_Rb,_2c,_4b,_2s,_Rc,_3s,_5c,_Ad,_7d,_Ac',0)
    #@core.rnd_mgr = deck 
    ## say to the core we need to use a custom deck
    #@core.game_opt[:replay_game] = true
    ## ---- custum deck end
    
    # need two dummy players
    player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
    player1.algorithm = AlgCpuMariazza.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuMariazza.new(player2, @core, nil)
    arr_players = [player1,player2]
    # start the match
    # execute only one event pro step to avoid stack overflow
    #@core.suspend_proc_gevents
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
      event_num = @core.process_only_one_gevent
    end
    
    @log.debug "test: primo segno finito"
    # here segno is finished, 
    # trigger a new one or end of match
    while @core.gui_new_segno == :new_giocata
      event_num = @core.process_only_one_gevent
      while event_num > 0
        event_num = @core.process_only_one_gevent
      end
    end
    # match terminated
    @log.debug "Match terminated"
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
end #end Test_mariazza_core

if $0 == __FILE__
  # use this file to run only one single test case
  tester = Test_mariazza_core.new('test_createdeck')
  def tester.assert_equal(expected, actual, message=nil)
    res = expected == actual ? "OK" : "FAILED #{expected} but it is #{actual}"
    @log.debug res 
  end
  
  tester.setup
  tester.log.outputters << Outputter.stdout
  tester.test_createdeck
  exit
end