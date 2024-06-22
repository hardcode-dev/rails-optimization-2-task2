require 'ruby-progressbar'
require 'set'
require 'date'
require 'json'
require 'oj'

class Report
  def initialize(file_name, out)
    @file_name = file_name
    @out  = out
  end

  def write
    unique_browsers = Set[]
    total_sessions = 0
    total_users = 0

    progressbar = ProgressBar.create(total: %x{wc -l #{file_name}}.split.first.to_i)

    json_stream  = Oj::StreamWriter.new(out)

    json_stream.push_object
    json_stream.push_object('usersStats')

    user = nil

    File.foreach(file_name) do |line|
      cols = line.split(',')
      if cols[0] == 'user'
        total_users  += 1
        write_user(json_stream, user) if user
        user = parse_user(cols)
      end

      if cols[0] == 'session'
        session = parse_session(cols)
        user['sessions']  << session
        unique_browsers << session['browser'].upcase
        total_sessions += 1
      end
      progressbar.increment
      measure_memory if (progressbar.progress % 100_000).zero?
    end
    write_user(json_stream, user)

    json_stream.pop

    json_stream.push_value(total_users, 'totalUsers')
    json_stream.push_value(unique_browsers.count, 'uniqueBrowsersCount')
    json_stream.push_value(total_sessions, 'totalSessions')
    json_stream.push_value(unique_browsers.sort.join(','), 'allBrowsers')

    json_stream.pop_all

    measure_memory
  end

  private

  def write_user(json_stream, user)
    json_stream.push_object("#{user['first_name']}" + ' ' + "#{user['last_name']}")
    json_stream.push_value(user['sessions'].count, 'sessionsCount')
    browsers = user['sessions'].map { |s| s['browser'].upcase }
    times = user['sessions'].map { |s| s['time'].to_i }
    json_stream.push_value("#{times.sum} min.", 'totalTime')
    json_stream.push_value("#{times.max.to_s} min.", 'longestSession')
    json_stream.push_value(browsers.sort.join(', '), 'browsers')
    json_stream.push_value(browsers.any? { |b| b =~ /INTERNET EXPLORER/ }, 'usedIE')
    json_stream.push_value(browsers.all? { |b| b =~ /CHROME/ }, 'alwaysUsedChrome')
    json_stream.push_value(user['sessions'].map { |s| s['date'].strip }.sort.reverse!, 'dates')
    json_stream.pop
  end

  attr_reader :file_name, :out

  def parse_user(fields)
    {
      'id' => fields[1],
      'first_name' => fields[2],
      'last_name' => fields[3],
      'age' => fields[4],
      'sessions' => []
    }
  end

  def parse_session(fields)
    {
      'user_id' => fields[1],
      'session_id' => fields[2],
      'browser' => fields[3],
      'time' => fields[4],
      'date' => fields[5],
    }
  end

  def measure_memory
    puts "MEMORY USAGE: %d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
  end
end
