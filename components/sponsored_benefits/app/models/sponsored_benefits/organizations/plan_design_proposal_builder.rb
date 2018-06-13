module SponsoredBenefits
  module Organizations
    class PlanDesignProposalBuilder

      attr_reader :plan_design_organization, :benefit_sponsorship

      def initialize(plan_design_organization, effective_date, options={})
        @plan_design_organization = plan_design_organization
        @effective_date = effective_date

        @title  = options[:title] || "Plan Design for #{effective_date.to_s}"

        @plan_design_profile = nil
        @benefit_sponsorship = nil
        @census_members_roster = nil
        @plan_design_proposal = @plan_design_organization.plan_design_proposals.build(title: title)
      end

      def add_plan_design_profile(new_plan_design_profile)
        raise "profile must include primary office location" unless new_plan_design_profile.primary_office_location.present?

        @plan_design_profile = SponsoredBenefits::Organizations::PlanDesignProfile.new(eligible_for_benefit_sponsorship: true)
        @plan_design_proposal.plan_design_profile = @plan_design_profile

        @plan_design_profile
      end

      def add_benefit_sponsorship(benefit_market = :aca_shop_cca, 
                                  annual_enrollment_period_begin_month = @effective_date.month,
                                  enrollment_frequency = :rolling_month, 
                                  contact_method = :paper_and_electronic)

        @benefit_sponsorship = SponsoredBenefits::BenefitSponsorships:BenefitSponsorship.new( benefit_market: @benefit_market, 
                                                                                              enrollment_frequency: @enrollment_frequency,
                                                                                              contact_method: @contact_method,
                                                                                              annual_enrollment_period_begin_month: annual_enrollment_period_begin_month,
                                                                                          )   
        
        @plan_design_profile.benefit_sponsorships << @benefit_sponsorship if @plan_design_profile.present? 
        benefit_sponsorship_id_for(@census_members_roster) if @census_members_roster.present?

      end

      def benefit_sponsorship_id_for(census_members_roster)
        census_members_roster.each { |census_member| census_member.benefit_sponsorship_id = @benefit_sponsorship.id }
      end

      def add_benefit_application(new_benefit_application)

        enrollment_timetable = SponsoredBenefits::BenefitApplications::BenefitApplication.enrollment_timetable_by_effective_date(effective_date)
        @benefit_application = SponsoredBenefits::BenefitApplications::BenefitApplication.new(effective_period: enrollment_timetable[:effective_period], open_enrollment_period:  enrollment_timetable[:open_enrollment_period])
        # fail NotImplementedError, 'abstract'
      end

      def add_census_members_roster(new_census_members_roster)
        @census_members_roster = new_census_members_roster  # SponsoredBenefits::CensusMembers::Roster.new
      end


      def plan_design_proposal
        raise "must add a plan design profile" if @plan_design_profile.blank?
        add_benefit_sponsorship if @benefit_sponsorship.blank?
          
        @plan_design_proposal
      end

      def census_members_roster
        @census_members_roster
      end


    end
  end
end
