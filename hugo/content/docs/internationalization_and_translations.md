---
title: "Internationalization and Translations"
date: 2021-01-07T12:12:25-05:00
draft: false
---


# Basic Overview (From Official Rails Docs)

Files in the config/locales directory are used for internationalization and are automatically loaded by Rails. If you want to use locales other than English, add the necessary files in this directory.

To use the locales, use `I18n.t`:

```
I18n.t 'hello'
```

 In views, this is aliased to just `t`:
```
     <%= t('hello') %>
```
 To use a different locale, set it with `I18n.locale`:
```
     I18n.locale = :es
```
 This would use the information in config/locales/es.yml. To learn more, please read the Rails Internationalization guide
 available at http://guides.rubyonrails.org/i18n.html.

# t vs I18n.t methods

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

# Enroll Implementation Steps and Examples

It is critical for accessibility that Enroll continuously support translations for our users. We implement translations through the base i18n functionality provided by rails, and our own helper file, dry_l10n_helper.rb:


```
module DryL10nHelper
  def l10n(translation_key, interpolated_keys = {})
    I18n.t(translation_key, interpolated_keys.merge(raise: true)).html_safe
  rescue I18n::MissingTranslationData
    translation_key.gsub(/\W+/, '').titleize
  end
end
```

If the `l10n` is invoked, it will look for the exact keys within the YML files or translation model (I Think???)

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

