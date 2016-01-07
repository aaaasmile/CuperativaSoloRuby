#file test_core_spazzino.rb
# Test some core spazzino functions

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'
require 'fakestuff'

PATH_TO_CLIENT = File.expand_path(File.dirname(__FILE__) + '/../../src')

require File.join( PATH_TO_CLIENT, 'core/core_game_base')
require File.join( PATH_TO_CLIENT, 'games/spazzino/core_game_spazzino')
require File.join( PATH_TO_CLIENT, 'games/spazzino/alg_cpu_spazzino')



include Log4r

##
# Test suite for testing 
class Test_Spazzino_core < Test::Unit::TestCase
 
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameSpazzino.new
    @rescheck = ResScopaChecker.new
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
    player1.algorithm = AlgCpuSpazzino.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuSpazzino.new(player2, @core, nil)
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
    puts "Match terminated"
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
    assert_equal([[:_7d], [:_3s, :_4s]], res)
  end
  
  ##
  # Test for picula
  def test_picula
    res =  @core.check_for_picula(:_Ad, :_Ab, [:_Ab] )
    assert_equal(1, res)
    res =  @core.check_for_picula(:_Ad, :_Ab, [:_Ab, :_4c] )
    assert_equal(0, res)
    res =  @core.check_for_picula(:_Ad, :_Ab, [] )
    assert_equal(0, res)
    res =  @core.check_for_picula(:_Cd, :_4d, [] )
    assert_equal(0, res)
  end
  
  ##
  # Test bager checker function
  def test_bager
    res =  @core.check_for_bager(:_6d, [:_2d, :_4s] )
    assert_equal(0, res)
    res =  @core.check_for_bager(:_7b, [:_3b, :_4b] )
    assert_equal(3, res)
    res =  @core.check_for_bager(:_Fc, [:_3c] )
    assert_equal(0, res)
    res =  @core.check_for_bager(:_Ab, [:_As] )
    assert_equal(0, res)
    res =  @core.check_for_bager(:_7c, [:_Ac, :_2c, :_4c] )
    assert_equal(4, res)
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
  
  def test_combi_standalone
    @core.create_deck
    
    card_on_table = [:_As, :_Ab, :_Ac, :_4c, :_2s, :_2c]
    rankcard = 7
    res = @core.combi_of_sum(card_on_table, rankcard)
    res_check = @rescheck.combicheck([[:_As, :_Ab, :_Ac, :_4c], [:_As, :_Ab, :_Ac, :_2s, :_2c], [:_4c, :_As, :_2c]], res)
    assert_equal(true, res_check)
  end
  
  ##
  # Test function combi_of_sum
  def test_combi
    @core.create_deck
    # other deck
    card_on_table = [:_As, :_4s, :_Cs, :_3s]
    rankcard = 7
    res = @core.combi_of_sum(card_on_table, rankcard)
    res_check = @rescheck.combicheck([[:_4s, :_3s]], res)
    assert_equal(true, res_check)
    
    # other deck
    card_on_table = [:_7b,:_5d,:_5s,:_2b,:_Rb]
    card = 7
    res = @core.combi_of_sum(card_on_table, card)
    res_check = @rescheck.combicheck([[:_5d, :_2b], [:_5s, :_2b]], res)
    assert_equal(true, res_check)
    # other deck
    card_on_table = [:_As, :_4s, :_Cs, :_3s, :_Cb, :_2c, :_Ad]
    rankcard = 5
    res = @core.combi_of_sum(card_on_table, rankcard)
    res_check = @rescheck.combicheck([[:_As, :_4s], [:_4s, :_Ad], [:_3s, :_2c]], res)
    assert_equal(true, res_check)
  end
  
  ##
  # Check a bug in combi
  def test_combi2
    @core.create_deck
    # other deck
    card_on_table = [:_7c,:_7s,:_5c,:_Rc,:_4d,:_3d,:_Ac,:_2b]
    rankcard = 7
    res = @core.combi_of_sum(card_on_table, rankcard)
    res_check = @rescheck.combicheck([[:_4d, :_3d], [:_4d, :_Ac, :_2b], [:_2b, :_5c]], res)
    assert_equal(true, res_check)
  end
  
  def test_which_card_pick
    table = [:_7c, :_Ab, :_Rc, :_7d, :_6d, :_3b, :_2c]
    @core.create_deck
    list = @core.which_cards_pick(:_5d, table)
    res_check = @rescheck.combicheck([[:_3b, :_2c]], [list[0]])
    assert_equal(true, res_check)
    
    table = [:_Rd, :_5s, :_2d, :_4s, :_As]
    list = @core.which_cards_pick(:_3b, table)
    res_check = @rescheck.combicheck([[:_2d, :_As]], [list[0]])
    assert_equal(true, res_check)
  end
  
  ##
  # Bug on erronuos assigned picula
  def test_bug_games27_211108
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    rep = ReplayManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/s27_gc1_2008_11_21_21_49_29-savedmatch.yaml')
    alg_coll = { "Alex" => nil, "igor060" => nil }
    # start to play the first smazzata 
    rep.replay_match(@core, match_info, alg_coll, 0)
    @core.gui_new_segno
    # continue with the second
    rep.replaynext_smazzata(@core, match_info, alg_coll, 1)
    # now build mano info
    io_fake.make_info_mano_onlogs
    # check result
    # now the error case, a picula was done when the user play 3s
    ix_mano =  io_fake.identify_mano('Card _3b played from  igor060. Taken: _3s')
    res = io_fake.checkdata_onmano(ix_mano, "picula")
    io_fake.display_mano_data(ix_mano)
    # correct result is no picula on mano 38
    assert_equal(false, res)
    
  end
  
  ##
  # Test last taker
  def test_lasttaker
    # set the custom logger
    puts "Test last card taker take the table..."
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    
    # ---- custom deck begin
    # set a custom deck
    deck =  RandomManager.new
    deck.set_predefined_deck('_As,_5d,_Rc,_Rb,_6b,_Fs,_7b,_5b,_7c,_4b,_2b,_Cc,_Fc,_Cs,_4d,_Rs,_Rd,_Cb,_Ab,_2c,_Fs,_3b,_Fd,_Ad,_Ac,_3d,_6s,_6c,_7d,_2d,_2s,_6d,_3s,_Fb,_Cd,_4s,_7s,_4c,_3c,_5c',1)
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
    # start the match
    # execute only one event pro step to avoid stack overflow
    #@core.suspend_proc_gevents
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
      event_num = @core.process_only_one_gevent
    end
    # segno terminated
    assert_equal(true, io_fake.checklogs('Last card played, Test2 take all the rest'))
    assert_equal(true, io_fake.checklogs('Riepilogo carte prese da Test2: _4s,_4c,_2d,_2s,_7d,_7s,_Ad,_Ac,_3b,_3d,_Cb,_Cd,_Rs,_Rd,_Cc,_Cs,_6b,_6c,_Rb,_Rc,_2b,_4b,_7b,_Fs,_5d,_As'))
    puts "Segno terminated"
  end  

  ##
  # Test custom segno
  def test_custom_segno
    # set the custom logger
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    
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
    arr_players = [player1,player2]
    # start the match
    # execute only one event pro step to avoid stack overflow
    #@core.suspend_proc_gevents
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
      event_num = @core.process_only_one_gevent
    end
    # segno terminated
    assert_equal(true, io_fake.checklogs('Riepilogo carte prese da Test1: _3s,_3c,_6s,_6d,_Fs,_Fb,_Fc,_Fd,_7c,_Ab,_2c,_4d,_5b,_5c,_Rc,_Rb,_6b,_6c'))
    puts "Segno terminated"
  end
#=end
  
  def test_deuced_match
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    
    @log.debug "Test if a macth can handle deuced points"
    # need two dummy players
    player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
    player1.algorithm = AlgCpuSpazzino.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuSpazzino.new(player2, @core, nil)
    arr_players = [player1,player2]
    # start the match
    # execute only one event pro step to avoid stack overflow
    #@core.suspend_proc_gevents
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
      event_num = @core.process_only_one_gevent
    end
    @log.debug "end of segno"
    # here segno is finished, 
    @core.points_curr_match.each do |k,v|
      #force deuce
      @core.points_curr_match[k] = 34
    end
    #p @core.points_curr_match
    
    # trigger a new one or end of match
    while @core.gui_new_segno == :new_giocata
      event_num = @core.process_only_one_gevent
      while event_num > 0
        event_num = @core.process_only_one_gevent
      end
    end
  end
    
end
