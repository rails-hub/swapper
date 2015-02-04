class UserController < ApiController

  skip_before_filter :check_token!

  # username - string
  # password - string
  # email - string
  # phone - string (optional)
  def register_api
    # begin
    email = register_api_params[:email].blank? ? "not_provided#{User.last.present? ? User.last.id : 0}@not_provided.com" : register_api_params[:email].downcase
    password = register_api_params[:password].blank? ? 'not_provided' : register_api_params[:password]
    @user = User.find_by_device_token(register_api_params[:device_token])
    @user = User.find_by_email(email) if @user.blank?
    if @user.blank?
      @user = User.create(:email => email, :username => register_api_params[:username], :password => password, :device_token => register_api_params[:device_token], :lat => register_api_params[:lat], :lng => register_api_params[:lng])
      images = images_with_distance(@user, register_api_params[:distance])
      render :json => {:user => {:id => @user.id, :username => @user.username, :auth_token => @user.auth_token, :device_token => @user.device_token, :notification_count => @user.notification_count, :created_at => @user.created_at, :updated_at => @user.updated_at, :lng => @user.lng, :lat => @user.lat}, :images => images}
    else
      @user.update_attributes(:lng => register_api_params[:lng].to_f, :lat => register_api_params[:lat].to_f)
      images = images_with_distance(@user, register_api_params[:distance])
      render :json => {:user => {:id => @user.id, :username => @user.username, :auth_token => @user.auth_token, :device_token => @user.device_token, :notification_count => @user.notification_count, :created_at => @user.created_at, :updated_at => @user.updated_at, :lng => @user.lng, :lat => @user.lat}, :images => images}
    end
    # rescue Exception => e
    #   error "Please provide all required fields or Something went wrong."
    # end
  end

  def update_profile
    @find_user = User.find_by_auth_token(params[:auth_token]) unless params[:auth_token].nil?
    if @find_user.nil?
      error "No such user found."
    else
      begin
        @find_user.username = params[:username]
        @find_user.email = params[:email]
        @find_user.phone = params[:phone]
        @find_user.save(:validate => false)
        json @find_user
      rescue ActiveRecord::RecordNotFound
        error "Error updating profile."
      end
    end
  end

  def update_password
    @user = User.find_by_auth_token(params[:auth_token]) unless params[:auth_token].nil?
    if @user.valid_password?(params[:old_password])
      begin
        @user.password = params[:new_password]
        @user.save(:validate => true)
        success "Password Changed Successfully"
      rescue
        error "Something went wrong"
      end
    else
      error "Old Password Doesn't match"
    end
  end

  def admin_log_in
  end

  # username - string (optional)
  # password - string (optional)
  # auth_token - string (optional)
  def login_api
    @user = User.find_for_database_authentication({:username => params[:username].downcase})

    if (!@user.nil?)
      if (!@user.valid_password?(params[:password]))
        @user = nil
      end
    end

    if (@user.nil?)
      @user = User.find_by_auth_token(params[:auth_token]) unless params[:auth_token].nil?
    else
      @user.generate_auth_token
    end

    if @user.nil?
      # Do nothing
      error "Your username or password was incorrect."
    else
      render json: @user
    end
  end

  def update_device_token
    @user = User.find_by_auth_token(params[:auth_token]) unless params[:auth_token].nil?
    if (!@user.nil?)
      begin
        @user.update_attribute('device_token', device_token_api_params[:device_token])
        success "Device Token updated"
      rescue
        error "Something went wrong"
      end
    else
      error "No such user exist"
    end
  end

  def reset_badge_api
    user = User.find_by_auth_token(params[:auth_token]) unless params[:auth_token].nil?
    unless user.blank?
      begin
        user.update_attribute(:notification_count, 0)
        success "Reset Successful."
      rescue
        error "Something went wrong"
      end
    else
      error "No such user found."
    end
  end

  def upload_pic
    user = User.find_by_auth_token(pic_api_params[:auth_token])
    unless user.blank?
      user.update_attributes(:lng => pic_api_params[:lng].to_f, :lat => pic_api_params[:lat].to_f)
      @id = 0
      data_value = pic_api_params[:image_data]
      StringIO.open(Base64.decode64(data_value)) do |data|
        img = UserImage.new
        img.avatar = data
        img.user_id = user.id
        @save_img = img.save
        @url = img.avatar.url
        img.update_attributes(:url => @url, :box_id => pic_api_params[:box_id], :title => pic_api_params[:title], :lat => pic_api_params[:lat], :lng => pic_api_params[:lng])
        @url_medium = img.avatar.url(:medium)
        @url_thumb = img.avatar.url(:thumb)
        @id = img.id
        # PushController.push_message_to_user "Picture was uploaded", user, "Picture Uploaded Successfully", @id, @url, @url_medium, @url_thumb
      end
      #Once image upload is successful check users with less than 20 meter range difference from this user
      puts "THIS-IS-USER::::", user.inspect
      if @id != 0
        render :json => {:status => 200, :message => "Image uploaded successfully", :id => @id, :url_original => @url, :url_medium => @url_medium, :url_thumb => @url_thumb}
      else
        render :json => {:status => 500, :message => "Image upload failed"}
      end
    else
      error "No such user found."
    end
  end

  def user_images
    user = User.find_by_auth_token(user_img_params[:auth_token])
    unless user.blank?
      user.update_attributes(:lng => user_img_params[:lng].to_f, :lat => user_img_params[:lat].to_f)
      u = User.where('id != ?', user.id).first
      find_distance = distance user.lat, user.lng, u.lat, u.lng
      # if find_distance <= 20
      render :json => {:status => 200, :message => "Success", :user_id => u.id, :urls => u.user_images.pluck(:url, :created_at)}
      # else
      #   render :json => {:status => 200, :message => "You are at longer distance than 20m from the other device."}
      # end
    else
      error "No such user found."
    end
  end

  def download_pic
    u = User.find_by_auth_token(pic_d_api_params[:auth_token])
    unless u.blank?
      u.update_attribute('lng', register_api_params[:lng].to_f)
      u.update_attribute('lat', register_api_params[:lat].to_f)
      pic = UserImage.find_by_id(register_api_params[:pic_id])
      unless pic.blank?
        #check users with less than 20 meter range difference from this user
        user = User.where('id = ?', pic.user_id)
        find_distance = distance user.lat, user.lng, u.lat, u.lng
        if find_distance <= 20
          render :json => {:can_download => true}
        else
          render :json => {:can_download => false}
        end
      end
    else
      error "No such user found."
    end

  end

  def images_with_distance(user, dis)
    images = nil
    # images with required distance
    users_images = []
    i = 0
    UserImage.where('user_id = ?', user.id).order("created_at DESC").each do |f|
      find_distance = distance user.lat, user.lng, f.lat, f.lng
      puts "AAAAAAAAA", user.lat.inspect
      puts "AAAAAAAAA", f.lat.inspect
      puts "AAAAAAAAA", find_distance.inspect
      puts "AAAAAAAAA", find_distance.inspect
      if find_distance <= dis.to_f
        users_images << f
        if i >= 5
          return users_images
        end
        i = i + 1
      end
    end
    users_images
  end

  def distance lat1, long1, lat2, long2
    dtor = Math::PI/180
    r = 6378.14*1000

    rlat1 = lat1 * dtor
    rlong1 = long1 * dtor
    rlat2 = lat2 * dtor
    rlong2 = long2 * dtor

    dlon = rlong1 - rlong2
    dlat = rlat1 - rlat2

    a = power(Math::sin(dlat/2), 2) + Math::cos(rlat1) * Math::cos(rlat2) * power(Math::sin(dlon/2), 2)
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))
    d = r * c

    return d
  end


  def power(num, pow)
    num ** pow
  end


  def register_api_params
    params.permit(:username, :password, :email, :device_token, :lng, :lat, :distance)
  end

  def login_api_params
    params.permit(:username, :password, :auth_token)
  end

  def device_token_api_params
    params.permit(:device_token, :auth_token)
  end

  def profile_api_params
    params.permit(:auth_token, :username, :email)
  end

  def pic_api_params
    params.permit(:auth_token, :username, :image_data, :lng, :lat, :box_id, :title)
  end

  def user_img_params
    params.permit(:auth_token, :lng, :lat)
  end

  def pic_d_api_params
    params.permit(:pic_id, :auth_token, :image_data, :lng, :lat)
  end

end
