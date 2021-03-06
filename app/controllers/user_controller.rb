class UserController < ApiController

  skip_before_filter :check_token!

  # username - string
  # password - string
  # email - string
  # phone - string (optional)
  def register_api
    # begin
    email = "not_provided#{User.last.present? ? User.last.id : 0}@not_provided.com"
    password = 'not_provided'
    @user = User.find_by_device_token(register_api_params[:device_token])
    @user = User.find_by_email(email) if @user.blank?
    if @user.blank?
      user = @user
      @user = User.new(:email => email, :username => register_api_params[:username], :password => password, :device_token => register_api_params[:device_token], :lat => register_api_params[:lat], :lng => register_api_params[:lng])
      @user.save!
      # images = images_with_distance(@user, register_api_params[:distance])
      images = UserImage.where('user_id = ?', @user.id).order("created_at DESC").limit(6)
      images = add_likes(images)
      render :json => {:user => {:id => @user.id, :username => @user.username, :auth_token => @user.auth_token, :device_token => @user.device_token, :notification_count => @user.notification_count, :created_at => @user.created_at, :updated_at => @user.updated_at, :lng => @user.lng, :lat => @user.lat}, :images => images}
    else
      @user.update_attributes(:lng => register_api_params[:lng].to_f, :lat => register_api_params[:lat].to_f)
      # images = images_with_distance(@user, register_api_params[:distance])
      images = UserImage.where('user_id = ?', @user.id).order("created_at DESC").limit(6)
      images = add_likes(images)
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
        puts "AAAAAAAAAAAAAAAAA", img.errors.inspect
        puts "AAAAAAAAAAAAAAAAA", img.errors.inspect
        puts "AAAAAAAAAAAAAAAAA", img.errors.inspect
        if @save_img = img.save
          puts "ImageSaved::ImageSaved::ImageSaved"
        else
          puts "ImageNotSaved::ImageNotSaved::ImageNotSaved"
        end
        @url = img.avatar.url.to_s.gsub('s3.amazonaws.com', 's3-us-west-2.amazonaws.com')
        img.update_attributes(:url => @url, :box_id => pic_api_params[:box_id], :title => pic_api_params[:title], :lat => pic_api_params[:lat], :lng => pic_api_params[:lng], :category => pic_api_params[:category])
        @url_medium = img.avatar.url(:medium).to_s.gsub('s3.amazonaws.com', 's3-us-west-2.amazonaws.com')
        @url_thumb = img.avatar.url(:thumb).to_s.gsub('s3.amazonaws.com', 's3-us-west-2.amazonaws.com')
        @id = img.id
        # PushController.push_message_to_user "Picture was uploaded", user, "Picture Uploaded Successfully", @id, @url, @url_medium, @url_thumb
      end

      #Once image upload is successful check users with less than 20 meter range difference from this user
      puts "THIS-IS-USER::::", user.inspect
      if @id != 0 && @id != nil
        puts "id::id::id::id::id::id::", @id.inspect
        puts "id::id::id::id::id::id::", @id.inspect
        puts "id::id::id::id::id::id::", @id.inspect
        delete_all_others_of_this_box(@id, user, pic_api_params[:box_id])
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
      if find_distance <= 20
        images = add_likes(u.user_images.pluck(:url, :created_at))
        render :json => {:status => 200, :message => "Success", :user_id => u.id, :urls => images}
      else
        render :json => {:status => 200, :message => "You are at longer distance than 20m from the other device."}
      end
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

  def like_pic
    u = User.find_by_auth_token(like_pic_params[:auth_token])
    unless u.blank?
      pic = UserImage.find_by_id(like_pic_params[:pic_id])
      unless pic.blank?
        find_pic = UserLike.where('user_id = ? and user_image_id = ?', u.id, pic.id)
        if find_pic.blank?
          user_like = UserLike.new(:user_id => u.id, :user_image_id => pic.id)
          if user_like.save
            render :json => {:message => "Success", :image_id => pic.id, :like_count => UserLike.find_all_by_user_image_id(pic.id).count}
          else
            error "Something went wrong."
          end
        else
          error "You already liked this picture."
        end
      else
        error "No such Picture found."
      end
    else
      error "No such user found."
    end

  end

  def report_pic
    u = User.find_by_auth_token(like_pic_params[:auth_token])
    unless u.blank?
      pic = UserImage.find_by_id(like_pic_params[:pic_id])
      unless pic.blank?
        find_report = UserReport.find_by_user_id_and_user_image_id(u.id, pic.id)
        if find_report.blank?
          user_report = UserReport.new(:user_id => u.id, :user_image_id => pic.id)
          if user_report.save
            pic_report = UserReport.find_all_by_user_image_id(pic.id)
            if pic_report.count >= 3
              pic.destroy
              success "Reported and Image deleted."
            else
              success "Reported"
            end
          else
            error "Something went wrong."
          end
        else
          error "You already reported this picture."
        end
      else
        error "No such Picture found."
      end
    else
      error "No such user found."
    end

  end

  def friends
    u = User.find_by_auth_token(friends_api_params[:auth_token])
    unless u.blank?
      u.update_attributes(:lng => friends_api_params[:lng].to_f, :lat => friends_api_params[:lat].to_f)
      images = images_with_distance_and_cat(u, friends_api_params[:distance], friends_api_params[:category])
      images = add_likes(images)
      render :json => {:images => images}
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
      puts "LAT1:::::::", user.lat.inspect
      puts "LAT2:::::::", f.lat.inspect
      puts "Distance::Distance::Distance::Distance::", find_distance.inspect
      puts "Distance::Distance::Distance::Distance::", find_distance.inspect
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

  def images_with_distance_and_cat(user, dis, cat)
    images = nil
    # images with required distance
    users_images = []
    imgs = UserImage.where('user_id != ? and category = ?', user.id, "#{cat}").order("created_at DESC")
    unless imgs.blank?
      imgs.each do |f|
        find_distance = distance user.lat, user.lng, f.lat, f.lng
        puts "AAAAAAAAA", user.lat.inspect
        puts "AAAAAAAAA", f.lat.inspect
        puts "AAAAAAAAA", find_distance.inspect
        puts "AAAAAAAAA", find_distance.inspect
        if find_distance.to_f <= (dis*1000).to_f
          users_images << f
        end
      end
    end
    users_images
  end

  def chat_user
    u = User.find_by_auth_token(chat_params[:auth_token])
    unless u.blank?
      u.update_attribute('lng', chat_params[:lng].to_f)
      u.update_attribute('lat', chat_params[:lat].to_f)
      user = User.where('device_token = ?', "#{chat_params[:udid]}").first
      unless user.blank?
        user_chat = UserChat.create!(:m_from => u.id, :m_to => user.id, :message => chat_params[:message], :user_image_id => chat_params[:image_id])
        success "chat sent successfully"
      else
        error "No user found."
      end
    else
      error "No such user found."
    end
  end

  def get_chat
    u = User.find_by_auth_token(chat_params[:auth_token])
    unless u.blank?
      u.update_attribute('lng', chat_params[:lng].to_f)
      u.update_attribute('lat', chat_params[:lat].to_f)
      user = User.where('device_token = ?', "#{chat_params[:udid]}").first
      user_chat = UserChat.where('(m_to = ? or m_to = ?) and (m_from = ? or m_from = ?) and user_image_id = ?', user.id, u.id, u.id, user.id, chat_params[:image_id]).order("created_at DESC").limit(5)
      puts "CHATS:::::", user_chat.inspect
      render :json => {:status => 200, :message => "Success", :chat => user_chat}
    else
      error "No such user found."
    end

  end

  def load_prev_message
    u = User.find_by_auth_token(chat_params[:auth_token])
    unless u.blank?
      u.update_attribute('lng', chat_params[:lng].to_f)
      u.update_attribute('lat', chat_params[:lat].to_f)
      last_message = UserChat.where('id = ?', "#{chat_params[:id]}").first
      unless last_message.blank?
        user_chat = UserChat.where('created_at < ? and (m_to = ? or m_to = ?) and (m_from = ? or m_from = ?) and user_image_id = ?', "#{last_message.created_at}", last_message.m_from, last_message.m_to, last_message.m_to, last_message.m_from, last_message.user_image_id).order("created_at DESC").limit(20)
        puts "CHATS:::::", user_chat.inspect
        render :json => {:status => 200, :message => "Success", :chat => user_chat}
      else
        error "No Such Chat Record Found"
      end
    else
      error "No such user found."
    end

  end

  def get_chat_images
    u = User.find_by_auth_token(chat_params[:auth_token])
    unless u.blank?
      u.update_attribute('lng', chat_params[:lng].to_f)
      u.update_attribute('lat', chat_params[:lat].to_f)
      user_chats = UserChat.find_by_sql("select *
      from (
         select *,
                row_number() over (partition by user_image_id order by created_at DESC) as row_number
         from user_chats
         where m_from = #{u.id} or m_to = #{u.id}
         ) as rows
      where row_number = 1 order by created_at DESC")

      images = []
      unless user_chats.blank?
        user_chats.each do |s|
          puts "USER CHAT:::::", s.inspect
          img = UserImage.find_by_id(s.user_image_id)
          from = User.find_by_id(s.m_from)
          to = User.find_by_id(s.m_to)
          unless img.blank?
            h = {:user_image_id => s.user_image_id, :uploaded_by => img.user.device_token, :from => from.device_token, :to => to.device_token, :title => img.title, :image_url => img.avatar.url.to_s.gsub('s3.amazonaws.com', 's3-us-west-2.amazonaws.com'), :likes => img.user_likes.count}
            images << h
          end
        end
      end
      puts "Chat Images:::::", images.inspect
      render :json => {:status => 200, :message => "Success", :images => images}
    else
      error "No such user found."
    end

  end

  def save_friends
    u = User.find_by_auth_token(chat_params[:auth_token])
    unless u.blank?
      u.update_attribute('lng', chat_params[:lng].to_f)
      u.update_attribute('lat', chat_params[:lat].to_f)
      user_friends = UserFriend.where('user_id = ?', u.id)
      unless user_friends.blank?
        user_friends.each do |t|
          t.destroy
        end
      end

      unless chat_params[:udids].blank?
        chat_params[:udids].split(',').each do |s|
          friend = UserFriend.create(:user_id => u.id, :my_udid => u.device_token, :friend_udids => s)
        end
        success "Friends Created Successfully."
      else
        error "No UDID's Provided."
      end
    else
      error "No such user found."
    end
  end

  def get_friends
    u = User.find_by_auth_token(chat_params[:auth_token])
    unless u.blank?
      u.update_attribute('lng', chat_params[:lng].to_f)
      u.update_attribute('lat', chat_params[:lat].to_f)
      user = User.where('device_token = ?', chat_params[:udid]).first
      user_friends = UserFriend.where('user_id = ?', user.id)
      render :json => {:status => 200, :message => "Success", :friends => user_friends}
    else
      error "No such user found."
    end
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

  def delete_all_others_of_this_box(except_this, user, box_id)
    umg = user.user_images.where('box_id = ? AND id != ?', box_id, except_this)
    unless umg.blank?
      umg.each do |f|
        f.destroy
      end
    end
  end

  def add_likes images
    img = []
    unless images.blank?
      images.each do |f|
        img << f.as_json.merge!(like_count: UserLike.find_all_by_user_image_id(f.id).count, :udid => f.user.device_token)
      end
    end
    img
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
    params.permit(:auth_token, :username, :image_data, :lng, :lat, :box_id, :title, :category)
  end

  def user_img_params
    params.permit(:auth_token, :lng, :lat)
  end

  def chat_params
    params.permit(:auth_token, :lng, :lat, :message, :udid, :udids, :image_id, :id)
  end

  def pic_d_api_params
    params.permit(:pic_id, :auth_token, :image_data, :lng, :lat)
  end

  def like_pic_params
    params.permit(:pic_id, :auth_token)
  end

  def friends_api_params
    params.permit(:auth_token, :distance, :category, :lng, :lat)
  end

end
