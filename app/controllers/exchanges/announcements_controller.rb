class Exchanges::AnnouncementsController < ApplicationController
  before_action :check_hbx_staff_role, except: [:dismiss]
  before_action :updateable?, :only => [:create, :destroy]
  def dismiss
    if params[:content].present?
      dismiss_announcements = JSON.parse(session[:dismiss_announcements] || "[]") rescue []
      dismiss_announcements << params[:content].strip
      dismiss_announcements.uniq!
      session[:dismiss_announcements] = dismiss_announcements.to_json
    end
    render json: 'ok'
  end

  def index
    @filter = params[:filter] || 'current'
    @announcements = @filter == 'all' ? Announcement.all : Announcement.current
  end

  def create
    @announcement = Announcement.new(announcement_params)
    if @announcement.save
      redirect_to exchanges_announcements_path, notice: 'Create Announcement Successful.'
    else
      @announcements = Announcement.current
      render :index
    end
  end

  def destroy
    @announcement = Announcement.find_by(id: params[:id])
    @announcement.destroy
    redirect_to exchanges_announcements_path, notice: 'Destroy Announcement Successful.'
  end

  private

  def updateable?
    authorize HbxProfile, :modify_admin_tabs?
  end

  def announcement_params
    params.require(:announcement).permit(
      :content, :start_date, :end_date,
      :audiences => []
    )
  end

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end
end
