require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "delink_user_and_person")

describe DelinkUserAndPerson do

  let(:given_task_name) { "delink_user_and_person" }
  let!(:person) { FactoryGirl.create(:person)}
  let!(:user) {FactoryGirl.create(:user,person:person)}

  subject { DelinkUserAndPerson.new(given_task_name, double(:current_scope => nil)) }

  before(:each) do
    allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
  end

  it "should delink the person from user" do
    expect(person.user).not_to eq nil
    subject.migrate
    person.reload
    expect(person.user).to eq nil
  end
  it "after delink the user should exists" do
    id=user.id
    expect(User.where(id:id)).not_to eq nil
    subject.migrate
    user.reload
    expect(User.where(id:id)).not_to eq nil
  end
end
