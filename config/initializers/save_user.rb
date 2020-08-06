# frozen_string_literal: true

class SAVEUSER
  def self.[]=(key, value)
    thread_var_name = "save_user_tl_#{key}"
    Thread.current[thread_var_name] = value
  end

  def self.[](key)
    thread_var_name = "save_user_tl_#{key}"
    Thread.current[thread_var_name]
  end
end
