# -*- coding: ISO-8859-1 -*-
#file: test_viewer_briscola.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'


require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'
require 'fakestuff'

PATH_TO_CLIENT = File.expand_path(File.dirname(__FILE__) + '/../../src')

require File.join( PATH_TO_CLIENT, 'base/core/core_game_base')
require File.join( PATH_TO_CLIENT, 'games/briscola/core_game_briscola')
require File.join( PATH_TO_CLIENT, 'games/briscola/alg_cpu_briscola')
require File.join( PATH_TO_CLIENT, 'base/core/viewer_base')

include Log4r

class ConsoleBriscolaViewer < TheViewer
  
  def initialize(name)
    super(name)
  end
  
  def game_action(*args)
    meth =  args[0][0]
    send(meth, args[0][1..-1])
  end
  
  def game_state(info)
    p info
  end
  
  def onalg_have_to_play(*args)
    p "onalg_have_to_play #{args}"
  end
  
  def onalg_player_has_played(*args)
    p "onalg_player_has_played #{args}"
  end
  
  def onalg_manoend(*args)
    p "onalg_manoend #{args}"
    p args[0]
  end
  
  def onalg_new_match(*args)
    p "onalg_new_match #{args}"
  end
  
  def onalg_new_giocata(*args)
    p "onalg_new_giocata #{args}"
  end
  
  def onalg_pesca_carta(*args)
    p "onalg_pesca_carta #{args}"
  end
  
  def onalg_giocataend(*args)
    p "onalg_giocataend #{args}"
    p args[0]
  end
end

class Test_Viewers_Briscola < Test::Unit::TestCase 
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @core = CoreGameBriscola.new
  end
  
  def test_match_with_viewer
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    
    #players
    player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
    player1.algorithm = AlgCpuBriscola.new(player1, @core, nil)
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuBriscola.new(player2, @core, nil)
    arr_players = [player1,player2]
    
    #viewwers
    spett1 = ConsoleBriscolaViewer.new("Bonconti")

    @core.add_viewer(spett1)
    @core.gui_new_match(arr_players)
    # gioca il primo segno 
    event_num = @core.process_only_one_gevent
    while event_num > 0
      event_num = @core.process_only_one_gevent
    end
    
  end
end
