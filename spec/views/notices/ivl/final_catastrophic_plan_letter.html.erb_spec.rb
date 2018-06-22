require "rails_helper"
include ActionView::Context

RSpec.describe "notices/ivl/final_catastrophic_plan_letter.html.erb" do

  let!(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_mailing_address)}
  let!(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Final Catastrophic Plan Notice',
                            :notice_template => 'notices/ivl/final_catastrophic_plan_letter',
                            :notice_builder => 'IvlNotices::FinalCatastrophicPlanNotice',
                            :event_name => 'final_catastrophic_plan',
                            :mpi_indicator => 'IVL_CAP',
                            :title => "Important Tax Information about your Catastrophic Health Coverage"})
                          }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}
  let!(:notice) { catastrophic_plan_notice.notice }
  let!(:catastrophic_plan_notice) { IvlNotices::FinalCatastrophicPlanNotice.new(person.consumer_role, valid_params) }

  before :each do
    catastrophic_plan_notice.append_hbe
    catastrophic_plan_notice.build
    render file: "notices/ivl/final_catastrophic_plan_letter", locals: {notice: notice}
  end

  it "should display the text" do
    expect(rendered).to have_selector('h3', text: 'TAX INFORMATION FOR YOUR CATASTROPHIC HEALTH PLAN')
    expect(rendered).to match /Federal law requires most Americans to have a minimum level of health coverage through 2018./
    expect(rendered).to match /Dear #{person.full_name}:/
    expect(rendered).to match /You are receiving this letter because you were enrolled in a catastrophic health plan through #{Settings.site.short_name} in #{previous_year}./
    expect(rendered).to match "For more information on these topics, consult a tax adviser or visit the IRS website at <a href=#{Settings.site.irs_url}>IRS.gov</a>."
    expect(rendered).to match /If you have questions or concerns, we’re here to help./
    expect(rendered).to match /The #{Settings.site.short_name} Team/
  end

  it "should render the partials" do
    render partial: 'notices/shared/cover_page', :locals => {notice: notice}
    render partial: 'notices/shared/logo_and_address_shop', :locals => {notice: notice}
    render partial: "notices/shared/date", :locals => {notice: notice}
    render partial: "notices/shared/address", :locals => {notice: notice}
    render partial: 'notices/shared/paragraph', :locals => {content: "The #{Settings.site.short_name} Team"}
    render partial: 'notices/shared/reference_paragraph', :locals => {contents: [""]}
  end
end
