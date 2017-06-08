person=Person.where(:hbx_id=>"#{ARGV[0]}").first
child=person.person_relationships.first
child.destroy