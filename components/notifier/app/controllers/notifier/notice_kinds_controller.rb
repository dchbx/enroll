module Notifier
  class NoticeKindsController < Notifier::ApplicationController

    before_action :check_hbx_staff_role
    
    layout 'notifier/single_column'

    def index
      @notice_kinds = Notifier::NoticeKind.all
      @datatable = Effective::Datatables::NoticesDatatable.new
      @errors = []
    end

    def show
      if params['id'] == 'upload_notices'
        redirect_to notice_kinds_path
      end
    end

    def new
      @notice_kind = Notifier::NoticeKind.new
      @notice_kind.template = Notifier::Template.new
    end

    def edit
      @notice_kind = Notifier::NoticeKind.find(params[:id])
      render :layout => 'notifier/application'
    end

    def create
      template = Template.new(notice_params.delete('template'))
      notice_kind = NoticeKind.new(notice_params)
      notice_kind.template = template

      if notice_kind.save
        flash[:notice] = 'Notice created successfully'
        redirect_to notice_kinds_path
      else
        @errors = notice_kind.errors.messages
        
        @notice_kinds = Notifier::NoticeKind.all
        @datatable = Effective::Datatables::NoticesDatatable.new

        render :action => 'index'
      end
    end

    def update
      notice_kind = Notifier::NoticeKind.find(params['id'])
      notice_kind.update_attributes(notice_params)

      flash[:notice] = 'Notice content updated successfully'
      redirect_to notice_kinds_path
    end

    def preview
      notice_kind = Notifier::NoticeKind.find(params[:id])
      notice_kind.generate_pdf_notice

      send_file "#{Rails.root}/tmp/#{notice_kind.title.titleize.gsub(/\s+/, '_')}.pdf", 
        :type => 'application/pdf', 
        :disposition => 'inline'
    end

    def delete_notices
      Notifier::NoticeKind.where(:id.in => params['ids']).each do |notice|
        notice.delete
      end

      flash[:notice] = 'Notices deleted successfully'
      redirect_to notice_kinds_path
    end

    def download_notices
      # notices = Notifier::NoticeKind.where(:id.in => params['ids'])

      send_data Notifier::NoticeKind.to_csv, 
        :filename => "notices_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv",
        :disposition => 'attachment',
        :type => 'text/csv'
    end

    def upload_notices
      notices = Roo::Spreadsheet.open(params[:file].tempfile.path)
      @errors = []

      notices.each do |notice_row|
        next if notice_row[0] == 'Notice Number'

        if Notifier::NoticeKind.where(notice_number: notice_row[0]).blank?
          notice = Notifier::NoticeKind.new(notice_number: notice_row[0], title: notice_row[1], description: notice_row[2], recipient: notice_row[3], event_name: notice_row[4])
          notice.template = Template.new(raw_body: notice_row[5])
          unless notice.save
            @errors << "Notice #{notice_row[0]} got errors: #{notice.errors.to_s}"
          end
        else
          @errors << "Notice #{notice_row[0]} already exists."
        end
      end

      if @errors.empty?
        flash[:notice] = 'Notices loaded successfully.'
      end

      @notice_kinds = Notifier::NoticeKind.all
      @datatable = Effective::Datatables::NoticesDatatable.new

      render :action => 'index'
    end

    def get_tokens
      builder = params['builder'] || 'Notifier::MergeDataModels::EmployerProfile'
      token_builder = builder.constantize.new
      tokens = token_builder.editor_tokens
      # placeholders = token_builder.place_holders

      respond_to do |format|
        format.html
        format.json { render json: {tokens: tokens} }
      end
    end

    def get_placeholders
      placeholders = Notifier::MergeDataModels::EmployerProfile.new.place_holders

      respond_to do |format|
        format.html
        format.json {render json: placeholders}
      end
    end

    private

    def check_hbx_staff_role
      if current_user.blank? || !current_user.has_hbx_staff_role?
        redirect_to main_app.root_path, :flash => { :error => "You must be an HBX staff member" }
      end
    end

    def notice_params
      params.require(:notice_kind).permit(:title, :description, :notice_number, :recipient, {:template => [:raw_body]})
    end
  end
end
