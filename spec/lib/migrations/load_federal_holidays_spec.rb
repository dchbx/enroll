require 'rails_helper'

RSpec.shared_examples "a federal holiday" do
   it { expect(holiday).to be_an_instance_of(Hash) }

   it 'each element should be an instance of Hash' do
     holiday.each do |attribute, value|
       expect(subject.send(attribute)).to eq(value)
     end
   end
end

RSpec.describe 'Load Federal Holidays Task', :type => :task do
  let (:holiday_date) {Date.today}

  context "scheduled_event:update_federal_holidays" do
    before :all do
      Rake.application.rake_require "tasks/migrations/load_federal_holidays"
      Rake::Task.define_task(:environment)
    end

    before :context do
      invoke_task
    end

    context "it creates holiday ScheduledEvent  elements correctly" do
     subject { ScheduledEvent.find_by(event_name: 'Independence Day') }
     it_should_behave_like "a federal holiday" do
        let(:holiday){ { type: "federal",
                                                 offset_rule: 0,
                                                 one_time: true,
                                                 start_time: schedule_time(Date.new(Date.today.year, 07, 04))
                                               } }
     end
   end
   context "it creates holiday ScheduledEvent  elements correctly" do
     subject { ScheduledEvent.find_by(event_name: 'Martin Luther King Jr Birthday') }
     it_should_behave_like "a federal holiday" do
       let(:holiday){ { type: "federal",
                                                 offset_rule: 0,
                                                 one_time: true,
                                                 start_time: nth_wday(3, 1, 1, Date.today.year).strftime("%a, %d %b %Y").to_date
                                               } }
     end
   end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: "President's Day") }
      it_should_behave_like "a federal holiday" do
      let(:holiday){ { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: nth_wday(3, 1, 2, Date.today.year).strftime("%a, %d %b %Y").to_date
                                                } }
      end
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Memorial Day') }
      it_should_behave_like "a federal holiday" do
      let(:holiday){ { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: last_monday_may(Date.today.year, 5, 31)
                                                } }
      end
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Labor Day') }
      it_should_behave_like "a federal holiday" do
      let(:holiday){ { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: nth_wday(1, 1, 9, Date.today.year).strftime("%a, %d %b %Y").to_date
                                                } }
      end
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Columbus Day') }
      it_should_behave_like "a federal holiday" do
      let(:holiday){ { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: nth_wday(2, 1, 10, Date.today.year).strftime("%a, %d %b %Y").to_date
                                                } }
      end
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Thanksgiving Day') }
      it_should_behave_like "a federal holiday" do
      let(:holiday){ { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: nth_wday(4, 4, 11, Date.today.year).strftime("%a, %d %b %Y").to_date
                                                } }
      end
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Veterans Day') }
      it_should_behave_like "a federal holiday" do
      let(:holiday){ { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: schedule_time(Date.new(Date.today.year, 11, 11))
                                                } }
      end
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'New Year Day') }
      it_should_behave_like "a federal holiday" do
      let(:holiday){ { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: schedule_time(Date.new(Date.today.year, 01, 01))
                                                } }
      end
    end
    context "it creates holiday ScheduledEvent  elements correctly" do
      subject { ScheduledEvent.find_by(event_name: 'Christmas Day') }
      it_should_behave_like "a federal holiday" do
      let(:holiday){ { type: "federal",
                                                  offset_rule: 0,
                                                  one_time: true,
                                                  start_time: schedule_time(Date.new(Date.today.year, 12, 25))
                                                } }
      end
    end

    private

    def invoke_task
      Rake::Task["load_federal_holidays:update_federal_holidays"].invoke
    end
  end
end
