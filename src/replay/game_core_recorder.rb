# file: game_core_recorder


##
# Used to record a game in order to re run it
class GameCoreRecorder
  
  def initialize
    @info_match = {}
  end
  
  ##
  # Store information when a new match start
  # players: player array (PlayerOnGame instances)
  # options: core game options
  # game_name: game name (e.g. "Briscola")
  def store_new_match(players, options, game_name)
    @info_match = {}
    pl_names = []
    players.each {|pl| pl_names << pl.name}
    @info_match[:players] = pl_names
    @info_match[:date] = Time.now
    @info_match[:giocate] = [ ] # items like { :deck => [], :first_plx => 0,  :actions => [] }
    @info_match[:game] = {:name => "#{game_name}", :opt => {}
    }
    # set options of the match
    options.each do |k,v|
      @info_match[:game][:opt][k] = v
    end
   
  end
  
  ##
  # Store info about match winner
  def store_end_match(best_pl_segni)
    @info_match[:match_winner] = best_pl_segni
  end
  ##
  # Store info about new giocata
  # deck: deck used
  # first_player: first player in the new giocata
  def store_new_giocata(deck, first_player)
    info_giocata = { 
      :deck => deck.dup, 
      :first_plx => first_player,  
      :actions => [] 
    }
    @info_match[:giocate] << info_giocata
  end
  
  ##
  # Store info about winner of giocata
  def store_end_giocata(info_winner)
    curr_giocata = @info_match[:giocate].last
    curr_giocata[:giocata_winner] = info_winner if curr_giocata
  end
  
  ##
  # Store a player action. An action need to be stored when game_core becomes a new
  # function called from gfx (i.e. alg_player_cardplayed_arr)
  # plname: player name
  # action: action type (:cardplayed, :change_briscola, :declare, :resign)
  def store_player_action(plname, action, *args)
    curr_giocata = @info_match[:giocate].last
    if curr_giocata
      curr_actions = {:pl_name => plname, :type => action, :arg => args}
      curr_giocata[:actions] << curr_actions
    end
  end
  
  ##
  # Save the current info match in a file
  def save_match_to_file(fname)
    #fname_old_loc = File.expand_path(File.join( File.dirname(__FILE__) + "/../..",fname))
    fname_old_loc = fname
    File.open( fname_old_loc, 'w' ) do |out|
      YAML.dump( @info_match, out )
    end
  end
end #end GameCoreRecorder

if $0 == __FILE__
  gr = GameCoreRecorder.new
end