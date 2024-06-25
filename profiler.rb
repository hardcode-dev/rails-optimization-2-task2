require_relative 'task-2.rb'
require 'benchmark'
require 'memory_profiler'

report = MemoryProfiler.report do
  work(file_name: ARGV[0])
end
report.pretty_print(scale_bytes: true)