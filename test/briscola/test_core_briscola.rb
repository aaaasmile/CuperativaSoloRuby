#file test_core_briscola.rb
# Test some core briscola functions



$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'
require 'fakestuff'

PATH_TO_CLIENT = File.expand_path(File.dirname(__FILE__) + '/../../src')

require File.join( PATH_TO_CLIENT, 'core/core_game_base')
require File.join( PATH_TO_CLIENT, 'games/briscola/core_game_briscola')
require File.join( PATH_TO_CLIENT, 'games/briscola/alg_cpu_briscola')

include Log4r

##
# Test suite for testing 
class Test_Core_Briscola < Test::Unit::TestCase 
  attr_reader :log
  
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameBriscola.new
    @io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', @io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    #@log.outputters << Outputter.stdout
  end
  
  def test_game_equal
    rep = ReplayManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/2008_03_17_22_39_52-6-savedmatch.yaml')
    player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
    #alg_cpu1 = AlgCpuBriscola.new(player1, @core)
    alg_coll = { "ospite1" => nil, "igor050" => nil } 
    segno_num = 2
    rep.replay_match(@core, match_info, alg_coll, segno_num)
    @core.gui_new_segno
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
   ##
  # Problem with play _Fc
  def test_not_allowedcard
    rep = ReplayManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/2008_04_23_20_01_33-1-savedmatch.yaml')
    player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
    #alg_cpu1 = AlgCpuBriscola.new(player1, @core, nil)
    alg_coll = { "Gino B." => nil, "Toro" => nil } 
    segno_num = 0
    rep.replay_match(@core, match_info, alg_coll, segno_num)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
  def test_prende_briscola    
    # ---- custom deck begin
    # set a custom deck
    deck =  RandomManager.new
    deck.set_predefined_deck('_2d,_6b,_7s,_Fc,_Cd,_Rd,_Cb,_5d,_Ab,_4s,_Fb,_Cc,_7b,_As,_5s,_6d,_Fs,_Fd,_6c,_5b,_Cs,_6s,_3d,_3b,_4d,_3c,_2b,_7c,_Rs,_4c,_Rb,_2c,_4b,_2s,_Rc,_3s,_5c,_Ad,_7d,_Ac',0)
    @core.rnd_mgr = deck 
    # say to the core we need to use a custom deck
    @core.game_opt[:replay_game] = true
    ## ---- custum deck end
    player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
    player1.algorithm = AlgCpuBriscola.new(player1, @core, nil)
    player1.algorithm.level_alg = :predefined
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuBriscola.new(player2, @core, nil)
    player2.algorithm.level_alg = :predefined
    arr_players = [player1,player2]
    
    player1.algorithm.add_card_to_predef_stack(:_Ad)
    player2.algorithm.add_card_to_predef_stack(:_Rc)
    
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
      next_event =  @core.read_next_ev_handl
      event_num = @core.process_only_one_gevent
      if(next_event == :mano_end)
        @log.debug "Mano end, test terminated"
        assert_equal(15, @core.points_curr_segno["Test2"])
        break
      end
    end
    assert_equal(0, @io_fake.warn_count)
  end
  
  def test_gioca_carta_sbagliata
    
    # ---- custom deck begin
    # set a custom deck
    deck =  RandomManager.new
    deck.set_predefined_deck('_2d,_6b,_7s,_Fc,_Cd,_Rd,_Cb,_5d,_Ab,_4s,_Fb,_Cc,_7b,_As,_5s,_6d,_Fs,_Fd,_6c,_5b,_Cs,_6s,_3d,_3b,_4d,_3c,_2b,_7c,_Rs,_4c,_Rb,_2c,_4b,_2s,_Rc,_3s,_5c,_Ad,_7d,_Ac',0)
    @core.rnd_mgr = deck 
    # say to the core we need to use a custom deck
    @core.game_opt[:replay_game] = true
    ## ---- custum deck end
    player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
    player1.algorithm = AlgCpuBriscola.new(player1, @core, nil)
    player1.algorithm.level_alg = :predefined
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuBriscola.new(player2, @core, nil)
    player2.algorithm.level_alg = :predefined
    arr_players = [player1,player2]
    
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    @core.process_only_one_gevent
    player1.algorithm.add_card_to_predef_stack(:_As)
    @core.process_only_one_gevent
    # carta non corretta, aspetto un warning
    assert_equal(1, @io_fake.warn_count)
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
    player1.algorithm = AlgCpuBriscola.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuBriscola.new(player2, @core, nil)
    arr_players = [player1,player2]
    # start the match
    # execute only one event pro step to avoid stack overflow
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
      event_num = @core.process_only_one_gevent
    end
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
 
end

if $0 == __FILE__
  # use this file to run only one single test case
  tester = Test_Core_Briscola.new('test_prende_briscola')
  FakeIO.add_a_simple_assert(tester)
  
  tester.setup
  tester.log.outputters << Outputter.stdout
  tester.test_prende_briscola
end
