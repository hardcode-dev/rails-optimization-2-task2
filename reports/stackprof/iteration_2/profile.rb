# Stackprof ObjectAllocations and Flamegraph
#
# Text:
# stackprof stackprof.dump
# stackprof stackprof.dump --method Object#work
#
# Graphviz:
# stackprof --graphviz stackprof_reports/stackprof.dump > graphviz.dot
# dot -Tpng graphviz.dot > graphviz.png
# imgcat graphviz.png

require 'stackprof'
require_relative '../../task-2.rb'

StackProf.run(mode: :object, out: 'reports/stackprof/report.dump', raw: true) do
  work(file: 'data/data_32_500.txt', disable_gc: false)
end
