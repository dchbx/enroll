#fam1=Family.all_with_multiple_family_members.limit(9155); nil
#fam2=Family.all_with_multiple_family_members.offset(9156); nil

families=Family.all_with_multiple_family_members

@broken_family=Family.find("566ebebcfaca145b8900000c")

families.each do |family|
  unless family == @broken_family
    if family.primary_applicant.person.consumer_role.present?
      family.family_members.each do |family_member|
        unless family_member.person.consumer_role.present?
          begin
            person = family_member.person
            dob = person.dob
            gender = person.gender
            consumer_role = ConsumerRole.new(:dob => dob, :gender => gender, :is_applicant => false )
            person.consumer_role = consumer_role
            person.save!
          rescue => e
            puts "This person #{person.id} can't be updated. Error #{e.message}"
          end
        end
      end
    end
  end
end
