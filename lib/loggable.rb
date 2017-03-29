# frozen_string_literal: true
module Loggable
  @logger = Logging.logger[self]

  def start_logging_to(path)
    Logging.logger.root.add_appenders(path, Logging.appenders.file(path, layout: Loggable.basic_layout))
  end

  def stop_logging_to(path)
    Logging.logger.root.remove_appenders(path, Logging.appenders.file(path, layout: Loggable.basic_layout))
  end

  def log_and_raise(message)
    @logger.fatal(message)
    raise StandardError, message
  end

  def self.basic_layout
    Logging.layouts.pattern(pattern: '[%d] %-5l %c: %m\n')
  end

  def self.bright_layout
    Logging.color_scheme('bright',
                         levels: {
                           info: :green,
                           warn: :yellow,
                           error: :red,
                           fatal: [:white, :on_red]
                         },
                         date: :blue,
                         logger: :cyan,
                         message: :magenta)
    Logging.layouts.pattern(pattern: '[%d] %-5l %c: %m\n', color_scheme: 'bright')
  end

  def self.stdout_brief_bright
    Logging.color_scheme('stdout_brief_bright',
                         lines: {
                           info: :green,
                           warn: :yellow,
                           error: :red,
                           fatal: :red
                         })
    Logging.layouts.pattern(pattern: '%m\n', color_scheme: 'stdout_brief_bright')
  end
end
