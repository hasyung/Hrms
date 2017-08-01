module Uploaderable

  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods

    # @overload uploader(field, uploader = nil, options = {}, &block)
    #   上传一个文件
    #   @param [field] 指定字段
    #   @param [uploader] 上传器
    #   @param [Hash] options
    #   @param options [Integer] :size 上传文件的大小,默认为0.5(512KB).
    #   @param options [Boolean] :dimensions 是否带图片的尺寸,默认为false,如果为true,会创建[field]_width,[field]_height.
    #   @yield If given, 一个block.
    #
    # @example A custom builder
    #   class Person
    #     include Mongoid::Document
    #     include Mongoid::UploadImage
    #
    #     uploader_image :image, ImageUploader, dimensions: true, size: 10
    #   end
    #
    def uploader_image field, uploader = nil, options = {}, &block
      options.merge!({ duration: false })
      uploader_resource field, uploader, options, &block
    end


    # @overload uploader_media(field, uploader = nil, options = {}, &block)
    #   上传一个媒体文件
    #   @param [field] 指定字段
    #   @param [uploader] 上传器
    #   @param [Hash] options
    #   @param options [Integer] :size 上传文件的大小,默认为0.5(512KB).
    #   @param options [Boolean] :presence 是否必填,默认为true.
    #   @param options [Boolean] :duration 记录时长
    #   @yield If given, 一个block.
    #
    # @example A custom builder
    #   class Person
    #     include Mongoid::Document
    #     include Mongoid::UploadImage
    #
    #     uploader_media :video, VideoUploader, size: 10
    #   end
    #
    def uploader_media field, uploader = nil, options = {}, &block
      options.merge!({ dimensions: false })
      uploader_resource field, uploader, options, &block
    end

    private
    def uploader_resource field, uploader = nil, options = {}, &block
      # 默认值
      # 上传文件大小,默认0.5M
      size = options.fetch(:size, 0.5)
      # 保存尺寸
      is_dimensions = options.fetch(:dimensions, true)
      # 保存时长
      is_duration = options.fetch(:duration, true)

      # CarrierWave
      mount_uploader field, uploader, options, &block

      # 验证
      validates field.to_sym, file_size: { maximum: size.megabytes.to_i }

      set_callback(:save, :before) do |model|
        if model.send("#{field}").present? && model.send("#{field}_changed?")
          # 更新type和size
          model.send("#{field}_type=", MIME::Types.type_for(model.send("#{field}").file.original_filename).first.to_s) if model.respond_to?("#{field}_type=")
          model.send("#{field}_size=", model.send("#{field}").file.size) if model.respond_to?("#{field}_size=")
          model.send("#{field}_name=", model.send("#{field}").file.filename) if model.respond_to?("#{field}_name=")
          # 更新尺寸
          if is_dimensions and model.respond_to?("#{field}_width=") and model.respond_to?("#{field}_height=")
            width, height = `identify -format "%wx%h" #{model.send("#{field}").path}`.split(/x/)
            model.send("#{field}_width=", width)
            model.send("#{field}_height=", height)
          end
          # 更新时长
          if is_duration and model.respond_to?("#{field}_duration=")
            model.send("#{field}_duration=", model.send("#{field}").info.duration)
          end
        end
      end

    end

  end

end # => Uploaderable