#file test_core_tombolon.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'
$:.unshift File.dirname(__FILE__) + '/../../src'

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'

require 'fakestuff'

require 'core/core_game_base'
require 'games/tombolon/core_game_tombolon'
require 'games/tombolon/alg_cpu_tombolon'


include Log4r

##
# Test suite for testing 
class Test_Tombolon_core < Test::Unit::TestCase
  
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameTombolon.new
    @rescheck = ResScopaChecker.new
  end
  
  ######################################### TEST CASES ########################
#=begin

  ##
  # Test a full match
  def test_simulated_game
    # set the custom logger
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
      
    # need two dummy players
    player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
    player1.algorithm = AlgCpuTombolon.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuTombolon.new(player2, @core, nil)
    arr_players = [player1,player2]
    # start the match
    # execute only one event pro step to avoid stack overflow
    @core.suspend_proc_gevents
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
    assert_equal(0, io_fake.error_count)
    assert_equal(0, io_fake.warn_count)
  end
    
  def test_tombolon
    @core.create_deck
    hand = [:_As, :_2s, :_3s, :_4s, :_5s, :_6s, :_7s, :_Fs, :_Cs, :_Rs, :_7d]
    res = @core.check_for_tobolon(hand)
    assert_equal(false, res)
    hand = [:_As, :_2s, :_3s, :_4s, :_5s, :_6s, :_7s, :_Fs, :_Cs, :_Rs, :_7d,:_Ac, :_2c, :_3c, :_4c, :_5c, :_6c, :_7c, :_Fc, :_Cc, :_Rc]
    res = @core.check_for_tobolon(hand)
    assert_equal(true, res)
    hand = [:_As, :_2b, :_3s, :_4s, :_5s, :_6s, :_7s, :_Fs, :_Cs, :_Rs, :_7d,:_Ac, :_2c, :_3c, :_4c, :_5c, :_6c, :_7c, :_Fc, :_Cc, :_Rc]
    res = @core.check_for_tobolon(hand)
    assert_equal(false, res)
    hand = [:_As, :_2s, :_3s, :_4s, :_5s, :_6s, :_7s, :_Fs, :_Cs, :_Rs, :_7c,:_Ac, :_2c, :_3c, :_4c, :_5c, :_6c, :_7c, :_Fc, :_Cc, :_Rc]
    res = @core.check_for_tobolon(hand)
    assert_equal(false, res)
  end
  
  ##
  # Test points assigned when a player does scopa
  def test_scopa_points
    @core.create_deck
    res = @core.points_scopa(:_7s)
    assert_equal(7, res)
    res = @core.points_scopa(:_Fc)
    assert_equal(3, res)
    res = @core.points_scopa(:_Rd)
    assert_equal(5, res)
    res = @core.points_scopa(:_Cd)
    assert_equal(4, res)
    res = @core.points_scopa(:_4s)
    assert_equal(4, res)
  end
  
  ##
  # Test bager checker function
  def test_scopa_colore
    @core.create_deck
    res =  @core.check_for_scopa_colore(:_6d, [:_2d, :_4s] )
    assert_equal(0, res)
    res =  @core.check_for_scopa_colore(:_7b, [:_3b, :_4b] )
    assert_equal(7, res)
    res =  @core.check_for_scopa_colore(:_Fc, [:_3c] )
    assert_equal(0, res)
    res =  @core.check_for_scopa_colore(:_Ab, [:_As] )
    assert_equal(0, res)
    res =  @core.check_for_scopa_colore(:_7c, [:_Ac, :_2c, :_4c] )
    assert_equal(7, res)
    res =  @core.check_for_scopa_colore(:_Rc, [:_Rb] )
    assert_equal(0, res)
    res =  @core.check_for_scopa_colore(:_5c, [:_3c, :_2c] )
    assert_equal(5, res)
  end
