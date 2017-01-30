namespace :person do
  desc "update status for person Jennefer Louise Rivera"
  task :disable_wrong_person => :environment do
    primary_applicant_id = '19789528'
    actived_hbxs = ["19789530"]
    disabled_hbxs = ["19789529", "19894827"]
    primary_applicant = Person.by_hbx_id(primary_applicant_id).last
    family = primary_applicant.try(:primary_family)

    actived_hbxs.each do |hbx|
      Person.by_hbx_id(hbx).entries.each do |person|
        person.update(is_active: true) unless person.is_active
        puts "person with hbx_id(#{person.hbx_id}) is active."
      end
    end

    disabled_hbxs.each do |hbx|
      Person.by_hbx_id(hbx).entries.each do |person|
        person.update(last_name: 'Wrong', dob: TimeKeeper.date_of_record)
        primary_applicant.person_relationships.where(relative_id: person.id).destroy_all
        if family.person_is_family_member?(person)
          family.remove_family_member(person) 
          family.save!
        end
        person.update(is_active: false) if person.is_active
        puts "person with hbx_id(#{person.hbx_id}) is not active."
        if family
          family_member = family.find_family_member_by_person(person)
          if family_member && family_member.is_active?
            family_member.update(is_active: false)
            puts "family_member with hbx_id(#{person.hbx_id}) is not active."
          end
        end
      end
    end
  end
end
