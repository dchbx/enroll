# frozen_string_literal: true

module FinancialAssistance
  module ApplicationHelper

    def to_est(datetime)
      datetime.in_time_zone("Eastern Time (US & Canada)") if datetime.present?
    end

    def total_aptc_across_eligibility_determinations(application_id)
      eds = FinancialAssistance::Application.find(application_id).eligibility_determinations
      eds.map(&:max_aptc).flat_map(&:to_f).inject(:+)
    end
    def eligible_applicants(application_id, eligibility_flag)
      application = FinancialAssistance::Application.find(application_id)
      application.active_applicants.where(eligibility_flag => true).map(&:full_name).map(&:titleize)
    end
    def any_csr_ineligible_applicants?(application_id)
      application = FinancialAssistance::Application.find(application_id)
      application.eligibility_determinations.inject([]) do |csr_eligible, ed_obj|
        csr_eligible << ed_obj.csr_percent_as_integer
        csr_eligible
      end.include?(0)
    end

    def applicant_age(applicant)
      now = Time.now.utc.to_date
      dob = applicant.dob
      now.year - dob.year - (now.month > dob.month || (now.month == dob.month && now.day >= dob.day) ? 0 : 1)
    end

    def find_next_application_path(application)
      if application.incomplete_applicants?
        go_to_step_application_applicant_path application, application.next_incomplete_applicant, 1
      else
        review_and_submit_application_path application
      end
    end

    def find_previous_from_step_one
      model_name = @model.class.to_s.split('::').last.downcase
      if  model_name == "applicant"
        edit_application_path(@application)
      elsif model_name == "application"
        review_and_submit_application_path(@application)
      else
        send("application_applicant_#{model_name.pluralize}_path", @application, @applicant)
      end
    end

    def find_applicant_path(application, applicant, options = {})
      document_flow = ['incomes', 'deductions', 'benefits']
      next_path = document_flow.find do |embeded_document|
        # this is a complicated condition but we need to make sure we don't work backwards in the flow from incomes to deductions to benefits
        # so if a current option is passed in we won't consider anything before it
        # if a current option is not passed then .index will return nil
        # and instead we'll short circuit by checking that -1 is less then i, which always would be true
        ((document_flow.index(options[:current]) || -1) < document_flow.index(embeded_document)) && applicant.send(embeded_document).present?
      end
      next_path ? send("application_applicant_#{next_path}_path", application, applicant) : other_questions_application_applicant_path(application, applicant)
    end

    def find_previous_applicant_path(application, applicant, options = {})
      reverse_document_flow = ['benefits', 'deductions', 'incomes']
      previous_path = reverse_document_flow.find do |embeded_document|
        # this is a complicated condition but we need to make sure we don't work backwards in the flow from incomes to deductions to benefits
        # so if a current option is passed in we won't consider anything before it
        # if a current option is not passed then .index will return nil
        # and instead we'll short circuit by checking that -1 is less then i, which always would be true
        ((reverse_document_flow.index(options[:current]) || -1) < reverse_document_flow.index(embeded_document)) && applicant.send(embeded_document).present?
      end
      previous_path ? send("application_applicant_#{previous_path}_path", application, applicant) : go_to_step_application_applicant_path(application, applicant, 2)
    end

    def left_nav_css(conditional)
      'cna disabled' unless conditional
    end

    def show_faa_status
      return true if controller_name == 'applications' && action_name == 'edit'
      false
    end

    def claim_eligible_tax_dependents
      return if @application.blank? || @applicant.blank?
      eligible_applicants = @application.active_applicants.map! do |applicant|
        [applicant.full_name, applicant.id.to_s] if applicant != @applicant && applicant.is_required_to_file_taxes? && applicant.claimed_as_tax_dependent_by != @applicant.id
      end
      eligible_applicants
    end

    def frequency_kind_options
      { 'Bi Weekly' => 'biweekly', 'Daily' => 'daily', 'Half Yearly' => 'half_yearly', 'Monthly' => 'monthly',  'Quarterly' => 'quarterly', 'Weekly' => 'weekly', 'Yearly' => 'yearly' }
    end

    def state_options
      %w[AL AK AZ AR CA CO CT DE DC FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NY NC ND OH OK OR PA PR RI SC SD TN TX UT VA VI VT WA WV WI WY]
    end

    def income_form_for(application, applicant, income)
      url = if income.new_record?
              application_applicant_incomes_path(application, applicant)
            else
              application_applicant_income_path(@application, @applicant, income)
            end

      form_for income, url: url, remote: true do |f|
        yield f
      end
    end

    def benefit_form_for(application, applicant, benefit)
      url = if benefit.new_record?
              application_applicant_benefits_path(application, applicant)
            else
              application_applicant_benefit_path(@application, @applicant, benefit)
            end

      form_for benefit, url: url, remote: true do |f|
        yield f
      end
    end

    def deduction_form_for(application, applicant, deduction)
      url = if deduction.new_record?
              application_applicant_deductions_path(application, applicant)
            else
              application_applicant_deduction_path(@application, @applicant, deduction)
            end

      form_for deduction, url: url, remote: true do |f|
        yield f
      end
    end

    def income_and_deductions_for(applicant)
      applicant.incomes + applicant.deductions
    end

    def income_and_deductions_for_any(application)
      return false if application.blank?
      application.applicants.any? {|applicant| income_and_deductions_for(applicant).present?}
    end

    def start_to_end_dates(embedded_document)
      start_date = embedded_document.start_on
      end_date = embedded_document.end_on
      end_date == TimeKeeper.date_of_record || !end_date ? "#{start_date} - Present" : "#{start_date} - #{end_date}"
    end

    def income_and_deductions_edit(application, applicant, embedded_document)
      if embedded_document.class == FinancialAssistance::Deduction
        application_applicant_deductions_path(application, applicant)
      elsif [FinancialAssistance::Income::JOB_INCOME_TYPE_KIND, FinancialAssistance::Income::NET_SELF_EMPLOYMENT_INCOME_KIND].include? embedded_document.kind
        application_applicant_incomes_path(application, applicant)
      else
        other_application_applicant_incomes_path(application, applicant)
      end
    end

    def support_text_placeholders(raw_support_text)
      # set <application-applicable-year> placeholdersr
      return [] if @application.nil?
      assistance_year = calculated_application_year.to_s

      raw_support_text.update(raw_support_text).each do |_key, value|
        value.gsub! '<application-applicable-year>', assistance_year if value.include? '<application-applicable-year>'
      end
    end

    def show_net_amount_for(other_income)
      other_income.kind == "capital_gains" || other_income.kind == "farming_and_fishing"
    end

    def decode_msg(encoded_msg)
      if encoded_msg == '101'
        'faa.acdes_lookup'
      elsif encoded_msg == '010'
        'faa.curam_lookup'
      end
    end

    def format_phone(phone)
      return '' unless phone.size == 10
      number_to_phone(phone, area_code: true)
    end

    def format_benefit_cost(cost, frequency)
      return '' if cost.nil? || frequency.nil?
      "$" + cost.to_s + " " + frequency.to_s.capitalize
    end

    def faa_relationship_options(dependent, _referer)
      relationships = FinancialAssistance::Relationship::RELATIONSHIPS_UI
      options_for_select(relationships.map{|r| [r.to_s.humanize, r.to_s] }, selected: FinancialAssistance::Relationship::INVERSE_MAP[dependent.applicant&.relationship])
    end

    def show_naturalized_citizen_container(applicant)
      applicant&.us_citizen
    end

    def show_immigration_status_container(applicant)
      applicant&.us_citizen == false
    end

    def show_tribal_container(applicant)
      applicant&.indian_tribe_member
    end

    def show_naturalization_doc_type(applicant)
      show_naturalized_citizen_container(applicant) && applicant&.naturalized_citizen
    end

    def show_immigration_doc_type(applicant)
      show_immigration_status_container(applicant) && applicant&.eligible_immigration_status
    end

    def show_vlp_documents_container(applicant)
      show_naturalization_doc_type(applicant) || show_immigration_doc_type(applicant)
    end

    def member_name_by_id(id)
      ::FinancialAssistance::Applicant.find(id).full_name
    end

    def immigration_document_options_submission_url(application, model)
      if model.try(:persisted?)
        { :remote => true, method: :put, :url => application_applicant_path(application_id: application.id, id: model.id), :as => :applicant }
      else
        { :remote => true, method: :post, :url => "/applications/#{application.id}/applicants", :as => :applicant }
      end
    end

    def humanize_relationships
      FinancialAssistance::Relationship::RELATIONSHIPS_UI.map {|r| [r.to_s.humanize, r.to_s] }
    end

    def calculated_application_year
      FinancialAssistanceRegistry[:application_year].item.call.value!
    end

    def human_boolean(boolean)
      if boolean
        'Yes'
      elsif boolean == false
        'No'
      else
        'N/A'
      end
    end
  end
end
