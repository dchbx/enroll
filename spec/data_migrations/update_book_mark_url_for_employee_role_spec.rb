require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_book_mark_url_for_employee_role")

describe UpdateBookMarkUrlForEmployeerole, dbclean: :after_each do

  let(:given_task_name) { "update_book_mark_url_for_employee_role" }
  subject { UpdateBookMarkUrlForEmployeerole.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update bookmark url" do

    let!(:employee_role) { FactoryGirl.create(:employee_role, bookmark_url: "https://enroll.dchealthlink.com")}

    before(:each) do
      allow(ENV).to receive(:[]).with("employee_role_id").and_return(employee_role.id.to_s)
      allow(ENV).to receive(:[]).with("bookmark_url").and_return("https://enroll.dchealthlink.com/families/home")    
    end

    it "should update bookmark url associated with employee role" do
      expect(employee_role.bookmark_url).to eq "https://enroll.dchealthlink.com"
      subject.migrate
      employee_role.reload
      expect(employee_role.bookmark_url).to eq "https://enroll.dchealthlink.com/families/home"
    end
  end
end

