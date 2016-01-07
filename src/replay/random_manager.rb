# file: random_manager.rb


##
# Manage random function in the core
class RandomManager
  
  def initialize
    # logger
    @log = Log4r::Logger.new("coregame_log::RandomManager")
    @deck_to_use = []
    @first_player = 0
    @state = :rnd_fun
    #reset_rnd
  end
  
  ##
  # Reset the manager for using random function for live game
  def reset_rnd
    @log.debug "RandomManager: using random function"
    @state = :rnd_fun
  end
    
  ##
  # Set a predefined deck, this override the default random function 
  # deck_str: deck on string format (e.g. _7c,_5s,_As,_2b,_6c,_2s,_Rb ...)
  # first_player: player index that is returned when get_first_player is called (e.g. 0)
  def set_predefined_deck(deck_str, first_player)
    @log.info "CAUTION: Override current deck (set_predefined_deck) #{first_player}"
    @deck_to_use = deck_str.split(",").collect!{|x| x.to_sym}
    set_predef_ready_deck(@deck_to_use, first_player)
  end
  
  # see set_predefined_deck, but using another format for deck
  # deck: array of cards symbols [_7c, _5s,...]
  def set_predef_ready_deck(deck, first_player)
    @log.debug "Set a user defined deck"
    @deck_to_use = deck
    @state = :predefined_game
    @first_player = first_player
  end
  
  def is_predefined_set?
    return @state == :predefined_game ? true : false
  end
  
  ##
  # Provides the deck for a new giocata
  # base_deck: complete unsorted deck
  def get_deck(base_deck)
    case @state
      when :predefined_game
        @log.debug "RM: using predifined deck size: #{@deck_to_use.size}"
        return @deck_to_use.dup
      else
        @log.debug "RM: using rnd deck size: #{base_deck.size}"
        return base_deck.sort_by{ rand }
    end
  end
  
  ##
  # Provides the first player
  # Total number of players
  def get_first_player(num_of_players)
    @log.debug "get first player: state #{@state}, first stored #{@first_player}"
    case @state
      when :predefined_game
        return @first_player
      else
        rand(num_of_players)
    end
  end
  
end