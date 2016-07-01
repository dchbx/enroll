Person.all.no_timeout.each do |c|
  if c.present? && c.consumer_role.present? && c.consumer_role.bookmark_url.present? && c.consumer_role.bookmark_url.include?("https://enroll.dchealthlink.com")
    link = c.consumer_role.bookmark_url.gsub("https://enroll.dchealthlink.com", '')
    c.consumer_role.update_attributes!(bookmark_url: link)
    p c.consumer_role.bookmark_url
  end
end

User.all.no_timeout.each do |u|
  if u.last_portal_visited.present? && u.last_portal_visited.include?("https://enroll.dchealthlink.com")
    link = u.last_portal_visited.gsub("https://enroll.dchealthlink.com", '')
    begin
      u.update_attributes!(last_portal_visited: link)
      p u.last_portal_visited
    rescue
     puts "user.email #{u.email} has blank oim_id"
    end
  end
end
