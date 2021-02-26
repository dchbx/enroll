---
title: "Resource Registry"
date: 2021-02-09:12:25-05:00
draft: false
---

## Intro to Resource Registry

[Resource Registry](https://github.com/ideacrew/resource_registry) is a library for system configuration, feature flipping and eventing.

ResourceRegistry initializes dry container with application name prefix ex. EnrollRegistry.  It loads YAML files from system folder under Rails root. It uses these YAML files to seed Features and namespaces.

ResourceRegistry uses a Feature to group related system functions and settings. Features are composed of the following high level attributes:

- key [Symbol] 'key' of the Feature's key/value pair. This is the Feature's identifier and must be unique

- item [Any] 'value' of the Feature's key/value pair. May be a static value, proc, class instance and may include an options hash

n- amespace [Array] an ordered list that supports optional taxonomy for relationships between Features

- is_enabled [Boolean] indicator whether the Feature is accessible in the current configuration

- settings [Array] a list of key/item pairs associated with the Feature

- meta [Hash] a set of attributes to store configuration values and drive their presentation in User Interface

- Here is an example Feature definition in YAML format. Note the settings effective_period value is an expression:
```
  - namespace:
    - :enroll_app
    - :aca_shop_market
    - :benefit_market_catalog
    - :catalog_2019
    - :contribution_model_criteria
    features:
      - key: :initial_sponsor_jan_default_2019
        item: :contribution_model_criterion
        is_enabled: true
        settings:
          - key: :contribution_model_key
            item: :zero_percent_sponsor_fixed_percent_contribution_model
          - key: :benefit_application_kind
            item: :initial
          - key: :effective_period
            item: <%= Date.new(2019,1,1)..Date.new(2019,1,31) %>
          - key: :order
            item: 1
          - key: :default
            item: false
          - key: :renewal_criterion_key
            item: :initial_sponsor_jan_default
```

Feature loading onto the registry is a two step process:

We load them under given namespace

We also register feature under feature_index. Feature Index enable us to access the feature directly using its key without namespace prefix. 

Note: Feature key should be Unique. Adding features with same key will throw feature already exists error. This is due to construction of feature_index, where we enlist all features without namespaces.

To get a list of all key values for Resource Registry features, run:

```EnrollRegistry.keys```

## Existing Feature Configurations

1) [Enroll Registry](https://github.com/dchbx/enroll/blob/master/config/initializers/resource_registry.rb)
- [Enroll App Config](https://github.com/dchbx/enroll/blob/master/system/config/templates/features/enroll_app/enroll_app.yml)
- [ACA Shop Market Config](https://github.com/dchbx/enroll/blob/master/system/config/templates/features/aca_shop_market/aca_shop_market.yml)
- [SEP Types Config](https://github.com/dchbx/enroll/blob/master/system/config/templates/features/enroll_app/sep_types.yml)
- [Product Selection Policies Config](https://github.com/dchbx/enroll/blob/master/system/config/templates/features/product_selection_policies/product_selection_policies.yml)


2) [Financial Assistance]((https://github.com/dchbx/enroll/blob/master/components/financial_assistance/config/initializers/resource_registry.rb)
- [Financial Asssistance Config](https://github.com/dchbx/enroll/blob/master/system/config/templates/features/aca_individual_market/financial_assistance.yml)

## Feature Retrieval

Feature can be retrieved directly from feature index using just the key 
```
2.5.1 :004 >  EnrollRegistry[:initial_sponsor_jan_default_2019]
```
Feature can also be fetched using full key that includes namespace
```
2.5.1 :005 >  EnrollRegistry['enroll_app.aca_shop_market.benefit_market_catalog.catalog_2019.contribution_model_criteria.initial_sponsor_jan_default_2019']
```
All the features registered on the container are wrapped in a FeatureDSL class (an implementation of Ruby Forwardable module).  It implements useful methods like
```
> EnrollRegistry[:initial_sponsor_jan_default_2019].enabled? # returns boolean based on is_enabled flag

> EnrollRegistry[:initial_sponsor_jan_default_2019].setting(:effective_period)# retreives setting by key

> EnrollRegistry[:initial_sponsor_jan_default_2019].disabled? # inverse of enabled? 
```
Please refer to the [feature DSL](https://github.com/ideacrew/resource_registry/blob/master/lib/resource_registry/feature_dsl.rb) for other useful methods.

Features can be queried by namespace using _features_by_namespace_ method it returns feature keys registered under the namespace.

```
2.5.1 :006 > EnrollRegistry.features_by_namespace("enroll_app.aca_shop_market.benefit_market_catalog")
 => [:contribution_model_aca_shop, :assign_contribution_model_aca_shop] 
2.5.1 :007 > 
```

## Adding Configurations for New Features

Add _key_, _item_, and _is_enabled?_ in the appropriate YML file. For example, from the [Family data table](https://github.com/dchbx/enroll/blob/master/app/models/effective/datatables/family_data_table.rb):

          if ::EnrollRegistry.feature_enabled?(:send_secure_message_family)
            dropdown.insert(8, ['Send Secure Message', new_secure_message_exchanges_hbx_profiles_path(person_id: row.primary_applicant.person.id, family_actions_id: "family_actions_#{row.id}"),
                                pundit_allow(HbxProfile, :can_send_secure_message?) ? "ajax" : "hide"])
          else
            dropdown.insert(8, ['Send Secure Message', new_insured_inbox_path(id: row.primary_applicant.person.id, profile_id: current_user.person.hbx_staff_role.hbx_profile.id, to: row.primary_applicant.person.last_name + ', ' +
              row.primary_applicant.person.first_name, family_actions_id: "family_actions_#{row.id}"), secure_message_link_type(row, current_user)])
          end

## Checking Configurations (in Enroll to turn feature on/off)

The above check of `::EnrollRegistry.feature_enabled?(:send_secure_message_family)` corresponds with the following lines in the [enroll_app config](https://github.com/dchbx/enroll/blob/master/system/config/templates/features/enroll_app/enroll_app.yml):

      - key: :send_secure_message_family
        item: :send_secure_message
        is_enabled: true

Features can be enabled or disabled using is_enabled attribute on the feature configuration.

You can verify feature enabled or not using feature_enabled? method as shown below.
```
> EnrollRegistry.feature_enabled?(:initial_sponsor_jan_default_2019)
```
Te method will return if a feature is enabled or not. **Please Note: to be considered enabled, the subject feature plus all its ancestor features must be in enabled state. Ancestor features are any that are registered in this feature's namespace tree/**

## Cucumber Specs

Enroll provides a [Resource Registry World](https://github.com/dchbx/enroll/blob/master/features/support/worlds/resource_registry_world.rb) in Cucumbers which can be used to mock enabling/disabling a given feature. If you write any cucumbers for any of your ResourceRegistry toggled features, you should definitely write parallel scenarios to test when that feature is disabled.

_Further Reading_: [Resource Registry Repository](https://github.com/ideacrew/resource_registry)



