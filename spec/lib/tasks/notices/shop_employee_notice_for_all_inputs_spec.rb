require 'rails_helper'
Rake.application.rake_require "tasks/notices/shop_employee_notice_for_all_inputs"
Rake::Task.define_task(:environment)


# TODO: Fix all of these specs.  They are far too fragile.
RSpec.describe 'Generate notices to employee by taking hbx_ids, census_ids and event name', :type => :task, dbclean: :after_each do
  let!(:employer_profile) { census_employee_2.employer_profile}
  let(:person) { FactoryBot.create(:person)}
  let!(:employee_role) { emp_role = FactoryBot.create(:employee_role, person: person, employer_profile: employer_profile)
                         emp_role.update_attributes(census_employee: census_employee)
                         emp_role}
  let!(:census_employee) { FactoryBot.create(:census_employee, employer_profile: employer_profile) }

  let(:person2) { FactoryBot.create(:person)}
  let!(:employee_role_2) { emp_role = FactoryBot.create(:employee_role, person: person2, employer_profile: employer_profile)
                           emp_role.update_attributes(census_employee: census_employee)
                           emp_role}
  let!(:census_employee_2) { FactoryBot.create(:census_employee) }

  before :each do
    $stdout = StringIO.new
    ActiveJob::Base.queue_adapter = :test
  end

  after(:each) do
    $stdout = STDOUT
    Rake::Task['notice:shop_employee_notice_event'].reenable
  end

  context "Trigger Notice to employees", dbclean: :after_each do
    pending "when multiple hbx_ids input is given should trigger twice"
    pending "should not trigger notice"
    pending "when census_employee_id(s) are given"
    pending "should trigger only once when one employee_id and one hbx_ids are given"
=begin
    it "when multiple hbx_ids input is given should trigger twice" do
      ClimateControl.modify event: 'rspec-event', hbx_ids: "#{person.hbx_id} #{person2.hbx_id}" do
        Rake::Task['notice:shop_employee_notice_event'].invoke
        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 2
        expect($stdout.string).to match(/Notice Triggered Successfully/)
      end
    end

    it "should not trigger notice" do
      ClimateControl.modify event: nil do
        Rake::Task['notice:shop_employee_notice_event'].invoke(hbx_ids: '1231 131323')
        expect($stdout.string).to match(/Please specify the type of event name/)
      end
    end

    it "when census_employee_id(s) are given" do
      census_employee_role_id = census_employee.id.to_s
      census_employee_2_rol_id = census_employee_2.id.to_s
      ClimateControl.modify event: 'rspec-event', employee_ids: "#{census_employee_role_id} #{census_employee_2_rol_id}" do
        Rake::Task['notice:shop_employee_notice_event'].invoke(employee_ids: "#{census_employee_role_id} #{census_employee_2_rol_id}", event: "rspec-event")
        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 2
      end
    end

    it "should trigger only once when one employee_id and one hbx_ids are given" do
      ClimateControl.modify event: 'rspec-event', employee_ids: census_employee.id.to_s, hbx_ids: person.hbx_id do
        allow(EmployerProfile).to receive(:find).with("987").and_return(employer_profile)
        Rake::Task['notice:shop_employee_notice_event'].invoke(employee_ids: census_employee.id.to_s, hbx_ids: person.hbx_id, event: "rpsec-event")
        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 1
      end
    end
=end
  end
end
