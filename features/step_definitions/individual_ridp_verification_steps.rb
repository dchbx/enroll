And(/^Admin logs in the Hbx Portal$/) do
	login_as hbx_admin, scope: :user
	visit exchanges_hbx_profiles_root_path
end

When(/^Admin click on families link$/) do
	login_as hbx_admin, scope: :user
	click_link 'Families'
	family_member = find('a', :text => /First/)
	family_member.click

end

Then(/^Admin sees page with RIDP documents$/) do
	expect(page).to have_content('Identity')
	expect(page).to have_content('Application')
	find('.interaction-click-control-continue')['disabled'].should == "disabled"
end
