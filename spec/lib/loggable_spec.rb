# frozen_string_literal: true
RSpec.describe Loggable do
  let(:klass) do
    Class.new do
      include Loggable
      def initialize
        @logger = Logging.logger[self]
      end
    end
  end
  subject { klass.new }
  it '#start_logging_to' do
    logger = subject.start_logging_to('/tmp/test')
    expect(logger.appenders.count).to eq 1
    expect(logger.appenders.first.filename).to eq('/tmp/test')
  end
  it '#stop_logging_to' do
    logger = subject.stop_logging_to('/tmp/test')
    expect(logger.appenders.count).to eq 0
  end
  it '#log_and_raise' do
    expect { subject.log_and_raise('message') }.to raise_error('message')
  end
  it '#bright_layout' do
    expect(described_class.bright_layout).to be_instance_of(Logging::Layouts::Pattern)
  end
  it '#basic_layout' do
    expect(described_class.basic_layout).to be_instance_of(Logging::Layouts::Pattern)
  end
  it '#bright_layout' do
    expect(described_class.stdout_brief_bright).to be_instance_of(Logging::Layouts::Pattern)
  end
end
