require "rails_helper"

RSpec.describe Upload, type: :model do
  user = FactoryBot.create(:user)  # Create a user
  upload = FactoryBot.create(:upload, user: user)

  describe "validations" do
    it "is valid with valid attributes" do
      expect(upload).to be_valid
    end

    it "is not valid without a name" do
      upload.name = nil
      expect(upload).not_to be_valid
    end

    it "is not valid without a file_path" do
      upload1 = FactoryBot.build(:upload, user: user, file_path: nil)
      expect(upload1).not_to be_valid
      expect(upload1.errors[:file_path]).to include("can't be blank")
    end

    it "is not valid without a user" do
      upload.user = nil
      expect(upload).not_to be_valid
    end
  end

  describe "#delete_upload" do
    context "when the file exists" do
      before do
        File.open(upload.file_path, "w") { |f| f.write("test content") }
      end

      it "deletes the file and returns true" do
        expect(File).to exist(upload.file_path)
        expect(upload.delete_upload).to be true
        expect(File).not_to exist(upload.file_path)
      end
    end

    context "when the file does not exist" do
      it "returns false" do
        expect(upload.delete_upload).to be false
      end
    end
  end

  describe "#read_text_content" do
    context "when the content type is text/plain" do
      it "reads and returns the file content" do
        File.open(upload.file_path, "w") { |f| f.write("test content") }
        expect(upload.read_text_content).to eq("test content")
        File.delete(upload.file_path)
      end
    end

    context "when an error occurs during reading" do
      it "logs an error and returns an error message" do
        allow(File).to receive(:read).and_raise(StandardError.new("File read error"))
        expect(Rails.logger).to receive(:error).with("Error reading file: File read error")
        expect(upload.read_text_content).to eq("Unable to Preview")
      end
    end

    describe "convert_size" do
      it "converts bytes to appropriate units" do
        expect(Upload.convert_size(500)).to eq("500 bytes")
        expect(Upload.convert_size(2048)).to eq("2.0 KB")
        expect(Upload.convert_size(2_097_152)).to eq("2.0 MB")
      end
    end

    describe ".save_locally" do
      let(:uploaded_file) do
        double("UploadedFile",
               original_filename: "test_file.txt",
               content_type: "text/plain",
               size: 11,
               read: "This is a test file.")
      end

      it "saves the file locally and returns file details" do
        save_path, new_file_name, file_size, content_type = Upload.save_locally(uploaded_file, user.id.to_s)
        expect(File).to exist(save_path)
        expect(new_file_name).to include("test_file")
        expect(file_size).to eq("11 bytes")
        expect(content_type).to eq("text/plain")
        File.delete(save_path)
      end
    end
  end
end
