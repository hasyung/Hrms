# encoding: utf-8

class AllegeAttachmentUploader < BaseUploader

  def extension_black_list
    Setting.upload_attachment_extension
  end

  def store_dir
    "uploads/#{model.class.to_s.pluralize.underscore}/#{mounted_as.to_s.pluralize.underscore}/#{model.id}"
  end
end