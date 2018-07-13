class Uis::Bootstrap3ExamplesController < ApplicationController

  def index
    @family_data_table = Effective::Datatables::ExampleDatatable.new
  end

  def getting_started
  end

  def components
  end

  def show
  end

end
