# -*- coding: ISO-8859-1 -*-
#file: alg_cpu_player_base.rb



# To check  if all interfaces are right use the test case on Test_Botbase
# Note: if you change the meaning of members of this interface,
# i.e carte_player becomes an hash instead of an array, you have
# to redifine NAL_Srv_Algorithm, so better is to implement a new function
class AlgCpuPlayerBase
  
  def initialize(player, coregame, gfx)
     # set algorithm player
    @alg_player = player
    # core game
    @core_game = coregame
    # game gfx
    @gfx_res = gfx
    #delay before play 
    @timeout_haveplay = 700
  end
  
  def onalg_new_giocata(carte_player) end
  def onalg_new_match(players) end
  def onalg_newmano(player) end
  def onalg_have_to_play(player,command_decl_avail) end
  def onalg_player_has_played(player, card) end
  def onalg_player_has_declared(player, name_decl, points) end
  def onalg_pesca_carta(carte_player) end
  def onalg_player_pickcards(player, cards_arr) end
  def onalg_manoend(player_best, carte_prese_mano, punti_presi) end
  def onalg_giocataend(best_pl_points) end
  def onalg_game_end(best_pl_segni) end
  def onalg_player_has_changed_brisc(player, card_briscola, card_on_hand) end
  def onalg_player_has_getpoints(player, points) end
  def onalg_player_cardsnot_allowed(player, cards) end
  def onalg_player_has_taken(player, cards) end
  def onalg_new_mazziere(player) end
  def onalg_gameinfo(info) end
end