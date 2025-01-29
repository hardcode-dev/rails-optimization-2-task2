require 'ruby-prof'
require_relative 'task-2'

RubyProf.measure_mode = RubyProf::MEMORY

result = RubyProf.profile do
  work('samples/10000.txt')
end

printer = RubyProf::CallTreePrinter.new(result)
printer.print(path: 'reports', profile: 'profile')