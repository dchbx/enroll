---
title: "Brakeman"
date: 2020-12-22T12:12:25-05:00
draft: false
---

[Brakeman](https://brakemanscanner.org/) is our static code security analysis tool which provides a detailed output of security vulnerabilities. Our Github full suite workflow is configured to run Brakeman on the main app and the engines before running Rspec and Cucumber tests. You can manually run Brakeman with the following command:

`brakeman`

You can generate an HTML report with GitHub links with the following:

`brakeman --github-repo dchbx/enroll -o output.html -o output.txt`

False positives are kept in `config/brakeman.ignore`. There are 5 approved false positives. We currently have some additional ones around mass assignment that in temporarily. Engines MUST be scanned individually and engines have their `config/brakeman.ignore` files.

## Mass Assignment

[Mass Assignment](https://brakemanscanner.org/docs/warning_types/mass_assignment/) brakeman vulnerabilities pose a threat because a user could potentially pass attributes that need to be protected. Some model attributes inherently need to protected from user input, such as `user_id`, `created_at`, `updated_at` to prevent them from creating things for other users or fraudulently updating timestamps.

### Strong Params

Strong parameters are used to protect attributes from a user passing in their own data. Strong params uses the `permit!` method called on a controller's params hash. It whitelists the attributes we want to allow from user input while keeping out any others. Nested structures need to traversed to permit those parameters.

In the file _app/controllers/inboxes_controller.rb_, the following line contained all params permitted:

`@new_message = Message.new(params.require(:message).permit!)`

Since there are a specific set of keys we need to create a new message, we can create strong, safe params like the following:

`@new_message = Message.new(params.require(:message).permit(:subject, :body, :folder, :to, :from))`

### Strong Params with Nested Attributes (Arrays/Hashes)

As a general rule of thumb, strong params with nested attributes *[must come last](https://blog.smartlogic.io/permitting-nested-arrays-using-strong-params-in-rails/)*. Here's an example method from `app/controllers/exchanges/manage_sep_types_controller.rb`:

```
    def forms_qualifying_life_event_kind_form_params
      forms_params = params.require(:forms_qualifying_life_event_kind_form).permit(
        [
          "_id",
          "coverage_end_on",
          "coverage_start_on",
          "created_by",
          "date_options_available",
          "end_on",
          "event_kind_label",
          "is_self_attested",
          "is_visible",
          "market_kind",
          "post_event_sep_in_days",
          "pre_event_sep_in_days",
          "published_by",
          "qle_event_date_kind",
          "reason",
          "start_on",
          "title",
          "tool_tip",
          "updated_by",
          "publish",
          "other_reason",
          effective_on_kinds: []
        ]
      )

      forms_params.merge!({_id: params[:id]}) if params.dig(:id)
      forms_params
    end
```

The attribute `effective_on_kinds` is an array of strings. You can also note that `merge!` is being used on the conditional that the attribute _id_ is present, and the _id_ attribute is previously permitted in the forms_params attribute.

Here's another example from `app/controllers/insured/family_members_controller.rb`:

```
 def permit_dependent_person_params
    params.require(:dependent).permit(:family_id, :same_with_primary, :addresses => {})
  end
```

Again, addresses are embedded within the dependent model and have no protected attributes, so they are permitted as a hash.


### Strong Params with Dynamic Param Keys

Sometimes param keys are dynamic, which can be a little tricker. Here are a few examples of Dynamic keys of how to safely permit dynamic params. You’ll have to research the source of the params to determine what the dynamic values are.

Here’s an example from the method transition_family_members_update in app/[Families Controller](controllers/insured/families_controller.rb):

Original method contained this line:  params_hash = params.permit!.to_h

The permit! Method means that any and all params passed through would be whitelisted. To see what params we actually need, let’s look to the next line:

`params_parser = ::Forms::BulkActionsForAdmin.new(params.permit(@permitted_param_keys).to_h)  `

The class BulkActionsForAdmin will expect some dynamic params (beginning with transition_ followed by id’s). We can use regexes to match the dynamic params:   

`dynamic_transition_params_keys = params.keys.map { |key| key.match(/transition_.*/) }.compact.map(&:to_s).map(&:to_sym)`

The class BulkActionsForAdmin will expect some dynamic params (beginning with transition_ followed by id’s). We can use regexes to match the dynamic params: 
```
dynamic_transition_params_keys = params.keys.map { |key| key.match(/transition_.*/) }.compact.map(&:to_s).map(&:to_sym)
non_dynamic_params_keys = [:family, :family_actions_id, :qle_id, :action]
@permitted_param_keys = dynamic_transition_params_keys.push(non_dynamic_params_keys).flatten`
```
*Relevant Pull Request with Dynamic Param Key Fixes*:

- [Pull Request 4114](https://github.com/dchbx/enroll/pull/4114/)

_Dev Tip_: If you’re unsure about params, one tip is to look at cucumbers or walk through the actions directly on an environment and observe the params.

## Denial of Service

[Denial of Service](https://brakemanscanner.org/docs/warning_types/denial_of_service/)(DoS) is any attack which causes a service to become unavailable for legitimate clients. Denial of Service can be caused by consuming large amounts of network, memory, or CPU resources.
### DoS for Regex

If an attacker can control the content of a regular expression, they may be able to construct a regular expression that requires exponential time to run. Consider the following method in `app/controllers/broker_agencies/broker_roles_controller.rb`:

```
def search_broker_agency
  orgs = Organization.has_broker_agency_profile.or({legal_name: /#{params[:broker_agency_search]}/i}, {"fein" => /#{params[:broker_agency_search]}/i})
end
```

The above query would have allowed a user to pass in any params into the search, including those which have special meanings with regards to Regex. We can fix this by using [Regex.escape](https://www.geeksforgeeks.org/ruby-regexp-escape-function/), which would prevent any characters with special Regex values from being considered.

Since there's a Regex used for user entered params which could lead a potential attack, we're escaping the Regex which would a user from controlling the regular expression.

`Organization.has_broker_agency_profile.or({legal_name: /#{Regexp.escape(params[:broker_agency_search])}/i}, {"fein" => /#{Regexp.escape(params[:broker_agency_search])}/i})`

*Relevant Pull request for Denial of Service fixes*:

- [Pull Request 4102](https://github.com/dchbx/enroll/pull/4102/)

Dev-tip: Always escape the Regex if it's controlled by end user. Examples to consider are params, DB values.

## Dangerous Send

[Dangerous Send](https://brakemanscanner.org/docs/warning_types/dangerous_send/) refers to unsafely using unfiltered user data to select a Class or Method to be dynamically sent.
It is much safer to whitelist the desired target or method.

### Malicious attack Dangerous Send

If an attacker tries to access the private or restricted methods in the application, he/she can get the data which they're not supposed to access or get hold of.

In the file app/controllers/exchanges/broker_applicants_controller.rb, the following line was using the send method on a Person object.
Had the attacker passed a different status as params, he would've got the information that he wasn't supposed to.

```
@status = status_params[:status] || 'applicant'
@people = @people.send("broker_role_#{@status}") if @people.respond_to?("broker_role_#{@status}")
```
As part of the fix, we are white listing the status params so that only valid `BROKER_ROLE_STATUS_TYPES` are allowed to be sent and if anything else is attempted it will fallback to `'applicant'`.
```
@status = status_params[:status] || 'applicant'
@status = BrokerRole::BROKER_ROLE_STATUS_TYPES.include?(status_params[:status]) ? status_params[:status] : 'applicant'
```

*Relevant pull request for Dangerous Send reference*:

- [Pull Request 4102](https://github.com/dchbx/enroll/pull/4102/)

Dev-tip: Never use a send method with params as it poses a threat.

## Redirect

[Redirects](https://brakemanscanner.org/docs/warning_types/redirect/) which rely on user-supplied values can be used to “spoof” websites or hide malicious links in otherwise harmless-looking URLs.
They can also allow access to restricted areas of a site if the destination is not validated.

### URI Parse

If an attacker wants to redirect the traffic from the application to his desired website or an malicious site, he can construct a URL that sends users from our trusted site to some where else of their choosing.

In the file, components/benefit_sponsors/app/controllers/benefit_sponsors/profiles/employers/employer_profiles_controller.rb, we have a redirect which reads from roster_upload_form.
If the attacker adds his desired website to the redirect, all the traffic that hits that page would be redirected to his site.

`redirect_to @roster_upload_form.redirection_url`

The fix for this issue would be to parse the url or restrict redirect from user input params. This way no other host can be substituted.

`redirect_to URI.parse(@roster_upload_form.redirection_url).to_s`

*Relevant pull request for redirect error reference*:

- [Pull Request 4102](https://github.com/dchbx/enroll/pull/4102/)

Dev-tip: Never use a redirect path without parsing the url or restricting the path.

## File Access

[File Access](https://brakemanscanner.org/docs/warning_types/file_access/) is when user input when accessing files (local or remote) will raise a warning in Brakeman. Consider this method in `app/controllers/documents_controller.rb`:
```
  def download_employer_document
    send_file params[:path]
  end
```

The above invoking of `send_file` could allow the user to download any file on the server with the specified parameters. To fix this security risk, we need the code to limit what files can be downloaded more specifically.

```
 def download_employer_document
    document = BenefitSponsors::Documents::EmployerAttestationDocument.find_by(identifier: params[:path])
    send_file document.identifier
  rescue StandardError => e
    redirect_back(fallback_location: root_path, :flash => {error: e.message})
  end

```

In the above fix, we've specified the exact path that can be accessed by the value in the params, and added a rescue to gracefully redirect back to the root path.


*Relevant pull request for file access reference*:
-[Pull Request 3791](https://github.com/dchbx/enroll/pull/3791)

## Dynamic Render Path

[Dynamic Render Path](https://brakemanscanner.org/docs/warning_types/dynamic_render_paths/) is when a call to render uses a dynamically generated path, template name, file name, or action, there is the possibility that a user can access templates that should be restricted. The issue may be worse if those templates execute code or modify the database. Consider the following method in `app/controllers/employers/census_employees_controller.rb`:

```
  def confirm_effective_date
    confirmation_type = params[:type]
    render "#{confirmation_type}_effective_date"
  end
```

In the above example, a user could theoretically render any template ending with "effective_date". We can fix this by limiting the input that can be rendered:

```
  # The CONFIRMATION_EFFECTIVE_DATE_TYPES is equal to CONFIRMATION_EFFECTIVE_DATE_TYPES = ['cobra', 'rehire', 'terminate'].freeze
  def confirm_effective_date
    confirmation_type = params[:type]
    return unless CensusEmployee::CONFIRMATION_EFFECTIVE_DATE_TYPES.include?(confirmation_type)
    render "#{confirmation_type}_effective_date"
  end
```

This wasn't a major vulnerability because of the string interpolation, but it shows the dangerous of allowing user input to select a view.

*Relevant pull request for dynamic render path reeference*:
-[Pull Request 4097](https://github.com/dchbx/enroll/pull/4097)


## Remote Code Execution

Brakeman reports on several cases of [Remote Code Execution](https://brakemanscanner.org/docs/warning_types/remote_code_execution/) in which a user is able to control and execute code in ways unintended by application authors.

## Safe use of Constantize

When we use unsafe reflection method constantize,eval, attacker may be able to halt the execution of a thread/the attacker would be able to access restricted information that he isn't supposed to.

In the file app/models/census_employee.rb, we are using constantize which was problematic.

`builder = notice_trigger.notice_builder.camelize.constantize.new(self)`

As part of the fix, we're white listing the notice class names, which would put a lock on the access.

`['IvlNotices::VariableIvlRenewalNotice','ShopEmployerNotices::OutOfPocketNotice'].find { |notice| notice == notice_type.classify }.safe_constantize`

*Relevant pull request for Remote Code Execution reference*:

- [Pull Request 4126](https://github.com/dchbx/enroll/pull/4126/)

_Dev Tip_: Never use eval, constantize