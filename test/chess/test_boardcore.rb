#file test_boardcore.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'
require 'fakestuff'

PATH_TO_CLIENT = File.expand_path(File.dirname(__FILE__) + '/../../src')

require File.join( PATH_TO_CLIENT, 'base/core/core_game_base')
require File.join( PATH_TO_CLIENT, 'games/chess/Board')
require File.join( PATH_TO_CLIENT, 'games/chess/chess_core')

include Log4r

class Test_Boardcore < Test::Unit::TestCase
   
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @board_core = Board.new
  end
  
  def atest_popmove_shortcastle
    fen_str = "RNBQK2R/7b/8/8/2ppp2p/B4Q1r/k3PR1P/1RK5 w - - 0 1"
    @board_core.board_with_fen(fen_str)
    @board_core.print_board(:white)
    
    move_castle = BoardMove.create_castle_move(:white, :shortcastle)
    @board_core.do_the_move(move_castle)
    @board_core.print_board(:white)
    @board_core.pop_move
    @board_core.print_board(:white)
  end
  
  def atest_popmove_longcastle
    fen_str = "R3KBNR/7b/8/8/2ppp2p/B4Q1r/k3PR1P/1RK5 w - - 0 1"
    @board_core.board_with_fen(fen_str)
    @board_core.print_board(:white)
    
    move_castle = BoardMove.create_castle_move(:white, :longcastle)
    @board_core.do_the_move(move_castle)
    @board_core.print_board(:white)
    @board_core.pop_move
    @board_core.print_board(:white)
  end
  
  def atest_popmove_eat
    fen_str = "R3KBNR/7b/8/8/2ppp2p/B4Q1r/k3PR1P/1RK5 w - - 0 1"
    @board_core.board_with_fen(fen_str)
    @board_core.print_board(:white)
    
    move_eat = BoardMove.create_move_from_strcoo(:white, 'f6h6', :reg)
    move_eat.set_eat(:torr)
    puts "test move #{move_eat.move_to_str}" 
    @board_core.do_the_move(move_eat)
    @board_core.print_board(:white)
    
    @board_core.pop_move
    
    @board_core.print_board(:white)
  end
  
  def atest_popmove_normal
    fen_str = "R3KBNR/7b/8/8/2ppp2p/B4Q1r/k3PR1P/1RK5 w - - 0 1"
    @board_core.board_with_fen(fen_str)
    @board_core.print_board(:white)
    
    move = BoardMove.create_move_from_strcoo(:white, 'b8b1', :torr)
    puts "test move #{move.move_to_str}"
     
    @board_core.do_the_move(move)
    @board_core.print_board(:white)
    
    @board_core.pop_move
    @board_core.print_board(:white)
  end
  
  def atest_popmove_enpassant
    fen_str = "R3KBNR/4P3/8/5p2/2ppp2p/B4Q1r/k3PR1P/1RK5 w - - 0 1"
    @board_core.board_with_fen(fen_str)
    @board_core.print_board(:white)
    
    move = BoardMove.create_move_from_strcoo(:white, 'e2e4', :ped)
    puts "prerequisite move #{move.move_to_str}"
     
    @board_core.do_the_move(move)
    @board_core.print_board(:white)
    
    move2 = BoardMove.create_move_from_strcoo(:black, 'f4e3', :ped)
    move2.set_enpassant
    puts "make enpassant move #{move2.move_to_str}"
     
    @board_core.do_the_move(move2)
    @board_core.print_board(:white)
    
    puts "now popup move"
    @board_core.pop_move
    @board_core.print_board(:white)
  end
  
  def atest_popmove_promotion
    fen_str = "R3KBNR/4P3/8/5p2/2ppp2p/B4Q1r/k3PR1P/1RK5 w - - 0 1"
    @board_core.board_with_fen(fen_str)
    @board_core.print_board(:white)
    
    move = BoardMove.create_move_from_strcoo(:white, 'e7e8', :ped)
    move.set_promoted(:reg)
    puts "make promotion move #{move.move_to_str}"
     
    @board_core.do_the_move(move)
    @board_core.print_board(:white)
    
    puts "now popup move"
    @board_core.pop_move
    @board_core.print_board(:white)
  end
  
  def atest_is_attacked
    fen_str = "R3KBNR/4P3/8/5p2/b1ppp2p/B4Q1r/k3PR1P/1RK5 w - - 0 1"
    @board_core.board_with_fen(fen_str)
    @board_core.print_board(:white)
    king_item = @board_core.get_piece_list(:re, :white).first
    puts "Check the #{king_item.to_string_piece}"
    @board_core.is_attacked(king_item)
  end
  
  def test_calculate_fen
    fen_str = "R3KBNR/4P3/8/5p2/b1ppp2p/B4Q1r/k3PR1P/1RK5 w - - 0 1"
    @board_core.board_with_fen(fen_str)
    str_calc = @board_core.calculate_current_fen
    assert_equal(fen_str, str_calc)
  end
  
end