#file test_core_scopetta.rb
# Test some core scopetta functions

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'
$:.unshift File.dirname(__FILE__) + '/../../src'

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'

require 'fakestuff'

require 'core/core_game_base'
require 'games/scopetta/core_game_scopetta'
require 'games/scopetta/alg_cpu_scopetta'


include Log4r

##
# Test suite for testing 
class Test_Scopetta_core < Test::Unit::TestCase
  attr_reader :log
  
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameScopetta.new
    @rescheck = ResScopaChecker.new
    @io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', @io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
  end
  
  ######################################### TEST CASES ########################

  ##
  # Test a full match
  def test_simulated_game
    # set the custom logger
    
    
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
    player1.algorithm = AlgCpuScopetta.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuScopetta.new(player2, @core, nil)
    arr_players = [player1,player2]
    # start the match
    # execute only one event pro step to avoid stack overflow
    #@core.suspend_proc_gevents
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
  
  ##
  # Test custom smazzata
  def test_custom_smazzata
    # ---- custom deck begin
    # set a custom deck
    deck =  RandomManager.new
    deck.set_predefined_deck('_6b,_Rc,_5d,_5s,_Rb,_7b,_5b,_As,_7c,_4b,_2b,_Cc,_Fc,_Cs,_4d,_Rs,_Rd,_Cb,_Ab,_2c,_Fs,_3b,_Fd,_Ad,_Ac,_3d,_6s,_6c,_7d,_2d,_2s,_6d,_3s,_Fb,_Cd,_4s,_7s,_4c,_3c,_5c',1)
    @core.rnd_mgr = deck 
    # say to the core we need to use a custom deck
    @core.game_opt[:replay_game] = true
    # ---- custum deck end
    
    # need two dummy players
    player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
    player1.algorithm = AlgCpuSpazzino.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuSpazzino.new(player2, @core, nil)
    arr_players = [player1, player2]
    
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
      event_num = @core.process_only_one_gevent
    end
   
    @log.debug "Segno terminated"
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
  ##
  # Test function which_cards_pick
  def test_card_pick
    @core.create_deck
    card_on_table = [:_As, :_4s, :_Cs, :_3s, :_7d]
    @core.set_card_on_table(card_on_table)
    res = @core.which_cards_pick(:_Cc, card_on_table)
    assert_equal([[:_Cs]], res)
    res = @core.which_cards_pick(:_7c, card_on_table)
    #assert_equal([[:_7d], [:_3s, :_4s]], res)
    assert_equal([[:_7d]], res)
  end
  
  ##
  # Test function that calculate napula
  def test_napula_calc
    spade_arr = [8,3,2,7,1,9]
    res =  @core.calc_napula_points(spade_arr)
    assert_equal(3, res)
    res =  @core.calc_napula_points([5,2,7,1,3,4])
    assert_equal(5, res)
    res =  @core.calc_napula_points([6,2,7,1,3,4])
    assert_equal(4, res)
    res =  @core.calc_napula_points([6,2,7,8,3,4])
    assert_equal(0, res)
  end
   
  ###
  # Test which_cards_pick without limitation of rule use combination with less cards
  def test_which_card_pick_nolessrule
    @core.create_deck
    @core.game_opt[:combi_sum_lesscard] = false
    
    table = [:_7c, :_Ab, :_Rc, :_7d, :_6d, :_3b, :_2c]
    list = @core.which_cards_pick(:_5d, table)
    assert_equal([:_2c,:_3b], list[0])
    
    table = [:_Rd, :_5s, :_2d, :_4s, :_As]
    list = @core.which_cards_pick(:_3b, table)
    assert_equal([:_As,:_2d], list[0])
    
    table = [:_7b,:_5d,:_Ab,:_5s,:_2b,:_4b]
    list = @core.which_cards_pick(:_Rb, table)
    res_check = @rescheck.combicheck([[:_7b, :_2b, :_Ab], [:_5s, :_5d], [:_4b, :_5d, :_Ab]], list)
    assert_equal(true, res_check)
    
  end
  
  ## 
  # Test combination on wich card pick for rules scopa
  def test_which_card_pick2
    @core.create_deck
    
    table = [:_7b,:_5d,:_Ab,:_5s,:_2b,:_4b]
    list = @core.which_cards_pick(:_Rb, table)
    # we expect a combination with only 2 cards
    res_check = @rescheck.combicheck([[:_5s, :_5d]], list)
    assert_equal(true, res_check)
    # we expect only one item, because combinations with 3 cards are not allowed 
    # in scopa if we have a combination within a less number of cards
    assert_equal(1, list.size)
    
    # another deck
    #@core.game_opt[:combi_sum_lesscard] = false
    table = [:_4b,:_4c,:_6b,:_2s,:_3c]
    list = @core.which_cards_pick(:_Fb, table)
    res_check = @rescheck.combicheck([[:_4b,:_4c], [:_6b,:_2s]], list)
    assert_equal(true, res_check)
    assert_equal(2, list.size)
    
    # another deck
    table = [:_4b,:_4c,:_6b,:_2s,:_3c, :_Fc]
    list = @core.which_cards_pick(:_Fb, table)
    res_check = @rescheck.combicheck([[:_Fc]], list)
    assert_equal(true, res_check)
    assert_equal(1, list.size)
  end
  
  ##
  # Test last taker
  def test_lasttaker
    # set the custom logger
    @log.debug "Test last card taker take the table..."
    
    # ---- custom deck begin
    # set a custom deck
    deck =  RandomManager.new
    deck.set_predefined_deck('_As,_5d,_6b,_Rc,_Fs,_Rb,_7b,_5b,_7c,_4b,_2b,_Cc,_Fc,_Cs,_4d,_Rs,_Rd,_Cb,_Ab,_2c,_Fs,_3b,_Fd,_Ad,_Ac,_3d,_6s,_6c,_7d,_2d,_2s,_6d,_3s,_Fb,_Cd,_4s,_7s,_4c,_3c,_5c',1)
    @core.rnd_mgr = deck 
    # say to the core we need to use a custom deck
    @core.game_opt[:replay_game] = true
    # ---- custum deck end
    
    # need two dummy players
    player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
    player1.algorithm = AlgCpuSpazzino.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuSpazzino.new(player2, @core, nil)
    arr_players = [player1,player2]
    
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
      event_num = @core.process_only_one_gevent
    end
    # segno terminated
    assert_equal(true, @io_fake.checklogs('Last card played, Test2 take all the rest'))
    assert_equal(true, @io_fake.checklogs('Cards taken by Test2: _4s,_4c,_2d,_2s,_7d,_7s,_Ad,_Ac,_Fd,_3d,_5c,_Cb,_Cd,_Rs,_Rd,_Cc,_Cs,_Rc,_Rb,_Fs,_As'))
    @log.debug "Segno terminated"
  end
  
  def test_combi_forscopa
    @log.debug "combi RD"
    @core.create_deck
    # other deck
    card_on_table = [:_7c,:_7s,:_5c,:_Rc,:_4d,:_3d,:_Ac,:_2b]
    rankcard = 8
    res = @core.combi_of_sum(card_on_table, rankcard)
    #p res
    #res = [[:_5c, :_3d], [:_Ac, :_7s], [:_7c, :_Ac], [:_5c, :_2b, :_Ac ], [:_3d,:_Ac, :_4d]]
    res_check = @rescheck.combicheck([[:_7c, :_Ac], [:_7s, :_Ac], [:_3d, :_5c], [:_4d,:_3d,:_Ac], [:_5c, :_Ac,:_2b ]], res)
    assert_equal(true, res_check)
    
    card_on_table = [:_7c,:_3d,:_Fc,:_2b]
    rankcard = 10
    res = @core.combi_of_sum(card_on_table, rankcard)
    res_check = @rescheck.combicheck([[:_7c, :_3d], [:_Fc,:_2b]], res)
    assert_equal(true, res_check)
  end
  
  ##
  # test calculation of primiera
  def test_primiera
    @core.create_deck
    # first hand win
    cards_player_1_str = "_7s,_7b,_Ac,_Ab,_6b,_6s,_Cs,_Cc,_5b,_5s,_3d,_3s,_Fb,_Fs,_3b,_3c,_7c,_7d,_Rc,_Rs,_6d,_6c"
    cards_player_2_str = "_4s,_4b,_2d,_2b,_Rd,_Rb,_5c,_5d,_Fd,_Fc,_4d,_4c,_As,_Ad,_Cb,_Cd,_2s,_2c"
    hand_pl1 =  @rescheck.str_cards_tosymbarr(cards_player_1_str)
    hand_pl2 =  @rescheck.str_cards_tosymbarr(cards_player_2_str)
    primiera_pt = @core.calculate_primiera(hand_pl1, hand_pl2)
    assert_equal([1,0], primiera_pt)
    # test the particular case, suit is missed
    cards_player_1_str = "_7s,_7b,_Ac"
    cards_player_2_str = "_4s,_4b,_2d,_2b,_Rd,_Rb,_5c,_5d,_Fd,_Fc,_4d,_4c,_As,_Ad,_Cb,_Cd,_2s,_2c"
    hand_pl1 =  @rescheck.str_cards_tosymbarr(cards_player_1_str)
    hand_pl2 =  @rescheck.str_cards_tosymbarr(cards_player_2_str)
    primiera_pt = @core.calculate_primiera(hand_pl1, hand_pl2)
    assert_equal([0,1], primiera_pt)
    # both hands have missed one suit
    cards_player_1_str = "_7s,_7b,_Ac"
    cards_player_2_str = "_4s,_4b,_2d"
    hand_pl1 =  @rescheck.str_cards_tosymbarr(cards_player_1_str)
    hand_pl2 =  @rescheck.str_cards_tosymbarr(cards_player_2_str)
    primiera_pt = @core.calculate_primiera(hand_pl1, hand_pl2)
    assert_equal([0,0], primiera_pt)
    # same value, unassigned primiera
    cards_player_1_str = "_7s,_7b,_Ac,_2d"
    cards_player_2_str = "_7c,_7d,_As,_2b"
    hand_pl1 =  @rescheck.str_cards_tosymbarr(cards_player_1_str)
    hand_pl2 =  @rescheck.str_cards_tosymbarr(cards_player_2_str)
    primiera_pt = @core.calculate_primiera(hand_pl1, hand_pl2)
    assert_equal([0,0], primiera_pt)
  end
  
  ##
  # Checksum is 39 instead of 40. The last played card is not assigned.
  def test_game77
    rep = ReplayManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/s77_gc1_2008_12_29_20_31_27-savedmatch.yaml')
    alg_coll = { "Ospite1" => nil, "igor061" => nil }
    # start to play the first smazzata 
    rep.replay_match(@core, match_info, alg_coll, 0, 1)
    #@core.gui_new_segno
    # continue with the second
    #rep.replaynext_smazzata(@core, match_info, alg_coll, 1)
    assert_equal(0, @io_fake.error_count, "Errors")
    assert_equal(0, @io_fake.warn_count, "Warnings")
    
  end
  
  def test_card_carmelo
    @log.debug "Test carmelo"
    @core.create_deck
    card_on_table = [:_4s, :_5s, :_3s, :_2s]
    @core.set_card_on_table(card_on_table)
    @core.game_opt[:combi_sum_lesscard] = false
    res = @core.which_cards_pick(:_Cc, card_on_table)
    #p list_combi = @core.combi_of_sum(card_on_table, 9)
    #p @core.game_opt[:combi_sum_lesscard]
    assert_equal(2, res.size)
    @core.game_opt[:combi_sum_lesscard] = true
    res = @core.which_cards_pick(:_Cc, card_on_table)
    assert_equal(1, res.size)
    #res = @core.which_cards_pick(:_7c, card_on_table)
    #assert_equal([[:_7d]], res)
    #p res
  end
  
end


if $0 == __FILE__
  # use this file to run only one single test case
  tester = Test_Scopetta_core.new('test_game77')
  FakeIO.add_a_simple_assert(tester)
  
  tester.setup
  tester.log.outputters << Outputter.stdout
  tester.test_game77
  
  exit
end
