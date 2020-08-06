# frozen_string_literal: true

module SponsoredBenefits
  module Forms
    class PlanDesignProposal

      include ActiveModel::Model
      include ActiveModel::Validations

      attr_reader :title, :effective_date, :zip_code, :county, :sic_code, :quote_date, :plan_option_kind, :metal_level_for_elected_plan
      attr_reader :profile
      attr_reader :plan_design_organization
      attr_reader :proposal
      attr_reader :kind

      validates_presence_of :title, :effective_date, :sic_code, :county, :zip_code

      def initialize(attrs = {})
        assign_wrapper_attributes(attrs)
        ensure_proposal
        ensure_profile
        ensure_sic_zip_county
      end

      def for_new
        service.ensure_benefits
      end

      def for_create(attrs)
        service.save_benefits(attrs)
      end

      def for_destroy
        service.destroy_benefits
      end

      def assign_wrapper_attributes(attrs = {})
        attrs.each_pair do |k,v|
          self.send("#{k}=", v)
        end
      end

      def organization=(val)
        @plan_design_organization = val
      end

      def profile=(attrs); end

      attr_writer :title

      def effective_date=(val)
        @effective_date = Date.strptime(val, "%Y-%m-%d")
      end

      def proposal_id=(val)
        return if val.blank?
        @proposal = @plan_design_organization.plan_design_proposals.detect{|proposal| proposal.id.to_s == val }
        if @proposal.present?
          @profile = @proposal.profile
          prepopulate_attributes
        end
      end

      attr_writer :kind

      def prepopulate_attributes
        @title = @proposal.title
        @effective_date = @profile.benefit_sponsorships.first.initial_enrollment_period.begin.strftime("%Y-%m-%d")
        @quote_date = @proposal.updated_at.strftime("%m/%d/%Y")
      end

      def ensure_proposal
        @proposal = @plan_design_organization.plan_design_proposals.build unless @proposal.present?
      end

      def ensure_sic_zip_county
        @sic_code = @plan_design_organization.sic_code
        if location = @plan_design_organization.office_locations.first
          @zip_code = location.address.zip
          @county = location.address.county
        end
      end

      def ensure_profile
        if @profile.blank?
          @profile = "SponsoredBenefits::Organizations::AcaShop#{Settings.aca.state_key.capitalize}EmployerProfile".constantize.new
          sponsorship = @profile.benefit_sponsorships.first
          sponsorship.benefit_applications.build
        end
        sponsorship = @profile.benefit_sponsorships.first
        sponsorship.benefit_applications.build if sponsorship.benefit_applications.empty?
      end

      def assign_benefit_group(benefit_group)
        if benefit_group.sole_source?
          benefit_group.build_relationship_benefits
        else
          benefit_group.build_composite_tier_contributions
        end
        sponsorship = @proposal.profile.benefit_sponsorships.first
        application = sponsorship.benefit_applications.first
        application.benefit_groups << benefit_group
        ## this is not saving even though it claims to be valid
        @proposal.save!
      end

      def save
        initial_enrollment_period = @effective_date..(@effective_date.next_year.prev_day)

        if @proposal.persisted?
          @proposal.assign_attributes(title: @title)
        else
          profile = "SponsoredBenefits::Organizations::AcaShop#{Settings.aca.state_key.capitalize}EmployerProfile".constantize.new
          profile.sic_code = @sic_code if @sic_code
          @proposal = @plan_design_organization.plan_design_proposals.build({title: @title, profile: profile})
        end

        sponsorship = @proposal.profile.benefit_sponsorships.first
        sponsorship.assign_attributes({initial_enrollment_period: initial_enrollment_period, annual_enrollment_period_begin_month: @effective_date.month})
        if sponsorship.present?
          renewal_employer = @plan_design_organization.is_renewing_employer?
          enrollment_dates = BenefitApplications::BenefitApplication.enrollment_timetable_by_effective_date(@effective_date, renewal_employer)
          benefit_application = (sponsorship.benefit_applications.first || sponsorship.benefit_applications.build)
          benefit_application.effective_period = enrollment_dates[:effective_period]
          benefit_application.open_enrollment_period = enrollment_dates[:open_enrollment_period]
        end

        @proposal.save!
      end

      def has_reference_plan_assigned?
        sponsorship = @proposal.profile.benefit_sponsorships.first
        application = sponsorship.benefit_applications.first
        return false unless application.present?
        return false if application.benefit_groups.empty?

        benefit_group = application.benefit_groups.first

        benefit_group.reference_plan_id.present?
      end

      def to_h
        effective_date = if @effective_date.is_a? Date
                           @effective_date
                         else
                           Date.strptime(@effective_date, "%Y-%m-%d")
                         end
        sponsorship = @profile.benefit_sponsorships.first
        {
          title: "Copy of #{@proposal.title}",
          effective_date: @effective_date,
          profile: [
            benefit_sponsorship: [
              initial_enrollment_period: effective_date..(effective_date.next_year.prev_day),
              annual_enrollment_period_begin_month: effective_date.month,
              benefit_market: sponsorship.benefit_market,
              contact_method: sponsorship.contact_method,
              benefit_application: [
                effective_period: effective_date..(effective_date.next_year.prev_day),
                open_enrollment_period: TimeKeeper.date_of_record..effective_date
              ]
            ]
          ]
        }
      end

      def is_dental?
        kind == "dental"
      end

      def service
        return @service if defined? @service
        @service = SponsoredBenefits::Services::PlanDesignProposalService.new(
          kind: kind,
          proposal: proposal
        )
      end

      def is_dental_plans_avialable?
        self.effective_date = @effective_date unless @effective_date.is_a?(Date)
        service.is_dental_plans_avialable?(self)
      end
    end
  end
end
