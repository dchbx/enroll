---
title: "Internationalization and Translations"
date: 2021-01-07T12:12:25-05:00
draft: false
---

# Enroll Implementation Steps and Examples

It is critical for accessibility that Enroll continuously support translations for our users. We implement translations with the following steps:

1) Including them in YML files in the [config/locales](https://github.com/dchbx/enroll/tree/master/config/locales).

2) Loading them with the [translations rake tasks](https://github.com/dchbx/enroll/blob/master/lib/tasks/load_translations.rake) (be sure to ask Devops to run it post deploy for you).

3) Translations will then be loaded through the base i18n functionality provided by rails, and our own helper file, dry_l10n_helper.rb:

```
module DryL10nHelper
  def l10n(translation_key, interpolated_keys = {})
    I18n.t(translation_key, interpolated_keys.merge(raise: true)).html_safe
  rescue I18n::MissingTranslationData
    translation_key.gsub(/\W+/, '').titleize
  end
end
```

If the `l10n` is invoked, it will look into the [translation model](https://github.com/dchbx/enroll/blob/master/app/models/translation.rb) to find a record matching the keys from the YML file added and then loaded.

Let's take an example from Enroll where this method is called, in the file app/views/insured/interactive_identity_verifications/service_unavailable.html.haml:

```
%h4= t('insured.interactive_identity_verifications.service_unavailable.try_again_later')
```

The string in the 't' method  maps to config/locales/view.en.yml, with the following YML:

```
  insured:
    interactive_identity_verifications:
        service_unavailable:
          try_again_later: "We’re sorry. Experian - the third-party service we use to confirm your identity - is unavailable. Please try again later."
```

Now, if the language of the application was being used another language, it would load the translation from that language.


# t vs I18n.t methods, "Lazy" loading

Invoking the 't' method will perform a 'lazy' lookup that can be used in both _views and controllers_, and it will look for something somewhat unspecific that matches the key. For example, given this YML:
```
es:
  books:
    index:
      title: "Título"
en:
  books
    index:
      title: "Title"
```
Can be accessed using this:
<%= t '.title' %>

_Related Reading_: More information on lazy loading can be viewed here: https://guides.rubyonrails.org/i18n.html#looking-up-translations
