class Attachment < ActiveRecord::Base
  validates_presence_of :file

  before_create :set_attachment_info

  belongs_to :attachmentable, polymorphic: true

  mount_uploader :file, AttachmentUploader

  def full_path
    "#{Rails.root}/public#{self.file.url}"
  end

  def file_extension
    self.file.file.extension
  end

  def convert_to_xls
    return if file_extension == "xls"
    cmd = "/usr/bin/unoconv -f xls #{self.file.path}"
  end

  private
  def set_attachment_info
    self.file_name = self.file.file.original_filename
    self.file_type = self.file.file.extension
    self.file_size = self.file.size
  end
end
