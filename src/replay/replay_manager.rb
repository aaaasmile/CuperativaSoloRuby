#file: replay_manager.rb

##
# Class used to manage a replay of a game
class ReplayManager
  attr_accessor :alg_cpu_contest
  
  @@ACTION_TO_CORE_CALL = {
     :cardplayed => :alg_player_cardplayed,
     :cardplayedarr => :alg_player_cardplayed_arr, 
     :change_briscola => :alg_player_change_briscola, 
     :declare => :alg_player_declare, 
     :resign => :alg_player_resign,
     :gui_new_segno => :gui_new_segno
   }
  
  def initialize(log)
    # array of PlayerOnGame
    @players = []
    # key is PlayerOnGame and value is FixAutoplayer
    @alg_name_conn = {}
    # core action queue, an array of couple player action
    @core_execute_queue = []
    # game core
    @core_game = nil
    # when you test only cpu algorithms with recorded match, set it to true
    @alg_cpu_contest = false
    # logger
    @log = log
  end
  
  ##
  # Create array of PlayerOnGame
  # name_array: array with player names (e.g ["toro", "gino"])
  # core: core game
  # alg_coll: hash with algorithm and player name e.g {"Toro" => algcpumariaz}
  def create_players(name_array, core, alg_coll)
    @players = []
    @alg_name_conn = {}
    alg = nil
    pl = nil
    name_array.each_index do |ix|
      alg = alg_coll[name_array[ix]]
      if alg
        # we have already define an aoutmated algorithm, take it
        pl = alg.alg_player
        pl.algorithm = alg
        pl.position = ix
        @log.info("Autoplayer #{pl.type} bind with #{pl.name} and reuse #{alg.class}")  
      else
        @log.debug "Create a new player for #{name_array[ix]}"
        alg = FixAutoplayer.new(@log, core, self) 
        pl = PlayerOnGame.new(name_array[ix], alg, "replicant_#{ix}".to_sym, ix)
        alg.bind_player(pl)
      end
      @players << pl
      @alg_name_conn[pl.name] = alg
    end
  end
  
  ##
  # Fill the action queue on each FixAutoplayer instance
  # curr_segno: segno hash info e.g. {:first_plx=>1, :actions=>[{:type=>:cardplayed, :arg=>["Gino B.", :_Cc]}...
  def build_action_queue(curr_segno)
    #check curr_segno and use @alg_name_conn to fill the action queue
    curr_segno[:actions].each do |action|
      #p action
      name_player = action[:pl_name]
      alg = @alg_name_conn[name_player]
      #p alg.alg_player
      if alg.alg_player.type.to_s =~ /replicant/
        #append action only on replicant algorithm
        #@log.debug "Append action #{action.inspect}"
        alg.append_action({:type => action[:type], :arg => action[:arg]})
      end
    end
  end
  
  ##
  # Submit an action to be processed when the core give the control back to the replayer
  # action: action detail (e.g. {:type=>:cardplayed, :arg=>["Gino B.", :_Cc]})
  # player: player on game
  def submit_core_action(player, action)
    @core_execute_queue <<  [player, action]
  end
  
  ##
  # EXecute the next core action
  def execute_core_action
    # each item of @core_execute_queue is [player, action]
    player, action = @core_execute_queue.slice!(0)
    alg_call = @@ACTION_TO_CORE_CALL[action[:type]]
    case action[:type]
      when :cardplayedarr
        arg1 = action[:arg][0]; arg2 = action[:arg][1] 
        @core_game.send(alg_call, player, arg2) 
      when :cardplayed 
        arg1 = action[:arg][0]; arg2 = action[:arg][1] 
        @core_game.send(alg_call, player, arg2)
      when :change_briscola
        arg1 = action[:arg][0]; arg2 = action[:arg][1]; arg3 = action[:arg][2]
        @core_game.send(alg_call, player, arg2, arg3)
      when :declare
        arg1 = action[:arg][0]; arg2 = action[:arg][1]
        @core_game.send(alg_call, player, arg2)
      when :resign
        arg1 = action[:arg][0]; arg2 = action[:arg][1] 
        @core_game.send(alg_call, player, arg2)
      when :gui_new_segno
        @core_game.send(alg_call)
      else
        @log.error("execute_core_action: Action #{action[:type]} for #{player.name} not recognized")
    end
  end
  
  # Start a replay of match. All actions, player names and core is provided
  # as input. We can replay a game using the description for all players (FixAutoplayer instance)
  # or the user can provides own algorithm binded to a playername. 
  # core: core game
  # match_info: match information to be replayed, usually is yaml load result of 
  # a previous saved game
  # alg_coll: hash with algorithm and player name e.g {"Toro" => algcpumariaz}
  # If you don't want to set algcpu, but only a replayer set "name" => nil
  # segno_toplay: segno index to be replayed
  def replay_match(core, match_info, alg_coll, segno_toplay, max_num_segni_to_play = nil)
    @core_game = core
    # create players
    create_players(match_info[:players], core, alg_coll)
    # set core options
    match_info[:game][:opt].each do |k,v|
      core.game_opt[k] = v
    end
    #turn off recording (why?, not needed)
    #core.game_opt[:record_game] = false
    # turn on replay
    core.game_opt[:replay_game] = true
    # set info about deck and first player on the random manager
    segni = match_info[:giocate] # catch all giocate, it is an array of hash
    ix_last_segno = max_num_segni_to_play == nil ?  segni.size : [segno_toplay + max_num_segni_to_play, segni.size].min
    
    segno_zero = segni[0]
    core.rnd_mgr.set_predef_ready_deck(segno_zero[:deck], segno_zero[:first_plx])
    core.gui_new_match(@players)
      
    while segno_toplay < ix_last_segno
      @log.debug "Replay segno #{segno_toplay}"
      curr_segno = segni[segno_toplay]
      core.rnd_mgr.set_predef_ready_deck(curr_segno[:deck], curr_segno[:first_plx])
      build_action_queue(curr_segno)
    
      event_num = core.process_only_one_gevent
      while event_num > 0
        event_num = core.process_only_one_gevent
        while @core_execute_queue.size > 0
          execute_core_action
          event_num = 1
        end
      end
      core.gui_new_segno
      segno_toplay += 1
    end
    @log.info("No more action to execute, replay_match terminate")
  end
  
  ##
  # Just continue with the next smazzata or segno after replay_match
  def replaynext_smazzata(core, match_info, alg_coll, segno_toplay)
    @log.info "++++++++++ NEXT SMAZZATA or SEGNO ++++++++++++++++"
    segni = match_info[:giocate] # catch all giocate, it is an array of hash
    curr_segno = segni[segno_toplay]
    #p curr_segno
    core.rnd_mgr.set_predef_ready_deck(curr_segno[:deck], curr_segno[:first_plx])
    # prepare action queue
    build_action_queue(curr_segno)
    if @alg_cpu_contest
      # we are testing a game between algorithms, we can't use @core_execute_queue
      core.suspend_proc_gevents
      core.gui_new_match(@players)
      event_num = core.process_only_one_gevent
      while event_num > 0
        event_num = core.process_only_one_gevent
      end
    else
      # now we can start the game on the core
      core.gui_new_match(@players)
      while @core_execute_queue.size > 0
        execute_core_action
      end
    end
    @log.info("No more action to execute, replay_match terminate")
  end
  
end


if $0 == __FILE__
  
  
end
