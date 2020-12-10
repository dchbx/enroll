---
title: "Notifier Engine"
date: 2020-11-18T12:11:55-05:00
draft: true
---

The Notifier(FA) engine is a [Rails Engine](https://guides.rubyonrails.org/engines.html) found in the components/ folder of Enroll. The Notifier provides an interface for non developer users to change the font/format/layout/etc. of notices to be sent to users, and even include some conditional logic.

## Basic User Interface Walkthrough and Models Overview

# Notices

Assuming the Notifier engine is active, the Notifier can be reached through the following steps:

1. Visit the root URL
2. Login as an HBX Admin
3. On the top right of the navbar, click "Notices"
4. You should be brought to an index page displaying Add/Upload/Download notices. Notices can be sorted by market (all/SHOP/IVL).

# Creating a Notice

After selecting "Add Notice", the user will be brought to a text editor. The text editor has all the expected functionality of a text editor, with options to add conditional logic. The buttons to add conditional and other logic are:

1. "Select Condition/Loop" dropdown, the user can insert a conditional statement and embed within it text that will only appear if taht condition is satisfied. 
2. "T" button, representing tokens. Displays "tokens" to insert such as notice dates, Employer Profile names, etc.
3. "Select Application Settings", inserts application Settings such as the site URL (I.E. DCHBX), Contact Center Info, State Name. etc.

# Viewing Notices

After creating a notice, clicking the notice name on the main notices index page will allow the user to view a preview of the Notice featuring stubbed information

## Technical Overview

Because Notifier is an engine, it does not directly internally reference root Enroll specific models such as consumer roles which are referenced in the Notifiers. To get around this and allow previews of notices, the Notifiers uses a "builder" and "merge model" pattern. For example:

`
module Notifier
  module MergeDataModels
    class ConsumerRole
      include Virtus.model
      include ActiveModel::Model


      attribute :dependents, Array[MergeDataModels::Dependent]
      attribute :magi_medicaid_members, Array[MergeDataModels::Dependent]
      attribute :aqhp_or_non_magi_medicaid_members, Array[MergeDataModels::Dependent]
      attribute :uqhp_or_non_magi_medicaid_members, Array[MergeDataModels::Dependent]
      attribute :addresses, Array[MergeDataModels::Address]
      attribute :aqhp_eligible, Boolean
      attribute :totally_ineligible, Boolean
      # All other attributes listed here
 `
 That same MergeModel class also contains a stubbed object for previews:
 `
      def self.stubbed_object
        notice = Notifier::MergeDataModels::ConsumerRole.new(
          {
            notice_date: TimeKeeper.date_of_record.strftime('%B %d, %Y'),
            first_name: 'Primary',
            last_name: 'Test',
            primary_fullname: 'Primary Test',
            age: 28,
            dc_resident: 'Yes',
            citizenship: 'US Citizen',
            # Other attributes here
            ivl_oe_start_date: Date.parse('November 01, 2019')
                                   .strftime('%B %d, %Y'),
            ivl_oe_end_date: Date.parse('January 31, 2020')
                                 .strftime('%B %d, %Y')
          }
        )

        notice.mailing_address = Notifier::MergeDataModels::Address.stubbed_object
        notice.addresses = [notice.mailing_address]
        notice.dependents = [Notifier::MergeDataModels::Dependent.stubbed_object]
        notice.aqhp_or_non_magi_medicaid_members = [notice]
        notice.magi_medicaid_members = [Notifier::MergeDataModels::Dependent.stubbed_object]
        notice
      end
The merge model class will also contain the collections (I.E. specific queries) and conditions defined in an array:

```
      def collections
        %w[addresses dependents magi_medicaid_members aqhp_or_non_magi_medicaid_members uqhp_or_non_magi_medicaid_members]
      end
      def conditions
        %w[
            aqhp_eligible? uqhp_eligible? incarcerated? irs_consent?
            magi_medicaid? magi_medicaid_members_present? aqhp_or_non_magi_medicaid_members_present? uqhp_or_non_magi_medicaid_members_present?
            irs_consent_not_needed? aptc_amount_available? csr?
            aqhp_event_and_irs_consent_no? csr_is_73? csr_is_87?
            csr_is_94? csr_is_100? csr_is_zero? csr_is_nil? non_magi_medicaid?
            aptc_is_zero? totally_ineligible? aqhp_event? uqhp_event? totally_ineligible_members_present? primary_member_present?
        ]
      end
```
The merge models, builders, and other relevant classes can be viewed [here](https://github.com/dchbx/enroll/tree/master/components/notifier/app/models/notifier) on Github.