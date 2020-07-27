# frozen_string_literal: true

require 'rails_helper'
require 'factory_bot_rails'

describe Effective::Datatables::SepTypeDataTable, dbclean: :after_each do

  context "can_expire_sep_type?", dbclean: :after_each do

    context " when qlek eligible to expire", dbclean: :after_each do
      let!(:qlek){FactoryBot.create(:qualifying_life_event_kind, is_active: true)}

      it "should return ajax" do
        expect(subject.can_expire_sep_type?(qlek, true)).to eq 'ajax'
      end
    end

    context " when qlek not eligible to expire", dbclean: :after_each do
      let!(:qlek){FactoryBot.create(:qualifying_life_event_kind, is_active: true)}

      it "should return disabled" do
        expect(subject.can_expire_sep_type?(qlek, false)).to eq 'disabled'
      end

      it "should return disabled" do
        qlek.update_attributes(aasm_state: :draft)
        expect(subject.can_expire_sep_type?(qlek, true)).to eq 'disabled'
      end
    end
  end
end

