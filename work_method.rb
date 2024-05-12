# frozen_string_literal: true

require 'json'

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end

  def collect_stats
    # Собираем количество сессий
    sessions_count = sessions.count
    
    # Собираем количество времени
    total_time = sessions.sum {|s| s['time'].to_i}.to_s + ' min.'

    # Выбираем самую длинную сессию пользователя
    longest_session = sessions.map {|s| s['time']}.map! {|t| t.to_i}.max.to_s + ' min.'

    # Браузеры пользователя через запятую
    browsers = sessions.map {|s| s['browser']}.map! {|b| b.upcase}.sort

    # Хоть раз использовал IE?
    used_IE = browsers.any? { |b| b =~ /INTERNET EXPLORER/ }

    # Всегда использовал только Chrome?
    always_used_chrome = browsers.all? { |b| b =~ /CHROME/ }

    # Даты сессий через запятую в обратном порядке в формате iso8601
    dates = sessions.map! { |session| session['date'] }.sort.reverse

    {
      'sessionsCount' => sessions_count,
      'totalTime' => total_time,
      'longestSession' => longest_session,
      'browsers' => browsers.join(', '),
      'usedIE' => used_IE,
      'alwaysUsedChrome' => always_used_chrome,
      'dates' => dates
    }
  end
end

def parse_user(fields)
  {
    'id' => fields[0],
    'first_name' => fields[1],
    'last_name' => fields[2],
    'age' => fields[3]
  }
end

def parse_session(fields)
  {
    'user_id' => fields[0],
    'session_id' => fields[1],
    'browser' => fields[2],
    'time' => fields[3],
    'date' => fields[4]
  }
end

def work(filename = '', disable_gc: false)
  puts 'Start work'
  GC.disable if disable_gc
  filename = (filename == '') ? 'data.txt' : filename

  file = File.open('result.json', 'w')
  total_users = 0
  total_sessions = 0
  uniqueBrowsers = Set.new

  current_user = nil
  prev_user = nil

  write_start_stats(file)

  File.foreach(ENV['DATA_FILE'] || filename) do |line|
    line_type, *fields = line.chomp.split(',')

    case line_type
    when 'user'
      total_users += 1

      prev_user = current_user
      current_user = User.new(attributes: parse_user(fields), sessions: [])

      if prev_user != nil  
        write_stats(file, prev_user)
      end

    when 'session'
      total_sessions += 1
      session = parse_session(fields)      
      current_user.sessions << session
      uniqueBrowsers << session['browser']
    end
  end

report = {
  totalUsers: total_users,
  totalSessions: total_sessions,
  uniqueBrowsersCount: uniqueBrowsers.uniq.count,
  allBrowsers: uniqueBrowsers.map!(&:upcase).sort.join(',')
}

  write_end_stats(file, current_user, report)

  file.close

  puts 'Finish work'
  puts "MEMORY USAGE: %d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
end

def write_start_stats(file)
  file.puts('{"usersStats": {')
end

def write_stats(file, user)
  user_stats = user.collect_stats
  user_key = "#{user.attributes['first_name']} #{user.attributes['last_name']}"
  file.write '"' + user_key + '":'
  file.write user_stats.to_json

  file.puts ','
end

def write_end_stats(file, user, report)
  user_stats = user.collect_stats
  user_key = "#{user.attributes['first_name']} #{user.attributes['last_name']}"
  file.write '"' + user_key + '":'
  file.write user_stats.to_json

  file.puts('},')

  file.write report.to_json.to_s[1..-2]

  file.puts('}')
end

