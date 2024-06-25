# Deoptimized version of homework task

require 'json'
require 'pry'
require 'date'
require 'minitest/autorun'

class User
  attr_accessor :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(user)
  {
    'id' => user[1],
    'full_name' => user[2] << ' ' << user[3],
    'age' => user[4],
  }
end

def parse_session(session)
  {
    'user_id' => session[1],
    'session_id' => session[2],
    'browser' => session[3],
    'time' => session[4],
    'date' => session[5],
  }
end

def collect_stats_from_user
  return unless @user.attributes

  stats = @user.sessions.inject({
    # Собираем количество сессий по пользователям
    'sessionsCount' => 0,
    # Собираем количество времени по пользователям
    'totalTime' => 0,
    # Выбираем самую длинную сессию пользователя
    'longestSession' => 0,
    # Браузеры пользователя через запятую
    'browsers' => [],
    # Даты сессий через запятую в обратном порядке в формате iso8601
    'dates' => []
  }) do |metric, session|
    # Собираем количество сессий по пользователям
    metric['sessionsCount'] += 1
    session_time = session['time'].to_i
    metric['totalTime'] += session_time
    metric['longestSession'] = session_time if metric['longestSession'] < session_time
    metric['browsers'] << session['browser'].upcase!
    metric['dates'] << session['date']
    @result_data['allBrowsers'] << session['browser'] if !@result_data['allBrowsers'].include?(session['browser'])
    metric
  end

  # Хоть раз использовал IE?
  stats['usedIE'] = stats['browsers'].any? { |b| b =~ /INTERNET EXPLORER/ }
  # Всегда использовал только Chrome?
  stats['alwaysUsedChrome'] = stats['browsers'].all? { |b| b =~ /CHROME/ }

  stats['totalTime'] = "#{stats['totalTime']} min."
  stats['longestSession'] = "#{stats['longestSession']} min."
  stats['browsers'] = stats['browsers'].sort.join(', ')
  stats['dates'].sort!.reverse!

  save_user(stats)
end

def save_user(stats)
  @result.write(',') if @result_data['totalUsers'] > 1

  user_hash = { @user.attributes['full_name'] => stats }
  json = user_hash.to_json
  json = json[1...json.length - 1] if json[0] == '{' && json[-1] == '}'
  @result.write(json)
  @user.sessions = []
  @user.attributes = nil
end

def work(file_name: ARGV[0] || 'data_large.txt')
  @result_data = {
    'totalUsers' => 0,
    'uniqueBrowsersCount' => 0,
    'totalSessions' => 0,
    'allBrowsers' => [],
  }

  @result = File.open('result.json', 'w')
  @result.write('{"usersStats":{')
  
  @user = User.new(attributes: nil, sessions: [])

  File.foreach(file_name) do |line|
    cols = line.chop.split(',')
    case cols[0]
    when 'session'
      @user.sessions << parse_session(cols)
      @result_data['totalSessions'] += 1
    when 'user'
      collect_stats_from_user

      @user.attributes = parse_user(cols)
      @result_data['totalUsers'] += 1
    end
  end

  collect_stats_from_user

  @result_data['uniqueBrowsersCount'] = @result_data['allBrowsers'].size
  @result_data['allBrowsers'] = @result_data['allBrowsers'].sort!.join(',')

  @result.write('},')
  @result.write(@result_data.to_json.slice(1..-1).to_s)
  @result.close

  puts 'Finish work'
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

class TestMe < Minitest::Test
  def setup
    File.write('result.json', '')
    File.write('data.txt',
'user,0,Leida,Cira,0
session,0,0,Safari 29,87,2016-10-23
session,0,1,Firefox 12,118,2017-02-27
session,0,2,Internet Explorer 28,31,2017-03-28
session,0,3,Internet Explorer 28,109,2016-09-15
session,0,4,Safari 39,104,2017-09-27
session,0,5,Internet Explorer 35,6,2016-09-01
user,1,Palmer,Katrina,65
session,1,0,Safari 17,12,2016-10-21
session,1,1,Firefox 32,3,2016-12-20
session,1,2,Chrome 6,59,2016-11-11
session,1,3,Internet Explorer 10,28,2017-04-29
session,1,4,Chrome 13,116,2016-12-28
user,2,Gregory,Santos,86
session,2,0,Chrome 35,6,2018-09-21
session,2,1,Safari 49,85,2017-05-22
session,2,2,Firefox 47,17,2018-02-02
session,2,3,Chrome 20,84,2016-11-25
')
  end

  def test_result
    work
    expected_result = JSON.parse('{"totalUsers":3,"uniqueBrowsersCount":14,"totalSessions":15,"allBrowsers":"CHROME 13,CHROME 20,CHROME 35,CHROME 6,FIREFOX 12,FIREFOX 32,FIREFOX 47,INTERNET EXPLORER 10,INTERNET EXPLORER 28,INTERNET EXPLORER 35,SAFARI 17,SAFARI 29,SAFARI 39,SAFARI 49","usersStats":{"Leida Cira":{"sessionsCount":6,"totalTime":"455 min.","longestSession":"118 min.","browsers":"FIREFOX 12, INTERNET EXPLORER 28, INTERNET EXPLORER 28, INTERNET EXPLORER 35, SAFARI 29, SAFARI 39","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-09-27","2017-03-28","2017-02-27","2016-10-23","2016-09-15","2016-09-01"]},"Palmer Katrina":{"sessionsCount":5,"totalTime":"218 min.","longestSession":"116 min.","browsers":"CHROME 13, CHROME 6, FIREFOX 32, INTERNET EXPLORER 10, SAFARI 17","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-04-29","2016-12-28","2016-12-20","2016-11-11","2016-10-21"]},"Gregory Santos":{"sessionsCount":4,"totalTime":"192 min.","longestSession":"85 min.","browsers":"CHROME 20, CHROME 35, FIREFOX 47, SAFARI 49","usedIE":false,"alwaysUsedChrome":false,"dates":["2018-09-21","2018-02-02","2017-05-22","2016-11-25"]}}}')
    assert_equal expected_result, JSON.parse(File.read('result.json'))
  end
end
