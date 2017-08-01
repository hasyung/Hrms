class AddExternalApplicationType < ActiveRecord::Migration
  def change
    add_column :external_applications, :push_type, :integer, default: 0, comment: '推送了类型'
  end
end
