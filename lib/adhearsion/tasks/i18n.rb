# encoding: utf-8

namespace :i18n do
  desc "Validate configured audio prompt files exist"
  task :validate_files => :environment do
    Adhearsion::Initializer.new.setup_i18n_load_path

    config = Adhearsion.config.core.i18n
    locale_files = Dir.glob(I18n.load_path)

    locale_errors = {}
    checked_prompts = 0
    locale_files.each do |locale_file|
      # We only support YAML for now
      next unless locale_file =~ /\.ya?ml$/
      prompts = YAML.load File.read(locale_file)

      locale = prompts.keys.first
      prompts = prompts[locale]

      prompts.each_pair do |key, mapping|
        logger.trace { "Checking i18n key #{key}" }
        # Not all prompts will have audio files
        next unless mapping['audio']

        file = File.absolute_path "#{config['audio_path']}/#{locale}/#{mapping['audio']}"
        unless File.exist?(file)
          logger.warn { "[#{locale}] Missing audio file: #{file}" }
          locale_errors[locale] ||= 0
          locale_errors[locale] += 1
        end
        checked_prompts += 1
      end
    end

    if checked_prompts == 0
      logger.warn { "No Adhearsion i18n prompts found. No files checked." }
    else
      if locale_errors.keys.count > 0
        logger.error { "Errors detected! Number of errors by locale:" }
        locale_errors.each_pair do |locale, err_count|
          logger.error { "[#{locale}]: #{err_count} missing prompts" }
        end
      else
        logger.info { "All configured prompt files successfully validated." }
      end
    end
  end
end
