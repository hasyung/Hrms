# 命令依赖
# ubuntu: sudo apt-get install antiword
# macos: brew install antiword
class WordParser
  attr_accessor :filename, :plain_text

  def initialize(filename)
    self.filename = filename
    self.load_content
  end

  protected

  def ealier_format?
    self.filename.downcase.end_with?(".doc")
  end

  def later_format?
    self.filename.downcase.end_with?(".docx")
  end

  def load_content
    unless File.exists?(self.filename)
      raise "File not found, filename: #{self.filename}"
    end

    begin
      if ealier_format?
        self.plain_text = `antiword "#{filename}"`
      elsif later_format?
        doc = Docx::Document.open(self.filename)
        self.plain_text = doc.to_s
      else
        self.plain_text = ''
        raise "Microsoft 2007 and later format unspported, filename: #{self.filename}"
      end
    rescue => ex
      puts "load document data errors: #{ex}"
    end
  end
end
