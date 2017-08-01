require 'zip'

class Hash
  def deep_reject(&blk)
    self.dup.deep_reject!(&blk)
  end

  def deep_reject!(&blk)
    self.each do |k, v|
      v.deep_reject!(&blk)  if v.is_a?(Hash)
      self.delete(k)  if blk.call(k, v)
    end
  end

  def extract(key, default_value=nil)
    return default_value unless self[key.to_sym]
    self[key.to_sym]
  end
end

class Date
  #difference_in_years('2012-01-11', '2009-02-01')
  def self.difference_in_years(s1, s2, count = 0)
    d1, d2 = Date.parse(s1), Date.parse(s2)
    while(d1.next_day >= d2)
      count += 1
      d1 = d1.end_of_year == d1 ? d1.prev_year.end_of_year : d1.prev_year
    end
    count > 1 ? count - 1 : 0
  end

  def self.difference_in_months(d1, d2, count = 0)
    while(d1.next_day >= d2)
      count += 1
      d1 = d1.end_of_month == d1 ? d1.prev_month.end_of_month : d1.prev_month
    end
    count > 1 ? count - 1 : 0
  end

  def self.has_natural_month?(d1, d2)
    if d1.class == Time
      d1 = d1.hour == 13 ? d1.to_date.prev_day : d1.to_date
    end
    if d2.class == Time
      d2 = d2.hour == 13 ? d2.to_date.next_day : d2.to_date
    end
    d2 <= (d1 == d1.end_of_month ? d1.beginning_of_month : d1.prev_month.beginning_of_month)
  end

  def self.range_list(start_date, end_date)
    date = start_date
    list = []

    while date <= end_date
      list << date
      date = date.next
    end

    list
  end
end

class File
  def self.creation_zip_file(folder, zip_filename, input_filenames)
    zipfile_name = folder + zip_filename

    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      input_filenames.each do |filename|
        zipfile.add(filename, folder + filename)
      end
    end
  end
end

class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end
  def yellow;         "\e[33m#{self}\e[0m" end

  def bg_black;       "\e[40m#{self}\e[0m" end
  def bg_red;         "\e[41m#{self}\e[0m" end
  def bg_green;       "\e[42m#{self}\e[0m" end
  def bg_brown;       "\e[43m#{self}\e[0m" end
  def bg_blue;        "\e[44m#{self}\e[0m" end
  def bg_magenta;     "\e[45m#{self}\e[0m" end
  def bg_cyan;        "\e[46m#{self}\e[0m" end
  def bg_gray;        "\e[47m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
  def blink;          "\e[5m#{self}\e[25m" end
  def reverse_color;  "\e[7m#{self}\e[27m" end

  def no_colors
    self.gsub /\e\[\d+m/, ""
  end
end
