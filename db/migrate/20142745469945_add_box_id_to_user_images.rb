class AddBoxIdToUserImages < ActiveRecord::Migration
  def change
    add_column :user_images, :box_id, :integer
    add_column :user_images, :title, :string
    add_column :user_images, :lng, :float
    add_column :user_images, :lat, :float

  end
end
