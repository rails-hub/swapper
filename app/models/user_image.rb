class UserImage < ActiveRecord::Base
  belongs_to :user
  has_attached_file :avatar, :styles => {:medium => "300x300>", :thumb => "100x100>"}
  # validates_attachment_content_type :avatar, :content_type => /.*/
  # validates_attachment_content_type :audio, :content_type => /.*/
  validates_attachment_content_type :audio, :content_type => ['audio/x-wav']
end
