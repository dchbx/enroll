Given(/issuers feature is enabled?/) do
    enable_feature(:issuers_tab)
end

Given(/issuers feature is disabled?/) do
    disable_feature(:issuers_tab)
end

Then(/^they should see the Issuers tab$/) do
    expect(page).to have_content("Issuers")
  end

Then(/^they should not see the Issuers tab$/) do
    expect(page).to_not have_content("Issuers")
end
