class ApiController < ApplicationController
  respond_to :json
  before_filter :check_token!
  skip_before_filter :verify_authenticity_token

  @logged_user = nil

  def error errorString
    render json: {errors: errorString}
  end

  def success successString
    render json: {'success' => successString}
  end

  def post post_object

    if post_object.nil?
      render json: {'error' => true}
    else
      if post_object.save
        render json: post_object
      else
        render json: {errors: post_object.errors.full_messages}
      end
    end
  end

  # Output an object as json
  def json object
    if object.nil?
      render json: {'error' => true}
    else
      render json: object
    end
  end

  def token_test
    json :succes => 1
  end

  def check_token!
    if params[:auth_token].nil?
      render json: {errors: 'You have been logged out.', logged_out: true}
      return
    end

    u=User.find_by_auth_token(params[:auth_token])
    if (u.nil?)
      render json: {errors: 'You have been logged out.', logged_out: true}
      return
    end
    @logged_user = u
  end

  def get get_object
    if get_object.nil?
      render json: {errors: 'A remote error occurred.'}
    else
      render json: get_object
    end
  end

end
