# frozen_string_literal: true

class YourInformation
  def self.user_name
    find(:xpath, '//strong[@class="users-name"]')
  end

  def self.help_link
    find(:xpath, '//a[@class="header-text interaction-click-control-help"]')
  end

  def self.logout_link
    find(:xpath, '//a[@class="header-text interaction-click-control-logout"]')
  end

  def self.learn_more_about_link
    find(:xpath, '//a[@class="interaction-click-control-learn-more-about-how-we-will-use-your-information."]')
  end

  def self.view_privacy_act_link
    find(:xpath, '//a[@class="interaction-click-control-view-privacy-act-statement"]')
  end

  def self.signed_in_successfully_message
    find(:xpath, '//div[@class="col-xs-12"]')
  end

  def self.continue_btn
    find(:xpath, '//a[@class="btn btn-lg btn-primary  interaction-click-control-continue"]')
  end
end