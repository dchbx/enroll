RSpec.shared_examples "family_member examples" do |class_name|

  let!(:person) {Person.new (primary_member_person_attr1)}
  let!(:person2) {Person.new (family_member_person_attr1)}
  let!(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
end
