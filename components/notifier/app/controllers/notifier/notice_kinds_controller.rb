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
      notices = Notifier::NoticeKind.where(:id.in => params['ids'].split(","))
      
      send_data notices.to_csv,
        :filename => "notices_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv",
        :disposition => 'attachment',
        :type => 'text/csv'
    end

    def upload_notices
      @errors = []
      if file_content_type == 'text/csv'
        notices = Roo::Spreadsheet.open(params[:file].tempfile.path)

        notices.each do |notice_row|
          next if notice_row[1] == 'Notice Number'

          if Notifier::NoticeKind.where(notice_number: notice_row[1]).blank?
            notice = Notifier::NoticeKind.new(market_kind: notice_row[0], notice_number: notice_row[1], title: notice_row[2], description: notice_row[3], recipient: notice_row[4], event_name: notice_row[5])
            notice.template = Template.new(raw_body: notice_row[6])
            unless notice.save
              @errors << "Notice #{notice_row[1]} got errors: #{notice.errors.to_s}"
            end
          else
            @errors << "Notice #{notice_row[1]} already exists."
          end
        end
      else
        @errors << 'Please upload csv format files only.'
      end

      if @errors.empty?
        flash[:notice] = 'Notices loaded successfully.'
      end

      @notice_kinds = Notifier::NoticeKind.all
      @datatable = Effective::Datatables::NoticesDatatable.new

      render :action => 'index'
    end

    def get_tokens
      service = Notifier::Services::NoticeKindService.new(params['market_kind'])
      service.builder = builder_param
      respond_to do |format|
        format.html
        format.json { render json: {tokens: service.editor_tokens} }
      end
    end

    def get_placeholders
      service = Notifier::Services::NoticeKindService.new(params['market_kind'])
      service.builder = builder_param
      respond_to do |format|
        format.html
        format.json { render json: { 
          placeholders: service.placeholders, setting_placeholders: service.setting_placeholders
        } }
      end
    end

    def get_recipients
      recipients = Notifier::Services::NoticeKindService.new(params['market_kind']).recipients

      respond_to do |format|
        format.html
        format.json { render json: {recipients: recipients} }
      end
    end

    private

    def file_content_type
      params[:file].content_type
    end

    def check_hbx_staff_role
      if current_user.blank? || !current_user.has_hbx_staff_role?
        redirect_to main_app.root_path, :flash => { :error => "You must be an HBX staff member" }
      end
    end

    def notice_params
      params.require(:notice_kind).permit(:title, :market_kind, :description, :notice_number, :recipient, :event_name, {:template => [:raw_body]})
    end

    def builder_param
      params['builder'] || 'Notifier::MergeDataModels::EmployerProfile'
    end
  end
end
