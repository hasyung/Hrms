module Pinyinable
  extend ActiveSupport::Concern

  included do
    include InstanceMethods
  end

  module InstanceMethods
    def name=(val)
      super(val)
      if name_changed? && self.class.to_s !~ /^CodeTable/
        self.pinyin_name = Pinyin.t(name, splitter: '')
        index = pinyin_name[0]
        self.pinyin_index = (index =~ /[a-z]/i) ? index.downcase : '!'
      end
    end

    def display_name=(val)
      super(val)
      if display_name_changed? && self.class.to_s =~ /^CodeTable/
        self.name = Pinyin.t(display_name, splitter: '')
      end
    end
  end
end
