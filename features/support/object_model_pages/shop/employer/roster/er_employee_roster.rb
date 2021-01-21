# frozen_string_literal: true

#benefit_sponsors/profiles/employers/employer_profiles/5ff77ba896a4a17b76f892bc?tab=employees
class EmployerEmployeeRoster

  def self.add_new_employee_btn
    'a[class="btn btn-default interaction-click-control-add-new-employee"]'
  end

  def self.upload_employee_roster_btn
    'a[class="btn btn-default interaction-click-control-upload-employee-roster"]'
  end

  def self.choose_file_btn
    'input#file'
  end

  def self.select_file_to_upload_btn
    'label[class="select btn btn-primary"]'
  end

  def self.upload_btn
    'input[class="btn btn-primary interaction-click-control-upload"]'
  end

  def self.download_employee_roster_btn
    'a[class="btn btn-default interaction-click-control-download-employee-roster"]'
  end

  def self.active_only_btn
    'div[id="Tab:active_alone"]'
  end

  def self.active_and_cobra_btn
    'div[id="Tab:active"]'
  end

  def self.cobra_only_btn
    'div[id="Tab:by_cobra"]'
  end

  def self.terminated_btn
    'div[id="Tab:terminated"]'
  end

  def self.all_btn
    'div[id="Tab:all"]'
  end

  def self.actions_btn
    'button[class="btn btn-default dropdown-toggle interaction-click-control-actions"]'
  end
end