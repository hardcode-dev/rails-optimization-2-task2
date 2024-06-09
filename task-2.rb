require 'json'
require 'pry'
require 'date'
require 'oj'
require 'set'

class User
  attr_reader :attributes

  def initialize(attributes:)
    @attributes = attributes
  end
end

# Отчёт в json
#   - Сколько всего юзеров +
#   - Сколько всего уникальных браузеров +
#   - Сколько всего сессий +
#   - Перечислить уникальные браузеры в алфавитном порядке через запятую и капсом +
#
#   - По каждому пользователю
#     - сколько всего сессий +
#     - сколько всего времени +
#     - самая длинная сессия +
#     - браузеры через запятую +
#     - Хоть раз использовал IE? +
#     - Всегда использовал только Хром? +
#     - даты сессий в порядке убывания через запятую +
def parse_file(file_in, file_out)
  writer = Oj::StreamWriter.new(file_out)
  writer.push_object

  session_count = 0
  user_count = 0
  browsers = Set.new

  current_sessions = []
  user = nil
  session = nil

  writer.push_key('usersStats')
  writer.push_object
  file_in.each_line do |line|
    if line.start_with? 'user'
      write_stats_for(user, current_sessions, writer) unless current_sessions.empty?
      user = User.new(attributes: parse_user(line))
      user_count += 1
      current_sessions = []
    elsif line.start_with? 'session'
      session = parse_session(line)
      current_sessions << session
      session_count += 1
      browsers << session['browser']
    end
  end
  write_stats_for(user, current_sessions, writer) unless current_sessions.empty?
  writer.pop

  writer.push_key('totalUsers')
  writer.push_value(user_count)

  writer.push_key('uniqueBrowsersCount')
  writer.push_value(browsers.size)

  writer.push_key('totalSessions')
  writer.push_value(session_count)

  writer.push_key('allBrowsers')
  writer.push_value(browsers.to_a.map { |b| b.upcase }.sort.join(','))

  writer.pop
end

def write_stats_for(user, sessions, writer)
  user_key = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
  writer.push_key(user_key)
  writer.push_object

  writer.push_key('sessionsCount')
  writer.push_value(sessions.count)

  times = sessions.map {|s| s['time']}.map! {|t| t.to_i}
  writer.push_key('totalTime')
  writer.push_value(times.sum.to_s + ' min.')

  writer.push_key('longestSession')
  writer.push_value(times.max.to_s + ' min.')

  browsers = sessions.map {|s| s['browser']}.map! {|b| b.upcase}
  writer.push_key('browsers')
  writer.push_value(browsers.sort.join(', '))

  writer.push_key('usedIE')
  writer.push_value(browsers.any? { |b| b =~ /INTERNET EXPLORER/ })

  writer.push_key('alwaysUsedChrome')
  writer.push_value(browsers.all? { |b| b =~ /CHROME/ })

  dates = sessions.map{|s| s['date']}
  writer.push_key('dates')
  writer.push_value(dates
                    .sort!
                    .reverse!
                    .map! do |d|
                      ary = d.split('-')
                      Date.new(ary[0].to_i, ary[1].to_i, ary[2].to_i).iso8601
                    end)
  writer.pop
end

def parse_user(user)
  fields = user.split(',')
  parsed_result = {
    'id' => fields[1],
    'first_name' => fields[2],
    'last_name' => fields[3],
    'age' => fields[4],
  }
end

def parse_session(session)
  fields = session.split(',')
  parsed_result = {
    'user_id' => fields[1],
    'session_id' => fields[2],
    'browser' => fields[3],
    'time' => fields[4],
    'date' => fields[5],
  }
end

def work(filename = '', disable_gc: true)
  puts "Start work"
  GC.disable if disable_gc

  file_in = File.open(filename)
  file_out = File.open('result.json', 'w')

  parse_file(file_in, file_out)

  file_in.close
  file_out.close

  puts "Finish work"
  puts "MEMORY USAGE: %d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
end
