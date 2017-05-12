--- !ruby/object:Gem::Specification
name: effective_datatables
version: !ruby/object:Gem::Version
  version: 2.6.14
platform: ruby
authors:
- Code and Effect
autorequire: 
bindir: bin
cert_chain: []
date: 2016-10-07 00:00:00.000000000 Z
dependencies:
- !ruby/object:Gem::Dependency
  name: rails
  requirement: !ruby/object:Gem::Requirement
    requirements:
    - - ! '>='
      - !ruby/object:Gem::Version
        version: 3.2.0
  type: :runtime
  prerelease: false
  version_requirements: !ruby/object:Gem::Requirement
    requirements:
    - - ! '>='
      - !ruby/object:Gem::Version
        version: 3.2.0
- !ruby/object:Gem::Dependency
  name: coffee-rails
  requirement: !ruby/object:Gem::Requirement
    requirements:
    - - ! '>='
      - !ruby/object:Gem::Version
        version: '0'
  type: :runtime
  prerelease: false
  version_requirements: !ruby/object:Gem::Requirement
    requirements:
    - - ! '>='
      - !ruby/object:Gem::Version
        version: '0'
- !ruby/object:Gem::Dependency
  name: kaminari
  requirement: !ruby/object:Gem::Requirement
    requirements:
    - - ! '>='
      - !ruby/object:Gem::Version
        version: '0'
  type: :runtime
  prerelease: false
  version_requirements: !ruby/object:Gem::Requirement
    requirements:
    - - ! '>='
      - !ruby/object:Gem::Version
        version: '0'
- !ruby/object:Gem::Dependency
  name: sass-rails
  requirement: !ruby/object:Gem::Requirement
    requirements:
    - - ! '>='
      - !ruby/object:Gem::Version
        version: '0'
  type: :runtime
  prerelease: false
  version_requirements: !ruby/object:Gem::Requirement
    requirements:
    - - ! '>='
      - !ruby/object:Gem::Version
        version: '0'
- !ruby/object:Gem::Dependency
  name: haml-rails
  requirement: !ruby/object:Gem::Requirement
    requirements:
    - - ! '>='
      - !ruby/object:Gem::Version
        version: '0'
  type: :runtime
  prerelease: false
  version_requirements: !ruby/object:Gem::Requirement
    requirements:
    - - ! '>='
      - !ruby/object:Gem::Version
        version: '0'
- !ruby/object:Gem::Dependency
  name: simple_form
  requirement: !ruby/object:Gem::Requirement
    requirements:
    - - ! '>='
      - !ruby/object:Gem::Version
        version: '0'
  type: :runtime
  prerelease: false
  version_requirements: !ruby/object:Gem::Requirement
    requirements:
    - - ! '>='
      - !ruby/object:Gem::Version
        version: '0'
description: Uniquely powerful server-side searching, sorting and filtering of any
  ActiveRecord or Array collection as well as post-rendered content displayed as a
  frontend jQuery Datatable
