#start_cuperativa.rb
# File used to start cuperativa

$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'fox16'
require 'cuperativa_gui'
require 'yaml'
require 'core/crash_reporter'


begin
  
  include Fox

  theApp = FXApp.new("CuperativaGui", "FXRuby")
  mainwindow = CuperativaGui.new(theApp)
  theApp.addSignal("SIGINT", mainwindow.method(:onCmdQuit))
  puts "create the APP"
  theApp.create
  
  begin    
    ret_val = nil
    puts "theApp.run"
    ret_val = theApp.run
  rescue => detail
    str_report = "Error on run \n"
    str_report.concat("Versione: #{CuperativaGui.prgversion}\n")
    str_report.concat("Program aborted on #{$!} \n")
    str_report.concat(detail.backtrace.join("\n")) 
    puts str_report
    
    mainwindow.hide
    crash_rep = CupCrashReporter.new(theApp)
    crash_rep.set_error_text(str_report)
    crash_rep.create
    crash_rep.show  
  
    theApp.run
  end
  
  theApp.destroy
  theApp = nil
  mainwindow = nil
  
rescue => detail
  str = "Error outside the run \n"
  str += "Program aborted on #{$!} \n"
  str += detail.backtrace.join("\n")
  puts str
  CupCrashReporter.create_ownapp(str)
end
