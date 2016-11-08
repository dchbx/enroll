require 'rails_helper'

describe "app/views/events/v2/employers/_benefit_group.xml.haml" do
  let(:benefit_group) { FactoryGirl.create(:benefit_group) }

  context "benefit_group xml" do
    context "reference plan" do
      before :each do
        render :template => "events/v2/employers/_benefit_group.xml.haml", locals: {benefit_group: benefit_group,
                                                                                    elected_plans: [], relationship_benefits: []}
        @doc = Nokogiri::XML(rendered)
      end

      it "does not include reference plan" do
        expect(@doc.xpath("//reference_plan").count).to eq(0)
      end
    end
  end
end
