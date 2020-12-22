---
title: "Brakeman"
date: 2020-12-22T12:12:25-05:00
draft: false
---

[Brakeman](https://brakemanscanner.org/) is our static code security analysis tool which provides a detailed output of security vulnerabilities. Run Brakeman with the following command:  

`brakeman --github-repo dchbx/enroll -o output.html -o output.txt  `

###[Mass Assignment](https://brakemanscanner.org/docs/warning_types/mass_assignment/)

Mass assignment brakeman vulnerabilities pose a threat because a user could potentially pass through anything into our controller. They’re typically characterized by the method permit! (With bang) being called on params. The best way to mitigate this is strong params:

# Strong Params

In the file _app/controllers/inboxes_controller.rb_, the following line contained all params permitted:

`@new_message = Message.new(params.require(:message).permit!)`

Since there are a specific set of keys we need to create a new message, we can create strong, safe params like the following:

`@new_message = Message.new(params.require(:message).permit(:subject, :body, :folder, :to, :from))`


# TODO The rest

# Strong Params with Dynamic Param Keys

Sometimes param key are dynamic, which can be a little tricker. Here are a few examples of Dynamic keys of how to safely permit dynamic params. You’ll have to research the source of the params to determine what the dynamic values are.

Here’s an example from the method transition_family_members_update in app/[Families Controller](controllers/insured/families_controller.rb):

Original method contained this line:  params_hash = params.permit!.to_h

The permit! Method means that any and all params passed through would be whitelisted. To see what params we actually need, let’s look to the next line:

`params_parser = ::Forms::BulkActionsForAdmin.new(params.permit(@permitted_param_keys).to_h)  `

The class BulkActionsForAdmin will expect some dynamic params (beginning with transition_ followed by id’s). We can use regexes to match the dynamic params:   

`dynamic_transition_params_keys = params.keys.map { |key| key.match(/transition_.*/) }.compact.map(&:to_s).map(&:to_sym)
non_dynamic_params_keys = [:family, :family_actions_id, :qle_id, :action]
@permitted_param_keys = dynamic_transition_params_keys.push(non_dynamic_params_keys).flatten`

*Relevant Pull Request with Dynamic Param Key Fixes*:

- [Pull Request 4114](https://github.com/dchbx/enroll/pull/4114/)

_Dev Tip_: If you’re unsure about params, one tip is to look at cucumbers or walk through the actions directly on an environment and observe the params.