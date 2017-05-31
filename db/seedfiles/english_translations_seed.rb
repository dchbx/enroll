puts "*"*80
puts "::: Generating English Translations :::"

translations = {
  "en.layouts.application_brand.byline" => "The Right Place for the Right Plan",
  "en.layouts.application_brand.call_customer_service" => "Call Customer Service",
  "en.layouts.application_brand.help" => "Help",
  "en.layouts.application_brand.logout" => "Logout",
  "en.layouts.application_brand.my_id" => "My ID",
  "en.shared.my_portal_links.my_insured_portal" => "My Insured Portal",
  "en.uis.bootstrap3_examples.index.alerts_link" => "Jump to the alerts section of this page",
  "en.uis.bootstrap3_examples.index.badges_link" => "Jump to the badges section of this page",
  "en.uis.bootstrap3_examples.index.body_copy" => "Body Copy",
  "en.uis.bootstrap3_examples.index.body_copy_text" => "Nullam quis risus eget urna mollis ornare vel eu leo. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nullam id dolor id nibh ultricies vehicula.  Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec ullamcorper nulla non metus auctor fringilla. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Donec ullamcorper nulla non metus auctor fringilla.  Maecenas sed diam eget risus varius blandit sit amet non magna. Donec id elit non mi porta gravida at eget metus. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit.",
  "en.uis.bootstrap3_examples.index.buttons_link" => "Jump to the buttons section of this page",
  "en.uis.bootstrap3_examples.index.carousels" => "Carousels",
  "en.uis.bootstrap3_examples.index.carousels_link" => "Jump to the carousels section of this page",
  "en.uis.bootstrap3_examples.index.click_to_toggle_Popover" => "Click To toggle Popover",
  "en.uis.bootstrap3_examples.index.contextual_alternatives" => "Contextual alternatives",
  "en.uis.bootstrap3_examples.index.complete" => "Complete",
  "en.uis.bootstrap3_examples.index.four_directions_popover" => "Four directions Popover",
  "en.uis.bootstrap3_examples.index.danger" => "Danger",
  "en.uis.bootstrap3_examples.index.default_progress_bar" => "Default progress bar",
  "en.uis.bootstrap3_examples.index.default_well" => "Default well",
  "en.uis.bootstrap3_examples.index.dismissal_popover" => "Dismissal Popover",
  "en.uis.bootstrap3_examples.index.dismissal_popover_content" => "And here's some amazing content. It's very engaging. Right?", "en.uis.bootstrap3_examples.index.heading_1" => "Heading 1",
  "en.uis.bootstrap3_examples.index.heading_2" => "Heading 2",
  "en.uis.bootstrap3_examples.index.heading_3" => "Heading 3",
  "en.uis.bootstrap3_examples.index.heading_4" => "Heading 4",
  "en.uis.bootstrap3_examples.index.heading_5" => "Heading 5",
  "en.uis.bootstrap3_examples.index.heading_6" => "Heading 6",
  "en.uis.bootstrap3_examples.index.headings" => "Headings",
  "en.uis.bootstrap3_examples.index.inputs_link" => "Jump to the inputs section of this page",
  "en.uis.bootstrap3_examples.index.large_well" => "Large well",
  "en.uis.bootstrap3_examples.index.navigation_link" => "Jump to the navigation section of this page",
  "en.uis.bootstrap3_examples.index.optional_classes" => "Optional classes",
  "en.uis.bootstrap3_examples.index.pagination_link" => "Jump to the pagination section of this page",
  "en.uis.bootstrap3_examples.index.breadcrumbs" => "Breadcrumbs",
  "en.uis.bootstrap3_examples.index.home" => "Home",
  "en.uis.bootstrap3_examples.index.library" => "Library",
  "en.uis.bootstrap3_examples.index.data" => "Data",
  "en.uis.bootstrap3_examples.index.panels_link" => "Jump to the panels section of this page",
  "en.uis.bootstrap3_examples.index.picture_one_title" => "Picture One Title",
  "en.uis.bootstrap3_examples.index.picture_two_title" => "Picture Two Title",
  "en.uis.bootstrap3_examples.index.picture_three_title" => "Picture Three Title",
  "en.uis.bootstrap3_examples.index.picture_one_caption" => "Picture One Caption",
  "en.uis.bootstrap3_examples.index.picture_two_caption" => "Picture Two Caption",
  "en.uis.bootstrap3_examples.index.picture_three_caption" => "Picture Three Caption",
  "en.uis.bootstrap3_examples.index.popover_on_left" => "Popover on Left",
  "en.uis.bootstrap3_examples.index.popover_on_right" => "Popover on Right",
  "en.uis.bootstrap3_examples.index.popover_on_bottom" => "Popover on Bottom",
  "en.uis.bootstrap3_examples.index.popover_on_top" => "Popover on Top",
  "en.uis.bootstrap3_examples.index.popover_on_left_data" => "Vivamus sagittis lacus vel augue laoreet rutrum faucibus.",
  "en.uis.bootstrap3_examples.index.popover_on_right_data" => "Vivamus sagittis lacus vel augue laoreet rutrum faucibus.",
  "en.uis.bootstrap3_examples.index.popover_on_bottom_data" => "Vivamus sagittis lacus vel augue laoreet rutrum faucibus.",
  "en.uis.bootstrap3_examples.index.popover_on_top_data" => "Vivamus sagittis lacus vel augue laoreet rutrum faucibus.",
  "en.uis.bootstrap3_examples.index.progress_bar_and_sliders" => "Progress Bars and Sliders",
  "en.uis.bootstrap3_examples.index.progressbars_link" => "Jump to the progress bars section of this page",
  "en.uis.bootstrap3_examples.index.small_well" => "Small well",
  "en.uis.bootstrap3_examples.index.slides_only" => "Slides only", 
  "en.uis.bootstrap3_examples.index.success" => "Complete",
  "en.uis.bootstrap3_examples.index.tables_link" => "Jump to the tables section of this page",
  "en.uis.bootstrap3_examples.index.toggle_Popover_content" => "And here's some amazing content. It's very engaging. Right?",
  "en.uis.bootstrap3_examples.index.tooltips_link" => "Jump to the tooltips section of this page",
  "en.uis.bootstrap3_examples.index.text_area" => "Text Area",
  "en.uis.bootstrap3_examples.index.comment" => "Comment",
  "en.uis.bootstrap3_examples.index.check_box" => "Check Box",
  "en.uis.bootstrap3_examples.index.checked" => "Do you have insurance before",
  "en.uis.bootstrap3_examples.index.unchecked" => "Do you have insurance before",
  "en.uis.bootstrap3_examples.index.disabled_checked" => "Disabled",
  "en.uis.bootstrap3_examples.index.disabled_unchecked" => "Admin Access",
  "en.uis.bootstrap3_examples.index.radio_button" => "Radio Button",
  "en.uis.bootstrap3_examples.index.radio_off" => "Do you have insurance before",
  "en.uis.bootstrap3_examples.index.radio_on" => "Do you have insurance before",
  "en.uis.bootstrap3_examples.index.disabled_radio_off" => "Admin Access",
  "en.uis.bootstrap3_examples.index.disabled_radio_on" => "Disabled",
  "en.uis.bootstrap3_examples.index.tooltip_four_directions" => "Tooltip Four directions",
  "en.uis.bootstrap3_examples.index.tooltips_and_popovers" => "Tooltips and Popovers",
  "en.uis.bootstrap3_examples.index.tooltip_on_left" => "Tooltip on Left",
  "en.uis.bootstrap3_examples.index.tooltip_on_right" => "Tooltip on Right",
  "en.uis.bootstrap3_examples.index.tooltip_on_bottom" => "Tooltip on Bottom",
  "en.uis.bootstrap3_examples.index.tooltip_on_top" => "Tooltip on Top",
  "en.uis.bootstrap3_examples.index.typography" => "Typography",
  "en.uis.bootstrap3_examples.index.typography_link" => "Jump to the typography section of this page",
  "en.uis.bootstrap3_examples.index.warning" => "Warning",
  "en.uis.bootstrap3_examples.index.wells_link" => "Jump to the wells section of this page",
  "en.uis.bootstrap3_examples.index.wells" => "Wells",
  "en.uis.bootstrap3_examples.index.with_controls" => "With controls",
  "en.uis.bootstrap3_examples.index.with_indicators" => "With indicators",
  "en.uis.bootstrap3_examples.index.with_captions" => "With captions",

  "en.welcome.index.sign_out" => "Sign Out",
  "en.welcome.index.assisted_consumer_family_portal" => "Assisted Consumer/Family Portal",
  "en.welcome.index.broker_agency_portal" => "Broker Agency Portal",
  "en.welcome.index.broker_registration" => "Broker Registration",
  "en.welcome.index.consumer_family_portal" => "Consumer/Family Portal",
  "en.welcome.index.employee_portal" => "Employee Portal",
  "en.welcome.index.employer_portal" => "Employer Portal",
  "en.welcome.index.general_agency_portal" => "General Agency Portal",
  "en.welcome.index.general_agency_registration" => "General Agency Registration",
  "en.welcome.index.hbx_portal" => "HBX Portal",
  "en.welcome.index.logout" => "Logout",
  "en.welcome.index.returning_user" => "Returning User",
  "en.welcome.index.signed_in_as" => "Signed in as %{current_user}",
  "en.welcome.index.welcome_email" => "Welcome %{current_user}",
  "en.welcome.index.welcome_to_site_name" => "Welcome to %{short_name}",
  "en.users.orphans.index.orphan_user_accounts" => "Orphan User Accounts",
  "en.users.orphans.index.accounts_without_associated_person" => "User accounts without associated Person records",
  "en.users.orphans.index.customer_first_visit_contents" => "When customers access the Enroll Application for the first time, a local account is created.  Once a customer successfully completes the account screening process (to prevent duplicate identities), their Enroll account is linked with: 1) one Person record in the Enroll system, and 2) one Single Sign On (SSO) account in the enterprise identity management system.",
  "en.users.orphans.index.unlinked_person_record_contents" => "Occasionally, accounts are created, but not linked, with a corresponding Person record. This may result from a number of scenarios. For example:",
  "en.users.orphans.index.incomplete_screen_process_list" => "Customer doesn't complete screening process",
  "en.users.orphans.index.fail_screen_process_list" => "Customer fails screening process (attempts to create a new account for an existing identity)",
  "en.users.orphans.index.mismatched_customer_list" => "An employee customer is unable to match using employer-entered roster values",
  "en.users.orphans.index.without_screen_process_list" => "Test accounts are created without completing screening process",
  "en.users.orphans.index.enroll_app_error_list" => "An Enroll App error prevents the customer from proceeding",
  "en.users.orphans.index.invalid_accounts_contents" => "However, not all unlinked accounts are invalid.  For example, a customer may return later (via SSO) and complete the screeing process.",
  "en.users.orphans.index.disable_customer_access_contents" => "Incorrect usage of this feature can <strong>disable a customer's access to the HBX</strong> and should be done only by a knowledgable adminstrator and in conjunction with any necessary action on the Enterprise SSO record.",
  "en.users.orphans.index.accounts_without_matching_person" => "User accounts without a matching Person",
  "en.users.orphans.index.th_account_id" => "Email Account ID (click to see details)",
  "en.users.orphans.index.th_created_at" => "Created at",
  "en.users.orphans.index.th_last_signin" => "Last sign in",
  "en.users.orphans.index.th_signin_count" => "Sign in count",
  "en.users.orphans.index.th_enterprise_id" => "Enterprise ID",
  "en.users.orphans.index.th_delete" => "Delete",
  "en.users.orphans.show.orphan_user_account" => "Orphan User Account",
  "en.users.orphans.show.email_account_id" => "Email Account ID:",
  "en.users.orphans.show.created_at" => "Created at",
  "en.users.orphans.show.last_signin" => "Last sign in",
  "en.users.orphans.show.last_signin_ip" => "Last sign in IP",
  "en.users.orphans.show.last_visited" => "Last portal visited",
  "en.users.orphans.show.signin_count" => "Sign in count",
  "en.users.orphans.show.verified_idp" => "IDP verified?",
  "en.users.orphans.show.oim_id" => "OIM ID",
  "en.users.orphans.show.back" => "Back",
  "en.users.orphans.show.delete" => "Delete"


}

translations.keys.each do |k|
  Translation.where(key: k).first_or_create.update_attributes!(value: "\"#{translations[k]}\"")
end

puts "::: English Translations Complete :::"
puts "*"*80