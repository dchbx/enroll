require 'rails_helper'

describe Queries::SepTypeDatatableQuery, "Filter Scopes for sep type Index", dbclean: :after_each do
  it "filters: by_individual_market" do
    fdq = Queries::SepTypeDatatableQuery.new({"manage_qles" => "ivl_qles"})
    expect(fdq.build_scope.selector).to eq ({"market_kind"=>"individual"})
  end

  it "filters: by_shop_market" do
    fdq = Queries::SepTypeDatatableQuery.new({"manage_qles" => "shop_qles"})
    expect(fdq.build_scope.selector).to eq ({"market_kind"=>"shop"})
  end

  it "filters: by_fehb_market" do
    fdq = Queries::SepTypeDatatableQuery.new({"manage_qles" => "fehb_qles"})
    expect(fdq.build_scope.selector).to eq ({"market_kind"=>"fehb"})
  end

  it "filters: by_active_individual_market" do
    fdq = Queries::SepTypeDatatableQuery.new({"individual_options" => "ivl_active_qles"})
    expect(fdq.build_scope.selector).to eq ({"market_kind"=>"individual", "aasm_state"=>{"$in"=>[:active, :expired_pending]}})
  end

  it "filters: by_inactive_individual_market" do
    fdq = Queries::SepTypeDatatableQuery.new({"individual_options" => "ivl_inactive_qles"})
    expect(fdq.build_scope.selector).to eq ({"market_kind"=>"individual", "aasm_state"=>:expired})
  end

  it "filters: by_draft_individual_market" do
    fdq = Queries::SepTypeDatatableQuery.new({"individual_options" => "ivl_draft_qles"})
    expect(fdq.build_scope.selector).to eq ({"market_kind"=>"individual", "aasm_state"=>:draft})
  end

  it "filters: by_active_shop_market" do
    fdq = Queries::SepTypeDatatableQuery.new({"employer_options" => "shop_active_qles"})
    expect(fdq.build_scope.selector).to eq ({"market_kind"=>"shop", "aasm_state"=>{"$in"=>[:active, :expired_pending]}})
  end

  it "filters: by_inactive_shop_market" do
    fdq = Queries::SepTypeDatatableQuery.new({"employer_options" => "shop_inactive_qles"})
    expect(fdq.build_scope.selector).to eq ({"market_kind"=>"shop", "aasm_state"=>:expired})
  end

  it "filters: by_draft_shop_market" do
    fdq = Queries::SepTypeDatatableQuery.new({"employer_options" => "shop_draft_qles"})
    expect(fdq.build_scope.selector).to eq ({"market_kind"=>"shop", "aasm_state"=>:draft})
  end

  it "filters: by_active_fehb_market" do
    fdq = Queries::SepTypeDatatableQuery.new({"congress_options" => "fehb_active_qles"})
    expect(fdq.build_scope.selector).to eq ({"market_kind"=>"fehb", "aasm_state"=>{"$in"=>[:active, :expired_pending]}})
  end

  it "filters: by_inactive_fehb_market" do
    fdq = Queries::SepTypeDatatableQuery.new({"congress_options" => "fehb_inactive_qles"})
    expect(fdq.build_scope.selector).to eq ({"market_kind"=>"fehb", "aasm_state"=>:expired})
  end

  it "filters: by_draft_fehb_market" do
    fdq = Queries::SepTypeDatatableQuery.new({"congress_options" => "fehb_draft_qles"})
    expect(fdq.build_scope.selector).to eq ({"market_kind"=>"fehb", "aasm_state"=>:draft})
  end

  it "search scope selector" do
    search_title = Queries::SepTypeDatatableQuery.new({})
    search_title.instance_variable_set(:@search_string, "test_title")
    expect(search_title.build_scope.selector).to eq ({"$or"=>[{"title"=>/test_title/i}]})
  end
end
