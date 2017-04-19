# frozen_string_literal: true
module Loggable
  @logger = Logging.logger[self]

  ##
  # Start a file logger to any given path along with a mapped diagnostic context. This allows for
  # logging patterns to include something like %X{blah} to match the key and use its value provided in the mdc argument.
  # @param [String] path - the path to the logfile to be written
  # @param [Hash] mdc - the key/value related to the expected mapped diagnostic context
  def start_logging_to(path, mdc)
    mdc.each_pair { |k, v| Logging.mdc[k.to_s] = v }
    Logging.logger.root.add_appenders(path, Logging.appenders.file(path, layout: Loggable.basic_layout))
  end

  ##
  # Stop a file logger to any given path along with a mapped diagnostic context. This will remove the
  # mapped diagnostic context key.
  # @param [String] path - the path to the logfile to be written
  # @param [Hash] mdc - the key/value related to the expected mapped diagnostic context
  def stop_logging_to(path, mdc)
    mdc.each_pair { |k, _v| Logging.mdc.delete(k.to_s) }
    Logging.logger.root.remove_appenders(path, Logging.appenders.file(path, layout: Loggable.basic_layout))
  end

  ##
  # Log a fatal exception and raise a StandardError
  # @param [String] message - the message to log and raise
  def log_and_raise(message)
    @logger.fatal(message)
    raise StandardError, message
  end

  def self.basic_layout
    Logging.layouts.pattern(pattern: '[%d] %-5l %X{item_id} %c: %m\n')
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
    Logging.layouts.pattern(pattern: '%X{item_id} [%d]: %m\n', color_scheme: 'stdout_brief_bright')
  end
end
