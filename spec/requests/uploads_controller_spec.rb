require "rails_helper"

RSpec.describe UploadsController, type: :controller do
  let(:user) { FactoryBot.create(:user, password: "Password123") }
  before do
    session[:user_id] = user.id
  end
  let(:uploaded_file) { Rack::Test::UploadedFile.new(Rails.root.join("Gemfile"), "text/plain") }
  describe "POST #upload" do
    context "with valid parameters" do
      let(:valid_params) { { upload: { file: uploaded_file } } }

      it "User not logged in" do
        session[:user_id] = nil
        post :create, params: valid_params, format: :html
        expect(response).to redirect_to("/signin")
      end

      it "User Logged in" do
        expect {
          post :create, params: valid_params, format: :html
        }.to change { Upload.count }.by(1)
        expect(response).to redirect_to("/")
      end

      it "renders JSON response for file upload" do
        expect {
          post :create, params: valid_params, format: :json
        }.to change { Upload.count }.by(1)
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("File uploaded successfully.")
      end
    end
  end
  context "with invalid parameters" do
    it "raises an error when no file is uploaded" do
      post :create, params: { file: nil }, format: :json
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to include("param is missing")
    end
  end

  describe "GET #index" do
    it "returns a list of uploaded files" do
      get :index, format: :html
      expect(response).to have_http_status(:success)
      expect(assigns(:files)).to eq(user.uploads.order(created_at: :desc))
    end

    it "returns JSON response of uploaded files" do
      get :index, format: :json
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["files"]).to be_an(Array)
    end
  end
  let!(:upload) { FactoryBot.create(:upload, user: user, is_public: false) }
  describe "PUT #update" do
    context "with valid parameters" do
      let(:valid_params) do
        { file_id: upload.id,
         upload: {
          is_public_updated: true
        } }
      end

      it "updates the visibility of the file" do
        put :update, params: valid_params, format: :json
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("Success")
      end

      it "redirects to the root path on HTML format" do
        put :update, params: valid_params, format: :html
        expect(response).to redirect_to("/")
        expect(flash[:notice]).to eq("File visibility updated successfully.")
      end
    end
    context "with missing parameters" do
      it "raises an error when is_public_updated is missing" do
        put :update, params: { file_id: upload.id }, format: :json
        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("param is missing")
      end
    end

    context "with a non-existent file" do
      it "raises an error when the file is not found" do
        put :update, params: { file_id: 99999, is_public_updated: 1 }, format: :json
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with an unauthorized access" do
      it "returns unauthorized status" do
        allow_any_instance_of(UploadsController).to receive(:logged_in_user).and_return(nil)

        put :update, params: { file_id: upload.id, is_public_updated: 1 }, format: :json
        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("User not Logged In")
      end
    end
  end
end
