require 'stackprof'
require_relative 'task-2'

StackProf.run(mode: :object, out: 'stackprof_reports/stackprof.dump', raw: true) do
  # work('data10000.txt', disable_gc: false)
  work('data_large.txt', disable_gc: false)
end
