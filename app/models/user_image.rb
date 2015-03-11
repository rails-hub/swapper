class UserImage < ActiveRecord::Base
  belongs_to :user
  # has_attached_file :avatar, :styles => {:medium => "300x300>", :thumb => "100x100>"}, :default_url => "/images/:style/missing.png"
  has_attached_file :avatar, :path => '/call_recordings/:filename'
  validates_attachment_content_type :avatar, :content_type => /.*/
end
