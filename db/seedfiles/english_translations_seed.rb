site_key = if Rails.env.test?
             'dc'
           else
             BenefitSponsors::Site.all.first.site_key
           end

Dir.glob("db/seedfiles/translations/en/#{site_key}/*").each do |file|
  require_relative "translations/en/#{site_key}/" + File.basename(file,File.extname(file))
end

puts '*' * 80 unless Rails.env.test?
puts '::: Generating English Translations :::'

MAIN_TRANSLATIONS = {
  :'en.shared.my_portal_links.my_insured_portal' => 'My Insured Portal',
  :'en.shared.my_portal_links.my_broker_agency_portal' => 'My Broker Agency Portal',
  :'en.shared.my_portal_links.my_general_agency_portal' => 'My General Agency Portal',
  :'en.shared.my_portal_links.my_employer_portal' => 'My Employer Portal'
}.freeze

def dc_translations
  [
    BOOTSTRAP_EXAMPLE_TRANSLATIONS,
    BUTTON_PANEL_EXAMPLE_TRANSLATIONS,
    LAYOUT_TRANSLATIONS,
    MAIN_TRANSLATIONS,
    USERS_ORPHANS_TRANSLATIONS,
    WELCOME_INDEX_TRANSLATIONS,
    BUTTON_PANEL_EXAMPLE_TRANSLATIONS,
    INSURED_TRANSLATIONS,
    BROKER_AGENCIES_TRANSLATIONS,
    EXCHANGE_TRANSLATIONS,
    DEVISE_TRANSLATIONS,
    EMPLOYER_TRANSLATIONS,
    PLAN_TRANSLATIONS,
    HBX_PROFILES_TRANSLATIONS,
    CENSUS_EMPLOYEE_TRANSLATIONS,
    BROWSER_SUPPORT_TRANSLATIONS,
    MANAGE_SEP_TYPES_TRANSLATIONS,
    ADMIN_ACTIONS_TRANSLATIONS
  ].reduce({}, :merge)
end

def cca_translations
  [
    BOOTSTRAP_EXAMPLE_TRANSLATIONS,
    BUTTON_PANEL_EXAMPLE_TRANSLATIONS,
    LAYOUT_TRANSLATIONS,
    MAIN_TRANSLATIONS,
    USERS_ORPHANS_TRANSLATIONS,
    WELCOME_INDEX_TRANSLATIONS,
    BUTTON_PANEL_EXAMPLE_TRANSLATIONS,
    INSURED_TRANSLATIONS,
    BROKER_AGENCIES_TRANSLATIONS,
    EXCHANGE_TRANSLATIONS,
    DEVISE_TRANSLATIONS,
    EMPLOYER_TRANSLATIONS,
    PLAN_TRANSLATIONS,
    HBX_PROFILES_TRANSLATIONS,
    CENSUS_EMPLOYEE_TRANSLATIONS,
    BROWSER_SUPPORT_TRANSLATIONS,
    ADMIN_ACTIONS_TRANSLATIONS
  ].reduce({}, :merge)
end

unless Rails.env.test?
  puts 'TRANSLATIONS'
  p send("#{site_key}_translations")
end

send("#{site_key}_translations").keys.each do |k|
  Translation.where(key: k).first_or_create.update_attributes!(value: "\"#{send("#{site_key}_translations")[k]}\"")
end

puts '::: English Translations Complete :::'
puts '*' * 80 unless Rails.env.test?
