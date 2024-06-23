require 'rspec'
require 'rspec-benchmark'
require_relative 'task-2'

RSpec.describe 'work' do
  include RSpec::Benchmark::Matchers

  it 'execute less 10 sec' do
    expect { work('data_large.txt') }.to perform_under(10).sec
  end

  it 'memory is busy less 45 Mb' do
    work('data_large.txt')
    expect((`ps -o rss= -p #{Process.pid}`.to_i / 1024)).to be < 45
  end
end
