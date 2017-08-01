# == Schema Information
#
# Table name: snapshots
#
#  id         :integer          not null, primary key
#  model      :string(255)
#  version    :integer          default("0")
#  data       :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_snapshots_on_model    (model)
#  index_snapshots_on_version  (version)
#

require 'rails_helper'

RSpec.describe Snapshot, :type => :model do
end
