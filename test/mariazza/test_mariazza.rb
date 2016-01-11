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
    create_core
    @io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', @io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
  end
  
  def create_core
    @core = CoreGameMariazza.new
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
    name1 = "Gino B."
    player1 = PlayerOnGame.new(name1, nil, :replicant, 1)
    alg_pl1 = AlgCpuMariazza.new(player1, @core, nil) 
    name0 = "Toro"
    player0 = PlayerOnGame.new(name0, nil, :replicant, 0)
    alg_pl0 = AlgCpuMariazza.new(player0, @core, nil)
    alg_coll = { name0 => alg_pl0, name1 => alg_pl1 }
    rep.replay_match(@core, match_info, alg_coll, 0, 1)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
  def test_cpu_change7_withcoreblocked
    deck =  RandomManager.new
    deck.set_predefined_deck('_3c,_Ab,_4b,_Cd,_6d,_Fb,_2b,_4c,_3b,_7c,_3d,_5b,_Ad,_2s,_Rs,_Fd,_2d,_4s,_Cb,_3s,_6b,_5c,_5s,_Cs,_7b,_Fs,_7d,_5d,_6c,_Rb,_Rd,_2c,_Fc,_Cc,_Rc,_Ac,_6s,_4d,_7s,_As',1) #deck fake to test the first hand alg
    @core.rnd_mgr = deck
    @core.game_opt[:replay_game] = true
    player1 = PlayerOnGame.new("Me", nil, :cpu_alg, 0)
    player1.algorithm = AlgCpuMariazza.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Cpu", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuMariazza.new(player2, @core, nil)
    arr_players = [player1,player2]
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
      event_num = @core.process_only_one_gevent
    end
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
  
  def test_hangup_after_decl
    # The match was broken (segno ix = 3) because "Igor" played _3b and "Gino B." declared the mariazza bastoni.
    # But the game did not continue and the 'giocata_end' was missed.
    rep = ReplayManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/Mariazza_2016_01_08_21_02_23.yaml')
    player1 = PlayerOnGame.new("Gino B.", nil, :replicant, 1)
    alg_pl1 = AlgCpuMariazza.new(player1, @core, nil) 
    # "Gino B." should be a replicant but then continue with :cpu_alg (the saved game was incompleted)
    # "Igor" instead is only a replicant from match_info.
    alg_coll = { "Igor" => nil, "Gino B." => alg_pl1 }
    rep.replay_match(@core, match_info, alg_coll, segno_toplay = 3, max_num_segni_to_play = 1)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
    assert_equal(true, @io_fake.checklogs('giocata_end'))
    assert_equal(45, @core.points_curr_segno["Igor"])
  end
  
  def test_match
    ## ---- custom deck begin
    ## set a custom deck
    #deck =  RandomManager.new
    #deck.set_predefined_deck('_4c,_3s,_Fc,_Cc,_Cb,_Ad,_Rb,_5s,_Cd,_7d,_Ac,_3c,_Fs,_2s,_5d,_3b,_4d,_Cs,_2b,_6b,_4b,_Fd,_Rc,_5c,_2d,_6d,_3d,_Rs,_2c,_Rd,_As,_7b,_7s,_Fb,_5b,_Ab,_6s,_4s,_7c,_6c',0)
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
    # start the match
    @core.gui_new_match(arr_players)
    while @core.is_game_ongoing? 
      event_num = @core.process_only_one_gevent
      while event_num > 0
        event_num = @core.process_only_one_gevent
      end
      @core.gui_new_segno
    end
    # match terminated
    @log.debug "Match terminated"
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
  def test_match_serie(limit = 20)
    count = 0
    while count < limit
      @log.debug "Match num #{count}"
      test_match
      create_core
      count += 1
    end
    @log.debug "All #{count} matches terminated"
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
end #end Test_mariazza_core

if $0 == __FILE__
  # use this file to run only one single test case
  tester = Test_mariazza_core.new('test_match_serie')
  FakeIO.add_a_simple_assert(tester)
  
  tester.setup
  tester.log.outputters << Outputter.stdout
  tester.test_match_serie(100)
  exit
end