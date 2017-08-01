class PerformanceAllegeAttachment < ActiveRecord::Base
  include Uploaderable

  belongs_to :performance_allege

  validates_presence_of :file

  uploader_image :file, AllegeAttachmentUploader, size: 50
end
