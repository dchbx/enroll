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

  context "can_clone_sep_type?", dbclean: :after_each do

    context " when qlek eligible to clone", dbclean: :after_each do
      let!(:qlek){FactoryBot.create(:qualifying_life_event_kind, aasm_state: :active, is_active: true)}

      it "should return true" do
        [:active, :expire_pending, :expired].each do |state|
          qlek.update_attributes(aasm_state: state)
          expect(subject.can_clone_sep_type?(qlek, true)).to eq true
        end
      end
    end

    context " when qlek not eligible to clone", dbclean: :after_each do
      let!(:qlek){FactoryBot.create(:qualifying_life_event_kind, aasm_state: :draft, is_active: false)}

      it "should return false" do
        expect(subject.can_clone_sep_type?(qlek, false)).to eq false
      end

      it "should return false" do
        qlek.update_attributes(aasm_state: :draft)
        expect(subject.can_clone_sep_type?(qlek, true)).to eq false
      end
    end
  end
end

