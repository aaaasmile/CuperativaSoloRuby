# -*- coding: ISO-8859-1 -*-

#file: test_alg_briscola.rb
# unit test for AlgCpuBriscola

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'
$:.unshift File.dirname(__FILE__) + '/../../src'

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'
require 'fakestuff'


require 'core/core_game_base'
require 'games/briscola/core_game_briscola'
require 'games/briscola/alg_cpu_briscola'


include Log4r

##
# Test suite for testing 
class Test_Alg_Briscola < Test::Unit::TestCase
 
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameBriscola.new
    @io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', @io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    #@log.outputters << Outputter.stdout
  end
  
  ###################################### Test List ###########################
  
  # NOTE: this test failed because algorithm is updated and don't play like
  #        the saved game
  def test_alg_not_work01
    rep = ReplayManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/alg_flaw_01.yaml')
    rep.replay_match(@core, match_info, {}, segno_num = 1, 1)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
  
  # NOTE: this test failed because algorithm is updated and don't play like
  #        the saved game
  def test_alg_not_work02
    rep = ReplayManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/alg_flaw_02.yaml')
    segno_num = 0
    rep.replay_match(@core, match_info, {}, segno_num, 1)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
  end
 
  ##
  # Error on algorithm: on the game briscola_err_alg_play3b.yaml the algorithm
  # play a _3b instead of _Fs. This happens on  mano 3,1 (forth hand, alg second).
  def test_alg_not_work03
    rep = ReplayManager.new(@log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/saved_games/briscola_err_alg_play3b.yaml')
    player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
    alg_cpu1 = AlgCpuBriscola.new(player1, @core, nil)
    alg_coll = { "Gino B." => alg_cpu1, "Toro" => nil } 
    segno_num = 0
    rep.replay_match(@core, match_info, alg_coll, segno_num)
    assert_equal(0, @io_fake.warn_count)
    assert_equal(0, @io_fake.error_count)
    # check the card played on hand 3,1 shold be _Fs and not _3b
    assert_equal(:_Fs, @io_fake.card_played_onhand("3","1"))
  end
  
end

# Look to the test_alg_mariazza.rb if you want to test a single test case using this file