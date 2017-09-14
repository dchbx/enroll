module FinancialAssistanceWorld
  def consumer(*traits)
    attributes = traits.extract_options!
    @consumer ||= FactoryGirl.create :user, :consumer, *traits, :with_consumer_role, attributes
  end

  def application(*traits)
    benchmark_plan
    attributes = traits.extract_options!
    attributes.merge!(family_id: consumer.primary_family.id)
    @application ||= FactoryGirl.create(:financial_assistance_application, *traits, attributes).tap do |application|
      application.populate_applicants_for(consumer.primary_family)
    end
  end

  def user_sign_up
    @user_sign_up_info ||= FactoryGirl.attributes_for :user
  end

  def personal_information
    address = FactoryGirl.attributes_for :address
    @personal_information ||= FactoryGirl.attributes_for :person, :with_consumer_role, :with_ssn, address
  end

  def benchmark_plan
    FactoryGirl.create(:plan, active_year: 2017, hios_id: "86052DC0400001-01")
  end

  def add_family_members(people_ids, family)
    people_ids.each do |id|
      family.family_members.create!(person_id: id) unless family.family_members.map(&:person_id).include?(id)
    end
  end
end
World(FinancialAssistanceWorld)
