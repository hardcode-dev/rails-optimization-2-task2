require 'ruby-prof'
require_relative 'task-2.rb'

RubyProf.measure_mode = RubyProf::ALLOCATIONS

profile = RubyProf::Profile.new
result = profile.profile do
  work('data_small.txt', disable_gc: true)
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open('ruby_prof_reports/flat.txt', 'w+'))

printer = RubyProf::DotPrinter.new(result)
printer.print(File.open('ruby_prof_reports/graphviz.dot', 'w+'))

printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(File.open('ruby_prof_reports/graph.html', 'w+'))

printer = RubyProf::CallStackPrinter.new(result)
printer.print(File.open('ruby_prof_reports/callstack.html', 'w+'))

printer = RubyProf::CallTreePrinter.new(result)
printer.print(path: 'ruby_prof_reports', profile: 'profile')