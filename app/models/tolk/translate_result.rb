module Tolk
  class TranslateResult < ActiveRecord::Base
    self.table_name = "tolk_translate_results"

    belongs_to :locale, :class_name => 'Tolk::Locale'
    belongs_to :file_path, :class_name => 'Tolk::FilePath'
  end
end
