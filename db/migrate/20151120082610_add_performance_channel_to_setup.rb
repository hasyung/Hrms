class AddPerformanceChannelToSetup < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :performance_channel, :string, index: true, comment: '绩效通道'
  end
end
