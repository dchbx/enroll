Dir.glob('db/seedfiles/translations/en/*').each do |file|
  puts file unless Rails.env.test?
  require_relative 'translations/en/' + File.basename(file,File.extname(file))
end

puts "*"*80 unless Rails.env.test?
puts "::: Generating English Translations :::" unless Rails.env.test?

MAIN_TRANSLATIONS = {
  "en.shared.my_portal_links.my_insured_portal" => "My Insured Portal"
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
  ASSISTANCE_TRANSLATIONS,
  DEVISE_TRANSLATIONS,
  HBX_PROFILES_TRANSLATIONS
].reduce({}, :merge)

puts "TRANSLATIONS" unless Rails.env.test?
p translations unless Rails.env.test?

translations.keys.each do |k|
  Translation.where(key: k).first_or_create.update_attributes!(value: "\"#{translations[k]}\"")
end

puts "::: English Translations Complete :::" unless Rails.env.test?
puts "*"*80 unless Rails.env.test?
