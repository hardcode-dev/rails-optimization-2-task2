require 'stackprof'
require_relative 'task-2'

StackProf.run(mode: :object, out: 'stackprof_reports/stackprof.dump', raw: true) do
  GC.disable
  work('data30000.txt')
end
