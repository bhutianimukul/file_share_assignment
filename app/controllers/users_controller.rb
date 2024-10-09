class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new user_params
    respond_to do |format|
      if @user.save
        session[:user_id] = @user.id
        format.html { redirect_to "/", notice: "User was successfully created." }
        format.json { render json: @user, status: :created }
      else
        flash[:alert] = @user.errors.full_messages.to_sentence
        format.html { redirect_to "/signup" }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end


  private

  def user_params
    params.require(:user).permit(:email, :password, :username)
  end
end
