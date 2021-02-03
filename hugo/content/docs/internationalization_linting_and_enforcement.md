---
title: "Internationalization Linting and Enforcement"
date: 2021-01-26T12:12:25-05:00
draft: false
---

## Translations View Linter

Enroll includes a custom class, ViewTranslationsLinter, to lint view files and assure that no strings within .erb files are left untranslated. The ViewTranslationsLinter class will be run automatically on Github actions against any of your branch's files containing .html.erb files, with the following command:

```
bundle exec rake view_translations_linter:lint_git_difference_changed_lines"
```

You can run the above *locally* if you wish, like so:
```
bundle exec rake view_translations_linter:lint_git_difference_changed_lines
```

## How Linting Works

The task will lint both strings *within* ERB tags, and outside of them.

Example 1:
```
# Within ERB Tags
<%= "This string would fail the check" %>
# Change this and add a corresponding translation
<%= l10n('string_check_fail_message') %>
```

Example 2:
```
# Outside ERB Tags
<p>"This would fail the check for outside ERB tags" %>
<p> <%= l10n('string_check_fail_message') %>

```

Example 2:

```
  # Within ERB Tags
  <%= link_to l10n('Back to Messages', main_app.exchanges_bulk_notices_path, class: 'btn btn-alt-blue' %>
  # Change it to this and add translation
  <%= link_to l10n('back_to_messages'), main_app.exchanges_bulk_notices_path, class: 'btn btn-alt-blue' %>

```


## When My Build Breaks

First, take a look at the output for the strings that didn't pass the check. 

Next, check the "Allow List." We include an "Allow List" of approved strings in an ERB file /spec/support/fixtures/approved_translation_strings.yml for strings that should be allowed through. Please do *not* add to this YML without lead dev approval. Here are the kinds of strings we allow and what exactly they allow:

| String Type Description                       | String List                                                                                                                             |
| -------------------------------------         | -----------                                                                                                                             |
| HTML Elements/Helper Methods                  | "l10n", "I18n", "content_for", "render", "pundit_span", "number_to_currency", "format_policy_purchase_date", "format_policy_purchase_time", "display_carrier_logo", "enrollment_coverage_end"                                                                                                                                  |
| Non-Word Numerical Strings                    | "coverage_year", "effective_on", "coverage_terminated_on", "hired_on", "end_of_month", "start_of_month", "terminated_on", "active_year", "dob"                                                                                                                                                                                     |
| Strings Related to Proper Names               | "name", "first_name", "last_name", "full_name","title"                                                                                  |
| Record Identifier                             | "hbx_id", "hbx_enrollment_id","hios_id"                                                                                                 |
| Non Text Method Calls                         | ".hios_id",".product_id"                                                                                                                |

Please *do not* add any strings to the allow_list without lead dev approval.
