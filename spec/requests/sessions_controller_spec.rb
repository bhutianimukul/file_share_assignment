require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  describe "POST #api/login" do
    let(:user) { FactoryBot.create(:user, password: "Password123") }
    context "when username and password are present" do
      context "with valid credentials" do
        let(:valid_params) { { user: { username: user.username, password: "Password123" } } }

        it "logs in successfully and redirects for HTML request" do
          post :create, params: valid_params, format: :html
          expect(session[:user_id]).to eq(user.id)
          expect(response).to redirect_to("/")
        end

        it "returns success message and user data for JSON request" do
          post :create, params: valid_params, format: :json
          expect(session[:user_id]).to eq(user.id)
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Logged in successfully.")
          expect(json_response["username"]).to eq(user.username)
        end
      end

      context "with invalid password" do
        let(:invalid_password_params) { { user: { username: user.username, password: "WrongPassword" } } }

        it "renders error and redirects for HTML request" do
          post :create, params: invalid_password_params, format: :html
          expect(session[:user_id]).to be_nil
          expect(response).to redirect_to("/signin")
          expect(flash[:alert]).to eq("Invalid username/password")
        end

        it "returns error message for JSON request" do
          post :create, params: invalid_password_params, format: :json
          expect(response).to have_http_status(:unauthorized)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Invalid username/password")
        end
      end

      context "when username or password is missing" do
        let(:missing_params) { { user: { username: "", password: "" } } }

        it "renders error for missing username/password and redirects for HTML request" do
          post :create, params: missing_params, format: :html
          expect(response).to redirect_to("/signin")
          expect(flash[:alert]).to include("Username and password are required.")
        end

        it "returns error for JSON request" do
          post :create, params: missing_params, format: :json
          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to include("Username and password are required.")
        end
      end

      context "when user does not exist" do
        let(:non_existing_user_params) { { user: { username: "non_existing_user", password: "Password123" } } }

        it "renders error for HTML request" do
          post :create, params: non_existing_user_params, format: :html
          expect(response).to redirect_to("/signin")
          expect(flash[:alert]).to include("User not found")
        end

        it "returns error message for JSON request" do
          post :create, params: non_existing_user_params, format: :json
          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to include("User not found")
        end
      end
    end

    describe "DELETE #destroy" do
      context "when the user is logged in" do
        let(:user) { FactoryBot.create(:user, password: "Password123") }

        before do
          session[:user_id] = user.id
        end

        it "logs out the user and redirects to the signin page" do
          delete :destroy, format: :html

          expect(session[:user_id]).to be_nil
          expect(response).to redirect_to("/signin")
          expect(flash[:notice]).to eq("Logged out successfully.")
        end

        it "logs out the user and returns success message for JSON request" do
          delete :destroy, format: :json

          expect(session[:user_id]).to be_nil
          expect(response.content_type).to eq("application/json; charset=utf-8")
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)["message"]).to eq("Success")
        end
      end

      context "when the user is not logged in" do
        it "raises RecordNotFound and handles the error" do
          delete :destroy, format: :html
          expect(response).to redirect_to("/signin")
          expect(flash[:alert]).to include("Logged In user not found")
        end
      end

      it "raises RecordNotFound for JSON request" do
        delete :destroy, format: :json
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Logged In user not found")
      end
    end
  end
end
