# == Schema Information
#
# Table name: attachments
#
#  id                  :integer          not null, primary key
#  path                :string(255)
#  size                :integer          default("0")
#  mimetype            :string(255)
#  user_id             :integer
#  attachmentable_id   :integer
#  attachmentable_type :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_attachments_on_attachmentable_id    (attachmentable_id)
#  index_attachments_on_attachmentable_type  (attachmentable_type)
#  index_attachments_on_user_id              (user_id)
#

require 'rails_helper'

RSpec.describe Attachment, :type => :model do
end
