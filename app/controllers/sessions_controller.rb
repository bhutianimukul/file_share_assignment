class SessionsController < ApplicationController
  def new
    session[:user_id] = nil
    @user = User.new
  end

  def create
    (raise ActionController::ParameterMissing, "Username and password are required.") if user_params[:username].blank? || user_params[:password].blank?
    @user = User.find_by(username: user_params[:username])
    respond_to do |format|
      (raise ActiveRecord::RecordNotFound, "User not found") unless @user
      (raise StandardError, "Invalid username/password") unless @user.authenticate(user_params[:password])
      session[:user_id] = @user.id
      format.html { redirect_to "/", notice: "Logged in successfully." }
      format.json { render json: { message: "Logged in successfully.", username: @user.username, id: @user.id }, status: :ok }
    end
  rescue ActiveRecord::RecordNotFound => e
    handle_error(e.message, :bad_request, "/signin")
  rescue ActionController::ParameterMissing => e
    handle_error(e.message, :bad_request, "/signin")
  rescue StandardError => e
    handle_error(e.message, :unauthorized, "/signin")
  end

  def destroy
    (raise ActiveRecord::RecordNotFound, "Logged In user not found") unless is_logged_in?
    session[:user_id] = nil
    respond_to do |format|
      format.html { redirect_to "/signin", notice: "Logged out successfully." }
      format.json { render json: { message: "Success" }, status: :ok }
    end
  rescue ActiveRecord::RecordNotFound => e
    handle_error(e.message, :bad_request, "/signin")
  end

  private
  def user_params
    params.require(:user).permit(:password, :username)
  end
end
