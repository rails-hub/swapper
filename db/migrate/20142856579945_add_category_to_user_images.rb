class AddCategoryToUserImages < ActiveRecord::Migration
  def change
    add_column :user_images, :category, :string
  end
end
