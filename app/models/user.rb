class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  after_create :generate_auth_token
  before_save :downcase_identifiers

  has_many :user_images
  has_many :user_places

  #validates :password, presence: true, length: {minimum: 5, maximum: 120}, on: :create
  #validates :password, length: {minimum: 5, maximum: 120}, on: :update, allow_blank: true

  #has_many :occurances_as_challenge, :class_name => "Challenge", :foreign_key => "challengee_id", :dependent => :destroy

  validates_presence_of :username, :password

  def email_required?
    false
  end

  def downcase_identifiers
    self.username.downcase! if self.username
    self.email.downcase! if self.email
  end

  def generate_auth_token
    puts 'generate_auth_token'
    # TODO: Remove this line and the if false below to generate real tokens
    #self.auth_token = "aa8xsYyUX1KTXRDQbdUeuk"
    #self.save
    tmp_auth_token = nil
    loop do
      tmp_auth_token = Devise.friendly_token
      break if User.where(:auth_token => tmp_auth_token).count==0
    end
    self.update_attribute('auth_token', tmp_auth_token)
  end

end