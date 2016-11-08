p = Person.where(is_active:true)

p.each do |c|
  if c.present?
    if c.consumer_role.present?
      if c.consumer_role.bookmark_url.present?
        link = c.consumer_role.bookmark_url.gsub("https://enroll.dchealthlink.com", '')
        c.consumer_role.update_attributes!(bookmark_url:link)
        p c.consumer_role.bookmark_url
      end
    end
  end
end




