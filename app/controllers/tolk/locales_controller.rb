require 'git'
require 'tocaro_webhook'

module Tolk
  class LocalesController < Tolk::ApplicationController
    before_action :find_locale, :only => [:show, :all, :update, :updated]
    before_action :ensure_no_primary_locale, :only => [:all, :update, :show, :updated]

    def index
      @locales = Tolk::Locale.secondary_locales.sort_by(&:language_name)
    end

    def show
      respond_to do |format|
        format.html do
          @phrases = @locale.phrases_without_translation(params[pagination_param]).per(15)
        end

        format.atom { @phrases = @locale.phrases_without_translation(params[pagination_param]).per(50) }

        format.yaml do
          data = @locale.to_hash
          render :text => Tolk::YAML.dump(data)
        end

      end
    end

    def update
      @locale.translations_attributes = translation_params
      @locale.save
      file_path_ids = translation_params.map { |p| p['file_path_id'] }.uniq
      file_path_ids.each do |file_path_id|
        Tolk::Locale.save_translate_results(@locale.id, file_path_id)
        # activerecordのメモリを解放する http://qiita.com/dainghiavotinh/items/8158213207b257670ff3
        ObjectSpace.each_object(ActiveRecord::Relation).each(&:reset)
        GC.start
      end
      redirect_to request.referrer
    end

    def all
      @phrases = @locale.phrases_with_translation(params[pagination_param])
    end

    def updated
      @phrases = @locale.phrases_with_updated_translation(params[pagination_param])
      render :all
    end

    def create
      Tolk::Locale.create!(locale_params)
      redirect_to :action => :index
    end

    def dump_all
      translate_results = Tolk::TranslateResult.all
      translate_results.each do |result|
        result.dump
      end

      I18n.reload!
      redirect_to request.referrer
    end

    def release
      # git
      g = Git.open(Tolk::Locale.app_root_path)
      g.add
      g.commit 'modify: change locale from cat tool'
      g.push
      unless Tolk::Locale.webhook_key.nil?
        # tocaro
        webhook_sender = TocaroWebhook::Sender.new(Tolk::Locale.webhook_key)
        webhook_sender.payload.add_attachment(title: "CAT tool", value: "change locale from CAT tool")
        webhook_sender.exec(color: 'success')
      end
      redirect_to request.referrer
    end

    def stats
      @locales = Tolk::Locale.secondary_locales.sort_by(&:language_name)

      respond_to do |format|
        format.json do
          stats = @locales.collect do |locale|
            [locale.name, {
              :missing => locale.count_phrases_without_translation,
              :updated => locale.count_phrases_with_updated_translation,
              :updated_at => locale.updated_at
            }]
          end
          render :json => Hash[stats]
        end
      end
    end

    private

    def find_locale
      @locale ||= Tolk::Locale.where('UPPER(name) = UPPER(?)', params[:id] || params[:tolk_locale]).first!
    end

    def locale_params
      params.require(:tolk_locale).permit(:name)
    end

    def translation_params
      params.permit(translations: [:id, :phrase_id, :locale_id, :file_path_id, :text])[:translations]
    end

  end
end
