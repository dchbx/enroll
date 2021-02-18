# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/custom_linters/view_ada_compliance_linter.rb"

RSpec.describe ViewAdaComplianceLinter do
  let(:compliance_rules_hash) do
    # TODO: Move this to config
    YAML.load_file("#{Rails.root}/spec/support/fixtures/tag_compliance_value_pairs.yml").with_indifferent_access
  end

  context "all configured attributes are unique" do
    let(:input_string) do
      "
        <input type='text' id='name' name='name' required minlength='4' maxlength='8' size='10'>
        <input type='text' id='name_1' name='name_1' required minlength='4' maxlength='8' size='10'>
      "
    end
    
    let(:linter_unique_attributes) { ViewAdaComplianceLinter.new({fake_view: input_string}, compliance_rules_hash) }

    it "should be ADA compliant" do
      expect(linter_unique_attributes.views_ada_compliant?).to eq(true)
    end
  end

  context "some configured attributes are not unique" do
    let(:input_string) do
      "
        <input type='text' id='fakeid' name='fakename' required minlength='4' maxlength='8' size='10'>
        <input type='text' id='fakeid' name='fakename' required minlength='4' maxlength='8' size='10'>
      "
    end
    
    let(:linter_non_unique_attributes) { ViewAdaComplianceLinter.new({fake_view: input_string}, compliance_rules_hash) }

    it "should not be ADA compliant" do
      expect(linter_non_unique_attributes.views_ada_compliant?).to eq(false)
    end
  end

  context "images alt text" do
    let(:images_string) do
      "
      <img src='img_girl.jpg' alt='An image of a girl' width='500' height='600'>
      <img src='img_dog.jpg' width='500' height='600'>
      <img src='img_pizza.jpg' alt = '' width='500' height='600'>

      "
    end
    
    let(:linter_no_img_alt_text) { ViewAdaComplianceLinter.new({fake_view: images_string}, compliance_rules_hash) }
    it "should not be ADA compliant if images do not have alt text" do
      expect(linter_no_img_alt_text.views_ada_compliant?).to eq(false)
    end
  end
end
