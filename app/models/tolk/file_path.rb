module Tolk
  class FilePath < ActiveRecord::Base
    self.table_name = "tolk_file_paths"

    has_many :translations, :class_name => 'Tolk::Translation', :dependent => :destroy
    has_many :translate_results, :class_name => 'Tolk::TranslateResult', :dependent => :destroy
  end
end
