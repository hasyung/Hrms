# encoding: utf-8

class FaviconUploader < BaseUploader
  include CarrierWave::MiniMagick
  
  def extension_white_list
    Setting.upload_image_extension
  end

  def store_dir
    "uploads/#{model.class.to_s.pluralize.underscore}/#{mounted_as.to_s.pluralize.underscore}/#{model.id}"
  end

  process :quality => 90

  version :small do
    process resize_to_fit: [40, 40]
  end

  version :middle do
    process resize_to_fit: [72, 72]
  end

  version :big do
    process resize_to_fit: [110, 110]
  end

end
