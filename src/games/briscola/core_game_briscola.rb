# file: core_game_briscola.rb
# handle the briscola game engine
#

$:.unshift File.dirname(__FILE__)

$:.unshift File.dirname(__FILE__) + '/../..'
require 'alg_cpu_briscola'
require 'replay/game_replayer'

# Class to manage the core card game
class CoreGameBriscola < CoreGameBase
  attr_accessor :game_opt, :rnd_mgr
  attr_reader :num_of_cards_onhandplayer, :points_curr_segno
  
  def initialize
    super
    # set all options related to the game
    @game_opt = {
      :shuffle_deck => true, 
      :target_points_segno => 61, 
      :num_segni_match => 2, 
      :num_of_players => 2,
      :replay_game => false, # if true we are using information already stored
      :record_game => true  # if true record the game
    }
    
    @log = Log4r::Logger.new("coregame_log::CoreGameBriscola") 
    
    # players (instance of class PlayerOnGame) order that have to play
    @round_players = []
    
    # array di simboli delle carte(:bA :c4 ...) gestisce il mazzo delle carte durante la partita
    @mazzo_gioco = []
    # array of players (instance of class PlayerOnGame
    @players = []
    # cards played during the mano on the table. Array of hash with lbl_card => player
    @carte_gioc_mano_corr = []
    # cards holds (to be played) for each player. The key is a player name, values are an array of card labels
    @carte_in_mano = {}
    # cards taken for each player. The key is a player name, values are an array of card labels
    @carte_prese = {}
    # points accumulated in the current segno for each player. The key is a player name, 
    # value is current player score.
    @points_curr_segno = {}
    # segni accumulated in the current match for each player. The key is a player name, 
    # value is current number of segni wons by the player.
    @segni_curr_match = {}
    # briscola in tavola. Simple card label
    @briscola_in_tav_lbl = nil
    # segno state
    @segno_state = :undefined 
    # match state
    @match_state = :undefined
    # random manager
    @rnd_mgr = RandomManager.new
    # game recorder
    @game_core_recorder = GameCoreRecorder.new
    # number of card on each player
    @num_of_cards_onhandplayer = 3
    # count the number of hands inside a giocata
    @mano_count = 0
    @card_played_error = {}
    load_game_info(File.dirname(__FILE__))
  end
  
  ##
  # Build deck before shuffle
  def create_deck
    @log.debug("Create a deck with rank and points")
    # array di simboli delle carte(:_Ac :_4c ...) gestisce il mazzo delle carte durante la partita
    @mazzo_gioco = []
    
    @deck_information.build_deck_briscola
    @deck_information.cards_on_game.each{|x| @mazzo_gioco << x}
    
  end
  
  
  def set_specific_options(options)
    #p options
    if options[:games_opt] and options[:games_opt][:briscola_game]
      opt_briscola = options[:games_opt][:briscola_game]
      if opt_briscola[:num_segni_match]
        @game_opt[:num_segni_match] = opt_briscola[:num_segni_match][:val]
      end
      if opt_briscola[:target_points_segno]
        @game_opt[:target_points_segno] = opt_briscola[:target_points_segno][:val]
      end
    end
    #p @game_opt[:num_segni_match]
  end
 
  ##
  # Col termine di giocata ci si riferisce al mescolamento delle carte e alla
  # sua distribuzione
  def new_giocata
    @log.debug "new_giocata START"
    @player_input_hdl.block_start
    @segno_state = :started
     # reset some data structure
    @carte_prese = {}
    @carte_in_mano = {}
    @mano_count = 0
    # reset also events queue
    clear_gevent
    
     #extract the first player
    first_player_ix = @rnd_mgr.get_first_player(@players.size) #rand(@players.size)
    # calculate the player order (first is the player that have to play)
    @round_players = calc_round_players( @players, first_player_ix)
    @round_players.each {|pl| @log.debug "Playing #{pl.name}"}
    
    create_deck
    #shuffle deck
    @mazzo_gioco = @rnd_mgr.get_deck(@mazzo_gioco)
    
    @game_core_recorder.store_new_giocata(@mazzo_gioco, first_player_ix) if @game_opt[:record_game]
    dump_curr_deck
    
    new_giocata_distribute_cards
    
    @log.debug "new_giocata END"
    @player_input_hdl.block_end
  end
  
  def new_giocata_distribute_cards
    # distribuite card to each player
    carte_player = []
    briscola = @mazzo_gioco.pop 
    @briscola_in_tav_lbl = briscola
    @round_players.each do |player|
      @num_of_cards_onhandplayer.times{carte_player << @mazzo_gioco.pop}
      #p carte_player
      player.algorithm.onalg_new_giocata( [carte_player, briscola].flatten)
      # store cards to each player for check
      @carte_in_mano[player.name] = carte_player
      carte_player = [] # reset array for the next player
      # reset cards taken during the giocata
      @carte_prese[player.name] = [] # uso il nome per rendere la chiave piccola 
      @points_curr_segno[player.name] = 0
    end
    #p @carte_prese
    submit_next_event(:new_mano)
  end
  
  ##
  # Col termine di mano ci si riferisce a tutte le carte giocate dai giocatori
  # prima che ci sia una presa
  def new_mano
    @log.info "new_mano START"
    @player_input_hdl.block_start
    
    # reverse it for use pop
    @round_players.reverse!
    player_onturn = @round_players.last
    
    #inform about start new mano
    @players.each{|pl| pl.algorithm.onalg_newmano(player_onturn) }
    @log.debug "player have to play #{player_onturn.name}"
    # notify all players about player that have to play
    @players.each do |pl|
      pl.algorithm.onalg_have_to_play(player_onturn)
    end
    @log.info "new_mano END"
    @player_input_hdl.block_end
  end
  

  ##
  # Check if giocata terminated because a player reach the target points
  def check_if_giocata_is_terminated
    tot_num_cards = 0
    @carte_in_mano.each do |k,card_arr|
      # cards in hand of player
      #p card_arr 
      tot_num_cards += card_arr.size
    end
    tot_num_cards += @mazzo_gioco.size
    @log.debug "Giocata end? cards yet in game are: #{tot_num_cards}"
    
    if tot_num_cards <= 0
      # segno is terminated because no more card are to be played
      @log.debug("Giocata end beacuse no more cards have to be played")
      return true
    end
    return false
  end
  
  ##
  # Tempo di pescare una carta dal mazzo
  def pesca_carta
    @log.info "pesca_carta"
    carte_player = []
    briscola_in_tavola = true
    if @mazzo_gioco.size > 0
      # ci sono ancora carte da pescare dal mazzo   
      @round_players.each do |player|
        # pesca una sola carta
        if @mazzo_gioco.size > 0
          carte_player << @mazzo_gioco.pop
        elsif briscola_in_tavola == true
          carte_player << @briscola_in_tav_lbl
          @log.info "pesca_carta: distribuisce anche la briscola"
          briscola_in_tavola = false
        else
          @log.error "Pesca la briscola che non c'è più"
        end 
        #p carte_player
        player.algorithm.onalg_pesca_carta(carte_player)
        # store cards to each player for check
        carte_player.each{|c| @carte_in_mano[player.name] << c}
        carte_player = [] # reset array for the next player
      end
    else
      @log.error "Pesca in un mazzo vuoto"
    end
    @log.info "Mazzo rimanenti: #{@mazzo_gioco.size}"
    submit_next_event(:new_mano)
  end
  
  ##
  # Una carta e' stata giocata con successo, continua la mano se
  # ci sono ancora giocatori che devono giocare, altrimenti la mano finisce.
  def continua_mano
    @log.debug "continua_mano START"
    @player_input_hdl.block_start
    
    player_onturn = @round_players.last
    if player_onturn
      # notify all players about player that have to play
      @log.debug "player have to play #{player_onturn.name}"
      @players.each do |pl|
        pl.algorithm.onalg_have_to_play(player_onturn)
      end
    else
      # no more player have to play
      @log.debug "continua_mano END"
      @player_input_hdl.block_end
      submit_next_event(:mano_end)
      return
    end
    @log.debug "continua_mano END"
    @player_input_hdl.block_end
  end
  
  ##
  # mano end
  def mano_end
    # mano end calcola chi vince la mano e ricomincia da capo
    # usa @carte_gioc_mano_corr per calcolare chi vince la mano; 
    # accumula le carte prese nell hash @carte_prese
    @log.info "mano_end"
    lbl_best,player_best =  vincitore_mano(@carte_gioc_mano_corr)
    @log.info "mano vinta da #{player_best.name}"
    @mano_count += 1
    
    @carte_gioc_mano_corr.each do |hash_card| 
      hash_card.keys.each{|lbl_card| @carte_prese[player_best.name] << lbl_card }
    end 
    # build circle of player that have now to play
    first_player_ix = @players.index(player_best)
    @round_players = calc_round_players( @players, first_player_ix)
    
    # prepare notification
    carte_prese_mano = []
    @carte_gioc_mano_corr.each do |hash_card| 
      hash_card.keys.each{|k| carte_prese_mano << k }
    end
    
    punti_presi = calc_puneggio(carte_prese_mano)
    @log.info "Punti fatti nella mano #{punti_presi}" 
    @players.each{|pl| pl.algorithm.onalg_manoend(player_best, carte_prese_mano, punti_presi) }
    
    # reset cards played on  the current mano
    @carte_gioc_mano_corr = []
  
    # add points
    @points_curr_segno[player_best.name] +=  punti_presi
    str_points = ""
    @points_curr_segno.each do |k,v|
      str_points += "#{k} = #{v} "
    end
    @log.info "Punteggio attuale: #{str_points}" 
    
    # check if giocata is terminated
    if check_if_giocata_is_terminated
      submit_next_event(:giocata_end)
      return
    end
    
    if @mazzo_gioco.size > 0
      # there are some cards in the deck
      submit_next_event(:pesca_carta)
      return
    else
      # continue without pick the card from deck
      submit_next_event(:new_mano)
      return
    end
  end
  
  def giocata_end_calc_bestpoints
    # notifica tutti i giocatori chi ha vinto il segno
    # crea un array di coppie fatte da nome e punteggio, esempio: 
    # [["rudy", 45], ["zorro", 33], ["alla", 23], ["casa", 10]]
    best_pl_points =  @points_curr_segno.to_a.sort{|x,y| y[1] <=> x[1]}
    nome_gioc_max = best_pl_points[0][0]
    update_segni_score(best_pl_points, nome_gioc_max)
    
    return best_pl_points
  end
 
  def update_segni_score(best_pl_points, nome_gioc_max)
    if best_pl_points[0][1] == 60
      @log.info "Game tied both players with 60 points"
    else
      @segni_curr_match[nome_gioc_max] += 1
    end
  end

  def giocata_end
    @log.info "giocata_end"
    @segno_state = :end
    best_pl_points = giocata_end_calc_bestpoints
    if @game_opt[:record_game]
      @game_core_recorder.store_end_giocata(best_pl_points)
    end
    
    @players.each{|pl| pl.algorithm.onalg_giocataend(best_pl_points) }
  end
  
  ##
  # Match finito
  def match_end
    @log.info "match_end"
    @match_state = :match_terminated
    # we don't need events anymore
    clear_gevent
    # notifica tutti i giocatori chi ha vinto la partita
    # crea un array di coppie fatte da nome e punteggio, esempio: 
    # [["rudy", 4], ["zorro", 1]]
    best_pl_segni =  segni_curr_match_sorted
    if @game_opt[:record_game]
      @game_core_recorder.store_end_match(best_pl_segni)
    end
    @players.each{|pl| pl.algorithm.onalg_game_end(best_pl_segni) }
  end
  
  ##
  # Provides an array for score, something like : [["rudy", 4], ["zorro", 1]]
  def segni_curr_match_sorted
    return @segni_curr_match.to_a.sort{|x,y| y[1] <=> x[1]}
  end
  
  ##
  # Calcola il punteggio delle carte in input
  # carte_prese_mano: card label array (e.g. [:_Ab, :_2s,...])
  def calc_puneggio(carte_prese_mano)
    punti = 0
    carte_prese_mano.each do |card_lbl|
      card_ifo = @deck_information.get_card_info(card_lbl)
      punti += card_ifo[:points]
    end
    
    return punti
  end
  
  ##
  # Return player  that catch the current mano and also the card played
  # carte_giocate: an array of hash with label and player (e.g [:_A =>player1])
  def vincitore_mano(carte_giocate)
    lbl_best = nil
    player_best = nil
    carte_giocate.each do |card_gioc|
      # card_gioc is an hash with only one key
      lbl_curr = card_gioc.keys.first
      player_curr = card_gioc[lbl_curr]
      unless lbl_best
        # first card is the best
        lbl_best = lbl_curr
        player_best = player_curr
        # continue with the next
        next
      end
      # now check with the best card
      info_cardhash_best = @deck_information.get_card_info(lbl_best)
      info_cardhash_curr = @deck_information.get_card_info(lbl_curr)
      if is_briscola?(lbl_curr) && !is_briscola?(lbl_best)
        # current wins because is briscola and best not
        lbl_best = lbl_curr; player_best = player_curr
      elsif !is_briscola?(lbl_curr) && is_briscola?(lbl_best)
        # best wins because is briscola and current not, do nothing
      else 
        # cards are both briscola or both not, rank decide when both cards are on the same seed
        if info_cardhash_curr[:segno] == info_cardhash_best[:segno]
          if info_cardhash_curr[:rank] > info_cardhash_best[:rank]
            # current wins because is higher
            lbl_best = lbl_curr; player_best = player_curr
          else
            # best wins because is briscola, do nothing
          end
        else
          # cards are not on the same suit, first win, it mean best
        end
      end 
    end
    return lbl_best, player_best
  end
  
  ##
  # Say if the lbl_card is a briscola. 
  # lbl_card: card label (e.g. :_Ab)
  def is_briscola?(lbl_card)
    card_info = @deck_information.get_card_info(lbl_card)
    card_info_briscola = @deck_information.get_card_info(@briscola_in_tav_lbl)
    segno_card = card_info[:segno]
    segno_brisc = card_info_briscola[:segno]
    res =  segno_brisc == segno_card
    #p "is_briscola #{lbl_card} #{res}"
    return res 
  end
  
  ##
  # Return true if the player is the first on this mano
  def first_to_play?(player)
    # a player is first when @round_players is not yet consumed
    # and on the last position of @round_players there is the player
    if @round_players.size ==  @players.size
      if @round_players.last == player
        return true
      end
    end
    return false
  end
  
 
  ## Algorithm and GUI notification calls ####################
  
  ##
  # Player resign a game
  # player: instance of PlayerOnGame
  # reason: :abandon or :disconnection
  def alg_player_resign(player, reason)
    return if super(player, reason)
    if @segno_state == :end
      return :not_allowed
    end
    @log.info "alg_player_resign: giocatore perde la partita"
    if @game_opt[:record_game]
      @game_core_recorder.store_player_action(player.name, :resign, player.name, reason)
    end
    @segno_state = :end
    # set negative value for segni in order to make player marked as looser
    @segni_curr_match[player.name] = -1
    
    submit_next_event(:match_end)
  end

  
  ##
  # Notification player has played a card
  # lbl_card: card played label (e.g. :_Ab)
  def alg_player_cardplayed(player, lbl_card)
    return if super(player, lbl_card)
    @log.debug "alg_player_cardplayed from #{player.name}: #{lbl_card}"
    if @segno_state == :end
      @card_played_error = {:player =>player, :lbl_card =>  lbl_card}
      submit_next_event(:card_played_is_erroneous)
      return :not_allowed
    end
    res = :not_allowed
    if @round_players.last == player
      # the player on turn has played, ok
      cards = @carte_in_mano[player.name]
      pos = cards.index(lbl_card) if cards
      if pos
        # card is allowed to be played
        res = :allowed
        if @game_opt[:record_game]
          @game_core_recorder.store_player_action(player.name, :cardplayed, player.name, lbl_card)
        end
        # remove it from list of availablecards
        @carte_in_mano[player.name].delete_at(pos)
        # uses a special trace to recognize this entry
        @log.info "++#{@mano_count},#{@carte_gioc_mano_corr.size},Card #{lbl_card} played from player #{player.name}"
        #store it in array of card played during the current mano
        @carte_gioc_mano_corr << {lbl_card => player}
        
        submit_next_event(:card_played_is_correct)
        return res
      end 
    else
      @log.warn "player #{player.name} is not the last, expected #{@round_players.last}"
    end
    if res == :not_allowed
      @log.warn "alg_player_cardplayed: not played correctly from #{player.name}, card #{lbl_card}. Why...?"
      @card_played_error = {:player =>player, :lbl_card =>  lbl_card}
      submit_next_event(:card_played_is_erroneous)
    end 
    
    return res
  end
  
  def card_played_is_correct
    #p @carte_gioc_mano_corr
    lbl_card = @carte_gioc_mano_corr.last.keys[0]
    player = @carte_gioc_mano_corr.last.values[0]
    # notify all players that a player has played a card
    @players.each{|pl| pl.algorithm.onalg_player_has_played(player, lbl_card) }
    # remove player from list of players that have to play
    @round_players.pop
    submit_next_event(:continua_mano)
  end
  
  def card_played_is_erroneous
    if @card_played_error[:player] != nil and
       @card_played_error[:lbl_card] != nil
      lbl_card = @card_played_error[:lbl_card]
      player = @card_played_error[:player]
      player.algorithm.onalg_player_cardsnot_allowed(player, [lbl_card])
      @log.warn "Card #{lbl_card} not allowed to be played from player #{player.name}"
      @card_played_error = {}
    else
      @log.warn "Card card_played_is_erroneous called without info"
    end
  end
  
  ##
  # Main app inform about starting a new match
  # players: array of PlayerOnGame
  def gui_new_match(players)
    return if super(players)
    @log.info "gui_new_match"
    unless @game_opt[:num_of_players] == players.size
      @log.error "Number of players don't match with option"
      return
    end
    @match_state = :match_started
    
    unless @game_opt[:replay_game]
      # we are not replay a game, reset random manager
      @rnd_mgr.reset_rnd 
    end
    if @game_opt[:record_game]
      @game_core_recorder.store_new_match(players, @game_opt, "Briscola")
    end
   
    @players = players
    
    submit_next_event(:new_match)
  end
  
  def new_match
    # notify all players about new match
    @log.debug "new_match, segni #{@game_opt[:num_segni_match]}, punti #{@game_opt[:target_points_segno]}"
    @players.each do |player| 
      player.algorithm.onalg_new_match( @players )
      @segni_curr_match[player.name] = 0 
    end
    name_players = []
    @players.each {|pl| name_players << pl.name}
    
    submit_next_event(:new_giocata)
  end
  
  ##
  # Trigger a new segno by gui. This action is done by gui and it a 
  # reaction of giocata_end. This is done using the gui because
  # we expect an user interaction after giocata_end and before
  # starting a new segno.
  def gui_new_segno
    return if super
    @log.debug "gui_new_segno"
    unless @segno_state == :end
      # reject request to start a new segno if it wasn't terminated
      @log.info "gui_new_segno request rejected"
      return
    end
    # when a new segno start, the game event queue should be empty
    clear_gevent
    str_status_segni = ""
    @segni_curr_match.each do |k,v|
      str_status_segni += "#{k} = #{v} "
    end
    @log.info "gui_new_segno #{str_status_segni}"
    if @segni_curr_match.values.max < @game_opt[:num_segni_match]
      # trigger a new giocata
      submit_next_event(:new_giocata)
      return
      #process_next_gevent
    else
      #  wait for a new match
      @log.info "gui_new_segno: aspetta inizio nuovo match"
      submit_next_event(:match_end)
      return
      #process_next_gevent
    end
  end
  
 
end

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  
  #require 'ruby-debug' # funziona con 0.9.3, con la versione 0.1.0 no
  #Debugger.start
  #debugger
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  core = CoreGameBriscola.new
  rep = ReplayManager.new(log)
  match_info = YAML::load_file(File.dirname(__FILE__) + '/../../../test/briscola/saved_games/2008_03_17_22_39_52-6-savedmatch.yaml')
  #p match_info
  player = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  alg_coll = { "Gino B." => nil } 
  segno_num = 0
  rep.replay_match(core, match_info, alg_coll, segno_num, 1)
  #sleep 2
end
