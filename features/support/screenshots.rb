# frozen_string_literal: true

Before do |scenario|
  @count = 0
  case scenario.class.to_s
  when "Cucumber::RunningTestCase::TestCase"
    @scenario_name = scenario.name.downcase.gsub(' ', '_')
    @feature_name = scenario.location.file.downcase.partition("/").last
  when "Cucumber::RunningTestCase::ScenarioOutlineExample"
    @scenario_name = scenario.scenario_outline.name.downcase.gsub(' ', '_')
    @feature_name = scenario.scenario_outline.feature.name.downcase.gsub(' ', '_')
  when "Cucumber::RunningTestCase::Scenario"
    @scenario_name = scenario.name.downcase.gsub(' ', '_')
    @feature_name = scenario.feature.name.downcase.gsub(' ', '_')
  else
    raise("Unhandled class, for #{scenario.class.s} look in features/support/screenshots.rb")
  end
end

module Screenshots
  def screenshot(name, options = {})
    return unless (ENV['SCREENSHOTS'] == 'true') || options[:force]

    width  = page.execute_script("return Math.max(document.body.scrollWidth, document.body.offsetWidth, document.documentElement.clientWidth, document.documentElement.scrollWidth, document.documentElement.offsetWidth);")
    height = page.execute_script("return Math.max(document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight);")

    page.driver.browser.manage.window.resize_to(width + 50, height + 50)
    page.save_screenshot "tmp/#{@feature_name}/#{@scenario_name}/#{@count += 1} - #{name}.png", full: true
    page.driver.browser.manage.window.resize_to(1024,768)
  end
end

World(Screenshots)
