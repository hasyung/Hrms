class AddChannelIdToRewards < ActiveRecord::Migration
  def change
    add_column :rewards, :channel_id, :integer, default: 0, index: true, comment: '通道id'
  end
end
