# encoding: utf-8

Then /^the file "([^"]*)" should contain each of these content parts:$/ do |file, content_parts|
  parts = content_parts.split("\n")
  parts.each do |p|
    steps %Q{Then the file "#{file}" should contain "#{p}"}
  end
end

Then /^the file "([^"]*)" should not contain each of these content parts:$/ do |file, content_parts|
  parts = content_parts.split("\n")
  parts.each do |p|
    steps %Q{Then the file "#{file}" should not contain "#{p}"}
  end
end
