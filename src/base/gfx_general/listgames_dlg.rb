# file: listgames_dlg.rb
# Game list

require 'rubygems'
require 'fox16'

include Fox

##
# Class to display the game list
class DlgListGames < FXDialogBox
  
  def initialize(owner, supp_game, curr_game_key, app_setting)
    super(owner, "Seleziona un gioco", DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE,
      0, 0, 0, 280, 0, 0, 0, 0, 4, 4)
    @cup_gui = owner
    color_back = Fox.FXRGB(120, 120, 120)
    color_label = Fox.FXRGB(255, 255, 255)
    
    @allgames_options = []
    supp_game.each do |k, v|
      opt = v.dup
      @allgames_options << opt
    end
    
    @opt_initial = {}
    sel_curr = set_curr_opt(supp_game, curr_game_key)
    set_opt_initial(app_setting, curr_game_key)
    
     
    #p @opt_initial
    
    main_vertical = FXVerticalFrame.new(self, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    lbl_games = FXLabel.new(main_vertical, "Lista giochi:", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    lbl_games.backColor = color_back
    lbl_games.textColor = color_label
    
    
    # list of games as menu pane
    @activated_key = curr_game_key
    
    # simple pane
    pane = FXPopup.new(self)
    
    supp_game.each do |k, v|
      # insert option into the pane
      opt = FXOption.new(pane, v[:name], nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
      opt.connect(SEL_COMMAND) do |sender, sel, ptr|
        set_curr_opt(supp_game, k)
        @activated_key = k
        @lbl_game_desc.text = "#{v[:desc]}"
        set_opt_initial(app_setting, k)
        create_widtget_opt(@frm_vertical, @opt_initial, true)
      end
    end #supp_game
    
    # create the list menu
    menu_list = FXOptionMenu.new(main_vertical, pane, (FRAME_RAISED|FRAME_THICK|
              JUSTIFY_HZ_APART|ICON_AFTER_TEXT|LAYOUT_CENTER_X|LAYOUT_CENTER_Y))
    # select the current game
    menu_list.setCurrentNo(sel_curr)
    
    # game description
    lbl_desctitle = FXLabel.new(main_vertical, "Descrizione:", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    lbl_desctitle.backColor = color_back
    lbl_desctitle.textColor = color_label
    @lbl_game_desc = FXLabel.new(main_vertical, "#{supp_game[curr_game_key][:desc]}", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    
    
    #options
    lbl_widg = FXLabel.new(main_vertical, "Opzioni:", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    lbl_widg.backColor = color_back
    lbl_widg.textColor = color_label
    
    @frm_vertical = FXVerticalFrame.new(main_vertical, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    create_widtget_opt(@frm_vertical, @opt_initial, false)
    
    # ----------- bottom part --------------
    FXHorizontalSeparator.new(main_vertical, SEPARATOR_RIDGE|LAYOUT_FILL_X)
    btframe = FXHorizontalFrame.new(main_vertical, 
                                    LAYOUT_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH )
    
    # Activate commnad
    create_bt = FXButton.new(btframe, "Attiva", @cup_gui.icons_app[:gonext], self, FXDialogBox::ID_ACCEPT,
      LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    create_bt.iconPosition = (create_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    # cancel command
    canc_bt = FXButton.new(btframe, "Cancella", @cup_gui.icons_app[:icon_close], self, FXDialogBox::ID_CANCEL,
      LAYOUT_RIGHT | FRAME_RAISED|FRAME_THICK, 0, 0, 0, 0, 30, 30, 4, 4)
    canc_bt.iconPosition = (canc_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
   
    
  end
  
  def create_widtget_opt(panel_frm, opt_list, create_flag)
    panel_frm.each_child{|c| panel_frm.removeChild(c)} #cancella tutti i controlli creati dentro al frame
    opt_widg_values = {}
    opt_list.each do |kk, vv|
        hf = FXMatrix.new(panel_frm, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        hf.numColumns = 4
        hf.create if create_flag # window è già mostrata, bisogna chiamare create solo in questo caso
        widget_type = vv[:type]
        # widget
        case widget_type
          when :textbox
            # label of the property
            lbl_f = FXLabel.new(hf, vv[:name], nil, JUSTIFY_RIGHT|LAYOUT_FILL_X|LAYOUT_CENTER_Y)
            lbl_f.create if create_flag
            # textbox
            txt_f =  FXTextField.new(hf, 2, nil, 0, (FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
            txt_f.text = vv[:val].to_s
            opt_widg_values[kk] = txt_f
            txt_f.create if create_flag   
          when :checkbox
            # checkbox
            lbl_f = FXLabel.new(hf, vv[:name], nil, JUSTIFY_RIGHT|LAYOUT_FILL_X|LAYOUT_CENTER_Y)
            lbl_f.create if create_flag
            chk_f = FXCheckButton.new(hf, "", nil, (FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
            chk_f.checkState = vv[:val]
            opt_widg_values[kk] = chk_f
            chk_f.create if create_flag
            #p opt_widg_values[kk].class
        end #end case
    end
    @opt_widg_values = opt_widg_values
    
  end
  
  def set_curr_opt(supp_game, curr_game_key)
    sel_curr = 0
    supp_game.each do |k, v|
      break if k == curr_game_key 
      sel_curr += 1
    end
    @curr_game_opt = @allgames_options[sel_curr]
    return sel_curr
  end
  
  def set_opt_initial(app_setting, curr_game_key)
    @opt_initial = @curr_game_opt[:opt]
    if app_setting[:games_opt] != nil
      app_sett_game = app_setting[:games_opt][curr_game_key]
      if app_sett_game != nil
        @opt_initial = app_sett_game
      end
    end
    #p "*** initial: #{curr_game_key}"; p @opt_initial
  end
  
  def get_curr_options
    res = {}
    @opt_initial.each do |k,vv|
      widg = @opt_widg_values[k]
      if widg.class == Fox::FXCheckButton
        val =  widg.checkState == 1 ? true : false
      elsif widg.class == Fox::FXTextField
        val = widg.text.to_i
      end
      res[k] = vv
      res[k][:val] = val
    end
    return res
  end
  
  ##
  # Provides the selected game key
  def get_activatedgame_key
    return @activated_key
  end
  
end # DlgListGames

if $0 == __FILE__
  require 'log4r'
  require '../../../test/gfx/test_dialogbox'
  require '../core/gameavail_hlp' 
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout 
  
  ##
  # Launcher of the dialogbox
  class TestMyDialogGfx

    def initialize(app, log)
      app.runner = self
      @log = log
      @dlg_box = DlgListGames.new(app, InfoAvilGames.info_supported_games(@log), 
          app.last_selected_gametype, app.app_settings)
    end
    
    ##
    # Method called from TestRunnerDialogBox when go button is pressed
    def run
      if @dlg_box.execute != 0
        p @dlg_box.get_curr_options
      end
    end
    
  end
  
  # create the runner: a window with one button that call runner.run
  theApp = FXApp.new("TestRunnerDialogBox", "FXRuby")
  mainwindow = TestRunnerDialogBox.new(theApp)
  mainwindow.set_position(0,0,300,300)
  # add a custom method present in @cup_gui
  def mainwindow.last_selected_gametype
    return :tombolon_game
  end
  
  def mainwindow.app_settings
    return {:games => nil}
  end
  
  tester = TestMyDialogGfx.new(mainwindow, log)
  theApp.create
  
  theApp.run
end

