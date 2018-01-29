puts "*"*80
puts "::: Generating Japanese Translations :::"

translations = {
  "ja.layouts.application_brand.call_customer_service" => "お客様サービスへ電話する",
  "ja.layouts.application_brand.help" => "ヘルプ",
  "ja.layouts.application_brand.logout" => "ログアウト",
  "ja.layouts.application_brand.my_id" => "私のID",
  "ja.shared.my_portal_links.my_insured_portal" => "保険契約者用ポータル",
  "ja.uis.bootstrap3_examples.index.alerts_link" => "Jump to the alerts section of this page",
  "ja.uis.bootstrap3_examples.index.badges_link" => "Jump to the badges section of this page",
  "ja.uis.bootstrap3_examples.index.body_copy" => "Body コピー",
  "ja.uis.bootstrap3_examples.index.body_copy_text" => "大きくは単節条虫亜綱と多節条虫亜綱に分けられる。一般にサナダムシとしてイメージするのは後者である。単節条虫亜綱のものは節に分かれない扁平な体で、先端に吸盤などを持つ。多節条虫亜綱のものは、頭部とそれに続く片節からなる。頭部の先端はやや膨らみ、ここに吸盤や鉤など、宿主に固着するための構造が発達する。それに続く片節は、それぞれに生殖器が含まれており、当節から分裂によって形成され、成熟すると切り離される。これは一見では体節に見えるが、実際にはそれぞれの片節が個体であると見るのが正しく、分裂した個体がつながったまま成長し、成熟するにつれて離れてゆくのである。そのため、これをストロビラともいう。長く切り離されずに10mにも達するものもあれば、常に数節のみからなる数mm程度の種もある。切り離された片節は消化管に寄生するものであれば糞と共に排出され、体外で卵が孵化するものが多い。",
  "ja.uis.bootstrap3_examples.index.buttons_link" => "Jump to the buttons section of this page",
  "ja.uis.bootstrap3_examples.index.carousels_link" => "Jump to the carousels section of this page",
  "ja.uis.bootstrap3_examples.index.heading_1" => "Heading 1",
  "ja.uis.bootstrap3_examples.index.heading_2" => "Heading 2",
  "ja.uis.bootstrap3_examples.index.heading_3" => "Heading 3",
  "ja.uis.bootstrap3_examples.index.heading_4" => "Heading 4",
  "ja.uis.bootstrap3_examples.index.heading_5" => "Heading 5",
  "ja.uis.bootstrap3_examples.index.heading_6" => "Heading 6",
  "ja.uis.bootstrap3_examples.index.headings" => "Headings",
  "ja.uis.bootstrap3_examples.index.inputs_link" => "Jump to the inputs section of this page",
  "ja.uis.bootstrap3_examples.index.navigation_link" => "Jump to the navigation section of this page",
  "ja.uis.bootstrap3_examples.index.pagination_link" => "Jump to the pagination section of this page",
  "ja.uis.bootstrap3_examples.index.panels_link" => "Jump to the panels section of this page",
  "ja.uis.bootstrap3_examples.index.progressbars_link" => "Jump to the progress bars section of this page",
  "ja.uis.bootstrap3_examples.index.tables_link" => "Jump to the tables section of this page",
  "ja.uis.bootstrap3_examples.index.tooltips_link" => "Jump to the tooltips section of this page",
  "ja.uis.bootstrap3_examples.index.typography" => "タイポグラフィ",
  "ja.uis.bootstrap3_examples.index.typography_link" => "Jump to the typography section of this page",
  "ja.uis.bootstrap3_examples.index.wells_link" => "Jump to the wells section of this page",
  "ja.welcome.index.assisted_consumer_family_portal" => "要支援顧客/家族用ポータル",
  "ja.welcome.index.broker_agency_portal" => "ブローカーエージェンシー用ポータル",
  "ja.welcome.index.broker_registration" => "ブローカー登録",
  "ja.layouts.application_brand.byline" => "あなたにとってベストなプランが見つかる場所",
  "ja.welcome.index.consumer_family_portal" => "顧客/家族用ポータル",
  "ja.welcome.index.employee_portal" => "社員用ポータル",
  "ja.welcome.index.employer_portal" => "雇用者用ポータル",
  "ja.welcome.index.general_agency_portal" => "一般エージェンシー用ポータル",
  "ja.welcome.index.general_agency_registration" => "一般エージェンシー登録",
  "ja.welcome.index.hbx_portal" => "HBXポータル",
  "ja.welcome.index.logout" => "ログアウト",
  "ja.welcome.index.returning_user" => "復帰ユーザ",
  "ja.welcome.index.sign_out" => "サインアウト",
  "ja.welcome.index.signed_in_as" => "%{current_user} のアカウントでサインインしています",
  "ja.welcome.index.welcome_email" => "%{current_user} へようこそ",
  "ja.welcome.index.welcome_to_site_name" => "%{short_name} へようこそ",
}

translations.keys.each do |k|
  Translation.where(key: k).first_or_create.update_attributes!(value: "\"#{translations[k]}\"")
end

puts "::: Japanese Translations Complete :::"
puts "*"*80
