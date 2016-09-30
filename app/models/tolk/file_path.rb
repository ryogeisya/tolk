module Tolk
  class FilePath < ActiveRecord::Base
    self.table_name = "tolk_file_paths"

    has_many :translations, :class_name => 'Tolk::Translation', :dependent => :destroy
  end
end
