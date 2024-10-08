class UploadsController < ApplicationController
  before_action :authenticate_user, except: [ :show, :download ]

  def create
    uploaded_file = file_params[:file]
    file_path, file_name, file_size, content_type = save_file_locally uploaded_file
    @upload = logged_in_user.uploads.new({ name: file_name, file_path: file_path, size: file_size, is_public: file_params[:is_public], content_type: content_type })
    if @upload.save
      redirect_to "/"
    else
      flash[:alert] = "Unable to upload"
      redirect_to "/upload"
    end
  end

  def new
    @upload = Upload.new
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
    is_logged_in_user = logged_in_user.id.to_s == params[:user_id].to_s
    if is_logged_in_user
      file = logged_in_user.uploads.find_by(id: params[:file_id])
      if file
        File.delete(file.file_path)
        file.destroy
        redirect_to "/"
      else
        flash[:alert] = "File not found"
        render json: { error: "File not found" }, status: :bad_request
      end
    else
      flash[:alert] = "Not a logged in user"
      render json: { error: "Not logged in user" }, status: :bad_request
    end
  end

  def show
    user_id = params[:user_id]
    @file_owner = User.find_by(id: user_id)
    if @file_owner
      @file = @file_owner.uploads.find_by(id: params[:file_id])
      if @file.present? && File.exist?(@file.file_path) && @file.is_public == true
        @relative_file_path = @file.file_path.sub(Rails.root.join("public").to_s, "")
        @file_content = read_file_content(@file) if @file.content_type == "text/plain"
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
        send_file_securely @file
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

  def file_params
    params.require(:upload).permit(:file, :is_public, :file_id, :user_id, :is_public_updated)
  end

  def save_file_locally(uploaded_file)
    save_path = Rails.root.join("public", "uploads", logged_in_user.id.to_s)
    FileUtils.mkdir_p(save_path) unless File.directory?(save_path)
    file_name = uploaded_file.original_filename
    base_name = File.basename(file_name, ".*")
    extension = File.extname(file_name)
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")  # Format: YYYYMMDDHHMMSS
    new_file_name = "#{base_name}_#{timestamp}#{extension}"
    file_path = File.join(save_path, new_file_name)
    File.open(file_path, "wb") do |file|
      file.write(uploaded_file.read)
    end
    file_size = convert_file_size uploaded_file.size
    [ file_path, new_file_name, file_size, uploaded_file.content_type ]
  end

  def convert_file_size(size_in_bytes)
    if size_in_bytes < 1024
      "#{size_in_bytes} bytes"
    elsif size_in_bytes < 1024 * 1024
      "#{(size_in_bytes / 1024.0).round(2)} KB"
    else
      "#{(size_in_bytes / (1024.0 * 1024.0)).round(2)} MB"
    end
  end

  def read_file_content(file)
    return nil unless file.content_type == "text/plain"
    File.read(file.file_path)
  rescue StandardError => e
    Rails.logger.error "Error reading file: #{e.message}"
    "Error reading file content"
  end

  def send_file_securely(file)
    original_filename = File.basename(file.file_path)
    extension = File.extname(original_filename)
    safe_filename = "#{SecureRandom.hex(8)}#{extension}"

    send_data File.read(file.file_path),
      filename: safe_filename,
      disposition: "attachment"
  end
end
