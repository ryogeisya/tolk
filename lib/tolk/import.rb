module Tolk
  module Import
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def import_primary
        import_all_dir(self.primary_locale_name)
      end

      def import_all
        locales = Dir.entries(self.locales_config_path)
        locale_block_filter = Proc.new {
          |l| ['.', '..'].include?(l) ||
            !l.ends_with?('.yml') ||
            l.match(/(.*\.){2,}/) # reject files of type xxx.en.yml
        }
        locales = locales.reject(&locale_block_filter).map {|x| x.split('.').first }
        # locales = locales - [Tolk::Locale.primary_locale.name]
        locales.each {|l| import_all_dir(l) }
      end

      def import_all_dir(locale_name)
        # ディレクトリのパスを取得する
        dir_paths = Dir.glob("#{self.locales_config_path}/**/")
        dir_paths.each { |dir_path|
          # pathをここで登録する
          import_locale(locale_name, dir_path)
        }
      end

      def import_locale(locale_name, dir_path)
        locale = Tolk::Locale.where(name: locale_name).first_or_create

        data = locale.read_locale_file(dir_path)
        return unless data
        path_model = Tolk::FilePath.where(value: dir_path).first_or_create

        phrases = Tolk::Phrase.all
        count = 0

        data.each do |key, value|
          phrase = phrases.detect {|p| p.key == key} || Tolk::Phrase.create!(:key => key)

          if phrase
            translation = Tolk::Translation.where(phrase: phrase, locale_id: locale.id).first_or_initialize
            translation.text = value
            translation.phrase = phrase
            translation.file_path_id = path_model.id
            if translation.save
              count = count + 1
            elsif translation.errors[:variables].present?
              puts "[WARN] Key '#{key}' from '#{locale_name}.yml' could not be saved: #{translation.errors[:variables].first}"
            end
          else
            puts "[ERROR] Key '#{key}' was found in '#{locale_name}.yml' but #{Tolk::Locale.primary_language_name} translation is missing"
          end
        end

        puts "[INFO] Imported #{count} keys from #{locale_name}.yml"
      end

      def save_translate_results(locale_id, file_path_id)
        translate_result = Tolk::TranslateResult.where(locale_id: locale_id, file_path_id: file_path_id).first_or_initialize

        puts "[INFO] Create #{translate_result.file_path.value}"
        file_path_traslations = Tolk::Translation.where(locale_id: locale_id, file_path_id: file_path_id)
        # TODO: valueの:yearなどを文字列にしたときに、yearになってしまう
        # 翻訳時に':year'などとしないといけない
        translate_result.json = translate_result.locale.to_hash(translations: file_path_traslations).to_json
        translate_result.save!
      end

    end

    # ループするようにする
    # locale以下のファイルをすべて読み込むようにする
    # 新しいテーブルを作成して、ディレクトリごとにファイルを吐き出せるようにする
    def read_locale_file(dir_path)
      locale_file = "#{dir_path}#{self.name}.yml"
      return nil unless File.exists?(locale_file)

      puts "[INFO] Reading #{locale_file} for locale #{self.name}"
      begin
        self.class.flat_hash(Tolk::YAML.load_file(locale_file)[self.name])
      rescue
        puts "[ERROR] File #{locale_file} expected to declare #{self.name} locale, but it does not. Skipping this file."
        nil
      end

    end

  end
end
