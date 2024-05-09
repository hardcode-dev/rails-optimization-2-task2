# Deoptimized version of homework task

require 'json'
require 'pry'
require 'date'
require 'minitest/autorun'
require 'set'

USER_STATS = {
  'sessionsCount' => -> (user) { user.sessions.count },
  'totalTime' => -> (user) { user.sessions_time.sum.to_s + ' min.' },
  'longestSession' => -> (user) { user.sessions_time.max.to_s + ' min.' },
  'browsers' => -> (user) { user.sessions_browsers.join(', ') },
  'usedIE' => -> (user) { user.sessions_browsers.join(', ').include? 'INTERNET EXPLORER' },
  'alwaysUsedChrome' => -> (user) { user.sessions_browsers.uniq.all? { |b| b.upcase =~ /CHROME/ } },
  'dates' => -> (user) { user.sessions.map{ |s| s.attributes['date'] }.sort.reverse }
}

JSON_FILE_PATH = 'result.json'

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:)
    @attributes = attributes
    @sessions = []
  end

  def add_session(session)
    @sessions << session
  end

  def sessions_time
    @sessions_time ||= sessions.map {|s| s.attributes['time'].to_i}
  end

  def sessions_browsers
    @sessions_browsers ||= sessions.map {|s| s.attributes['browser'].upcase}.sort
  end
end

class Session
  attr_reader :attributes

  def initialize(attributes:)
    @attributes = attributes
  end
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

def collect_stats_from_users(report, user, stat, block)
  user_key = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
  report['usersStats'][user_key] ||= {}
  report['usersStats'][user_key][stat] = block.call(user)
end

def process_user(user, file, is_last_one)
  report = {}
  report['usersStats'] = {}

  USER_STATS.each do |stat, block|
    collect_stats_from_users(report, user, stat, block) 
  end

  file.write("#{report['usersStats'].to_json[1..-2]}")
  file.write(',') unless is_last_one
end

def work(filepath, options = {})
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

  File.delete(JSON_FILE_PATH) if File.exist?(JSON_FILE_PATH)

  GC.disable if options[:disable_gc]

  report = {}
  report['totalUsers'] = 0
  report['totalSessions'] = 0
  all_browsers = Set.new

  previos_user, current_user = nil

  result_file = File.open(JSON_FILE_PATH, 'a')
  result_file.write("{\"usersStats\":{")

  File.open(filepath) do |file|
    file.lazy.each_slice(1000) do |batch|
      batch.each do |line|
        cols = line.split(',')

        if cols[0] == 'user'
          previos_user = current_user if current_user
          new_user_attributes = parse_user(line)
          current_user = User.new(attributes: new_user_attributes)

          process_user(previos_user, result_file, false) if previos_user
          report['totalUsers'] += 1
        elsif cols[0] == 'session'
          session_attributes = parse_session(line)
          session_object = Session.new(attributes: session_attributes)

          current_user.add_session(session_object)
          report['totalSessions'] += 1
          all_browsers.add(session_object.attributes['browser'].upcase)
        end
      end
    end

    process_user(current_user, result_file, true)
  end

  report['allBrowsers'] = all_browsers.to_a
  report['uniqueBrowsersCount'] = all_browsers.size

  result_file.write("},")
  result_file.write("#{report.to_json[1..-2]}")
  result_file.write('}')
  result_file.close

  puts format('MEMORY USAGE: %d MB', (`ps -o rss= -p #{Process.pid}`.to_i / 1024))
end
