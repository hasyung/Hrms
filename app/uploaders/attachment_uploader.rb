class AttachmentUploader < BaseUploader
  def extension_black_list
    Setting.upload_attachment_extension
  end

  def store_dir
    "uploads/#{model.class.to_s.pluralize.underscore}/#{mounted_as.to_s.pluralize.underscore}/#{model.id}"
  end

  def filename
    "#{secure_token}#{Time.now.to_i.to_s}.#{file.extension}" if original_filename.present?
  end

  version :thumb, if: :is_image? do
    process resize_to_fit: [800, 800]
  end

  protected
  def is_image?(file)
    file.content_type.include?("image/")
  end

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
  end
end
