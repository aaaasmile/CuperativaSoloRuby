# tressette_gfx.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../..'
$:.unshift File.dirname(__FILE__) + '/..'

if $0 == __FILE__
  # we are testing this gfx, then load all dependencies
  require '../../cuperativa_gui.rb' 
end

require 'gfx/gfx_general/base_engine_gfx'
require 'gfx/gfx_general/gfx_elements'
require 'gfx/gfx_comp/smazzata_mbox_gfx'
require 'core_game_tressettein4'
require 'tressette/tressette_gfx'


class Tressettein4Gfx < TressetteGfx
  
  # constructor 
  # parent_wnd : application gui     
  def initialize(parent_wnd)
    super(parent_wnd)
    
    @log = Log4r::Logger.new("coregame_log::Tressettein4Gfx") 
   
    @core_name_class = 'CoreGameTressettein4'
    @algorithm_name = "AlgCpuTressettein4" 
  end
  
  def build_controls_onnewgame(players)
    
    #p players
    # set players algorithm
    pos_names_opp = [:ovest, :est]
    ix = 0
    ix_socio = calc_ix_socio(@player_on_gui[:index])
    players.each do |player|
      player_label = player.name.to_sym
      # prepare info, an empty hash for gfx elements on the player
      @player_gfx_info[player_label] = {}
      if player.type == :cpu_local
        if ix_socio == ix
          player.position = :nord
        else
          player.position = pos_names_opp.pop
        end
        player.algorithm = eval(@algorithm_name).new(player, @core_game, method(:registerTimeout))
      elsif player.type == :human_local
        # already done above
      end
      
      if player.position == :est ### EST
        @log.debug "EST: #{player.name}"
        @cards_players.build_with_info(player.name, :card_opp_img, false,
              {:x => {:type => :right_anchor, :offset => 0},
               :y => {:type => :center_anchor_vert, :offset => 0},
               :anchor_element => :canvas, :intra_card_off => -30 } )
        @otherplayers_list << player
        @labels_graph.set_label_text(player.name.to_sym,
                                     player.name, 
              {:x => {:type => :right_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 50},
               :anchor_element => :canvas })
        @turn_marker.add_marker(player.name, :is_on,
              {:x => {:type => :right_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 58},
               :anchor_element => :canvas, :marker_width => 40, :marker_height => 15 })
        
        elsif player.position == :ovest  ### OVEST
        @log.debug "OVEST: #{player.name}"
        @cards_players.build_with_info(player.name, :card_opp_img, false,
              {:x => {:type => :top_anchor, :offset => 0},
               :y => {:type => :center_anchor_vert, :offset => 0},
               :anchor_element => :canvas, :intra_card_off => -30 } )
        @otherplayers_list << player
        @labels_graph.set_label_text(player.name.to_sym,
                                     player.name, 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 150},
               :anchor_element => :canvas })
        @turn_marker.add_marker(player.name, :is_on,
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 58},
               :anchor_element => :canvas, :marker_width => 40, :marker_height => 15 })
        @labels_graph.set_label_text(:nord_player_pt,
                                     "Punti: ", 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 80},
               :anchor_element => :canvas })
        @picked_cards_shower.build(player.name.to_sym, :coperto,
              {:x => {:type => :right_anchor, :offset => -140},
               :y => {:type => :center_anchor_vert, :offset => -120},
               :anchor_element => :canvas} )
        
        @cards_taken.build_with_info(player.name,
              {:x => {:type => :left_anchor, :offset => 20},
               :y => {:type => :top_anchor, :offset => 136},
               :anchor_element => :canvas, :intra_card_off => -20 } )
        @labels_graph.set_label_text(:info_click_1,
                                     "Click sul mazzetto", 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 184},
               :anchor_element => :canvas }, :small_font)
        @labels_graph.set_label_text(:info_click_2,
                                     "per ultima mano", 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 200},
               :anchor_element => :canvas }, :small_font)
      
      elsif player.position == :nord ### NORD
        @log.debug "NORD: #{player.name}"
        @cards_players.build_with_info(player.name, :card_opp_img, false,
              {:x => {:type => :center_anchor_horiz, :offset => 0},
               :y => {:type => :top_anchor, :offset => 10},
               :anchor_element => :canvas, :intra_card_off => -30 } )
        @otherplayers_list << player
        @labels_graph.set_label_text(player.name.to_sym,
                                     player.name, 
              {:x => {:type => :left_anchor, :offset => 100},
               :y => {:type => :top_anchor, :offset => 40},
               :anchor_element => :canvas })
        @turn_marker.add_marker(player.name, :is_on,
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 48},
               :anchor_element => :canvas, :marker_width => 90, :marker_height => 15 })
        
      elsif player.position == :sud
        @log.debug "SUD: #{player.name}"
      else
        raise "Player position #{player.position} not recognized"
      end
      
      set_position_cardtaken(player_label, player.position)
      
      @players_on_match << player
      ix = ix + 1
    end
    
    # create cards on table
    #@table_cards_played.build(nil)
    @table_cards_played.build_with_info(
        {:x => {:type => :center_anchor_horiz, :offset => 0},
         :y => {:type => :center_anchor_vert, :offset => -40},
         :anchor_element => :canvas,
         :max_num_cards => 4, :intra_card_off => 0, 
         :img_coperto_sym => :coperto, :type_distr => :circular,
         :player_positions => [:nord, :est, :sud, :ovest]})
    
    
                     
                          
    
  end
  
  def calc_ix_socio(ix)
    case ix
    when 0
      return 2
    when 1
      return 3
    when 2
      return 0
    when 3
      return 1
    end
    raise "Index socio impossible to calculate for #{ix}"
  end
  
 
  
end #end Tressettein4Gfx

##############################################################################
##############################################################################

if $0 == __FILE__
  # test this gfx
  require '../../../test/test_canvas'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  
  theApp = FXApp.new("TestCanvas", "FXRuby")
  mainwindow = TestCanvas.new(theApp)
  mainwindow.set_position(0,0,900,700)
  
  
  theApp.create()
  players = []
  players << PlayerOnGame.new('me', nil, :human_local, 0)
  players << PlayerOnGame.new('cpu1', nil, :cpu_local, 1)
  players << PlayerOnGame.new('cpu2', nil, :cpu_local, 2)
  players << PlayerOnGame.new('cpu3', nil, :cpu_local, 3)
  
  mainwindow.init_gfx(Tressettein4Gfx, players)
  theApp.run
end 