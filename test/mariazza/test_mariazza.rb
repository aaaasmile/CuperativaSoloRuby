#file: test_mariazza.rb
# unit test for mariazza game

$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'


PATH_TO_CLIENT = File.expand_path(File.dirname(__FILE__) + '/../../src')

require File.join( PATH_TO_CLIENT, 'core/core_game_base')
require File.join( PATH_TO_CLIENT, 'games/mariazza/core_game_mariazza')
require File.join( PATH_TO_CLIENT, 'games/mariazza/alg_cpu_mariazza')

include Log4r

##
# Test suite for testing 
class Test_mariazza_core < Test::Unit::TestCase
  
  #
  # Class used to intercept log to recognize errors and warning
  class FakeIO < IO
    attr_accessor :warn_count, :error_count
    
    def initialize(arg1,arg2)
      super(arg1,arg2)
      reset_counts
    end
    
    def reset_counts
      @warn_count = 0; @error_count = 0;
      @points_state = []
    end
    
    def print(*args)
      #print(args)
      str = args.slice!(0)
      aa = str.split(':')
      if aa[0] =~ /WARN/
        @warn_count += 1
      elsif aa[0] =~ /ERROR/
        @error_count += 1
      elsif aa[1] =~ /Punteggio attuale/
        @points_state << aa[2].gsub(" ", "").chomp
      end
    end
    
    ##
    # Check if points str_points was reached
    def punteggio_raggiunto(str_points)
      str_points.gsub!(" ", "")
      #p @points_state
      aa = @points_state.index(str_points)
      if aa
        # points state found
        return true
      end
      return false
    end
    
  end#end FakeIO
  
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameMariazza.new
  end
  
  def atest_createdeck
    @core.create_deck
    assert_equal(11, @core.get_deck_info[:_Ab][:points])
    assert_equal(10, @core.get_deck_info[:_3d][:points])
    assert_equal(0, @core.get_deck_info[:_7c][:points])
  end

  ##
  # Test a game where cpu algorithm try to change the 7 with briscola
  def test_cpu_change7
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    rep = ReplayerManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/mariaz_sett_cam_brisc.yaml')
    player = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
    alg_cpu = AlgCpuMariazza.new(player, @core, nil)
    alg_cpu.level_alg = :dummy
    alg_coll = { "Gino B." => alg_cpu } 
    rep.replay_match(@core, match_info, alg_coll, 0)
    assert_equal(0, io_fake.warn_count)
    assert_equal(0, io_fake.error_count)
  end
  
  ##
  # G2 gioca per secondo. dichiara mariazza, g1 prende dichiara mariazza
  # g2 prende ma non gli venfono assegnati 20 punti
  def test_decl20after_marzdecl
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    rep = ReplayerManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/2008_05_08_20_21_15-3-no20pt.yaml')
    # replay the game
    alg_coll = { "Parma" => nil, "igor0500" => nil } 
    rep.replay_match(@core, match_info, alg_coll, 1)
    assert_equal(0, io_fake.warn_count)
    assert_equal(0, io_fake.error_count)
    # check the fixed end result
    assert_equal(true, io_fake.punteggio_raggiunto("igor0500 = 47 Parma = 39 "))
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
    puts "Match terminated"
    assert_equal(0, io_fake.warn_count)
    assert_equal(0, io_fake.error_count)
  end
  
end #end Test_mariazza_core