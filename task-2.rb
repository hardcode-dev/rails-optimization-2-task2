require 'json'
require 'minitest/autorun'

class User
  attr_accessor :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(fields)
  {
    'id' => fields[1],
    'first_name' => fields[2],
    'last_name' => fields[3],
    'age' => fields[4],
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

# Общая статистика по юзерам
$general_info = {
  'totalUsers' => 0,
  'uniqueBrowsersCount' => 0,
  'totalSessions' => 0,
  'allBrowsers' => []
}

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
def collect_stats_from_users(user, result_file)
  return unless user.attributes

  stats = user.sessions.inject({
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
  }) do |acc, session|
    # Собираем количество сессий по пользователям
    acc['sessionsCount'] += 1
    session_time = session['time'].to_i
    acc['totalTime'] += session_time
    acc['longestSession'] = session_time if acc['longestSession'] < session_time
    acc['browsers'] << session['browser'].upcase!
    acc['dates'] << session['date']

    $general_info['allBrowsers'] << session['browser'] if !$general_info['allBrowsers'].include?(session['browser'])
    acc
  end

  # Хоть раз использовал IE?
  stats['usedIE'] = stats['browsers'].any? { |b| b =~ /INTERNET EXPLORER/ }
  # Всегда использовал только Chrome?
  stats['alwaysUsedChrome'] = stats['browsers'].all? { |b| b =~ /CHROME/ }

  stats['totalTime'] = "#{stats['totalTime']} min."
  stats['longestSession'] = "#{stats['longestSession']} min."
  stats['browsers'] = stats['browsers'].sort.join(', ')
  stats['dates'].sort!.reverse!

  write_to_file(user, stats, result_file)
  clear_data(user)
end

def write_to_file(user, stats, result_file)
  result_file.write(',') if $general_info['totalUsers'] > 1

  user_data = { "#{user.attributes['first_name']} #{user.attributes['last_name']}" => stats }
  json_data = JSON.generate(user_data)
  json_data = json_data[1...json_data.length - 1] if json_data[0] == '{' && json_data[-1] == '}'
  result_file.write(json_data)
end

def clear_data(user)
  user.sessions = []
  user.attributes = nil
end

def work(file_name = 'data_large.txt')
  reset_general_info
  result_file = File.open('result.json', 'w')
  result_file.write('{"usersStats":{')

  user = User.new(attributes: nil, sessions: [])

  File.foreach(file_name) do |line|
    cols = line.chomp.split(',')

    case cols[0]
    when 'session'
      user.sessions << parse_session(cols)
      $general_info['totalSessions'] += 1
    when 'user'
      collect_stats_from_users(user, result_file)

      user.attributes = parse_user(cols)
      $general_info['totalUsers'] += 1
    end
  end

  collect_stats_from_users(user, result_file)

  $general_info['uniqueBrowsersCount'] = $general_info['allBrowsers'].size
  $general_info['allBrowsers'] = $general_info['allBrowsers'].sort!.join(',')

  result_file.write('},')
  result_file.write(JSON.generate($general_info).slice(1..-1).to_s)
  result_file.close

  puts 'Finish work'
  puts "MEMORY USAGE: %d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
end

def reset_general_info
  $general_info['totalUsers'] = 0
  $general_info['uniqueBrowsersCount'] = 0
  $general_info['totalSessions'] = 0
  $general_info['allBrowsers'] = []
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
