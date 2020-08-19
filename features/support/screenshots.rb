Before do |scenario|
  @count = 0
  case scenario
  when Cucumber::RunningTestCase::ScenarioOutlineExample
    @scenario_name = scenario.scenario_outline.name.downcase.gsub(' ', '_')
    @feature_name = scenario.scenario_outline.feature.name.downcase.gsub(' ', '_')
  when Cucumber::RunningTestCase::Scenario
    @scenario_name = scenario.name.downcase.gsub(' ', '_')
    @feature_name = scenario.feature.name.downcase.gsub(' ', '_')
  else
    raise("Unhandled class, look in features/support/screenshots.rb")
  end
end

module Screenshots
  def screenshot(name, options={})
    if ENV['SCREENSHOTS'] == 'true' or options[:force]
      page.save_screenshot "tmp/#{@feature_name}/#{@scenario_name}/#{@count += 1} - #{name}.png", full: true
    end
  end

  def screenshot_and_post_to_slack(name, options={})
    page.save_screenshot "tmp/slack/#{options[:channel]}/#{@feature_name}/#{name}.png", full: true
  end
end

World(Screenshots)
