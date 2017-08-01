# encoding: utf-8

class FlowAttachmentUploader < BaseUploader

  def extension_black_list
    Setting.upload_attachment_extension
  end

  def store_dir
    "uploads/#{model.class.to_s.pluralize.underscore}/#{mounted_as.to_s.pluralize.underscore}/#{model.id}"
  end

  version :thumb, if: :is_image? do
    process resize_to_fit: [800, 800]
  end

  protected
  def is_image?(file)
    file.content_type.include?("image/")
  end
end
