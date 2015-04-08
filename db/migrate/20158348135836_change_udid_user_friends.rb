class ChangeUdidUserFriends < ActiveRecord::Migration
  def change
    remove_column :user_friends, :my_udid, :integer
    add_column :user_friends, :my_udid, :string

    remove_column :user_friends, :friend_udids, :integer
    add_column :user_friends, :friend_udids, :string

  end

end
