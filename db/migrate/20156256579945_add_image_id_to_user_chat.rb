class AddImageIdToUserChat < ActiveRecord::Migration
  def change
    add_column :user_chats, :user_image_id, :integer
  end
end
