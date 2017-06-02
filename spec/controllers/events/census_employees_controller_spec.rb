require "rails_helper"

describe Events::CensusEmployeesController do
  describe "census employee, employer_request event" do
    let(:channel) { double(:default_exchange => exchange, :close => nil) }
    let(:rendered_template) { double }
    let(:reply_to_key) { "some queue name" }
    let(:exchange) { double }
    let(:connection) { double(:create_channel => channel) }
    let(:census_employee) { ep = FactoryGirl.create(:employer_profile);
    ce = FactoryGirl.create(:census_employee, {employer_profile_id: ep.id, middle_name: 'sample_middle'});
    ce }
    let(:headers) { {"ssn" => census_employee.ssn, "dob" => census_employee.dob.strftime("%Y%m%d")} }
    let(:properties) { double(:headers => headers, :reply_to => reply_to_key) }

    let(:body) { rendered_template }

    before :each do
      header_params = { ssn:headers["ssn"], dob:census_employee.dob}
      allow(controller).to receive(:find_census_employee).with(header_params).and_return([census_employee])
      allow(CensusEmployee).to receive(:search_with_ssn_dob).with(census_employee.ssn, census_employee.dob.strftime("%Y%m%d")).and_return(census_employee)

      allow(controller).to receive(:render_to_string).with(
          "events/census_employee/employer_response", {:formats => ["xml"], :locals => {
          :census_employees => [census_employee]
      }}).and_return(rendered_template)
    end

    it "should send out a message to the bus with the response xml" do
      expect(exchange).to receive(:publish).with(rendered_template, {
          :routing_key => reply_to_key,
          :headers => {
              :return_status => "200",
          }
      })
      controller.resource(connection, reply_to_key, properties, rendered_template)
    end

    context "header with invalid dob format" do
      let(:headers) { {"ssn" => census_employee.ssn, "dob" => "19642310"} }
      before :each do
        allow(controller).to receive(:render_to_string).with(
         "events/census_employee/employer_response", {:formats => ["xml"], :locals => {
                                                       :census_employees => []
                                                   }}).and_return(rendered_template)
      end

      it "should return return_status = 404" do
        expect(exchange).to receive(:publish).with(rendered_template, {
          :routing_key => reply_to_key,
          :headers => {
              :return_status => "404",
          }
        })
        controller.resource(connection, reply_to_key, properties, rendered_template)
      end
    end
  end

  describe "find_census_employee" do
    context "census employee" do
      let(:census_employee) { ep = FactoryGirl.create(:employer_profile);
      ce = FactoryGirl.create(:census_employee, employer_profile_id: ep.id, middle_name: 'sample_middle');
      ce }

      context "matching ssn and dob" do
        it "should find the census_employee" do
          allow(CensusEmployee).to receive(:search_with_ssn_dob).with(census_employee.ssn, census_employee.dob).and_return(census_employee)
          census_employees = @controller.send(:find_census_employee, {ssn: census_employee.ssn, dob: census_employee.dob})
          expect(census_employees).to eql([census_employee])
        end
      end

      context "mismatching ssn, matching dob" do
        it "should not find the census_employee" do
          allow(CensusEmployee).to receive(:search_with_ssn_dob).with('999999999', census_employee.dob).and_return([])
          census_employees = @controller.send(:find_census_employee, {ssn: '999999999', dob: census_employee.dob})
          expect(census_employees).to eql([])
        end
      end
    end

    context "census dependent" do
      let(:census_employee) { ep = FactoryGirl.create(:employer_profile);
      ce = FactoryGirl.create(:census_employee, employer_profile_id: ep.id, middle_name: 'sample_middle');
      ce.census_dependents << FactoryGirl.build(:census_dependent);
      ce }
      let(:benefit_group) { FactoryGirl.create(:benefit_group) }

      let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }
      let(:census_dependent) { census_employee.census_dependents.first }

        before do
          census_employee.benefit_group_assignments = [benefit_group_assignment]
          census_employee.save
        end

      context "matching" do
        it "should find a census_employee with the dependent" do
          allow(CensusEmployee).to receive(:search_with_ssn_dob).with(census_dependent.ssn, census_dependent.dob).and_return([])
          allow(CensusEmployee).to receive(:search_dependent_with_ssn_dob).with(census_dependent.ssn, census_dependent.dob).and_return([census_employee])
          census_employees = @controller.send(:find_census_employee, {ssn: census_dependent.ssn, dob: census_dependent.dob})
          expect(census_employees).to eql([census_employee])
        end
      end

      context "mismatching ssn, matching dob " do
        it "should not find a census_employee with the dependent" do
          allow(CensusEmployee).to receive(:search_with_ssn_dob).with('999999999', Date.strptime("17000101", "%Y%m%d")).and_return([])
          allow(CensusEmployee).to receive(:search_dependent_with_ssn_dob).with('999999999', Date.strptime("17000101", "%Y%m%d")).and_return([])
          census_employees = @controller.send(:find_census_employee, {ssn: '999999999', dob: Date.strptime("17000101", "%Y%m%d")})
          expect(census_employees).to eql([])
        end
      end
    end
  end
end