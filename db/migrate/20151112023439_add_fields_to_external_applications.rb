class AddFieldsToExternalApplications < ActiveRecord::Migration
  def change
    add_column :external_applications, :check_ip, :boolean, default: true, index: true
    add_column :external_applications, :check_signature, :boolean, default: true, index: true
    add_column :external_applications, :check_time, :boolean, default: true, index: true
    add_column :external_applications, :push_retry_count, :integer, default: true, index: true, comment: '推送失败重试次数'
    add_column :external_applications, :push_failed_count, :integer, default: true, index: true, comment: '推送失败总次数'
    add_column :external_applications, :client_ips, :string, default: true, comment: '接口应用ip集合'
  end
end
