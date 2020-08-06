# frozen_string_literal: true

When(/^the Admin selects the Paper application option$/) do
  find("li", :text => "Paper").click
end