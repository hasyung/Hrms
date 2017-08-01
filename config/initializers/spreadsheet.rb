require 'spreadsheet'
require 'roo'

module Spreadsheet
  class << self
    alias_method :ori_open, :open

    def open file, mode = 'rb+'
      str = file.respond_to?(:path) ? file.path : file

      if str.downcase.end_with?('xls')
        obj = ori_open(file, mode)
      else
        obj = Roo::Spreadsheet.open(file)
      end

      return obj
    end
  end
  class Formula
    def to_f
      self.value.to_f
    end
  end
end

module Roo
  class Excelx
    def worksheet idx
      self.sheet(idx)
    end
  end
end
