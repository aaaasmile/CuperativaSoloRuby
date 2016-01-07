# -*- coding: ISO-8859-1 -*-

#file: test_alg_mariazza.rb
# unit test for AlgCpuMariazza

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
class Test_alg_mariazza < Test::Unit::TestCase
  attr_reader :log
  #
  # Class used to intercept log to recognize errors and warning
  class Test_mariazza_core_FakeIO < IO
    attr_accessor :warn_count, :error_count
    
    def initialize(arg1,arg2)
      super(arg1,arg2)
      reset_counts
    end
    
    def reset_counts
      @cards_played = []
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
      if aa[1].strip =~ /Card (_..) played from player (.*)/
        card_lbl = $1
        name_pl = $2
        @cards_played << {:card_s => card_lbl, :name => name_pl }
       
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
    
    ##
  # Check if a card was played because trace info.
  # provides position if played card is found
  # name: player name (e.g. "Gino B.")
  # card_lbl: card label to find (e.g "_2c")
  def check_playedcard(name, card_lbl)
    pos = 0
    #p @cards_played
    @cards_played.each do |cd_played_info|
      #p cd_played_info
      if cd_played_info[:name] == name and card_lbl.to_s == cd_played_info[:card_s]
        return pos
      end
      pos += 1
    end
    return nil
  end
    
  end#end FakeIO
  
  
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameMariazza.new
    @io_fake = Test_mariazza_core_FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', @io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    #@log.outputters << Outputter.stdout
  end
  
  def test_alg_not_work01
    rep = ReplayerManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/alg_not_work01.yaml')
    player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
    alg_cpu1 = AlgCpuMariazza.new(player1, @core, nil)
    alg_coll = { "Gino B." => alg_cpu1, "Toro" => nil } 
    segno_num = 0
    rep.replay_match(@core, match_info, alg_coll, segno_num)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
  def test_alg_not_work02
    rep = ReplayerManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/alg_not_work02.yaml')
    player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
    alg_cpu1 = AlgCpuMariazza.new(player1, @core, nil)
    alg_coll = { "Gino B." => alg_cpu1, "Toro" => nil } 
    segno_num = 0
    rep.replay_match(@core, match_info, alg_coll, segno_num)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
   
  def test_alg_not_work03
    rep = ReplayerManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/alg_not_work03.yaml')
    player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
    player2 = PlayerOnGame.new("Toro", nil, :cpu_alg, 0)
    alg_cpu1 = AlgCpuMariazza.new(player1, @core, nil)
    # using a nil AlgCpuMariazza, then the yaml file action is used instead
    alg_coll = { "Gino B." => alg_cpu1, "Toro" => AlgCpuMariazza.new(player2, @core, nil) } 
    segno_num = 0
    rep.replay_match(@core, match_info, alg_coll, segno_num)
    assert_equal(0, @io_fake.warn_count, 'Too many warnings')
    assert_equal(0, @io_fake.error_count)
  end
  
  def test_alg_not_work04
    rep = ReplayerManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/alg_not_work04.yaml')
    player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
    player2 = PlayerOnGame.new("Toro", nil, :cpu_alg, 0)
    alg_cpu1 = AlgCpuMariazza.new(player1, @core, nil)
    alg_coll = { "Gino B." => alg_cpu1, "Toro" => AlgCpuMariazza.new(player2, @core, nil) } 
    segno_num = 0
    rep.replay_match(@core, match_info, alg_coll, segno_num)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
  def test_alg_not_work05
    rep = ReplayerManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/alg_not_work05.yaml')
    player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
    alg_cpu1 = AlgCpuMariazza.new(player1, @core, nil)
    alg_coll = { "Gino B." => alg_cpu1, "Toro" => nil } 
    segno_num = 1
    rep.replay_match(@core, match_info, alg_coll, segno_num)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
  def test_alg_not_work06
    rep = ReplayerManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/alg_not_work06.yaml')
    player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
    alg_cpu1 = AlgCpuMariazza.new(player1, @core, nil)
    alg_coll = { "Gino B." => alg_cpu1, "Toro" => nil } 
    segno_num = 0
    rep.replay_match(@core, match_info, alg_coll, segno_num)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
  def test_alg_not_work07
    rep = ReplayerManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/2008_02_29_19_57_38-7-savedmatch.yaml')
    player1 = PlayerOnGame.new("ospite1", nil, :cpu_alg, 0)
    alg_cpu1 = AlgCpuMariazza.new(player1, @core, nil)
    alg_coll = { "ospite1" => alg_cpu1, "igor047" => nil } 
    segno_num = 0
    rep.replay_match(@core, match_info, alg_coll, segno_num)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
end

if $0 == __FILE__
  # use this file to run only one single test case
  tester = Test_alg_mariazza.new('test_alg_not_work03')
  def tester.assert_equal(expected, actual, message=nil)
    res = expected == actual ? "OK" : "FAILED #{expected} but it is #{actual}"
    @log.debug res 
  end
  
  tester.setup
  tester.log.outputters << Outputter.stdout
  tester.test_alg_not_work03
end
