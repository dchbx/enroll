require 'rails_helper'
require Rails.root.join("lib", "sbc", "sbc_processor2015")

describe SbcProcessor2015, dbclean: :around_each do
  let(:csv_path) { Dir.glob(File.join(Rails.root, 'spec/test_data/plan_data/sbc/*.csv')).first }
  let(:pdf_path) { Dir.glob(File.join(Rails.root, 'spec/test_data/plan_data/sbc/pdf/')).first }
  let(:product) { FactoryBot.create(
      :benefit_markets_products_health_products_health_product,
      hios_id: "59763MA0030014-01",
      application_period: Date.new(2018, 1, 1)..Date.new(2018, 12, 31),
      sbc_document: nil
  )}
  let(:plan){ FactoryBot.create(
    :plan,
    active_year: product.active_year,
    hios_id: product.hios_id,
    sbc_document: product.sbc_document
  )}

  before :all do
    DatabaseCleaner.clean
  end

  context "should initialize " do

    before(:each) do
      product
      sbc_processor = SbcProcessor2015.new(csv_path, pdf_path)
      sbc_processor.run
      product.reload
      plan
    end

    it "should map sbc to the product" do
      expect(product.sbc_document.try(:identifier)).to eq "urn:openhbx:terms:v1:file_storage:s3:bucket:mhc-enroll-sbc-test#11111111-1111-1111-1111-111111111111"
    end
  end
end
