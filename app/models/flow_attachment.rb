class FlowAttachment < ActiveRecord::Base
  include Uploaderable

  validates_presence_of :file

  belongs_to :flow

  # Uploader
  uploader_image :file, FlowAttachmentUploader, size: 50
end
