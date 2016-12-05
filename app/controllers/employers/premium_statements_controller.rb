require 'csv'
require 'prawn/table'
class Employers::PremiumStatementsController < ApplicationController
  layout "two_column", only: [:show]
  include Employers::PremiumStatementHelper

  def show
    @employer_profile = EmployerProfile.find(params[:id])
    bill_date = set_billing_date
    authorize @employer_profile, :list_enrollments?
    scopes={ id: params.require(:id), billing_date: bill_date}
    @datatable = Effective::Datatables::PremiumBillingReportDataTable.new(scopes)
    respond_to do |format|
      format.html
      format.js
    end
  end

  private


 def set_billing_date
    if params[:billing_date].present?
      @billing_date = Date.strptime(params[:billing_date], "%m/%d/%Y")
    else
      @billing_date = billing_period_options.first[1]
    end
 end
end
