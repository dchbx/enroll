require "rails_helper"

describe Events::CensusEmployeesController do
  describe "census employee, employer_request event" do
    let(:headers) { {ssn: '111111111', dob: '19000101'} }
    let(:channel) { double(:default_exchange => exchange, :close => nil) }
    let(:rendered_template) { double }
    let(:reply_to_key) { "some queue name" }
    let(:exchange) { double }
    let(:connection) { double(:create_channel => channel) }
    let(:properties) { double(:headers => headers, :reply_to => reply_to_key) }
    let(:census_employees) { ep = FactoryGirl.create(:employer_profile);
    ce = FactoryGirl.create(:census_employee, employer_profile_id: ep.id);
    [ce] }
    let(:body) { rendered_template }

    before :each do
      allow(controller).to receive(:find_census_employee).with(headers).and_return(census_employees)
      allow(controller).to receive(:ssn_and_dob).with(body).and_return([headers[:ssn], headers[:dob]])

      allow(controller).to receive(:render_to_string).with(
          "events/census_employee/employer_response", {:formats => ["xml"], :locals => {
          :census_employees => census_employees
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
  end

  describe "find_census_employee()" do
    context "given correct ssn and dob" do
      let(:census_employee) { ep = FactoryGirl.create(:employer_profile);
      ce = FactoryGirl.create(:census_employee, employer_profile_id: ep.id);
      ce }

      it "should find the census_employee" do
        census_employees = @controller.send(:find_census_employee, {ssn: census_employee.ssn, dob: census_employee.dob.strftime("%Y%m%d")}).to_a
        expect(census_employees).to eql([census_employee])
      end
    end

    context "given non-existent ssn and dob" do
      it "should find the census_employee" do
        census_employees = @controller.send(:find_census_employee, {ssn: '999999999', dob: "17000131"}).to_a
        expect(census_employees).to eql([])
      end
    end
  end

  describe "ssn_and_dob()" do
    let(:xml) { double }
    let(:ssn) { "111111111" }
    let(:dob) { "19900101" }
    let(:parsed_xml_hash) { {request: {parameters: {ssn: ssn, dob: dob}}} }

    before do
      allow(controller).to receive(:parse_request).with(xml).and_return(parsed_xml_hash)
    end

    it "should return an array [ssn, dob]" do
      expect(@controller.send(:ssn_and_dob, xml)).to eql([ssn, dob])
    end
  end
end