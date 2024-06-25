require_relative 'task-2.rb'
require 'benchmark'
require 'ruby-prof'


RubyProf.measure_mode = RubyProf::ALLOCATIONS

result = RubyProf.profile do
  work(file_name: ARGV[0])
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open('ruby_prof_reports/flat.txt', 'w+'))

# printer = RubyProf::DotPrinter.new(result)
# printer.print(File.open('ruby_prof_reports/graphviz.dot', 'w+'))

printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(File.open('ruby_prof_reports/graph.html', 'w+'))

printer = RubyProf::CallStackPrinter.new(result)
printer.print(File.open('ruby_prof_reports/callstack.html', 'w+'))