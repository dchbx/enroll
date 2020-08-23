# frozen_string_literal: true

module ApplicationHelper
  def menu_tab_class(a_tab, current_tab)
    a_tab == current_tab ? raw(" class=\"active\"") : ""
  end
end
