require 'ruby-prof'
require_relative 'task-2'

RubyProf.measure_mode = RubyProf::ALLOCATIONS

result = RubyProf::Profile.profile do
  GC.disable
  work('data_large.txt')
end

# Профилирование по аллокациям
printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open('ruby_prof_reports/flats/flat.txt', 'w+'))

printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(File.open('ruby_prof_reports/graphs/graph.html', 'w+'))

printer = RubyProf::CallStackPrinter.new(result)
printer.print(File.open('ruby_prof_reports/callstacks/callstack.html', 'w+'))

# Профилирование по объёму памяти
RubyProf.measure_mode = RubyProf::MEMORY

result = RubyProf::Profile.profile do
  work('data_large.txt')
end

printer = RubyProf::CallTreePrinter.new(result)
printer.print(path: 'ruby_prof_reports/calltrees', profile: 'profile')
