require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "creating_person_record")

describe CreatingPersonRecord, dbclean: :after_each do
  let(:given_task_name) { "creating_person_record" }
  subject { CreatingPersonRecord.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "should create Person record" do
    before do
      allow(ENV).to receive(:[]).with('file_name').and_return "spec/test_data/person_test_record.csv"
    end
    it "should create person record" do
      expect(Person.all.to_a.size).to eq 0 # before migration
      expect(Person.all.map(&:addresses).count).to eq 0
      subject.migrate
      expect(Person.all.to_a.size).to eq 1 # after migration
      expect(Person.all.map(&:addresses).count).to eq 1
    end
  end
end
