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

      each_prompt(prompts) do |key, mapping|
        logger.trace "Checking i18n key #{key}"
        # Not all prompts will have audio files
        next unless mapping['audio']

        file = File.absolute_path "#{config['audio_path']}/#{locale}/#{mapping['audio']}"
        unless File.exist?(file)
          logger.warn "[#{locale}] Missing audio file: #{file}"
          locale_errors[locale] ||= 0
          locale_errors[locale] += 1
        end
        checked_prompts += 1
      end
    end

    if checked_prompts == 0
      logger.warn "No Adhearsion i18n prompts found. No files checked."
    else
      if locale_errors.keys.count > 0
        logger.error "Errors detected! Number of errors by locale:"
        locale_errors.each_pair do |locale, err_count|
          logger.error "[#{locale}]: #{err_count} missing prompts"
        end
      else
        logger.info "All configured prompt files successfully validated."
      end
    end
  end

  desc "Generate recording script (Markdown format)"
  task :generate_script do
    @output_dir = File.join Adhearsion.root, 'doc'
    File.mkdir @output_dir unless File.exist? @output_dir

    seen_locales = Set.new
    locale_files = Dir.glob(I18n.load_path)
    locale_files.each do |locale_file|
      # We only support YAML for now
      next unless locale_file =~ /\.ya?ml$/

      prompts = YAML.load File.read(locale_file)

      seen_locales << locale = prompts.keys.first
      prompts = prompts[locale]

      File.open script_name(locale), 'w+' do |fh|
        each_prompt(prompts) do |key, mapping|
          logger.trace "Checking i18n key #{key}"

          # Ignore any prompt that doesn't have a text translation
          next unless mapping['text']
          audiofile = mapping['audio'] ? mapping['audio'] : "#{key}.wav"

          fh.puts "* `#{audiofile}`: \"#{mapping['text']}\""
          fh.puts
        end
      end

    end

    seen_locales.each do |locale|
      if File.zero? script_name(locale)
        logger.warn "No prompts found, script not created."
        File.unlink script_name(locale)
      else
        logger.info "Audio recording script written to #{script_name(locale)}"
      end
    end
  end

  def script_name(locale)
    File.join @output_dir, "prompts_#{locale}.md"
  end

  def children(node)
    node.is_a?(Hash) && node.keys - ['text', 'audio'] || []
  end

  def prompt?(node)
    node.is_a?(Hash) && (node.key?('text') || node.key?('audio'))
  end

  def each_prompt(collection, prefix = '', &block)
    collection.each do |key, data|
      next if ['text', 'audio'].include? key
      current_prefix = prefix.empty? ? prefix : "#{prefix}."
      current_prefix += key.to_s
      each_prompt(data, current_prefix, &block) unless children(data).empty?
      yield current_prefix, data if prompt? data
    end
  end
end
