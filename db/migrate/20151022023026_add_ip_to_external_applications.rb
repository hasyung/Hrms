class AddIpToExternalApplications < ActiveRecord::Migration
  def change
    add_column :external_applications, :internal_ip, :string, index: true, comment: '内网ip地址'
    add_column :external_applications, :public_ip, :string, index: true, comment: '公网ip地址'
  end
end
