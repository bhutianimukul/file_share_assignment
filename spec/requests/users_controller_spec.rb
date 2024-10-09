require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe 'POST #api/signin' do
    let(:valid_attributes) do
      {
        user: {
          email: 'example@gmail.com',
          password: 'Password123',
          username: 'unique_username'
        }
      }
    end

    let(:invalid_attributes) do
      {
        user: {
          email: '',
          password: '',
          username: ''
        }
      }
    end

    context 'with valid attributes' do
      it 'creates a new user and redirects to home for HTML' do
        post :create, params: valid_attributes
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/')
        expect(session[:user_id]).to eq(User.last.id)
      end

      it 'creates a new user and returns JSON response' do
        post :create, params: valid_attributes, as: :json
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['email']).to eq('example@gmail.com')
        expect(json_response['username']).to eq('unique_username')
        expect(session[:user_id]).to eq(User.last.id)
      end
    end

      context 'with invalid attributes' do
        it 'does not create a user and redirects to signup for HTML' do
          post :create, params: invalid_attributes
          expect(response).to redirect_to('/signup')
          expect(flash[:alert]).to be_present
          expect(User.count).to eq(0)
        end

        it 'does not create a user and returns errors in JSON response' do
          post :create, params: invalid_attributes, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to include("Email can't be blank", "Password can't be blank", "Username can't be blank")
          expect(User.count).to eq(0)
        end
      end
  end
end
