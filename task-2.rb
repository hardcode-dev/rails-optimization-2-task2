# frozen_string_literal: true

require 'json'
require 'pry'
require 'date'
# require 'minitest/autorun'
require 'minitest'

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end

  def key
    "#{attributes['first_name']}" + ' ' + "#{attributes['last_name']}"
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

def collect_stats_from_users(report, users_objects, &block)
  users_objects.each do |user|
    report['usersStats'][user.key] ||= {}
    report['usersStats'][user.key] = report['usersStats'][user.key].merge(block.call(user))
  end
end

def handle_user_sessions(report, user_attributes, user_sessions)
  return if !user_attributes

  user_object = User.new(attributes: user_attributes, sessions: user_sessions)

  report['totalUsers'] += 1
  report['totalSessions'] += user_sessions.count

  report['allBrowsers'].concat(user_sessions.map {|s| s['browser']}.map {|b| b.upcase})
  report['allBrowsers'].sort!
  report['allBrowsers'].uniq!

  report['uniqueBrowsersCount'] = report['allBrowsers'].count

  collect_stats_from_users(report, [user_object]) do |user|
    {
      'sessionsCount'       => user.sessions.count,
      'totalTime'           => user.sessions.map {|s| s['time']}.map {|t| t.to_i}.sum.to_s + ' min.',
      'longestSession'      => user.sessions.map {|s| s['time']}.map {|t| t.to_i}.max.to_s + ' min.',
      'browsers'            => user.sessions.map {|s| s['browser']}.map {|b| b.upcase}.sort.join(', '),
      'usedIE'              => user.sessions.map{|s| s['browser']}.any? { |b| b.upcase =~ /INTERNET EXPLORER/ },
      'alwaysUsedChrome'    => user.sessions.map{|s| s['browser']}.all? { |b| b.upcase =~ /CHROME/ },
      'dates'               => user.sessions.map{|s| s['date']}.map {|d| Date.parse(d)}.sort.reverse.map { |d| d.iso8601 }
    }
  end
end

def work(filename)
  puts "MEMORY USAGE: %d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
  user_attributes = nil
  user_sessions = []

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

  report = {
    'totalUsers' => 0,
    'totalSessions' => 0,
    'uniqueBrowsersCount' => 0,
    'allBrowsers' => [],
    'usersStats' => {
      # 'First Last' => {
      #   "sessionsCount":    6,
      #   "totalTime":        "455 min.",
      #   "longestSession":   "118 min.",
      #   "browsers":         "FIREFOX 12, INTERNET EXPLORER 28, INTERNET EXPLORER 28, INTERNET EXPLORER 35, SAFARI 29, SAFARI 39",
      #   "usedIE":           true,
      #   "alwaysUsedChrome": false,
      #   "dates":            ["2017-09-27","2017-03-28","2017-02-27","2016-10-23","2016-09-15","2016-09-01"]
      # }
    }
  }

  File.readlines(filename, chomp: true).each do |line|
    string_type, *fields = line.split(',')

    case string_type
    when 'user'
      handle_user_sessions(report, user_attributes, user_sessions)

      user_object = nil
      user_sessions = []
      user_attributes = parse_user(line)
    when 'session'
      user_sessions << parse_session(line)
    end
  end

  handle_user_sessions(report, user_attributes, user_sessions)

  report['allBrowsers'] = report['allBrowsers'].join(',')

  File.write('result.json', "#{report.to_json}\n")
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
    work('data.txt')
    expected_result = JSON.parse('{"totalUsers":3,"uniqueBrowsersCount":14,"totalSessions":15,"allBrowsers":"CHROME 13,CHROME 20,CHROME 35,CHROME 6,FIREFOX 12,FIREFOX 32,FIREFOX 47,INTERNET EXPLORER 10,INTERNET EXPLORER 28,INTERNET EXPLORER 35,SAFARI 17,SAFARI 29,SAFARI 39,SAFARI 49","usersStats":{"Leida Cira":{"sessionsCount":6,"totalTime":"455 min.","longestSession":"118 min.","browsers":"FIREFOX 12, INTERNET EXPLORER 28, INTERNET EXPLORER 28, INTERNET EXPLORER 35, SAFARI 29, SAFARI 39","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-09-27","2017-03-28","2017-02-27","2016-10-23","2016-09-15","2016-09-01"]},"Palmer Katrina":{"sessionsCount":5,"totalTime":"218 min.","longestSession":"116 min.","browsers":"CHROME 13, CHROME 6, FIREFOX 32, INTERNET EXPLORER 10, SAFARI 17","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-04-29","2016-12-28","2016-12-20","2016-11-11","2016-10-21"]},"Gregory Santos":{"sessionsCount":4,"totalTime":"192 min.","longestSession":"85 min.","browsers":"CHROME 20, CHROME 35, FIREFOX 47, SAFARI 49","usedIE":false,"alwaysUsedChrome":false,"dates":["2018-09-21","2018-02-02","2017-05-22","2016-11-25"]}}}')
    assert_equal expected_result, JSON.parse(File.read('result.json'))
  end
end
