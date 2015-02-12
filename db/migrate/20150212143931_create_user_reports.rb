class CreateUserReports < ActiveRecord::Migration
  def change
    create_table :user_reports do |t|
      t.integer :user_id
      t.integer :user_image_id

      t.timestamps
    end
  end
end