#=end
  def test_game_predf
     # set the custom logger
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    
    # ---- custom deck begin
    # set a custom deck
    deck =  RandomManager.new
    deck.set_predefined_deck('_4b,_7b,_Rd,_Fc,_6s,_6d,_7s,_7d,_2s,_4c,_3s,_5c,_7c,_2c,_Fb,_Cb,_Ad,_6b,_Fd,_2b,_4d,_5d,_Cc,_6c,_4s,_Rs,_Fs,_Cd,_3b,_5s,_Cs,_2d,_Ab,_3c,_Rb,_Ac,_5b,_Rc,_As,_3d',0)
    @core.rnd_mgr = deck 
    # say to the core we need to use a custom deck
    @core.game_opt[:replay_game] = true
    # ---- custum deck end
    
    # need two dummy players
    player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
    player1.algorithm = AlgCpuTombolon.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuTombolon.new(player2, @core, nil)
    arr_players = [player1,player2]
    # start the match
    # execute only one event pro step to avoid stack overflow
    @core.suspend_proc_gevents
    @core.gui_new_match(arr_players)
    event_num = @core.process_only_one_gevent
    while event_num > 0
      event_num = @core.process_only_one_gevent
    end
  end

  def test_combi_standalone_1
    @core.create_deck
    
    card_on_table = [:_As, :_Ab, :_Ac, :_4c, :_2s, :_2c]
    rankcard = 7
    res = @core.combi_of_sum(card_on_table, rankcard)
    res_check = @rescheck.combicheck([[:_As, :_Ab, :_Ac, :_4c], [:_As, :_Ab, :_Ac, :_2s, :_2c], [:_4c, :_As, :_2c]], res)
    assert_equal(true, res_check)
    
    card_on_table = [:_5d, :_7b, :_5s, :_2c, :_Fb]
    rankcard = 7
    res = @core.combi_of_sum(card_on_table, rankcard)
    res_check = @rescheck.combicheck([[:_2c, :_5d], [:_2c, :_5s]], res)
    assert_equal(true, res_check)
  end
  
  def test_combi_card_taken
    #@log.outputters << Outputter.stdout
    @core.create_deck
    card_on_table = [:_5d, :_7b, :_5s, :_2c, :_Fb]
    card_lbl = :_7c
    list = @core.which_cards_pick(card_lbl, card_on_table)
    res_check = @rescheck.combicheck([[:_7b],[:_2c, :_5d], [:_2c, :_5s]], list)
    assert_equal(true, res_check)
  end

  def test_double_onori
    @core.create_deck
    hand = [:_Ab, :_2s, :_3s, :_4s, :_5s, :_6s, :_7s, :_Fs, :_Cs, :_Rs, :_7d,:_Ac, :_2c, :_3c, :_4c, :_5c, :_6c, :_7c, :_Fc, :_Cc, :_Rc]
    res = @core.check_for_double_onori(hand)
    assert_equal(true, res)
    hand = [:_As, :_2s, :_3s, :_4s, :_5s, :_6s, :_7s, :_Fs, :_Cs, :_Rs, :_7c,:_Ac, :_2c, :_3c, :_4c, :_5c, :_6c, :_7c, :_Fc, :_Cc, :_Rc]
    res = @core.check_for_double_onori(hand)
    assert_equal(false, res)
  end

  def test_mescola
    @log.outputters << Outputter.stdout
    @core.create_deck
    card_on_table = [:_5d, :_7b, :_5s, :_2c]
    res = @core.deck_table_isok?(card_on_table)
    assert_equal(true, res)
    card_on_table = [:_7d, :_7b, :_5s, :_7c]
    res = @core.deck_table_isok?(card_on_table)
    assert_equal(false, res)
    card_on_table = [:_Fd, :_2b, :_Fs, :_Fc]
    res = @core.deck_table_isok?(card_on_table)
    assert_equal(false, res)
    card_on_table = [:_Fd, :_Rb, :_Rs, :_Rc]
    res = @core.deck_table_isok?(card_on_table)
    assert_equal(false, res)
    card_on_table = [:_Cd, :_Cb, :_Cs, :_Rc]
    res = @core.deck_table_isok?(card_on_table)
    assert_equal(false, res)
    card_on_table = [:_7d, :_7b, :_Cs, :_Rc]
    res = @core.deck_table_isok?(card_on_table)
    assert_equal(true, res)
    card_on_table = [:_Ad, :_2b, :_3s, :_4c]
    res = @core.deck_table_isok?(card_on_table)
    assert_equal(true, res)
    
  end      
#=end
  
  ###
  # Game don't end on 31, game was 33-33 but win was assigned
  def test_bug_22062009
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    rep = ReplayManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/s204_gc1_2009_06_22_21_23_42-savedmatch.yaml')
    #p match_info[:giocate][0]
    alg_coll = { "aaaasmile" => nil, "jason" => nil }
    # start to play the first smazzata 
    rep.replay_match(@core, match_info, alg_coll, 0)
    @core.gui_new_segno
    # continue with the second
    rep.replaynext_smazzata(@core, match_info, alg_coll, 1)
    rep.replaynext_smazzata(@core, match_info, alg_coll, 2)
    rep.replaynext_smazzata(@core, match_info, alg_coll, 3)
    rep.replaynext_smazzata(@core, match_info, alg_coll, 4)
    rep.replaynext_smazzata(@core, match_info, alg_coll, 5)
    # now build mano info
    io_fake.make_info_mano_onlogs
    ## check result
    ## now the error case, terminated game was not found.
    ix_mano =  io_fake.identify_mano('Terrminated the game because the player jason call out with 31.')
    #res = io_fake.checkdata_onmano(ix_mano, "picula")
    io_fake.display_mano_data(ix_mano)
    ## correct result is no picula on mano 38
    assert_equal(197, ix_mano)
    
  end
  
end
