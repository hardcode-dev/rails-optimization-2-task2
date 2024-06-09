require 'stackprof'
require_relative 'task-2'

StackProf.run(mode: :object, out: 'stackprof_reports/stackprof.dump', raw: true) do
  work('data_small.txt', disable_gc: false)
end