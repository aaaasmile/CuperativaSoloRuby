#file: fakestuff.rb
# some fake class used during unit test

#########################################################################
#########################################################################
######################################### CLASS ResScopaChecker##########
#########################################################################

class ResScopaChecker
  
  ##
  # Convert a string array like "_7d,_3c..." to an array of symbols [:_7d,...]
  def str_cards_tosymbarr(str)
    tmp = str.split(",")
    tmp.collect!{|e| e.to_sym}
    return tmp
  end
  
  ##
  # Check if ref_arr is equivalent in card combination
  def combicheck(ref_arr, result)
    found_combi = []
    not_found_combi = []
    ref_arr.each do |item|
      #p item
      if combifind_in(item, result)
        found_combi << item
      else
        not_found_combi << item
      end
    end
    if found_combi.size == ref_arr.size
      puts "Combicheck is ok"
      return true
    else
      puts "Combicheck failed, NOT found #{not_found_combi.size}/#{ref_arr.size} combi, they are:"
      not_found_combi.each{|e| puts e.join(",") }
    end
    return false
  end
  
  def combifind_in(item, result)
    result.each do |res_item|
      found_nr = 0
      item.each do |data|
        ix = res_item.index(data)
        if ix 
          found_nr += 1
        else
          # now exams the next result
          break
        end
      end
      if  found_nr >= res_item.size
        # combi found
        puts "check: Combi found #{item.join(",")}"
        return true
      end
    end
    return false
  end
  
end

#########################################################################
#########################################################################
######################################### CLASS FAKEIO ##################
#########################################################################


#
# Class used to intercept log to recognize errors and warning
class FakeIO < IO
  attr_accessor :warn_count, :error_count
  
  def initialize(arg1,arg2)
    super(arg1,arg2)
    reset_counts
    @cards_played = []
    @data_logs = []
    @cards_withmano_table = {}
  end
  
  # When you use an unit test class, the assert_equal funtion is missed. Add a simple assert implementation.
  def self.add_a_simple_assert(unit_test_class)
    str = "def unit_test_class.assert_equal(expected, actual, message=nil) res = expected == actual ? \"OK\" : \"FAILED \#{expected} but it is \#{actual}\"; @log.debug res; end"
  	eval(str)
  end
  
  def reset_counts
    @warn_count = 0; @error_count = 0;
    @points_state = []
    @cards_played = []
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
    # check something like "Card _2c played from player Gino B.\n"
    if aa[1].strip =~ /Card (_..) played from player (.*)/
      card_lbl = $1
      name_pl = $2
      @cards_played << {:card_s => card_lbl, :name => name_pl }
      # more detailed
      manocountpos = aa[1].strip.split("++")[1].split(",")
      mano_count = manocountpos[0]
      mano_pos = manocountpos[1]
      @cards_withmano_table[mano_count] = {} unless @cards_withmano_table[mano_count]
      @cards_withmano_table[mano_count][mano_pos] = card_lbl
    end
    @data_logs << aa[1..-1].join(':').strip
  end
  
  ##
  # Check if inside collectd logs there is also the provided entry
  def checklogs(entry)
    @data_logs.each do |line|
      if line =~ /#{entry}/
        puts "Checklogs found:\"#{line}\""
        return true
      end
      #p line 
    end
    return false
  end
  
  ##
  # Try to assign event on each mano
  def make_info_mano_onlogs
    puts "make_info_mano_onlogs"
    @mano_coll = []
    curr_ix = 0
    curr_mano_info = {:ix => curr_ix, :data => []}
    @data_logs.each do |line|
      #p line
      if line =~ /new_mano/
        @mano_coll << curr_mano_info if curr_mano_info.size > 0
        curr_ix += 1
        curr_mano_info = {:ix => curr_ix, :data => []}
      else
        curr_mano_info[:data] << line 
      end
    end
  end
  
  ##
  # Check data on particular mano
  def checkdata_onmano(ixmano, str_log)
    puts "checkdata_onmano: #{ixmano}"
    @mano_coll.each do |item|
      #p item
      if item[:ix] == ixmano
        # search the given string inside the log data
        item[:data].each do |data_item|
          #p data_item
          if data_item =~ /#{str_log}/
            puts "Found item (#{data_item}) requested on mano: #{ixmano}"
            return true
          end
        end
        return false 
      end
    end
    return false
  end
  
  ##
  # Display data collected for a particular hand
  def display_mano_data(ix_mano)
    puts "display_mano_data #{ix_mano}"
    @mano_coll.each do |item|
      #p item
      if item[:ix] == ix_mano
        # search the given string inside the log data
        item[:data].each do |data_item|
          puts data_item
        end
        return 
      end
    end
  end
  
  ##
  # Identify a particular hand
  def identify_mano(str_log)
    puts "identify_mano #{str_log}"
    ix = 0
    @mano_coll.each do |item|
      item[:data].each do |data_item|
        #p data_item
        if data_item =~ /#{str_log}/
          puts "Found item requested on mano: #{ix}"
          #p  item
          return ix
        end
      end
      ix += 1
    end
    return ix
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
      if cd_played_info[:name] == name and card_lbl.to_s == cd_played_info[:card_s]
        return pos
      end
      pos += 1
    end
    return nil
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
    @points_state.each do |pt_line|
      aa = pt_line.include?(str_points)
      return true if aa
    end
    return false
  end

  ##
  # Provides the card played in the mano_count in the card_ontable_pos
  # card_ontable_pos: player as second is 1 player as first is 0 
  # mano_count: current mano count inside a giocata
  def card_played_onhand(mano_count,card_ontable_pos)
    mano_hash =  @cards_withmano_table[mano_count]
    card = mano_hash[card_ontable_pos]
    return card.to_sym  
  end
  
end
 