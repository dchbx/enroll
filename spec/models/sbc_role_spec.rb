# frozen_string_literal: true

require 'rails_helper'

describe SbcRole, dbclean: :after_each do
  let!(:sbc_user)                { FactoryBot.create(:user) }
  let!(:person)                  { FactoryBot.create(:person, :with_sbc_role, user: sbc_user) }

  context "#class methods" do
    it "should return find by id" do
      expect(SbcRole.find(person.sbc_role.id)).to eq person.sbc_role
    end

    it "should return all users with sbc_roles" do
      expect(SbcRole.all).to eq [sbc_user&.person&.sbc_role]
    end
  end

  context "#instance_methods" do
    it "should return parent" do
      expect(person.sbc_role.parent).to eq person
    end
  end
end