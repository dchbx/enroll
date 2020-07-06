When(/^Hbx Admin navigate to main page$/) do
	visit exchanges_hbx_profiles_root_path
end

When(/^user clicks on Families dropdown link$/) do
  links = page.all('a')
  family_dropdown = links.detect { |link| link.text == "Families" }
  family_dropdown.click
end

And(/^user clicks on Families index page link from dropdown/) do
  click_link 'Families'
end

Then(/^the user should see (.*) options enabled in the families dropdown$/) do |enabled_options|
	page_links = page.all('a')
	non_nil_href_page_links = page_links.reject { |page_link| page_link[:href].nil? }
	case enabled_options
	when 'outstanding verifications'
		dropdown_hrefs = ["/exchanges/hbx_profiles/outstanding_verification_dt"]
	when 'new consumer application'
		dropdown_hrefs = ["/exchanges/agents/begin_consumer_enrollment?original_application_type=phone"]
	when 'all'
	  dropdown_hrefs = [
	    "/exchanges/hbx_profiles/family_index_dt",
	  	"/exchanges/hbx_profiles/outstanding_verification_dt",
    	"/exchanges/agents/begin_consumer_enrollment?original_application_type=phone",
    	"/exchanges/hbx_profiles/identity_verification",
    	"/exchanges/residents/begin_resident_enrollment?original_application_type=paper"
		]
	end
	family_links = dropdown_hrefs.map { |href| non_nil_href_page_links.detect { |page_link| page_link[:href].include?(href) } }
	family_links.each { |link| expect(link[:class].include?("blocking")).to eq(false) }
end

Then(/^the only enabled option should be Outstanding Verifications$/) do
	find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[1]/a/span[1]", text: 'Families')[:class].include?("blocking") == true
	find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[2]/a/span[1]", text: 'Outstanding Verifications')[:class].include?("blocking") == false
	find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[3]/a/span[1]", text: 'New Consumer Application')[:class].include?("blocking") == true
	find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[4]/a/span[1]", text: 'Identity Verification')[:class].include?("blocking") == true
end

Then(/^the only enabled option should be New Consumer Application$/) do
	find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[1]/a/span[1]", text: 'Families')[:class].include?("blocking") == true
	find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[2]/a/span[1]", text: 'Outstanding Verifications')[:class].include?("blocking") == true
	find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[3]/a/span[1]", text: 'New Consumer Application')[:class].include?("blocking") == false
	find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[4]/a/span[1]", text: 'Identity Verification')[:class].include?("blocking") == true
end
