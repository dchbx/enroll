require 'rails_helper'

class FakesController < ApplicationController
  include VlpDoc
end

describe FakesController do
  let(:consumer_role) { FactoryGirl.build_stubbed(:consumer_role) }

  context "updating consumer documents" do
    before :each do
      person_params = { person: { consumer_role: { vlp_documents_attributes: { "0" => { expiration_date: "06/23/2016" }}}, naturalized_citizen: false, eligible_immigration_status: false }}
      person_params = ActionController::Parameters.new(person_params)
      subject.instance_variable_set("@params", person_params)
      subject.stub(:params).and_return(person_params)
    end

    it "should convert the date string to dateTime instance" do
      subject.params[:person].should be_a(Hash)
      subject.params[:person][:consumer_role].should be_a(Hash)
      subject.params[:person][:consumer_role][:vlp_documents_attributes]["0"].should be_a(Hash)
      subject.params[:person][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date].should be_a(String)
      subject.update_vlp_documents(consumer_role, "person".to_sym)
      subject.params[:person][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date].should be_a(DateTime)
    end
  end

  context "updating consumer documents" do
    before :each do
      dependent_params = { dependent: { consumer_role: { vlp_documents_attributes: { "0" => { expiration_date: "06/23/2016" }}}, naturalized_citizen: false, eligible_immigration_status: false }}
      dependent_params = ActionController::Parameters.new(dependent_params)
      subject.instance_variable_set("@params", dependent_params)
      subject.stub(:params).and_return(dependent_params)
    end

    it "should convert the date string to dateTime instance" do
      subject.params[:dependent].should be_a(Hash)
      subject.params[:dependent][:consumer_role].should be_a(Hash)
      subject.params[:dependent][:consumer_role][:vlp_documents_attributes]["0"].should be_a(Hash)
      subject.params[:dependent][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date].should be_a(String)
      subject.update_vlp_documents(consumer_role, "dependent".to_sym)
      subject.params[:dependent][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date].should be_a(DateTime)
    end
  end
end
