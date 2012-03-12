# encoding: utf-8

Then /^the file "([^"]*)" should contain each of these content parts:$/ do |file, content_parts|
  parts = content_parts.split
  parts.each do |p|
    steps %Q{Then the file "#{file}" should contain "#{p}"}
  end
end
