module CapybaraHelpers
  def wait_for_ajax(delta=2, time_to_sleep=0.2)
    start_time = Time.now
    Capybara.default_max_wait_time = delta
    Timeout.timeout(Capybara.default_max_wait_time) do
      until finished_all_ajax_requests? do
        sleep(0.01)
      end
    end
    end_time = Time.now
    Capybara.default_max_wait_time = 2
    if Time.now > start_time + delta.seconds
      fail "ajax request failed: took longer than #{delta.seconds} seconds. It waited #{end_time - start_time} seconds."
    end
    puts "Finished helper method after #{end_time - start_time} seconds"
    sleep(time_to_sleep)
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end
end

World(CapybaraHelpers)
