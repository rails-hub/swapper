class PushController < ApplicationController
#AK= AKIAJHQWLMQT2JNSSBVQ
#SK= fNRmxPbURLcYdAhRXJ8RNLgbfRQ476iclF3Wqm8w
# This is strictly used to send push notifications

  def self.push_message_to_user(message, user, type, id, url, url_medium, url_thumb)
    self.push_message_to_users(message, [user], type, id, url, url_medium, url_thumb)
  end

  def self.push_message_to_users(message, users, type, id, url, url_medium, url_thumb)
    APNS.host = 'gateway.sandbox.push.apple.com'
    APNS.pem = "#{Rails.root}/certi.pem"
    APNS.port = 2195

    notifications = []
    users.each do |user|
      if !user.device_token.nil?
        user.update_attribute(:notification_count, (user.notification_count).to_i + 1)
        notification = APNS::Notification.new(user.device_token, :alert => message, :badge => user.notification_count, :other => {:type => type, :url_original => url})
        notifications << notification
      end
    end

    puts APNS.send_notifications(notifications)
  end

end
