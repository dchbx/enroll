require 'csv'
require 'prawn/table'
class Employers::PremiumStatementsController < ApplicationController
  layout "two_column", only: [:show]
  include Employers::PremiumStatementHelper

  def show
    @employer_profile = EmployerProfile.find(params.require(:id))
    authorize @employer_profile, :list_enrollments?
    set_billing_date
    @hbx_enrollments = @employer_profile.enrollments_for_billing(@billing_date)

    respond_to do |format|
      format.html
      format.js
      format.csv do
        send_data(csv_for(@hbx_enrollments), type: csv_content_type, filename: "DCHealthLink_Premium_Billing_Report.csv")
      end
    end
  end

  private

  def csv_for(hbx_enrollments)
    (output = "").tap do
      CSV.generate(output) do |csv|
        csv << ["Name", "SSN", "DOB", "Hired On", "Benefit Group", "Type", "Name", "Issuer", "Covered Ct", "Employer Contribution",
        "Employee Premium", "Total Premium"]
        hbx_enrollments.each do |enrollment|
          ee = enrollment.census_employee
          next if ee.blank?
          csv << [  ee.full_name,
                    ee.ssn,
                    ee.dob,
                    ee.hired_on,
                    ee.published_benefit_group.title,
                    enrollment.plan.coverage_kind,
                    enrollment.plan.name,
                    enrollment.plan.carrier_profile.legal_name,
                    enrollment.humanized_members_summary,
                    view_context.number_to_currency(enrollment.total_employer_contribution),
                    view_context.number_to_currency(enrollment.total_employee_cost),
                    view_context.number_to_currency(enrollment.total_premium)
                  ]
        end
      end
    end
  end

  def csv_content_type
    case request.user_agent
      when /windows/i
        'application/vnd.ms-excel'
      else
        'text/csv'
    end
  end

  def set_billing_date
    if params[:billing_date].present?
      @billing_date = Date.strptime(params[:billing_date], "%m/%d/%Y")
    else
      @billing_date = billing_period_options.first[1]
    end
  end
end
