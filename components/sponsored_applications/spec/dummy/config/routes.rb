Rails.application.routes.draw do

  mount SponsoredApplications::Engine => "/sponsored_applications"
end
