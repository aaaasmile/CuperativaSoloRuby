# -*- coding: ISO-8859-1 -*-
# file: BoardInfoItem.rb

require 'BoardMove'


##
# Information element on squared item board
class BoardInfoItem
  attr_reader :color_piece, :type_piece, :row_start, :column_start, :name_short, :possible_moves, :unique_code
  attr_accessor :is_blocked
  
  # pgn conversion of piece
  @@conv_piece = {:cav => 'N', :alf => 'B', :reg => 'Q', :re => 'K', :torr => 'R'}
  # italian piece names
  @@ita_pieces = {'C' => :cav, 'A' => :alf, 'D' => :reg, 'R' => :re, 'T' => :torr}
  # pgn conversion of column position
  @@col_to_str = {0 => 'a', 1 => 'b', 2 => 'c', 3 => 'd', 4 => 'e', 5=> 'f', 6=> 'g',7=> 'h'}
  @@colupstr_to_int = {'A' => 0, 'B' => 1, 'C' => 2, 'D' => 3, 'E' => 4, 'F' => 5, 'G' => 6, 'H' => 7}
  # name used for image files
  @@name_color = { :white => 'w', :black =>'b'}
  @@name_pieces = {:alf => 'b', :re => 'k', :torr => 'r', :reg => 'q', :cav => 'n', :ped => 'p'}
  
  ###
  # constructor
  def initialize(rr,cc)
    @unique_code = "#{rr}#{cc}".to_sym
    @row_start = rr
    @column_start = cc
    # possible values: :vuoto , :ped, :alf, :torr, :cav, :reg, :re
    @type_piece = :vuoto 
    @color_piece = :notdef
    @name_short = ''
    #blocked flag because otherwise check
    @is_blocked = false 
    @log = Log4r::Logger.new("coregame_log::BoardInfoItem")
  end
  
  ##
  # Change end_item with start_item and start_item becomes empty
  def self.exchange(start_item, end_item)
    tmp_col = start_item.color_piece
    tmp_piece = start_item.type_piece
    start_item.clear
    end_item.setinfo(tmp_piece, tmp_col)
  end
  
 
  ##
  # Provides the italian type of the given character
  def self.TypeIta(char)
    ret = @@ita_pieces[char]
    unless ret
      ret = :ped
    end
    return ret
  end
  
  ##
  # Provides true if this is different from type, color
  def check_unequal(type, color)
    if type == @type_piece and color == @color_piece
      return false
    end
    return true
  end
  
  def setinfo(pie, color)
    @type_piece = pie
    @color_piece = color
    col_name = @@name_color[color]
    pie_name = @@name_pieces[pie]
    @name_short = "#{col_name}#{pie_name}"
  end
  
  def clear
    @type_piece = :vuoto
    @color_piece = :notdef
  end
  
  ##
  # Conversion to pgn piece information
  def to_string_piece
    return  BoardInfoItem.type_piece_to_str(@type_piece)
  end
  
  def to_s_fenpiece
    res = @@name_pieces[@type_piece]
    unless res
      res = ''
    end
    res.upcase! if @color_piece == :white
    return res
  end
  
  def self.type_piece_to_str(tp)
    res = @@conv_piece[tp]
    unless res
      res = ''
    end
    return res 
  end
  
  ##
  # Provides the column as string
  def colix_tostr()
    return lett_col = @@col_to_str[@column_start]
  end
  
  def self.column_to_s(column)
    return lett_col = @@col_to_str[column]
  end
  
  def self.row_to_s(row)
    return "#{row+1}"
  end
  
  def self.rows_to_i(rows)
    return ((rows.to_i) - 1)
  end
  
  def self.colupstr_to_int(col_name_upcase)
    return @@colupstr_to_int[col_name_upcase.upcase]
  end
  
  ##
  # Conversion to position on pgn part, i.e item (0,0) is 'a1'
  def to_dest_pgn
    lett_col = @@col_to_str[@column_start]
    str = "#{lett_col}#{@row_start+1}"
    return str
  end
  
  ##
  # Provides the row position if the pawn move one step forward
  def row_pawn_one_forward
    if  @color_piece == :black
      return @row_start - 1
    else
      return @row_start + 1
    end
  end
  
  ##
  # Provides the row position if the pawn move one step backward
  def row_pawn_one_back
    if  @color_piece == :black
      return @row_start + 1
    else
      return @row_start - 1
    end
  end
  
  ##
  # Provide an asci rapresentation of the piece
  def to_ascii_board_piece
    res = ''
    if @type_piece == :vuoto
      return '  '
    elsif @type_piece == :ped
      res =  'P'
    else
      res = @@conv_piece[@type_piece]
    end
    if @color_piece == :black
      # mark black pieces
      res += '*'
    else
      res += ' '
    end
  end
  
  ##
  # Generate all moves that are teoretically available for this piece
  # Moves are stored in @possible_moves. There is no check if the board state
  # after the move is correct (i.e if the own king is under check after the move)
  def generate_possible_moves(board)
    @possible_moves = []
    return if @is_blocked
    case @type_piece
      when :alf
        generate_moves_alf(board)
      when :re
        generate_moves_re(board)
      when :torr
        generate_moves_torr(board)
      when :reg
        generate_moves_reg(board)
      when :cav
        generate_moves_cav(board)
      when :ped
        generate_moves_ped(board)
      else
        @log.error "Generate moves on #{@type_piece}: unknown piece type"
    end
  end
  
  def add_moves_with_dir(changes_ix, start_x, start_y, board)
    return if changes_ix.size == 0
    ix_dir = changes_ix.pop
    continue_dir = add_next_move_indir(ix_dir, start_x, start_y, board)
    while continue_dir
      start_x += ix_dir[:col]
      start_y += ix_dir[:row]
      continue_dir = add_next_move_indir(ix_dir, start_x, start_y, board)
    end
    add_moves_with_dir(changes_ix, @column_start, @row_start, board)
  end
  
  def add_next_move_indir(ix_dir, start_x, start_y, board)
    if start_x > 7 or start_x < 0 or start_y > 7 or start_y < 0
      return false
    end
    end_x = start_x + ix_dir[:col]
    end_y = start_y + ix_dir[:row]
    if end_x > 7 or end_x < 0 or end_y > 7 or end_y < 0
      return false
    end
    piece_on_end = board.get_piece_on_rowcol(end_x, end_y)
    return false if piece_on_end == nil
    cont_is_possible = true
    if piece_on_end.color_piece != @color_piece and
       piece_on_end.type_piece != :vuoto
       # mangia: mossa valida ma non si continua nella stessa dir
       cont_is_possible = false
    elsif piece_on_end.color_piece == @color_piece and
      piece_on_end.type_piece != :vuoto  
      # mangerebbe pezzo dello stesso colore
      return false
    end
    
    move = {:color => @color_piece, :movetype => :move, :start_x => @column_start, :start_y => @row_start, :end_x => end_x, :end_y => end_y, :type_piece => @type_piece}
    
    @possible_moves << BoardMove.create_from_movehash(move)
    
    return cont_is_possible
  end
  
  def generate_moves_alf(board)
    @log.debug "generate moves for B"
    changes_ix = [{:col => 1, :row => 1}, {:col => -1, :row => -1}, 
                  {:col => -1, :row => 1}, {:col => 1, :row => -1}]
    add_moves_with_dir(changes_ix, @column_start, @row_start, board)
    #p @possible_moves
  end
  
  def generate_moves_re(board)
    @log.debug "generate moves for K"
    add_next_move_indir({:col => 0, :row => 1}, @column_start, @row_start, board)
    add_next_move_indir({:col => 0, :row => -1}, @column_start, @row_start, board)
    add_next_move_indir({:col => 1, :row => 0}, @column_start, @row_start, board)
    add_next_move_indir({:col => -1, :row => 0}, @column_start, @row_start, board)
    add_next_move_indir({:col => -1, :row => -1}, @column_start, @row_start, board)
    add_next_move_indir({:col => -1, :row => 1}, @column_start, @row_start, board)
    add_next_move_indir({:col => 1, :row => 1}, @column_start, @row_start, board)
    add_next_move_indir({:col => 1, :row => -1}, @column_start, @row_start, board)
  end
  
  def generate_moves_torr(board)
    @log.debug "generate moves for R"
    changes_ix = [{:col => 0, :row => 1}, {:col => 0, :row =>-1},
                  {:col => -1, :row => 0}, {:col => 1, :row => 0}]
    add_moves_with_dir(changes_ix, @column_start, @row_start, board)
  end
  
  def generate_moves_reg(board)
    @log.debug "generate moves for Q"
    changes_ix = [{:col => 1, :row => 1}, {:col => -1, :row => -1}, 
                  {:col => -1, :row => 1}, {:col => 1, :row => -1},
                  {:col => 0, :row => 1}, {:col => 0, :row =>-1},
                  {:col => -1, :row => 0}, {:col => 1, :row => 0}]
    add_moves_with_dir(changes_ix, @column_start, @row_start, board)
  end
  
  def generate_moves_cav(board)
    @log.debug "generate moves for N"
    add_next_move_indir({:col => 1, :row => 2}, @column_start, @row_start, board)
    add_next_move_indir({:col => 1, :row => -2}, @column_start, @row_start, board)
    add_next_move_indir({:col => -1, :row => 2}, @column_start, @row_start, board)
    add_next_move_indir({:col => -1, :row => -2}, @column_start, @row_start, board)
    add_next_move_indir({:col => 2, :row => 1}, @column_start, @row_start, board)
    add_next_move_indir({:col => -2, :row => 1}, @column_start, @row_start, board)
    add_next_move_indir({:col => 2, :row => -1}, @column_start, @row_start, board)
    add_next_move_indir({:col => -2, :row => -1}, @column_start, @row_start, board)
  end
  
  def generate_moves_ped(board)
    @log.debug "generate moves for P"
    if @color_piece == :white
      # one step white
      if @row_start == 6
        #check for promotion
        piece_on_end = board.get_piece_on_rowcol(@column_start, @row_start + 1)
        if piece_on_end != nil and piece_on_end.type_piece == :vuoto
          # ok promote
          @possible_moves << BoardMove.new(@color_piece, @row_start, @column_start, @row_start + 1, @column_start, :promotion, @type_piece)
        end
      else
        add_next_move_indir({:col => 0, :row => 1}, @column_start, @row_start, board)
      end
      
      # two step
      if @row_start == 1
        add_next_move_indir({:col => 0, :row => 2}, @column_start, @row_start, board)
      end
      # check enpassant
      if board.last_moved_item != nil and 
         board.last_moved_item.type_piece == :ped and @row_start == 4
        lm = board.get_last_move
        if lm != nil and (lm.row_s - lm.row_e) == 2 and
          (lm.col_s - @column_start).abs == 1
          #enpassant possible
          @possible_moves << BoardMove.new(@color_piece, @row_start, @column_start, @row_start + 1, lm.col_e, :enpassant, @type_piece)
        end
      end
      # check capture left
      piece_on_end = board.get_piece_on_rowcol(@column_start - 1, @row_start + 1)
      if piece_on_end != nil and piece_on_end.color_piece != @color_piece and
               piece_on_end.type_piece != :vuoto
               # ok can taken
        @possible_moves << BoardMove.new(@color_piece, @row_start, @column_start, @row_start + 1, @column_start - 1, :move_eat, @type_piece)
      end
      # check capture right
      piece_on_end = board.get_piece_on_rowcol(@column_start + 1, @row_start + 1)
      if piece_on_end != nil and piece_on_end.color_piece != @color_piece and
               piece_on_end.type_piece != :vuoto
               # ok can taken
        @possible_moves << BoardMove.new(@color_piece, @row_start, @column_start, @row_start + 1, @column_start + 1, :move_eat, @type_piece)
      end
    else
      # black Pawn
      # one step black
      if @row_start == 1
        #check for promotion
        piece_on_end = board.get_piece_on_rowcol(@column_start, @row_start - 1)
        if piece_on_end != nil and piece_on_end.type_piece == :vuoto
          # ok promote
          @possible_moves << BoardMove.new(@color_piece, @row_start, @column_start, @row_start - 1, @column_start, :promotion, @type_piece)
        end
      else
        add_next_move_indir({:col => 0, :row => 1}, @column_start, @row_start, board)
      end
      
      # two step
      if @row_start == 6
        add_next_move_indir({:col => 0, :row => -2}, @column_start, @row_start, board)
      end
      # check enpassant
      if board.last_moved_item != nil and  
        board.last_moved_item.type_piece == :ped and @row_start == 3
        lm = board.get_last_move
        if lm != nil and (lm.row_e - lm.row_s) == 2 and
          (lm.col_s - @column_start).abs == 1
          #enpassant possible
          @possible_moves << BoardMove.new(@color_piece, @row_start, @column_start, @row_start - 1, lm.col_e, :enpassant, @type_piece)
        end
      end
      # check capture left
      piece_on_end = board.get_piece_on_rowcol(@column_start - 1, @row_start - 1)
      if piece_on_end != nil and piece_on_end.color_piece != @color_piece and
               piece_on_end.type_piece != :vuoto
               # ok can taken
        @possible_moves << BoardMove.new(@color_piece, @row_start, @column_start, @row_start - 1, @column_start - 1, :move_eat, @type_piece)
      end
      # check capture right
      piece_on_end = board.get_piece_on_rowcol(@column_start + 1, @row_start - 1)
      if piece_on_end != nil and piece_on_end.color_piece != @color_piece and
               piece_on_end.type_piece != :vuoto
               # ok can taken
        @possible_moves << BoardMove.new(@color_piece, @row_start, @column_start, @row_start - 1, @column_start + 1, :move_eat, @type_piece)
      end
    end
    #p @possible_moves
  end
  
  def print_all_moves
    str = ""
    @possible_moves.each{|m| str+= "#{m.move_to_str} "}
    @log.debug "moves: #{str}"
  end
  
  def possible_move_has?(start_x, start_y, end_x, end_y)
    if start_x == @column_start and start_y == @row_start
      @possible_moves.each do |move|
        if move[:end_x] == end_x and move[:end_y] == end_y
          return true
        end
      end
    end
    return false
  end
  
end #end BoardInfoItem
