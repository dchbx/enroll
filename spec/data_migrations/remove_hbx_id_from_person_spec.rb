require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_hbx_id_from_person")

describe RemoveHbxIdFromPerson do
  let(:given_task_name) { "remove_hbx_id_from_person" }
  subject { RemoveHbxIdFromPerson.new(given_task_name, double(:current_scope => nil)) }
  
  let(:person_1) { FactoryGirl.create(:person) }
  let(:person_2) { FactoryGirl.create(:person) }

  before do
    allow(ENV).to receive(:[]).with("p1_id").and_return person_1.hbx_id
    allow(ENV).to receive(:[]).with("p2_id").and_return person_2.hbx_id
    allow(ENV).to receive(:[]).with("hbx").and_return "911911911"
  end
  
  it "changes person 2 hbx id to person 1 hbx id" do
    subject.migrate
    person_1.reload
    expect(person_1.hbx_id).to eq "911911911"
  end
end
