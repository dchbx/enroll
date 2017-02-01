namespace :person do
  desc "update status for person Jennefer Louise Rivera"
  task :disable_wrong_person => :environment do
    primary_applicant = '19789528'
    actived_hbxs = ["19789530"]
    disabled_hbxs = ["19789529", "19894827"]
    family = Person.by_hbx_id(primary_applicant).last.try(:primary_family)

    actived_hbxs.each do |hbx|
      Person.by_hbx_id(hbx).entries.each do |people|
        people.update(is_active: true) unless people.is_active
        puts "person with hbx_id(#{people.hbx_id}) is active."
      end
    end

    disabled_hbxs.each do |hbx|
      Person.by_hbx_id(hbx).entries.each do |people|
        people.update(is_active: false) if people.is_active
        puts "person with hbx_id(#{people.hbx_id}) is not active."
        if family
          family_member = family.find_family_member_by_person(people)
          if family_member && family_member.is_active?
            family_member.update(is_active: false)
            puts "family_member with hbx_id(#{people.hbx_id}) is not active."
          end
        end
      end
    end
  end
end
