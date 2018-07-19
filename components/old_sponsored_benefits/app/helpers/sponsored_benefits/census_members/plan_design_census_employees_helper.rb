module SponsoredBenefits::CensusMembers::PlanDesignCensusEmployeesHelper

  def link_to_add_dependent_fields(name, f, association, classes='')
    new_object = f.object.send(association).klass.new
    id = new_object.object_id

    fields = f.fields_for(association, new_object, fieldset: false, child_index: id) do |builder|
      render(association.to_s.singularize + "_fields", f: builder, child_index: id)
    end
    link_to(content_tag(:span, raw("&nbsp;"), class: 'fui-plus-circle') + name,
            '#', class: "add_fields #{classes}", data: {id: id, fields: fields.gsub("\n", "")})
  end
end