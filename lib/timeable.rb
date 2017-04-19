# frozen_string_literal: true
module Timeable
  def time_since(dt)
    secs = (Time.now - dt.to_time).to_int
    mins = secs / 60
    hours = mins / 60
    days = hours / 24

    if days > 0
      "#{days} days and #{hours % 24} hours"
    elsif hours > 0
      "#{hours} hours and #{mins % 60} minutes"
    elsif mins > 0
      "#{mins} minutes and #{secs % 60} seconds"
    elsif secs >= 0
      "#{secs} seconds"
    end
  end
end
