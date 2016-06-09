require 'rails_helper'

describe "insured/families/check_qle_date.js.erb" do
  let(:qle) {FactoryGirl.create(:qualifying_life_event_kind)}

  context "with qualified_date" do
    context "without effective_on_options" do
      before :each do
        assign :qualified_date, true
        assign :qle_aptc_block, false
        assign :qle, qle
        render file: "insured/families/check_qle_date.js.erb"
      end

      it "should match effective_on_kinds" do
        expect(rendered).to match(/effective_on_kinds/)
      end
    end

    context "with effective_on_options" do
      context "when I Losing Employer-Subsidized Insurance because employee is going on Medicare" do
        before :each do
          assign :qualified_date, true
          assign :qle_aptc_block, false
          assign :qle_date, TimeKeeper.date_of_record + 1.month
          assign :effective_on_options, [1, 2]
          render file: "insured/families/check_qle_date.js.erb"
        end

        it "should have qle message" do
          qle_date = TimeKeeper.date_of_record + 1.month
          expect(rendered).to match /Because your other health insurance is ending/
          expect(rendered).to match /#{qle_date.beginning_of_month}/
          expect(rendered).to match /#{(qle_date + 1.month).beginning_of_month}/
          expect(rendered).to match /#{qle_date.beginning_of_month - 1.day}/
        end
      end

      context "effective_on_options not an array" do
        before :each do
          assign :qualified_date, true
          assign :qle_aptc_block, false
          assign :qle_date, TimeKeeper.date_of_record + 1.month
          assign :qle, qle
          assign :effective_on_options, TimeKeeper.date_of_record
          render file: "insured/families/check_qle_date.js.erb"
        end

        it "should match effective_on_kinds" do
          expect(rendered).to match(/effective_on_kinds/)
        end
      end
    end

    context "with qle_aptc_block" do
      before :each do
        assign :qualified_date, true
        assign :qle_aptc_block, true
        render file: "insured/families/check_qle_date.js.erb"
      end

      it "should match qle block notice" do
        expect(rendered).to match /We need a bit of additional information to redetermine your eligibility/
        expect(rendered).to match /Please call us at #{Settings.contact_center.phone_number}/
        expect(rendered).to match /Acknowledge/
      end
    end
  end

  context "without qualified_date" do
    before :each do
      assign :qualified_date, false
      assign :qle, qle
      render file: "insured/families/check_qle_date.js.erb"
    end

    it "should match error notcie" do
      expect(render).to match /The date you submitted does not qualify for special enrollment/
      expect(render).to match /Please double check the date or contact DC Health Link's Customer Care Center: #{Settings.contact_center.phone_number}/
    end
  end

  context "For event which happens in future" do
    before :each do
     assign :qualified_date, false
     assign :future_qualified_date, true
     assign :qle, qle
     render file: "insured/families/check_qle_date.js.erb"
    end

    it "should match error notice " do
      expect(render).to match /The date you submitted does not qualify for a special enrollment period. Qualifying life events may be reported up to 30 days after the date of the event. If you are trying to report a future event, please come back on or after the actual date of the event. For further assistance, please contact DC Health Link Customer Service at #{Settings.contact_center.phone_number}/
    end
  end
end
