require_relative 'report'

Report.new(ARGV[0] || 'data.txt', File.open('report.json', 'w')).write
