# frozen_string_literal: true

require_relative '../task-2'
require 'ruby-prof'

RubyProf.measure_mode = RubyProf::WALL_TIME

result = RubyProf.profile do
  work('data/data_large.txt')
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open('ruby_prof_reports/flat.txt', 'w+'))
