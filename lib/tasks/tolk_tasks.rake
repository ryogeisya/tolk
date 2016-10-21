namespace :tolk do
  desc "Update locale"
  task :update_locale, [:old_name, :new_name] => :environment do |t, args|
    old_name, new_name = args[:old_name], args[:new_name]
    puts Tolk::Locale.rename(old_name, new_name)
  end

  desc "Add database tables, copy over the assets, and import existing translations"
  task :setup => :environment do
    system 'rails g tolk:install'

    Rake::Task['db:migrate'].invoke
    Rake::Task['tolk:import'].invoke
  end

#  desc "Sync Tolk with the default locale's yml file"
#  task :sync => :environment do
#    Tolk::Locale.sync!
#  end

  desc "Generate yml files for all the locales defined in Tolk"
  task :dump_all => :environment do
    Tolk::Locale.dump_file_path_all
  end

  desc "Generate a single yml file for a specific locale"
  task :dump_yaml, [:locale] => :environment do |t, args|
    locale = args[:locale]
    Tolk::Locale.dump_yaml(locale)
  end

  desc "Imports primary locale yml files to Tolk"
  task :import_primary => :environment do
    Tolk::Locale.import_primary
  end

  desc "Imports data all non default locale yml files to Tolk"
  task :import => :environment do
    Tolk::Locale.import_all
    Rake::Task['tolk:create_translate_results'].invoke
  end

  task :create_translate_results => :environment do
    locales = Tolk::Locale.eager_load(:translations).where('tolk_locales.id != ?', Tolk::Locale.primary_locale.id)
    file_paths = Tolk::FilePath.all

    locales.each do |locale|
      file_paths.each do |file_path|
        Tolk::Locale.save_translate_results(locale.id, file_path.id)
      end
    end
  end

  desc "Show all the keys potentially containing HTML values and no _html postfix"
  task :html_keys => :environment do
    bad_translations = Tolk::Locale.primary_locale.translations_with_html
    bad_translations.each do |bt|
      puts "#{bt.phrase.key} - #{bt.text}"
    end
  end
end
