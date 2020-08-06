# frozen_string_literal: true

class CreateFehbQles < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"

      @logger = Logger.new("#{Rails.root}/log/fehb_qles_migration.log") unless Rails.env.test?
      @logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      create_and_update_fehb_qle

      @logger.info "End of the script- #{TimeKeeper.datetime_of_record}" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down; end

  def self.create_and_update_fehb_qle
    say_with_time("Time taken to create fehb QLE's") do
      QualifyingLifeEventKind.where(market_kind: 'shop').each do |qle|
        new_qle = QualifyingLifeEventKind.new(qle.attributes.except("_id", "created_at", "updated_at"))
        new_qle.market_kind = "fehb"
        new_qle.save!
      end
    end

    say_with_time("Time taken to create fehb QLE's hash") do
      @qle_map = {}
      QualifyingLifeEventKind.where(market_kind: 'shop').each do |qle|
        fehb_qle_id = QualifyingLifeEventKind.where(title: qle.title, market_kind: "fehb").first.id
        @qle_map[qle.id] = fehb_qle_id
      end
    end

    say_with_time("Time taken to migrate fehb SEP's") do
      profile_ids = BenefitSponsors::Organizations::Organization.where(:"profiles._type" => /.*FehbEmployerProfile/).map(&:employer_profile).map(&:_id)
      fehb_sponsorship = BenefitSponsors::Organizations::Organization.where(:"profiles._type" => /.*FehbEmployerProfile/).map(&:active_benefit_sponsorship).map(&:_id)
      Person.where(:employee_roles.exists => true, :'employee_roles.benefit_sponsors_employer_profile_id'.in => profile_ids).each do |person|

        if person.employee_roles.unscoped.map(&:benefit_sponsors_employer_profile_id).all?{|id| profile_ids.include?(id)}
          person.primary_family.special_enrollment_periods.shop_market.each do |sep|
            fehb_qle = @qle_map[sep.qualifying_life_event_kind_id]
            sep.update_attributes(qualifying_life_event_kind_id: fehb_qle)
            print '.' unless Rails.env.test?
          end
        elsif person.employee_roles.unscoped.map(&:benefit_sponsors_employer_profile_id).any?{|id| profile_ids.include?(id)}
          person.primary_family.special_enrollment_periods.shop_market.each do |sep|
            next unless person.primary_family.hbx_enrollments.where(:special_enrollment_period_id => sep.id, :benefit_sponsorship_id.in => fehb_sponsorship).any?
            fehb_qle = @qle_map[sep.qualifying_life_event_kind_id]
            sep.update_attributes(qualifying_life_event_kind_id: fehb_qle)
            print '.' unless Rails.env.test?
          end
          if person.primary_family.latest_active_sep.present? && person.primary_family.latest_active_sep.qualifying_life_event_kind.market_kind == "shop"
            if person.active_employee_roles.count == 1 && profile_ids.include?(person.active_employee_roles.first.benefit_sponsors_employer_profile_id)
              person.primary_family.latest_active_sep.update_attributes(qualifying_life_event_kind_id: @qle_map[person.primary_family.latest_active_sep.qualifying_life_event_kind_id])
              print '.' unless Rails.env.test?
            end
          end
        end
      rescue StandardError => e
        print 'F' unless Rails.env.test?
        @logger.error "Update failed for person id: #{person.hbx_id}, #{e.message}" unless Rails.env.test?

      end
    end
  end
end