email:
- info@codeandeffect.com
executables: []
extensions: []
extra_rdoc_files: []
files:
- MIT-LICENSE
- README.md
- Rakefile
- app/assets/images/dataTables/sort_asc.png
- app/assets/images/dataTables/sort_both.png
- app/assets/images/dataTables/sort_desc.png
- app/assets/javascripts/dataTables/buttons/buttons.bootstrap.js
- app/assets/javascripts/dataTables/buttons/buttons.colVis.js
- app/assets/javascripts/dataTables/buttons/buttons.html5.js
- app/assets/javascripts/dataTables/buttons/buttons.print.js
- app/assets/javascripts/dataTables/buttons/dataTables.buttons.js
- app/assets/javascripts/dataTables/colreorder/dataTables.colReorder.js
- app/assets/javascripts/dataTables/dataTables.bootstrap.js
- app/assets/javascripts/dataTables/jquery.dataTables.js
- app/assets/javascripts/dataTables/jszip/jszip.js
- app/assets/javascripts/dataTables/responsive/dataTables.responsive.js
- app/assets/javascripts/dataTables/responsive/responsive.bootstrap.js
- app/assets/javascripts/effective_datatables.js
- app/assets/javascripts/effective_datatables/bulk_actions.js.coffee
- app/assets/javascripts/effective_datatables/charts.js.coffee
- app/assets/javascripts/effective_datatables/initialize.js.coffee
- app/assets/javascripts/effective_datatables/responsive.js.coffee
- app/assets/javascripts/effective_datatables/scopes.js.coffee
- app/assets/javascripts/vendor/jquery.delayedChange.js
- app/assets/stylesheets/dataTables/buttons/buttons.bootstrap.css
- app/assets/stylesheets/dataTables/colReorder/colReorder.bootstrap.css
- app/assets/stylesheets/dataTables/dataTables.bootstrap.css
- app/assets/stylesheets/dataTables/responsive/responsive.bootstrap.css
- app/assets/stylesheets/effective_datatables.scss
- app/assets/stylesheets/effective_datatables/_overrides.scss.erb
- app/controllers/effective/datatables_controller.rb
- app/helpers/effective_datatables_helper.rb
- app/helpers/effective_datatables_private_helper.rb
- app/models/effective/access_denied.rb
- app/models/effective/active_record_datatable_tool.rb
- app/models/effective/array_datatable_tool.rb
- app/models/effective/datatable.rb
- app/models/effective/effective_datatable/ajax.rb
- app/models/effective/effective_datatable/charts.rb
- app/models/effective/effective_datatable/dsl.rb
- app/models/effective/effective_datatable/dsl/bulk_actions.rb
- app/models/effective/effective_datatable/dsl/charts.rb
- app/models/effective/effective_datatable/dsl/datatable.rb
- app/models/effective/effective_datatable/dsl/scopes.rb
- app/models/effective/effective_datatable/helpers.rb
- app/models/effective/effective_datatable/hooks.rb
- app/models/effective/effective_datatable/options.rb
- app/models/effective/effective_datatable/rendering.rb
- app/views/effective/datatables/_actions_column.html.haml
- app/views/effective/datatables/_bulk_actions_column.html.haml
- app/views/effective/datatables/_bulk_actions_dropdown.html.haml
- app/views/effective/datatables/_chart.html.haml
- app/views/effective/datatables/_datatable.html.haml
- app/views/effective/datatables/_scopes.html.haml
- app/views/effective/datatables/_spacer_template.html
- config/routes.rb
- lib/effective_datatables.rb
- lib/effective_datatables/engine.rb
- lib/effective_datatables/version.rb
- lib/generators/effective_datatables/install_generator.rb
- lib/generators/templates/README
- lib/generators/templates/effective_datatables.rb
- lib/tasks/effective_datatables_tasks.rake
- spec/dummy/README.rdoc
- spec/dummy/Rakefile
- spec/dummy/app/assets/javascripts/application.js
- spec/dummy/app/assets/stylesheets/application.css
- spec/dummy/app/controllers/application_controller.rb
- spec/dummy/app/helpers/application_helper.rb
- spec/dummy/app/views/layouts/application.html.erb
- spec/dummy/config.ru
- spec/dummy/config/application.rb
- spec/dummy/config/boot.rb
- spec/dummy/config/database.yml
- spec/dummy/config/environment.rb
- spec/dummy/config/environments/development.rb
- spec/dummy/config/environments/production.rb
- spec/dummy/config/environments/test.rb
- spec/dummy/config/initializers/backtrace_silencers.rb
- spec/dummy/config/initializers/inflections.rb
- spec/dummy/config/initializers/mime_types.rb
- spec/dummy/config/initializers/secret_token.rb
- spec/dummy/config/initializers/session_store.rb
- spec/dummy/config/initializers/wrap_parameters.rb
- spec/dummy/config/locales/en.yml
- spec/dummy/config/routes.rb
- spec/dummy/db/schema.rb
- spec/dummy/public/404.html
- spec/dummy/public/422.html
- spec/dummy/public/500.html
- spec/dummy/public/favicon.ico
- spec/dummy/script/rails
- spec/effective_datatables_spec.rb
- spec/spec_helper.rb
- spec/support/factories.rb
homepage: https://github.com/code-and-effect/effective_datatables
licenses:
- MIT
metadata: {}
post_install_message: 
rdoc_options: []
require_paths:
- lib
required_ruby_version: !ruby/object:Gem::Requirement
  requirements:
  - - ! '>='
    - !ruby/object:Gem::Version
      version: '0'
required_rubygems_version: !ruby/object:Gem::Requirement
  requirements:
  - - ! '>='
    - !ruby/object:Gem::Version
      version: '0'
requirements: []
rubyforge_project: 
rubygems_version: 2.2.1
signing_key: 
specification_version: 4
summary: Uniquely powerful server-side searching, sorting and filtering of any ActiveRecord
  or Array collection as well as post-rendered content displayed as a frontend jQuery
  Datatable
test_files:
- spec/dummy/app/assets/javascripts/application.js
- spec/dummy/app/assets/stylesheets/application.css
- spec/dummy/app/controllers/application_controller.rb
- spec/dummy/app/helpers/application_helper.rb
- spec/dummy/app/views/layouts/application.html.erb
- spec/dummy/config/application.rb
- spec/dummy/config/boot.rb
- spec/dummy/config/database.yml
- spec/dummy/config/environment.rb
- spec/dummy/config/environments/development.rb
- spec/dummy/config/environments/production.rb
- spec/dummy/config/environments/test.rb
- spec/dummy/config/initializers/backtrace_silencers.rb
- spec/dummy/config/initializers/inflections.rb
- spec/dummy/config/initializers/mime_types.rb
- spec/dummy/config/initializers/secret_token.rb
- spec/dummy/config/initializers/session_store.rb
- spec/dummy/config/initializers/wrap_parameters.rb
- spec/dummy/config/locales/en.yml
- spec/dummy/config/routes.rb
- spec/dummy/config.ru
- spec/dummy/db/schema.rb
- spec/dummy/public/404.html
- spec/dummy/public/422.html
- spec/dummy/public/500.html
- spec/dummy/public/favicon.ico
- spec/dummy/Rakefile
- spec/dummy/README.rdoc
- spec/dummy/script/rails
- spec/effective_datatables_spec.rb
- spec/spec_helper.rb
- spec/support/factories.rb
