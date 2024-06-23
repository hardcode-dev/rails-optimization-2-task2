# Deoptimized version of homework task

require_relative 'task-2'
require 'benchmark'

time = Benchmark.realtime do
  work('data_large.txt')
end

puts "Программа выполнилась за #{time.round(2)} секунд"
