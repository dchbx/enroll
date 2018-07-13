module InsuredHomePageWorld
  def enrollment_selection_badges
    page.all('.hbx-enrollment-panel').select { |n| n.all('h3', :text => /Coverage/i).any? }
  end
end

World(InsuredHomePageWorld)
