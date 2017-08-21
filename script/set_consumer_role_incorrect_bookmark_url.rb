#16977

hbx_ids = []

Person.all_consumer_roles.each do |person|
  if /group_selection/.match(person.consumer_role.bookmark_url) && /qhp/.match(person.consumer_role.bookmark_url)
    hbx_ids << person.hbx_id
  end
end

reps = [["?aqhp=true", ""], ["?uqhp=true", ""]]

hbx_ids.each do |hbx_id|
  begin
    people = Person.where(hbx_id: hbx_id)
    if people.size != 1
      puts "Found more than 1 person records for hbx_id: #{hbx_id}"
      next
    end

    person = people.first

    url = person.consumer_role.bookmark_url

    reps.each do |rep|
      url.gsub!(rep[0], rep[1])
    end

    Person.where(hbx_id: hbx_id).first.consumer_role.update_attributes!(bookmark_url: url)
    puts "updated consumer_role bookmark_url for person with hbx_id: #{hbx_id}"
  rescue Exception => e
    puts "Errors with hbx_id: #{hbx_id}"
    puts "#{e}"
  end
end
