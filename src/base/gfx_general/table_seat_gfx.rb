#file: table_seat_gfx.rb


class TableSeatGfx
  attr_reader  :model_canvas_gfx
  
  def initialize(wnd, cup_gui, height, width)
    @app_owner = wnd
    @widget_list_clickable = []
    @curr_game_info = nil
    @log = Log4r::Logger.new("coregame_log::TableSeatGfx")
    @cup_gui = cup_gui
    @enabled = false
    @model_canvas_gfx = ModelCanvasGfx.new
    @model_canvas_gfx.info[:canvas] = {:height => height, :width => width, :pos_x => 0, :pos_y => 0 }
    @curr_game_info = {}
    create
  end
  
  def onSizeChange(width,height)
    @model_canvas_gfx.info[:canvas] = {:height => height, :width => width, :pos_x => 0, :pos_y => 0 }
  end
  
  def enable
    return if @enabled == true
    @enabled = true
    @labels_graph.change_font_color(Fox.FXRGB(255, 255, 255))
    show_detail_of_current
    
    
  end
  
  def disable
    @enabled = false
    @curr_game_info = {}
    @labels_graph.clear_labels
    @labels_graph.change_font_color(Fox.FXRGB(0, 0, 0))
    @labels_graph.set_label_text(:info,
                                     "Giochi in rete non disponibili", 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 20},
               :anchor_element => :canvas }, :small_font)
    
    @labels_graph.build()
    
    @app_owner.update_dsp
  end
  
  def create
    @font_text_curr = {}
    @font_text_curr[:big] = FXFont.new(@cup_gui.getApp(), "arial", 14, FONTWEIGHT_BOLD)
    @font_text_curr[:small] = FXFont.new(@cup_gui.getApp(), "arial", 10)
    @font_text_curr.each_value{|e| e.create}
    
    @color_text_label = Fox.FXRGB(0, 0, 0)
    
    @composite_graph = GraphicalComposite.new(@app_owner)
    @labels_graph = LabelsGxc.new(@app_owner, self, @color_text_label, @font_text_curr[:big], @font_text_curr[:small])
    @composite_graph.add_component(:labels_graph, @labels_graph)

  end
  
  def draw_static_scene(dc, width, height)
    if @enabled == false 
      dc.foreground = Fox.FXRGB(243, 240, 100)
      dc.fillRectangle(0, 0, width, height)
    end
    if @composite_graph != nil
      @composite_graph.draw(dc) 
    end
  end
  
  def onLMouseDown(event)
    ele_clickable = false
    @widget_list_clickable.sort! {|x,y| x.z_order <=> y.z_order}
    @widget_list_clickable.each do |item|
      if item.visible
        bres = item.on_mouse_lclick(event.win_x, event.win_y)
        ele_clickable = true
        break if bres
      end
    end
    @app_owner.update_dsp if ele_clickable
  end
  
  def onLMouseUp(x,y)
    ele_clickable = false
    @widget_list_clickable.sort! {|x,y| x.z_order <=> y.z_order}
    @widget_list_clickable.each do |item|
      if item.visible
        bres = item.on_mouse_lclick_up
        ele_clickable = true
        break if bres
      end
    end
    @app_owner.update_dsp if ele_clickable
  end
  
  #game_data: {:players=>["marco"], :user_score=>0, :class=>true, :index=>"15", :game=>"Briscola", :user=>"marco", :user_type=>:user, :prive=>false, :opt_game=>{:num_segni_match=>{:type=>:textbox, :name=>"Segni in una partita", :val=>2}, :target_points_segno=>{:type=>:textbox, :name=>"Punti vittoria segno", :val=>61}}}
  def set_game_detail(game_data )
    if game_data != @curr_game_info
      @curr_game_info = game_data
      #p @curr_game_info
      show_detail_of_current
    end
  end
  
  def show_detail_of_current
    @labels_graph.clear_labels
    #p @curr_game_info
    #p @curr_game_info[:user]
    if @curr_game_info == nil or @curr_game_info[:game] == nil
      @labels_graph.set_label_text(:info,
                                     "Nessun gioco selezionato. Seleziona o creane uno nuovo.", 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 20},
               :anchor_element => :canvas }, :small_font)
      @labels_graph.build()
      @app_owner.update_dsp
      return
    end
    
    str_class_val = @curr_game_info[:class] ? "si" : "no"
    str_prive_val = @curr_game_info[:prive] ? "si" : "no"
    str_giocatori = @curr_game_info[:players].join(",")
    line_detail(10, 18, 200, "Gioco:", @curr_game_info[:game] )
    line_detail(10, 34, 200, "Creato da:", @curr_game_info[:user] )
    line_detail(10, 52, 200, "Giocatori:", str_giocatori )
    line_detail(10, 68, 200, "Classifica:", str_class_val )
    line_detail(10, 84, 200, "Gioco privato:", str_prive_val )
    line_detail(10, 100, 200, "Opzioni:", "" )
    
    tokenize_options(20, 116, 200, 16, @curr_game_info[:opt_game])
    
    @labels_graph.build()
    
    @app_owner.update_dsp
  end
  
  # opt: {:num_segni_match=>{:type=>:textbox, :name=>"Segni in una partita", :val=>2}, :target_points_segno=>{:type=>:textbox, :name=>"Punti vittoria segno", :val=>61}
  def tokenize_options(x_off, y_off, x_off_col2, step_y, opt)
    y_curr = y_off
    opt.each do |k, opt_det|
      str_name = opt_det[:name].to_s
      str_val = opt_det[:val].to_s
      if opt_det[:type] == :checkbox
        str_val = opt_det[:val] ? "si" : "no"
      end
      
      lbl_key = "opt_#{str_name}_name"
      @labels_graph.set_label_text(lbl_key.to_sym,
                                     "#{str_name}:", 
              {:x => {:type => :left_anchor, :offset => x_off},
               :y => {:type => :top_anchor, :offset => y_curr},
               :anchor_element => :canvas }, :small_font)
      
      lbl_key = "opt_#{str_name}_val"
      @labels_graph.set_label_text(lbl_key.to_sym,
                                     "#{str_val}", 
              {:x => {:type => :left_anchor, :offset => x_off_col2},
               :y => {:type => :top_anchor, :offset => y_curr},
               :anchor_element => :canvas }, :small_font)
      
      y_curr += step_y
    end
  end
  
  def line_detail(x_off, y_off, x_col2, str_name, str_val)
    
    key_name = "#{str_name}_name".to_sym
    key_val = "#{x_off}#{y_off}_val".to_sym
    
    @labels_graph.set_label_text(key_name,
                                     str_name, 
              {:x => {:type => :left_anchor, :offset => x_off},
               :y => {:type => :top_anchor, :offset => y_off},
               :anchor_element => :canvas }, :small_font)
    
    @labels_graph.set_label_text(key_val,
                                     str_val, 
              {:x => {:type => :left_anchor, :offset => x_col2},
               :y => {:type => :top_anchor, :offset => y_off},
               :anchor_element => :canvas }, :small_font)
  end
  
end