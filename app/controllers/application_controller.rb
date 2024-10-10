class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  skip_before_action :verify_authenticity_token
  helper_method :logged_in_user, :is_logged_in?, :handle_error

  def logged_in_user
    if session[:user_id]
      @logged_in_user ||= User.find_by(id: session[:user_id])
    end
  end

  def is_logged_in?
    logged_in_user
    !@logged_in_user.nil?
  end

  def authenticate_user
    respond_to do |format|
      format.html { redirect_to "/signin" unless is_logged_in? }
      format.json { (render json: { error: "User not Logged In" }, status: :unauthorized) unless is_logged_in? }
    end
  end

  def handle_error(error_message, status, route = "/")
    respond_to do |format|
      format.html do
        flash[:alert] = error_message
        redirect_to route
      end
      format.json { render json: { error: error_message }, status: status }
    end
  end
end
