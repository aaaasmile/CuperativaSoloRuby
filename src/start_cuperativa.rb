#start_cuperativa.rb
# File used to start cuperativa

$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'fox16'
require 'cuperativa_gui'
require 'yaml'
require 'crash_reporter/crash_reporter'


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
    puts "Error on run"
    err_name = Time.now.strftime("%Y_%m_%d_%H_%M_%S")
    fname = File.join(File.dirname(__FILE__), "err_app_#{err_name}.log")
    str_report = fname + "\n"
    str_report.concat("Versione: #{CuperativaGui.prgversion}\n")
    File.open(fname, 'w') do |out|
      out << "Program aborted on #{$!} \n"
      out << detail.backtrace.join("\n")
      str_report.concat("Program aborted on #{$!} \n")
      str_report.concat(detail.backtrace.join("\n")) 
    end
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
  puts "Error outside the run"
  err_name = Time.now.strftime("%Y_%m_%d_%H_%M_%S")
  fname = File.join(File.dirname(__FILE__), "starter_err_#{err_name}.log")
  File.open(fname, 'w') do |out|
    str = "Program aborted on #{$!} \n"
    out << str
    puts str
    str = detail.backtrace.join("\n")
    out << str
    puts str
  end
end
