require 'json'
require 'pry'
# require 'minitest/autorun'

DATA_DIRECTORY = "#{__dir__}/../data/".freeze
USER_STR = 'user'.freeze
SESSION_STR = 'session'.freeze
COMMA_STR = ','.freeze
COMMA_SPACE_STR = ', '.freeze
MIN_STR = ' min.'.freeze
SPACE_STR = ' '.freeze

class User
  attr_reader :attributes
  attr_accessor :sessions

  def initialize(attributes:)
    @attributes = attributes
    @sessions = []
  end
end

def data_path(file_name)
  DATA_DIRECTORY + file_name
end

def parse_user(cols)
  attributes = {
    'id' => cols[1],
    'first_name' => cols[2],
    'last_name' => cols[3],
    'age' => cols[4],
  }
  User.new(attributes: attributes)
end

def parse_session(fields)
  {
    'user_id' => fields[1],
    'session_id' => fields[2],
    'browser' => fields[3],
    'time' => fields[4],
    'date' => fields[5].strip,
  }
end

def collect_stats_from_users(report, users, &block)
  users.each do |user|
    user_key = "#{user.attributes['first_name']}" + SPACE_STR + "#{user.attributes['last_name']}"
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key] = report['usersStats'][user_key].merge(block.call(user))
  end
end

def work(file_name, disable_gc: false)
  GC.disable if disable_gc

  users = []
  sessions = []
  current_user = nil

  File.open(file_name).each_line do |l|
    cols = l.split(COMMA_STR)
    if cols[0] == USER_STR
      current_user = parse_user(cols)
      users << current_user
    end
    if cols[0] == SESSION_STR
      session = parse_session(cols)
      current_user.sessions << session
      sessions << session
    end
  end

  report = {}

  report[:totalUsers] = users.count

  uniqueBrowsers = sessions.map { |s| s['browser'] }.uniq

  report['uniqueBrowsersCount'] = uniqueBrowsers.count

  report['totalSessions'] = sessions.count

  report['allBrowsers'] = sessions.map { |s| s['browser'].upcase }.uniq.sort.join(',')

  # Статистика по пользователям
  report['usersStats'] = {}

  collect_stats_from_users(report, users) do |user|
    times = user.sessions.map { |s| s['time'].to_i }
    browsers = user.sessions.map { |s| s['browser'].upcase }
    {
      'sessionsCount' => user.sessions.count,
      'totalTime' => times.sum.to_s + MIN_STR,
      'longestSession' => times.max.to_s + MIN_STR,
      'browsers' => browsers.sort.join(COMMA_SPACE_STR),
      'usedIE' => browsers.any? { |b| b =~ /INTERNET EXPLORER/ },
      'alwaysUsedChrome' => browsers.all? { |b| b =~ /CHROME/ },
      'dates' => user.sessions.map {|s| s['date']}.sort.reverse,
    }
  end

  File.write('result.json', "#{report.to_json}\n")
end

# class TestCorrectness < Minitest::Test
#   def setup
#     File.write('result.json', '')
#     File.write('data.txt',
# 'user,0,Leida,Cira,0
# session,0,0,Safari 29,87,2016-10-23
# session,0,1,Firefox 12,118,2017-02-27
# session,0,2,Internet Explorer 28,31,2017-03-28
# session,0,3,Internet Explorer 28,109,2016-09-15
# session,0,4,Safari 39,104,2017-09-27
# session,0,5,Internet Explorer 35,6,2016-09-01
# user,1,Palmer,Katrina,65
# session,1,0,Safari 17,12,2016-10-21
# session,1,1,Firefox 32,3,2016-12-20
# session,1,2,Chrome 6,59,2016-11-11
# session,1,3,Internet Explorer 10,28,2017-04-29
# session,1,4,Chrome 13,116,2016-12-28
# user,2,Gregory,Santos,86
# session,2,0,Chrome 35,6,2018-09-21
# session,2,1,Safari 49,85,2017-05-22
# session,2,2,Firefox 47,17,2018-02-02
# session,2,3,Chrome 20,84,2016-11-25
# ')
#   end
#
#   def test_result
#     work(data_path('data.txt'))
#     expected_result = '{"totalUsers":3,"uniqueBrowsersCount":14,"totalSessions":15,"allBrowsers":"CHROME 13,CHROME 20,CHROME 35,CHROME 6,FIREFOX 12,FIREFOX 32,FIREFOX 47,INTERNET EXPLORER 10,INTERNET EXPLORER 28,INTERNET EXPLORER 35,SAFARI 17,SAFARI 29,SAFARI 39,SAFARI 49","usersStats":{"Leida Cira":{"sessionsCount":6,"totalTime":"455 min.","longestSession":"118 min.","browsers":"FIREFOX 12, INTERNET EXPLORER 28, INTERNET EXPLORER 28, INTERNET EXPLORER 35, SAFARI 29, SAFARI 39","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-09-27","2017-03-28","2017-02-27","2016-10-23","2016-09-15","2016-09-01"]},"Palmer Katrina":{"sessionsCount":5,"totalTime":"218 min.","longestSession":"116 min.","browsers":"CHROME 13, CHROME 6, FIREFOX 32, INTERNET EXPLORER 10, SAFARI 17","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-04-29","2016-12-28","2016-12-20","2016-11-11","2016-10-21"]},"Gregory Santos":{"sessionsCount":4,"totalTime":"192 min.","longestSession":"85 min.","browsers":"CHROME 20, CHROME 35, FIREFOX 47, SAFARI 49","usedIE":false,"alwaysUsedChrome":false,"dates":["2018-09-21","2018-02-02","2017-05-22","2016-11-25"]}}}' + "\n"
#     assert_equal expected_result, File.read('result.json')
#   end
# end
