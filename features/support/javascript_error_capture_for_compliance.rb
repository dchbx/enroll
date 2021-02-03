After do |scenario|
  if page.driver.to_s.match("Selenium")
    # Access Lint Messages
    # https://github.com/AccessLint/accesslint.js
    logs = page.driver.browser.manage.logs.get(:browser)
    access_lint_messages = logs.select { |log| log.message.match('accesslint') }
    if access_lint_messages.present?
      access_lint_messages_text = access_lint_messages.map(&:message)
      binding.pry

      last_access_lint_logfile = File.read("#{Rails.root.to_s}/support/accesss_js_lint_logs").find { |file| file.match(/lint_log/) }
      binding.pry
      # Mode a appends the last line
      File.write("log.txt", "data...", mode: "a")
    end
    if errors.any?
      puts '-------------------------------------------------------------'
      puts "Found #{errors.length} javascript #{pluralize(errors.length, 'error')}"
      puts '-------------------------------------------------------------'
      errors.each do |error|
        puts "    #{error["errorMessage"]} (#{error["sourceName"]}:#{error["lineNumber"]})"
      end
      raise "Javascript #{pluralize(errors.length, 'error')} detected, see above"
    end
  end
end