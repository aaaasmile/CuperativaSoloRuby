# file: inv_theme.rb

class InvTheme
  attr_reader :back_color, :fore_color, :border_color, :main_color, :fonts_text, :accent_color
  
  def self.create_default(fxapp)
    theme = InvTheme.new(fxapp)
    return theme
  end
  
  private
  
  def initialize(fxapp)
    set_default(fxapp)
  end
  
  def set_default(fxapp)
    @fonts_text = {}
    @fonts_text[:big] = FXFont.new(fxapp, "arial", 14, FONTWEIGHT_BOLD)
    @fonts_text[:small] = FXFont.new(fxapp, "arial", 10)
    @fonts_text[:medium] = FXFont.new(fxapp, "arial", 12)
    @fonts_text.each_value{|e| e.create}
    @back_color = Fox.FXRGB(0x22, 0x8a, 0x4c)
    @fore_color = Fox.FXRGB(0xff, 0xff, 0xff)
    @border_color = Fox.FXRGB(0x99, 0xe6, 0xb8)
    @main_color = Fox.FXRGB(0x14, 0x52, 0x2d)
    @accent_color = Fox.FXRGB(0x28, 0xa4, 0x5a)
  end
  
end

