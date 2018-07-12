require 'rails_helper'

RSpec.shared_examples "a sic codes data" do |attributes|
   attributes.each do |attribute, value|
     it "should return #{value} from ##{attribute}" do
       expect(subject.send(attribute)).to eq(value)
     end
   end
end

RSpec.describe 'Load sic codes data Task', :type => :task do
  context "wrgthrdyjfyg" do	
    before :all do
      Rake.application.rake_require "tasks/migrations/load_sic_code"
      Rake::Task.define_task(:environment)
    end  
    before :context do
      invoke_task
    end

	context "it creates SicCode correctly" do
	  subject { SicCode.where(sic_code: "0111").first }	
	  it_should_behave_like "a sic codes data", { division_code: "A",
	                                              division_label: "Agriculture, Forestry, And Fishing",
	  	                                          major_group_code: "01",
	  	                                          major_group_label: "Agricultural Production Crops",
	  	                                          industry_group_code: "011",
	  	                                          industry_group_label: "Cash Grains",
	  	                                          sic_code: "0111",
	  	                                          sic_label: "Wheat"
	  	                                        }
	end

	private

    def invoke_task
      Rake::Task["load_sic_code:update_sic_codes"].invoke
    end
  end
end	
