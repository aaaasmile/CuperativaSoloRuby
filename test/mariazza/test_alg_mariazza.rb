# -*- coding: ISO-8859-1 -*-

#file: test_alg_mariazza.rb
# unit test for AlgCpuMariazza

$:.unshift File.dirname(__FILE__)


require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'


$:.unshift File.dirname(__FILE__) + '/../..'

require 'src/core/core_game_base'
require 'src/games/mariazza/core_game_mariazza'
require 'src/games/mariazza/alg_cpu_mariazza'
require 'test/fakestuff'

include Log4r

 
##
# Test suite for testing 
class Test_alg_mariazza < Test::Unit::TestCase
  attr_reader :log
  
     
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameMariazza.new
    @io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', @io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    #@log.outputters << Outputter.stdout
  end
  
  def test_alg_not_work01
    rep = ReplayManager.new(@log)
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
    rep = ReplayManager.new(@log)
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
    rep = ReplayManager.new(@log)
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
    rep = ReplayManager.new(@log)
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
    rep = ReplayManager.new(@log)
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
    rep = ReplayManager.new(@log)
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
    rep = ReplayManager.new(@log)
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
  atest = Test_alg_mariazza.new('test_alg_not_work03')
  FakeIO.add_a_simple_assert(atest)
  atest.setup
  atest.log.outputters << Outputter.stdout
  atest.test_alg_not_work03
  exit
end
