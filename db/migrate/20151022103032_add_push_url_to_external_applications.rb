class AddPushUrlToExternalApplications < ActiveRecord::Migration
  def change
    add_column :external_applications, :push_url, :string, comment: '推送地址'
  end
end
