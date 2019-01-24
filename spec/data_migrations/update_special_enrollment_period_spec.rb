require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_special_enrollment_period.rb")

describe UpdateSpecialEnrollmentPeriod do
  let(:given_task_name) { "update_special_enrollment_period" }
  subject { UpdateSpecialEnrollmentPeriod.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update sep invalid records", dbClean: :after_each do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:sep) {FactoryGirl.create(:special_enrollment_period, family:family, market_kind: "shop")}

    before(:each) do
      allow(ENV).to receive(:[]).with("sep_id").and_return(sep.id)
      allow(ENV).to receive(:[]).with("attrs").and_return("{market_kind: 'ivl'}")
      subject.migrate
      sep.reload
    end

    it "should update market kind" do
      expect(sep.market_kind).to eq "ivl"
    end
  end
end
