require 'rspec'
require 'rspec-benchmark'
require_relative 'task-2'

RSpec.describe 'work' do
  include RSpec::Benchmark::Matchers

  it 'requires < 60 Mb' do
    work(file_name: 'data_large.txt')
    expect((`ps -o rss= -p #{Process.pid}`.to_i / 1024)).to be < 60
  end
end
