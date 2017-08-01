require 'spreadsheet'

module Excel
  class ShareFundImporter
    def self.import(file_path)
      sheet = get_sheet(file_path)
    end

    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end
  end
end
