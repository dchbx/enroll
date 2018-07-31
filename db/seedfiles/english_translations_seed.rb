Dir.glob('db/seedfiles/translations/en/*').each do |file|
  require_relative 'translations/en/' + File.basename(file,File.extname(file))
end

puts "*"*80 unless Rails.env.test?
puts "::: Generating English Translations :::"

MAIN_TRANSLATIONS = {
  "en.shared.my_portal_links.my_insured_portal" => "My Insured Portal",
  "en.shared.my_portal_links.my_broker_agency_portal" => "My Broker Agency Portal",
  "en.shared.my_portal_links.my_employer_portal" => "My Employer Portal"
}
translations = [
  BOOTSTRAP_EXAMPLE_TRANSLATIONS,
  BUTTON_PANEL_EXAMPLE_TRANSLATIONS,
  LAYOUT_TRANSLATIONS,
  MAIN_TRANSLATIONS,
  USERS_ORPHANS_TRANSLATIONS,
  WELCOME_INDEX_TRANSLATIONS,
  BUTTON_PANEL_EXAMPLE_TRANSLATIONS,
  INSURED_TRANSLATIONS,
  BROKER_AGENCIES_TRANSLATIONS,
  DEVISE_TRANSLATIONS,
  EMPLOYER_TRANSLATIONS
].reduce({}, :merge)

unless Rails.env.test?
  puts "TRANSLATIONS"
  p translations
end

translations.keys.each do |k|
  Translation.where(key: k).first_or_create.update_attributes!(value: "\"#{translations[k]}\"")
end

puts "::: English Translations Complete :::"
puts "*"*80 unless Rails.env.test?