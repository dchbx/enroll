# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/custom_linters/view_ada_compliance_linter.rb"

RSpec.describe ViewAdaComplianceLinter do
  let(:compliance_rules_hash) do
    compliance_rules_hash = YAML.load_file("#{Rails.root}/spec/support/fixtures/tag_compliance_value_pairs.yml").with_indifferent_access
  end

 # context "#unique_page_attributes" do
 #   context "configured unique attributes from YML"
 #     context "non unique attributes present" do
 #       it "should throw puts output message" do

 #       end
 #     end

  context "all configured attributes are unique" do
    let(:view_string) do
      "
        <input type='text' id='name' name='name' required minlength='4' maxlength='8' size='10'>
        <input type='text' id='name_1' name='name_1' required minlength='4' maxlength='8' size='10'>
      "
    end
    
    let(:linter_unique_attributes) { ViewAdaComplianceLinter.new({fake_view: view_string}, compliance_rules_hash) }

    it "should be ADA compliant" do
      expect(linter_unique_attributes.view_ada_compliant?).to eq(true)
    end
  end
end