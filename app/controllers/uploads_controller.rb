class UploadsController < ApplicationController
  before_action :authenticate_user, except: [ :show, :download ]

  def new
    @upload = Upload.new
  end

  def create
    uploaded_file = file_params[:file]
    file_path, file_name, file_size, content_type = Upload.save_locally(uploaded_file, logged_in_user.id.to_s)
    @upload = logged_in_user.uploads.new({ name: file_name, file_path: file_path, size: file_size, is_public: file_params[:is_public], content_type: content_type })
    if @upload.save
      redirect_to "/"
    else
      flash[:alert] = "Unable to upload"
      redirect_to "/upload"
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
    puts "Inside File update"
    file = logged_in_user.uploads.find_by(id: params[:file_id])
    if file
      is_public = file_params[:is_public_updated].to_i == 1 ? true : false
      file.update(is_public: is_public)
      respond_to do |format|
        format.html { redirect_to "/", notice: "File visibility updated successfully." }
        format.json { render json: { status: "Success" } }
      end
    else
      render json: { error: "File Not found" }, status: :bad_request
    end
  end

  def destroy
    permitted_params = params.permit(:file_id, :user_id)
    is_logged_in_user = logged_in_user.id.to_s == permitted_params[:user_id].to_s
    if is_logged_in_user
      file_id = permitted_params[:file_id]
      file = logged_in_user.uploads.find_by!(id: file_id)
      if file.delete_upload
        file.destroy
        redirect_to "/"
      else
        render json: { error: "File not found" }, status: :bad_request
      end
    else
      render json: { error: "Not logged in user" }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "File not found" }, status: :not_found
  end

  def show
    user_id = params[:user_id]
    @file_owner = User.find_by(id: user_id)
    if @file_owner
      @file = @file_owner.uploads.find_by(id: params[:file_id])
      if @file.present? && File.exist?(@file.file_path) && @file.is_public == true
        @relative_file_path = @file.file_path.sub(Rails.root.join("public").to_s, "")
        @file_content = @file.read_text_content if @file.content_type == "text/plain"
        respond_to do |format|
          format.html
          format.json { render json: { file: @file } }
        end
      else
        render json: { error: "File not found" }, status: :bad_request
      end
    else
      render json: { error: "Invalid Url" }, status: :bad_request
    end
  end

  def download
    user_id = params[:user_id]
    @file_owner = User.find_by(id: user_id)
    if @file_owner
      @file = @file_owner.uploads.find_by(id: params[:file_id])
      file_path = @file.file_path

      if @file.present? && File.exist?(file_path) && (@file.is_public == true)
        send_upload_securely @file
      else
        flash[:alert] = "File not found"
        render json: { error: "File not found.... Only Public files can be downloaded" }, status: :bad_request
      end
    else
      flash[:alert] = "Not a logged in user"
      render json: { error: "Not logged in user" }, status: :bad_request
    end
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
