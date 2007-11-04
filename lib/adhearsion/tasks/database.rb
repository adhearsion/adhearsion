task:migrate do
  require 'active_record'
  %w.db/migrate db/ahn..each
  ActiveRecord::Migrator.migrate 'db/migrate', ENV['VERSION'] ? ENV['VERSION'].to_i : nil
end