#file test_client_protocoll.rb
# Test function for testing cup_serv_core.rb

$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'test/unit'
require 'log4r'
require 'yaml'


PATH_TO_CLIENT = File.expand_path(File.dirname(__FILE__) + '/../src')

require File.join( PATH_TO_CLIENT, 'cuperativa_gui')
#require File.join( PATH_TO_CLIENT, 'network/client/control_net_conn')


include Log4r

##
# Test suite for testing 
class Test_Client_Protocoll < Test::Unit::TestCase
  
  #
  # Class used to intercept log to recognize errors and warning
  class FakeIO < IO
    attr_accessor :warn_count, :error_count
    
    def initialize(arg1,arg2)
      super(arg1,arg2)
      reset_counts
      @cards_played = []
    end
    
    def reset_counts
      @warn_count = 0; @error_count = 0;
    end
    
    def print(*args)
      #print(args)
      str = args.slice!(0)
      aa = str.split(':')
      if aa[0] =~ /WARN/
        @warn_count += 1
      elsif aa[0] =~ /ERROR/
        @error_count += 1
      end
      # check something like "Card _2c played from player Gino B.\n"
      if aa[1].strip =~ /Card (_..) played from player (.*)/
        card_lbl = $1
        name_pl = $2
        @cards_played << {:card_s => card_lbl, :name => name_pl }
      end
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
    
  end
  
  class FakeCockpitView
    attr_accessor :last_record
    
    def initialize(model)
      @model_net_data = model
    end
    
    def table_add_pgitem2(ix_game)
      @last_record = @model_net_data.get_record_pg(ix_game)
    end
  end #FakeCockpitView
  
  class FakeCupGui
    attr_accessor :logentries
    
    def initialize
      @logentries = []
    end
    def log_sometext(str)
      @logentries << str
      puts str
    end
  end
  
  def setup
    @log = Log4r::Logger.new("coregame_log")
    @cup_gui = FakeCupGui.new
    @control = ControlNetConnection.new(@cup_gui)
    @model_net_data = ModelNetData.new
    @network_cockpit_view = FakeCockpitView.new(@model_net_data)
    @control.set_model_view(@model_net_data, @network_cockpit_view) 
  end
  
  ######################################### TEST CASES ########################
  

  ##
  # Test pg_add command
  def test_pgadd
    #Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    msg_details = "1,Tontouser,Spazzino,<vittoria ai 21,gioco privato>"
    ix_pg = 1
    @control.cmdh_list2_add(msg_details)
    assert_equal "vittoria ai 21,gioco privato", @network_cockpit_view.last_record[3]
  end
  
  def test_srverror
    err_code = 1
    puts "Check server error with code #{err_code}"
    msg_details = "#{err_code}"
    @control.cmdh_srv_error(msg_details)
    assert_match(/<Server ERROR>*./, @cup_gui.logentries.last)
  end
  
  ##
  # Test server response platform update is needed
  def test_updateresp2_platform
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    serverstr = nil
    file_pack_str = nil
    typesym = :platf_update
    sizestr = nil
    descriptionstr = nil
    linkplat = 'http://invido.it/setup.exe'
    msg_details = YAML.dump({:type => typesym, :link_platf => linkplat, :server => serverstr, :file => file_pack_str, :size => sizestr})
    @control.cmdh_update_resp2(msg_details)
    assert_equal(0,io_fake.error_count )
  end
  
  ##
  # Test server response platform update is needed
  def test_updateresp2_application
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    serverstr = 'kickers.fabbricadigitale.it'
    file_pack_str = '/cuperativa/rel/up_to_0_6_4.tgz'
    typesym = :appli_update
    sizestr = '0,1 Mb'
    descriptionstr = "Aggiunto il gioco dell'invido"
    linkplat = nil
    msg_details = YAML.dump({:type => typesym, :link_platf => linkplat, :server => serverstr, :file => file_pack_str, :size => sizestr})
    @control.cmdh_update_resp2(msg_details)
    assert_equal(0,io_fake.error_count )
  end
  
  ##
  # Test server response platform update is needed
  def test_updateresp2_noupdate
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    serverstr = nil
    file_pack_str = nil
    typesym = :nothing 
    sizestr = nil
    descriptionstr = nil
    linkplat = nil
    msg_details = YAML.dump({:type => typesym, :link_platf => linkplat, :server => serverstr, :file => file_pack_str, :size => sizestr})
    @control.cmdh_update_resp2(msg_details)
    assert_equal(0,io_fake.error_count )
  end

    
  ##
  # Test the pgadd2, the yaml version of pgadd
  def test_pgadd2
    io_fake = FakeIO.new(1,'w')
    IOOutputter.new('coregame_log', io_fake)
    Log4r::Logger['coregame_log'].add 'coregame_log'
    @log.outputters << Outputter.stdout
    ix = 35
    user = 'pioppa'
    gamesym = "Spazzino" # on server coded in @@games_available
    bclass = true
    opt_game = {:target_points=>{:name=>"Punti vittoria", :val=>21}}
    bprive = true
    
    msg_details = YAML.dump({:index => ix, :user => user, :game => gamesym, 
                   :prive => bprive, :class => bclass, :opt_game => opt_game})
    @control.cmdh_list2_add(msg_details)
    assert_equal(0,io_fake.error_count )
  end
    
end
