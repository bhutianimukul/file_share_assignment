class UploadsController < ApplicationController
  before_action :authenticate_user, except: [ :show, :download ]

  def new
    @upload = Upload.new
  end

  def create
    begin
      uploaded_file = file_params[:file]
      (raise ActiveRecord::ParameterMissing, "Upload file") if uploaded_file.blank?
      file_path, file_name, file_size, content_type = Upload.save_locally(uploaded_file, logged_in_user.id.to_s)
      @upload = logged_in_user.uploads.new({
        name: file_name,
        file_path: file_path,
        size: file_size,
        is_public: file_params[:is_public].nil? ? false : file_params[:is_public],
        content_type: content_type
      })
      respond_to do |format|
        if @upload.save
          format.html { redirect_to "/", notice: "File uploaded successfully." }
          format.json { render json: { message: "File uploaded successfully.", upload: @upload }, status: :created }
        else raise StandardError, "Unable to upload file"         end
      end
    rescue ActionController::ParameterMissing => e
      handle_error(e.message, :bad_request)
    rescue ActiveRecord::RecordNotFound => e
      handle_error(e.message, :bad_request)
    rescue StandardError => e
      handle_error(e.message, :unprocessable_entity)
    end
  end

  def index
    @files = logged_in_user.uploads.order(created_at: :desc)
    respond_to do |format|
      format.html
      format.json { render json: { files: @files } }
    end
  end

  def update
    begin
      (raise ActionController::ParameterMissing, "fileId and is_public_updated are required.") if file_params[:is_public_updated].blank? || params[:file_id].blank?
      file = logged_in_user.uploads.find_by(id: params[:file_id])
      if file
        is_public = file_params[:is_public_updated].to_i == 1 ? true : false
        file.update(is_public: is_public)
        respond_to do |format|
          format.html { redirect_to "/", notice: "File visibility updated successfully." }
          format.json { render json: { status: "Success" } }
        end
      else raise ActiveRecord::RecordNotFound, "File not found"       end
    end
  rescue ActiveRecord::RecordNotFound => e
    handle_error(e.message, :bad_request)
  rescue ActionController::ParameterMissing => e
    handle_error(e.message, :bad_request)
  rescue StandardError => e
    handle_error(e.message, :unauthorized)
  end

  def destroy
    permitted_params = params.permit(:file_id)
    (raise ActionController::ParameterMissing, "fileId is required.") if permitted_params[:file_id].blank?
    file_id = permitted_params[:file_id]
    file = logged_in_user.uploads.find_by!(id: file_id)
    (raise ActiveRecord::RecordNotFound, "Unable to delete") unless file.delete_upload
    respond_to do |format|
      file.destroy
      format.html { redirect_to "/", notice: "File visibility updated successfully." }
      format.json { render json: { status: "Success" } }
    end
  rescue ActiveRecord::RecordNotFound => e
    handle_error(e.message, :bad_request)
  rescue ActionController::ParameterMissing => e
    handle_error(e.message, :bad_request)
  rescue StandardError => e
    handle_error(e.message, :unauthorized)
  end

  def show
    begin
      user_id = params[:user_id]
      (raise ActionController::ParameterMissing, "UserId and fileId are required.") if params[:file_id].blank? || params[:user_id].blank?
      @file_owner = User.find_by(id: user_id)
      (raise StandardError, "Not able to access file") unless @file_owner
      @file = @file_owner.uploads.find_by(id: params[:file_id])
      if @file.present? && File.exist?(@file.file_path) && @file.is_public == true
        @relative_file_path = @file.file_path.sub(Rails.root.join("public").to_s, "")
        @file_content = @file.read_text_content if @file.content_type == "text/plain"
        respond_to do |format|
          format.html
          format.json { render json: { file: @file } }
        end
      else raise ActiveRecord::RecordNotFound, "File not found"       end
    end
  rescue ActiveRecord::RecordNotFound => e
    handle_error(e.message, :bad_request)
  rescue ActionController::ParameterMissing => e
    handle_error(e.message, :bad_request)
  rescue StandardError => e
    handle_error(e.message, :unauthorized)
  end

  def download
    begin
      (raise ActionController::ParameterMissing, "UserId and fileId are required.") if params[:file_id].blank? || params[:user_id].blank?
      user_id = params[:user_id]
      @file_owner = User.find_by(id: user_id)
      (raise StandardError, "Not able to access file") unless @file_owner
      @file = @file_owner.uploads.find_by(id: params[:file_id])
      file_path = @file.file_path
      if @file.present? && File.exist?(file_path) && (@file.is_public == true)
        send_upload_securely @file
      else raise ActiveRecord::RecordNotFound, "File not found.... Only Public files can be downloaded"       end
    end
  rescue ActiveRecord::RecordNotFound => e
    handle_error(e.message, :bad_request)
  rescue ActionController::ParameterMissing => e
    handle_error(e.message, :bad_request)
  rescue StandardError => e
    handle_error(e.message, :unauthorized)
  end

  private

  def send_upload_securely(upload)
    original_filename = File.basename(upload.file_path)
    extension = File.extname(original_filename)
    safe_filename = "#{SecureRandom.hex(8)}#{extension}"
    send_data File.read(upload.file_path), # Not in model because this is a controller method
      filename: safe_filename,
      disposition: "attachment"
  end

  def file_params
    params.require(:upload).permit(:file, :is_public, :file_id, :user_id, :is_public_updated)
  end
end
