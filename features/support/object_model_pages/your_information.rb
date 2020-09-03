# frozen_string_literal: true

class YourInformation

  include RSpec::Matchers
  include Capybara::DSL

  def user_name
    '//strong[@class="users-name"]'
  end

  def help_link
    '//a[@class="header-text interaction-click-control-help"]'
  end

  def logout_link
    '//a[@class="header-text interaction-click-control-logout"]'
  end

  def learn_more_about_link
    '//a[@class="interaction-click-control-learn-more-about-how-we-will-use-your-information."]'
  end

  def view_privacy_act_link
    '//a[@class="interaction-click-control-view-privacy-act-statement"]'
  end

  def signed_in_successfully_message
    '//div[@class="col-xs-12"]'
  end

  def continue_btn
    '//a[@class="btn btn-lg btn-primary  interaction-click-control-continue"]'
  end
end