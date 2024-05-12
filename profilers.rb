# Stackprof ObjectAllocations and Flamegraph
#
# Text:
# stackprof stackprof_reports/stackprof.dump
# stackprof stackprof_reports/stackprof.dump --method Object#work
#
# Graphviz:
# stackprof --graphviz stackprof_reports/stackprof.dump > stackprof_reports/graphviz.dot
# dot -Tpng stackprof_reports/graphviz.dot > stackprof_reports/graphviz.png
# imgcat stackprof_reports/graphviz.png

require 'stackprof'
require 'ruby-prof'
require_relative 'work_method.rb'

StackProf.run(mode: :object, out: 'stackprof_reports/stackprof.dump', raw: true) do
  work('data_small.txt', disable_gc: false)
end

# ruby-prof
# dot -Tpng graphviz.dot > graphviz.png
# imgcat graphviz.png
# cat ruby_prof_reports/flat.txt

RubyProf.measure_mode = RubyProf::ALLOCATIONS

result = RubyProf::Profile.profile do
  work('data_small.txt', disable_gc: true)
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open('ruby_prof_reports/flat.txt', 'w+'))

printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(File.open('ruby_prof_reports/graph.html', 'w+'))

printer = RubyProf::CallStackPrinter.new(result)
printer.print(File.open('ruby_prof_reports/callstack.html', 'w+'))

# printer = RubyProf::DotPrinter.new(result)
# printer.print(File.open('ruby_prof_reports/graphviz.dot', 'w+'))

# На этот раз профилируем не allocations, а объём памяти!
RubyProf.measure_mode = RubyProf::MEMORY

result = RubyProf::Profile.profile do
  work('data_small.txt', disable_gc: false)
end

printer = RubyProf::CallTreePrinter.new(result)
printer.print(path: 'ruby_prof_reports', profile: 'profile')

