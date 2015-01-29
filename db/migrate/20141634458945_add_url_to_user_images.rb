class AddUrlToUserImages < ActiveRecord::Migration
  def change
    add_column :user_images, :url, :string
  end
end
