class ChangeColumnsForExternalApplications < ActiveRecord::Migration
  def change
    change_column :external_applications, :push_retry_count, :integer, default: 0, index: true, comment: '推送失败重试次数'
    change_column :external_applications, :push_failed_count, :integer, default: 0, index: true, comment: '推送失败总次数'
    change_column :external_applications, :client_ips, :string, default: nil, index: true, comment: '接口应用ip集合'
  end
end
