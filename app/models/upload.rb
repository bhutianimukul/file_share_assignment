class Upload < ApplicationRecord
  belongs_to :user

  def delete_upload
    puts "Inside delete"
    if File.exist?(self.file_path)
      File.delete(self.file_path)
      true
    else
      false
    end
  end

  def read_text_content
    return nil unless self.content_type == "text/plain"
    File.read(self.file_path)
  rescue StandardError => e
    Rails.logger.error "Error reading file: #{e.message}"
    "Error reading file content"
  end

  def self.convert_size(size_in_bytes)
    if size_in_bytes < 1024
      "#{size_in_bytes} bytes"
    elsif size_in_bytes < 1024 * 1024
      "#{(size_in_bytes / 1024.0).round(2)} KB"
    else
      "#{(size_in_bytes / (1024.0 * 1024.0)).round(2)} MB"
    end
  end

  def self.save_locally(uploaded_file, login_user_id)
    save_path = Rails.root.join("public", "uploads", login_user_id)
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
    file_size = Upload.convert_size uploaded_file.size
    [ file_path, new_file_name, file_size, uploaded_file.content_type ]
  end
end
