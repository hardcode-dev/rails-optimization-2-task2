class Report
  attr_reader :sessions_count, :total_time, :longest_session, :browsers, :usedIE, :always_used_chrome, :dates

  def initialize
    @sessions_count = 0
    @total_time = 0
    @longest_session = 0
    @browsers = []
    @usedIE = false
    @always_used_chrome = true
    @dates = []
  end

  def process(browser, time, date)
    @sessions_count +=1
    @total_time += time

    @longest_session = time > longest_session ? time : longest_session
    @browsers << browser

    if !@usedIE && browser.start_with?('INTERNET EXPLORER')
      @usedIE = true
    end

    if @always_used_chrome && !@browsers.include?('CHROME')
      @always_used_chrome = false
    end

    @dates << date
  end
end
