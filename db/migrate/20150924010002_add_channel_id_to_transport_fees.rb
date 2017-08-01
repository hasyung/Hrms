class AddChannelIdToTransportFees < ActiveRecord::Migration
  def change
    add_column :transport_fees, :channel_id, :integer, index: true, comment: '通道ID'
  end
end
