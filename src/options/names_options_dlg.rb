#file: names_options_dlg.rb

require 'basic_dlg_options_setter'

##
# Players names setter
class NamesOptionsDlg < BasicDlgOptionsSetter
  
  def initialize(owner, settings, cupera_gui)
    @cupera_gui = cupera_gui
    super(owner, "Nomi giocatori nella Cuperativa (gioco locale)",settings, @cupera_gui,
      30, 30, 500, 600)  
  end
  
  ##
  # Building the option dialogbox. Called during BasicDlgOptionsSetter.initialize
  # main_vertical: vertical frame where to build all child controls
  def on_build_vertframe(main_vertical)
    @widg_players_names = []
    ix = 1
    @settings["players"].each do |vv|
      hf = FXHorizontalFrame.new(main_vertical, LAYOUT_TOP|LAYOUT_LEFT|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH)
      FXLabel.new(hf, "Giocatore #{ix}:", nil, JUSTIFY_RIGHT|LAYOUT_FILL_X|LAYOUT_CENTER_Y)
      txt_f =  FXTextField.new(hf, 2, nil, 0, (FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
      txt_f.text = vv[:name].to_s
      @widg_players_names << txt_f
      ix += 1 
    end
  end
  
  def set_settings
    # update players on table
    @widg_players_names.each_index do |ix|
      @settings["players"][ix][:name] = @widg_players_names[ix].text
    end
    #@cupera_gui.set_players_ontable
  end
  
end#end NamesOptionsDlg

if $0 == __FILE__
  $:.unshift File.dirname(__FILE__) + '/../../..'
  
  require 'test/gfx/test_dialogbox' 
  require 'src/core/resource_info'
  
  ##
  # Launcher of the dialogbox
  class DialogboxCreator
    attr_accessor :main_app
    
    def initialize(app)
      @main_app = app      
      @log = Log4r::Logger.new("coregame_log::DialogboxCreator")
      @log.debug "DialogboxCreator initialized"
    end
    
    ##
    # Method called from TestRunnerDialogBox when go button is pressed
    def run
      @log.debug "Run the tester..."
      settings = YAML::load_file(File.join(ResourceInfo.get_dir_appdata(), 'app_options.yaml'))
      dlg = NamesOptionsDlg.new(@main_app, settings, @main_app)
      dlg.execute
    end
  end
  
  # create the runner: a window with one button that call runner.run
  TestRunnerDialogBox.create_app(DialogboxCreator)
  
end


