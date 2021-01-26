---
title: "Internationalization and Translations"
date: 2021-01-07T12:12:25-05:00
draft: false
---

# Enroll Implementation Steps and Examples 

## Using Translations in Views/Controllers


### I18n.t vs t() both are acceptable

There have been a couple of different translation methods used in Enroll but we are using the `I18n.t` method.

In your view you should use when there is no interpolation, you should use either the t or I18n.t method:

```
I18n.t('insured.interactive_identity_verifications.failed_validation.override')

```

If you want to perform a "lazy" lookup, such as if you only wanted to translate a single word and wanted to match the first translation associated with it, use the t method:

```
t('.override')
```

Here is an example with interpolation (I.E. you needed to pass a variable)
```
<h4 class="modal-title"><%= t('devise.login_history.admin.history_for_user', email: @user.email || @user.oim_id) %></h4>
```
The above would be included in the translation file like so:

```
"en.devise.login_history.admin.history_for_user" => "Login history for %{email}",
```


Here are some additional examples where internationalization should be implemented:


1) Select Tags:

```
<%= render "shared/organizations/entity_name_and_type_fields", f: f, entity_kinds: Organization::ENTITY_KINDS[0..3] %>
```

The above renders a list of "entity kinds", which should include their own translation.

2) Title Tags for Screen Reader:

Visually impaired users rely on screen readers to read a webpage, and they will have difficulty navigating if they don't speak the language the title tags are in:

```
<span class="glyphicon glyphicon-user hidden-md hidden-sm hidden-lg" title="Families"></span>
```

The text "Families" should be internationalized.

3) Conditional Logic returning strings:

```
<td><%= pp.user.present? ? "Yes" : "No" %></td>
```

"Yes" and "No" should be internationalized.

4) Text for links:

```
  <%= link_to('Add Office Location', new_office_location_path(:child_index => f.object.office_locations.length, :parent_object => f.object_name), remote: true, class: 'btn btn-default pull-left') %>
```

The text "Add Office Location" should be internationalized.

5) Placeholder text:

```
<%= text_field_tag :agency_search, nil, placeholder: 'Name/FEIN', class: 'form-control' %>
```

6) Data loading text:

```
<a href="#" onclick="return false;" class="btn btn-select search" data-loading-text="Loading...">
```


### t is safer, doesn’t error

The "t" method *will not* raise an exception for missing translations. I18n.t will generate an exception unless a key of "default" is passed, like so:

```
I18n.t('users.sign_up.success', default: "Successful Sign Up")
```

_Related Reading_:

More information on lazy loading can be viewed here: https://guides.rubyonrails.org/i18n.html#looking-up-translations

### Deprecated l10n helper

In the past we have used own `l10n` helper. This will soon be *deprecated*  in order to better conform to Rails conventions:

```
module L10nHelper
  def l10n(translation_key, interpolated_keys={})
    I18n.t(translation_key, interpolated_keys.merge(default: translation_key.gsub(/\W+/, ''))).html_safe
  end
end
```

If the `l10n` is invoked, it will look into the [translation model](https://github.com/dchbx/enroll/blob/master/app/models/translation.rb) to find a record matching the keys from the YML file added and then loaded.

## Translation Location

Translations are specified in .rb files in constants in the [db/seedfiles/translations](https://github.com/dchbx/enroll/tree/master/db/seedfiles/translations) directory.

### CCA vs DC

The translations seed uses the site key with the following logic to determine which translations seed to use:

```
site_key = if Rails.env.test?
             'dc'
           else
             BenefitSponsors::Site.all.first.site_key
           end
```

So, if the key is "cca", the translations will be pulled from `db/seedfiles/translations/en/cca`, and so on.


## Translation Seeding Process

Translations are seeded into the database with the [following command](https://github.com/dchbx/enroll/blob/master/db/seedfiles/english_translations_seed.rb):
```
bundle exec rake 'seed:translations[db/seedfiles/english_translations_seed.rb
```
If youre adding/changing translations and something is being deployed, be sure to ask Devops to run the command post deploy for you.

Please note that that command will run a different set of translations according to the environment.

## I18n Tasks

Enroll uses the [I18n tasks gem](https://github.com/glebm/i18n-tasks) to help with keeping track of the translations. With the command `bundle exec i18n-tasks`, you can see the available commands:

```
 health                           is everything OK?
    missing                          show missing translations
    translate-missing                translate missing keys with Google Translate or DeepL Pro
    add-missing                      add missing keys to locale data
    find                             show where keys are used in the code
    unused                           show unused translations
    remove-unused                    remove unused keys
    check-consistent-interpolations  verify that all translations use correct interpolation variables
    eq-base                          show translations equal to base value
    normalize                        normalize translation data: sort and move to the right files
    check-normalized                 verify that all translation data is normalized
    mv                               rename/merge the keys in locale data that match the given pattern
    rm                               remove the keys in locale data that match the given pattern
    data                             show locale data
    data-merge                       merge locale data with trees
    data-write                       replace locale data with tree
    data-remove                      remove keys present in tree from data
    tree-translate                   Google Translate a tree to root locales
    tree-merge                       merge trees
    tree-filter                      filter tree by key pattern
    tree-mv                          rename/merge/remove the keys matching the given pattern
    tree-subtract                    tree A minus the keys in tree B
    tree-set-value                   set values of keys, optionally match a pattern
    tree-convert                     convert tree between formats
    config                           display i18n-tasks configuration
    gem-path                         show path to the gem
    irb                              start REPL session within i18n-tasks context
```

The gem contains the file _spec/i18n_spec.rb_ which contains specs to check for missing or unused translation keys, as well as inconsistent interpolations or files that need normalizing.
