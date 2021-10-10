# Deoptimized version of homework task

require 'json'
require 'oj'
require 'set'

COMMA = ','.freeze
SPACE = ' '.freeze
NULLSTRING = ''.freeze
SESSION = 'session'.freeze
USER = 'user'.freeze
SESSIONCOUNT = 'sessionsCount'.freeze
CHROME = 'Chrome'.freeze
TOTALTIME = 'totalTime'.freeze
LONGESTSESSION = 'longestSession'.freeze
BROWSERS = 'browsers'.freeze
USEDIE = 'usedIE'.freeze
IE = 'INTERNET EXPLORER'.freeze
ALWAYSCHROME = 'alwaysUsedChrome'.freeze
DATES = 'dates'.freeze

class User
  
  @@last = nil
  @@count = 0
  @@total_session_count = 0
  @@unique_browsers = SortedSet.new

  def self.initialize_serializer
    @@file = File.open('result.json','w')
    @@serializer = Oj::StreamWriter.new(@@file)
    @@serializer.push_object()
    @@serializer.push_object('usersStats')
  end

  def initialize(name)
    @name = name
    @sessions_count = 0
    @total_time = 0
    @longest_session = 0
    @browsers = SortedSet.new
    @dates = SortedSet.new
    @always_chrome = true
    @@last = self
    @@count += 1
  end

  def add_session(session)

    @sessions_count += 1
    time = session[4].to_i
    @total_time += time
    current_longest_session = @longest_session 
    @longest_session = time if @longest_session < time
    browser = session[3]
    @browsers << browser
    @always_chrome = false if !browser.include?(CHROME)
    @dates << session[5]
  end

  def serialize
    user_browsers = @browsers.reduce(NULLSTRING){|sum, b| sum.empty? ? b.upcase : "#{sum}#{COMMA} #{b.upcase}"}
    @@total_session_count += @sessions_count
    @@unique_browsers += @browsers
    @@serializer.push_object(@name)
    @@serializer.push_value(@sessions_count, SESSIONCOUNT)
    @@serializer.push_value("#{@total_time} min.", TOTALTIME)
    @@serializer.push_value("#{@longest_session} min.", LONGESTSESSION)
    @@serializer.push_value(user_browsers, BROWSERS)
    @@serializer.push_value(user_browsers.include?(IE), USEDIE)
    @@serializer.push_value(@always_chrome, ALWAYSCHROME)
    @@serializer.push_value(@dates.to_a.reverse, DATES)
    @@serializer.pop

    @@last = nil
  end

  def self.serialize_stats
    @@last&.serialize
    @@serializer.pop
    @@serializer.push_value(@@count, 'totalUsers')
    @@serializer.push_value(@@unique_browsers.count, 'uniqueBrowsersCount')
    @@serializer.push_value(@@total_session_count, 'totalSessions')
    @@serializer.push_value(@@unique_browsers.reduce(NULLSTRING){|sum, b| sum.empty? ? b.upcase : "#{sum}#{COMMA} #{b.upcase}"}, 'allBrowsers')
    @@serializer.pop
    @@last = nil
    @@count = 0
    @@total_session_count = 0
    @@unique_browsers = SortedSet.new
    @@file.close
  end
  
  def self.last
    @@last
  end


end


def work(file = 'data_medium.txt')

  User.initialize_serializer

  File.foreach(file, chomp: true) do |line|
    cols = line.split(COMMA)
    if cols[0] == USER
      User.last&.serialize
      User.new("#{cols[2]} #{cols[3]}")
    elsif cols[0] == SESSION
      User.last.add_session(cols)
    end
  end

  User.serialize_stats

  

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




  puts "MEMORY USAGE: %d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
end

