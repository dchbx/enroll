# frozen_string_literal: true

class Logger::SimpleJsonFormatter < Logger::Formatter
  Format = "[%s] [%s]: %s\n"

  SEVERITY_MAP = {
    "DEBUG" => "debug",
    "ERROR" => "err",
    "WARN" => "warning",
    "INFO" => "info",
    "FATAL" => "crit"
  }.freeze

  attr_accessor :datetime_format

  def initialize
    @datetime_format = nil
  end

  def call(severity, time, _progname, msg)
    JSON.dump({time: format_datetime(time), level: map_severity(severity), full_message: msg2str(msg)}) + "\n"
  end

  protected

  def map_severity(severity)
    SEVERITY_MAP.keys.include?(severity) ? SEVERITY_MAP[severity] : "info"
  end

  def format_datetime(time)
    if @datetime_format.nil?
      time.strftime("%s")
    else
      time.strftime(@datetime_format)
    end
  end

  def msg2str(msg)
    case msg
    when ::String
      msg
    when ::Exception
      ("#{msg.message} (#{msg.class})\n" <<
      (msg.backtrace || []).join("\n"))
    else
      msg.inspect
    end
  end

end
