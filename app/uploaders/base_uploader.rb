# encoding: utf-8

class BaseUploader < CarrierWave::Uploader::Base
  
  include CarrierWave::MiniMagick
  include CarrierWave::MimeTypes
  include Sprockets::Rails::Helper
  # include Sprockets::Helpers::IsolatedHelper
  
  CarrierWave::SanitizedFile.sanitize_regexp = /[^[:word:]\.\-\+]/
  
  process :set_content_type

  def filename
    if super.present?
      @name ||= Digest::MD5.hexdigest(File.dirname(current_path))
      "#{@name}.#{file.extension.downcase}"
    end
  end

end
