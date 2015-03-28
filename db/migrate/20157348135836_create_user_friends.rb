class CreateUserFriends < ActiveRecord::Migration
  def change
    create_table :user_friends do |t|
      t.integer :user_id
      t.integer :my_udid
      t.integer :friend_udids
      t.timestamps
    end
  end
end
