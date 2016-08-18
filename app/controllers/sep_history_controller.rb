class SepHistoryController < ApplicationController

 def index
   @person = Person.find(params[:person_id])
   @family = Family.find(params[:family_id])
 end

end
