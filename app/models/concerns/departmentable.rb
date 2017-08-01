module Departmentable
  extend ActiveSupport::Concern

  included do
    include InstanceMethods
  end

  module InstanceMethods
    def leafs
      self.childrens.inject([]) do |leafs, child|
        leafs << (child.childrens_count > 0 ? child.leafs : child)
        leafs.flatten
      end
    end

    def leafs_count
      leafs.count
    end

    def filename
      CGI::escape("#{self.created_at.to_date.to_s(:db)}-#{self.name}.xls")
    end

    def file_path
      dir = "#{Rails.root}/public/export/excel/#{self.model}/#{self.version}/"

      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      dir + filename
    end

    def exist_excel?
      File.exist?(self.file_path)
    end
  end
end
