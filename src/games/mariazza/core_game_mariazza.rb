# file: core_game_mariazza.rb
# handle the mariazza game engine
#

$:.unshift File.dirname(__FILE__)

require File.dirname(__FILE__) + '/../briscola/core_game_briscola'
require File.dirname(__FILE__) + '/../../replay/game_replayer'
require 'alg_cpu_mariazza'

# Class to manage the core card game
class CoreGameMariazza < CoreGameBriscola
  
  def initialize
    super
    @num_of_cards_onhandplayer = 5
    @game_opt[:target_points_segno] = 41
    @log = Log4r::Logger.new("coregame_log::CoreGameMariazza")
    # defines mariazza declaration
    @mariazze_def = {:mar_den => {:name_lbl => "Mariazza di denari", :carte => [:_Cd, :_Rd]}, 
      :mar_spa => {:name_lbl => "Mariazza di spade", :carte => [:_Cs, :_Rs]},
      :mar_cop => {:name_lbl => "Mariazza di coppe", :carte => [:_Cc, :_Rc]},
      :mar_bas => {:name_lbl => "Mariazza di bastoni", :carte => [:_Cb, :_Rb]}
    }
    
    
    @declaration_done = {}
    # mariazza point for the next declaration
    @mariazza_points_nextdecl = 20
    # pending points mariazza declaration on the second mano
    @pending_mariazza_points = {}
    load_game_info(File.dirname(__FILE__))
  end
  
  def set_specific_options(options)
    #p options[:games_opt][:mariazza_game]
    return unless options[:games_opt]
    if options[:games_opt][:mariazza_game]
      opt_game = options[:games_opt][:mariazza_game]
      if opt_game[:num_segni_match]
        @game_opt[:num_segni_match] = opt_game[:num_segni_match][:val]
      end
      if opt_game[:target_points_segno]
        @game_opt[:target_points_segno] = opt_game[:target_points_segno][:val]
      end
    end
    #p @game_opt[:num_segni_match]
  end
  
  def new_giocata
    @player_input_hdl.block_start
    @mariazza_points_nextdecl = 20
    @pending_mariazza_points = {}
    super
    @round_players.each do |player|
      @declaration_done[player.name] = []
    end
    @player_input_hdl.block_end
  end
  
  ##
  # Col termine di mano ci si riferisce a tutte le carte giocate dai giocatori
  # prima che ci sia una presa
  def new_mano
    @log.debug "new_mano START"
    @player_input_hdl.block_start
    
    # reverse it for use pop
    @round_players.reverse!
    player_onturn = @round_players.last
    
    #inform about start new mano
    @players.each{|pl| pl.algorithm.onalg_newmano(player_onturn) }
    
    # notify all players about player that have to play
    @players.each do |pl|
      if pl == player_onturn  
        if @pending_mariazza_points[player_onturn.name]
          # player now can get points prieviously declared
          points_get = @pending_mariazza_points[player_onturn.name][:points]
          # don't reset all @pending_mariazza_points because it could be more mariazza declaration pending
          @pending_mariazza_points[player_onturn.name] = nil #points are consumed
          @log.info "Player #{player_onturn.name} get #{points_get} points for declaration in the past"
          @points_curr_segno[player_onturn.name] += points_get
          # notify all players that a player has got points
          @players.each do |player_to_ntf|
            # pay attention with the name because we are already iterating @players
            player_to_ntf.algorithm.onalg_player_has_getpoints(player_onturn, points_get) 
          end
          # check if the player reach a target points
          if check_if_giocata_is_terminated
            # we don't need to continue anymore
            @log.debug "giocata recognized as terminated"
            @log.debug "new_mano END"
            @player_input_hdl.block_end
            submit_next_event(:giocata_end)
            return 
          end
        end
        # check which mariazza declarations are availables
        command_decl_avail = check_mariaz_declaration(player_onturn)
        #check for additional change of the briscola command
        check_change_briscola(player_onturn, command_decl_avail )
        # notify player about his available commands 
        pl.algorithm.onalg_have_to_play(player_onturn, command_decl_avail)
      else
        # don't notify commands declaration for player that are only informed
        pl.algorithm.onalg_have_to_play(player_onturn, [])
      end
    end
    @log.debug "new_mano END"
    @player_input_hdl.block_end
  end
  
  ##
  # Check if giocata terminated because a player reach the target points
  def check_if_giocata_is_terminated
    #p "check_if_giocata_is_terminated"
    # usando max(metodo di enumerable) per un hash, ogni valore e' un array
    # dove il primo valore e' la chiave il secondo il valore (ex: ["toro", 40]).
    # max fornisce un solo array, ma questo non e' un problema
    nome_gioc_max, punti_attuali_max = @points_curr_segno.max{|a,b| a[1]<=>b[1]}
    # il pareggio non e' possibile in quanto il gioco finisce subito dopo che
    # un giocatore raggiunge i 41 punti
    str_points = ""
    @points_curr_segno.each do |k,v|
      str_points += "#{k} = #{v} "
    end
    @log.info "Punteggio attuale: #{str_points}, max #{punti_attuali_max}, target #{@game_opt[:target_points_segno]}" 
    #p @game_opt[:target_points_segno]
    #p punti_attuali_max
    if punti_attuali_max >= @game_opt[:target_points_segno]
      return true
    end
    return false
  end
  
  
  ##
  # Check if the player can make a chage of briscola on table
  # command_decl_avail: array of hash with command definition 
  # We are using 3 index: :name, :points and :change_briscola. :name, :points
  # are always set, :change_briscola is only in this function
  def check_change_briscola(player, command_decl_avail )
    cards = @carte_in_mano[player.name]
    cards.each do |card_on_hand|
      symb_card_on_hand = get_card_logical_symb(card_on_hand)
      if is_briscola?(card_on_hand) and symb_card_on_hand == :set and @mazzo_gioco.size > 0
        # 7 of briscola is present on player hand and there is briscola on the table to take
        command_decl_avail << {
          :name => :change_briscola,
          :points => 0,
          # briscola change
          :change_briscola => {
            :briscola => @briscola_in_tav_lbl,
            :on_hand => card_on_hand
          } 
        }
        break
      end
    end
  end
  
  ##
  # Check if the player has some declaration, and if yes give availables commands
  # This function return an array of hash. A command use alway index :name and :points.
  def check_mariaz_declaration(player)
    commands_avail = []
    carte_player = @carte_in_mano[player.name]
    @mariazze_def.each do |k, mariaz_ref|
      ix1 = carte_player.index(mariaz_ref[:carte][0])
      ix2 = carte_player.index(mariaz_ref[:carte][1])
      if ix1 and ix2
        #found mariazza
        # check if it was already declared
        decl_ix = @declaration_done[player.name].index(k)
        unless decl_ix
          # mariazza not declared
          @log.debug "Found mariazza #{mariaz_ref[:name_lbl]}"
          # if mariazza has the same seed like briscola it has 20 points more
          seed_b = @briscola_in_tav_lbl.to_s[2..-1]
          seed_mariaz = mariaz_ref[:carte][0].to_s[2..-1]
          extra_points = 0
          if seed_b == seed_mariaz
            # mariazza on the same seed of briscola
            @log.debug "Found mariazza on briscola, 20 more points"
            extra_points = 20
          end
          commands_avail << {
            #name of the command
            :name => k,
            #point of the command 
            :points => @mariazza_points_nextdecl + extra_points,
            # briscola change
            :change_briscola => nil 
          }
        end
      end
    end 
    return commands_avail   
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
      @players.each do |pl|
        if pl == player_onturn
          # check which declaration are availables
          # expert say that mariazza declaration is always available, but points 
          # are given when the player start to play
          command_decl_avail = []
          command_decl_avail = check_mariaz_declaration(player_onturn) 
          check_change_briscola(player_onturn, command_decl_avail )
          pl.algorithm.onalg_have_to_play(player_onturn, command_decl_avail)
        else
          # don't notify declaration for player that are only informed
          pl.algorithm.onalg_have_to_play(player_onturn, [])
        end 
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
  
  
  ### Algorithm and GUI notification calls ####################
  
  ##
  # Notification player change his card with the card on table that defines briscola
  # Only the 7 of briscola is allowed to make this change
  def alg_player_change_briscola(player, card_briscola, card_on_hand )
    return :allowed if super_alg_player_change_briscola(player, card_briscola, card_on_hand)
    @log.debug "alg_player_change_briscola #{player.name}"
    if @segno_state == :end
      return :not_allowed
    end
    res = :not_allowed
    if @round_players.last == player
      # the player on turn want to change briscola: ok
      cards = @carte_in_mano[player.name]
      if cards 
        pos1 = cards.index(card_on_hand)
        if pos1 and @briscola_in_tav_lbl == card_briscola
          symb_card_on_hand = get_card_logical_symb(card_on_hand)
          if is_briscola?(card_on_hand) and symb_card_on_hand == :set  
            # 7 of briscola  is really in the hand of the player
            res = :allowed
            if @game_opt[:record_game]
              @game_core_recorder.store_player_action(player.name, :change_briscola, player.name, card_briscola, card_on_hand)
            end
            # swap 7 with briscola
            @carte_in_mano[player.name][pos1] = card_briscola
            @briscola_in_tav_lbl =  card_on_hand
            @log.info "Player #{player.name} changes the briscola on table " +
            "#{@deck_information.nome_carta_completo(card_briscola)} with #{@deck_information.nome_carta_completo(card_on_hand)}"
            # notify all players that a briscola was changed
            @players.each do |pl| 
              pl.algorithm.onalg_player_has_changed_brisc(player, card_briscola, card_on_hand) 
            end
            #notify the player that have to play with a recalculation of commands
            # mariazza is available only if we start firts
            command_decl_avail = []
            #if @carte_gioc_mano_corr.size == 0
            command_decl_avail = check_mariaz_declaration(player)
            #end
            # don't need to check change briscola
            # remember the player have to play
            player.algorithm.onalg_have_to_play(player, command_decl_avail)
          end
        end
      end 
    end
    if res == :not_allowed
      @log.info "Changing #{card_briscola} with #{card_on_hand} not allowed from player #{player.name}"
      player.algorithm.onalg_player_change_brisc_notallowed if player.algorithm.respond_to?(:onalg_player_change_brisc_notallowed)
    else
      @log.debug "Change ok"
    end 
    
    return res
  end
  
  ##
  # Notification player has make a declaration
  # name_decl: name of mariazza declaration defined in @mariazze_def (e.g. :mar_den)
  def alg_player_declare(player, name_decl)
    return if super_alg_player_declare(player, name_decl)
    @log.debug "alg_player_declare #{player.name}: #{name_decl}"
    if @segno_state == :end
      return :not_allowed
    end
    res = :not_allowed
    if @round_players.last == player
      # the player on turn want to declare: ok
      cards = @carte_in_mano[player.name]
      if cards and @mariazze_def[name_decl]
        c1_mar = @mariazze_def[name_decl][:carte][0]
        c2_mar = @mariazze_def[name_decl][:carte][1]
        pos1 = cards.index(c1_mar)
        pos2 = cards.index(c2_mar)
        if pos1 and pos2
          # mariazza is really in the hand of the player
          # check if it is already declared
          decl_ix = @declaration_done[player.name].index(name_decl) 
          unless decl_ix
            # Mariazza declaration OK, check points
            # first instace of mariazza declaration 
            # add mariazza points
            seed_b = @briscola_in_tav_lbl.to_s[2..-1]
            seed_mariaz = c1_mar.to_s[2..-1]
            extra_points = 0
            if seed_b == seed_mariaz
              # mariazza on the same seed of briscola
              extra_points = 20
            end
            points_mariazza_decl = @mariazza_points_nextdecl + extra_points
            if first_to_play?(player)
              @points_curr_segno[player.name] += points_mariazza_decl
              # don't reset all @pending_mariazza_points because it could be more mariazza declaration pending
              @pending_mariazza_points[player.name] = nil #points are consumed
            else
              # we are not on first mano, that mean we can declare but poits are assigned when 
              # we are first
              @log.debug("Player #{player.name} accumulate points (#{points_mariazza_decl}) assigned when he start")
              @pending_mariazza_points[player.name] ||=  { :points => 0}
              @pending_mariazza_points[player.name][:points] += points_mariazza_decl
              points_mariazza_decl = 0
            end 
            @declaration_done[player.name] << name_decl 
            res = :allowed
            if @game_opt[:record_game]
              @game_core_recorder.store_player_action(player.name, :declare, player.name, name_decl)
            end
            @log.info "Player #{player.name} declare #{@mariazze_def[name_decl][:name_lbl]}"
            # notify all players that a player has declared
            @players.each do |pl| 
              pl.algorithm.onalg_player_has_declared(player, name_decl, points_mariazza_decl) 
            end
            # check if the giocata is terminated
            if check_if_giocata_is_terminated
              @log.debug("Giocata is terminated with declaration")
              submit_next_event(:giocata_end)
              return res
            else
              # experts in Breda say that mariazza is always 20 points
              @mariazza_points_nextdecl = 20
              
              # remember the player have to play
              command_decl_avail=[]
              check_change_briscola(player, command_decl_avail )
              @log.debug "Request continue play with #{command_decl_avail} to #{player.name}"
              player.algorithm.onalg_have_to_play(player, command_decl_avail)
            end
          end
        end
      end 
    end
    if res == :not_allowed
      @log.info "Declaration #{name_decl} not allowed from player #{player.name}"
    end 
    
    return res
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
  core = CoreGameMariazza.new
  rep = ReplayManager.new(log)
  # test algorithm change briscola
  #match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/mariazza/saved_games/mariaz_sett_cam_brisc.yaml')
  # test mariazza declaration second
  match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/mariazza/saved_games/mariaz_acc_secd_03.yaml')
  #p match_info
  player = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  #alg_cpu = AlgCpuMariazza.new(player, core, nil)
  #alg_coll = { "Gino B." => alg_cpu } 
  alg_coll = { "Gino B." => nil } 
  segno_num = 0
  rep.replay_match(core, match_info, alg_coll, segno_num)
  #sleep 2
end
