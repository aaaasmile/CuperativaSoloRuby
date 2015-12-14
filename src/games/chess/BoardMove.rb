# -*- coding: ISO-8859-1 -*-
# file: BoardMove.rb


class BoardMove
  attr_reader :color, :row_s, :col_s, :row_e, :col_e, :movetype, :type_piece, :eated, :promoted
  attr_accessor :fen_after_move
  
  # movetype: :move, :enpassant, :promotion, :shortcastle, :longcastle, :move_eat
  # type_piece: :cav, :alf, :reg, :re, :torr, :ped
  def initialize(color, row_s, col_s, row_e, col_e, movetype, type_piece)
    @color= color
    @row_s = row_s
    @col_s = col_s 
    @row_e = row_e 
    @col_e = col_e  
    @movetype = movetype 
    @type_piece = type_piece
    @eated = nil    #:cav, :alf, :reg, :torr, :ped
    @promoted = nil #:cav, :alf, :reg, :torr
    @fen_after_move = ''
  end
  
  # movehash: qualcosa come {:color => :white, :start_x => @column_start, :start_y => @row_start, :end_x => end_x, :end_y => end_y}
  def self.create_from_movehash(movehash)
    color= movehash[:color]
    row_s = movehash[:start_y]
    col_s = movehash[:start_x]
    row_e = movehash[:end_y] 
    col_e = movehash[:end_x]  
    movetype = movehash[:movetype] 
    type_piece = movehash[:type_piece]
    return BoardMove.new(color, row_s, col_s, row_e, col_e, movetype, type_piece)
  end
  
  # type:  :longcastle, :shortcastle
  def self.create_castle_move(color, type)
    if type != :longcastle and type != :shortcastle
      raise "unsupported castle type move"
    end
    type_piece = :re
    movetype = type
    #move the king
    row_s = 0
    row_e = 0
    col_s = 4
    col_e = 6
    col_e = 2 if type == :longcastle
    if color == :black
      row_s = 7
      row_e = 7
    end
    
    return BoardMove.new(color, row_s, col_s, row_e, col_e, movetype, type_piece)
  end
  
  # str_coor: something like 'e2e4'
  def self.create_move_from_strcoo(color, str_coor, type_piece)
    col_s = BoardInfoItem.colupstr_to_int(str_coor[0..0])
    row_s = BoardInfoItem.rows_to_i(str_coor[1..1])
    col_e = BoardInfoItem.colupstr_to_int(str_coor[2..2])
    row_e = BoardInfoItem.rows_to_i(str_coor[3..3])
    return BoardMove.new(color, row_s, col_s, row_e, col_e, :move, type_piece)
  end
  
  # eated: :cav, :alf, :reg, :torr, :ped
  def set_eat(eated)
    @eated = eated
    @movetype = :move_eat
  end
  
  # promoted: :cav, :alf, :reg, :torr
  def set_promoted(promoted)
    @promoted = promoted
    @movetype = :promotion
  end
  
  def set_enpassant
    @eated = :ped
    @movetype = :enpassant
  end
  
  def is_equal_to?(move)
    if  move.color == @color and
        move.row_s == @row_s and
        move.col_s == @col_s and
        move.row_e == @row_e and 
        move.col_e == @col_e and
        move.type_piece == @type_piece and
        move.movetype == @movetype
      return true
    end
    return false 
  end
  
  def move_to_str
    if @movetype == :shortcastle
      return "O-O"
    elsif @movetype == :longcastle
      return "O-O-O"
    end
    y0 = BoardInfoItem.row_to_s(@row_s)
    x0 = BoardInfoItem.column_to_s(@col_s)
    y1 = BoardInfoItem.row_to_s(@row_e)
    x1 = BoardInfoItem.column_to_s(@col_e)
    tp = BoardInfoItem.type_piece_to_str(@type_piece)
    str_res = ""
    bind = "-"
    bind = "x" if @movetype == :move_eat
    str_res += "EP " if @movetype == :enpassant
    str_res += "#{tp}#{x0}#{y0}#{bind}#{x1}#{y1}"
    if @movetype == :promotion
      str_res += "=#{BoardInfoItem.type_piece_to_str(@promoted)}"
    end 
    return str_res
  end
  
end #end BoardMove
