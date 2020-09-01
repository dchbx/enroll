# frozen_string_literal: true

class YourInformation

  include RSpec::Matchers
  include Capybara::DSL

  def user_name
    find(:xpath, '//strong[@class="users-name"]')
  end

  def help_link
    find(:xpath, '//a[@class="header-text interaction-click-control-help"]')
  end

  def logout_link
    find(:xpath, '//a[@class="header-text interaction-click-control-logout"]')
  end

  def learn_more_about_link
    find(:xpath, '//a[@class="interaction-click-control-learn-more-about-how-we-will-use-your-information."]')
  end

  def view_privacy_act_link
    find(:xpath, '//a[@class="interaction-click-control-view-privacy-act-statement"]')
  end

  def signed_in_successfully_message
    find(:xpath, '//div[@class="col-xs-12"]')
  end

  def continue_btn
    find(:xpath, '//a[@class="btn btn-lg btn-primary  interaction-click-control-continue"]')
  end
end