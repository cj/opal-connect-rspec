require 'bundler'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

require 'opal/rspec/rake_task'
require_relative 'spec/rspec/core/core_spec_loader'
require_relative 'spec/rspec/expectations/expectation_spec_loader'
require_relative 'spec/rspec/support/support_spec_loader'
require_relative 'spec/rspec/mocks/mocks_spec_loader'

task :default => [
  :unit_specs,
  :verify_opal_specs,
  :integration_specs,
  :verify_rspec_specs,
]

desc 'Runs a set of specs in opal'
Opal::RSpec::RakeTask.new(:opal_specs) do |_, task|
  task.pattern = 'spec/opal/**/*_spec.{rb,opal}'
  task.default_path = 'spec/opal'
end

desc 'Generates an RSpec requires file free of dynamic requires'
task :generate_requires do
  # Do this free of any requires used to make this Rake task happen
  sh 'ruby -Irspec/lib -Irspec-core/lib/rspec -Irspec-support/lib/rspec util/create_requires.rb'
end

desc 'Runs a test to test browser based specs using Opal specs in spec/opal'
RSpec::Core::RakeTask.new :integration_specs do |t|
  t.pattern = 'spec/mri/integration/**/*_spec.rb'
end

desc 'Unit tests for MRI focused components of opal-rspec'
RSpec::Core::RakeTask.new :unit_specs do |t|
  t.pattern = 'spec/mri/unit/**/*_spec.rb'
  t.exclude_pattern = 'spec/mri/unit/opal/rspec/opal/**/*'
end

desc 'A more limited spec suite to test pattern usage'
Opal::RSpec::RakeTask.new(:other_specs) do |_, task|
  task.pattern = 'spec/other/dummy_spec.rb'
  task.default_path = 'spec/other'
end

Opal::RSpec::RakeTask.new(:color_on_by_default) do |_, task|
  task.pattern = 'spec/other/color_on_by_default_spec.rb'
  task.default_path = 'spec/other'
end

Opal::RSpec::CoreSpecLoader.rake_tasks_for(:rspec_core_specs)
Opal::RSpec::ExpectationSpecLoader.rake_tasks_for(:rspec_expectation_specs)
Opal::RSpec::SupportSpecLoader.rake_tasks_for(:rspec_support_specs)
Opal::RSpec::MocksSpecLoader.rake_tasks_for(:rspec_mocks_specs)

# These are done
desc 'Verifies all RSpec specs'
task :verify_rspec_specs => [
         :verify_rspec_support_specs,
         :verify_rspec_core_specs,
         :verify_rspec_expectation_specs,
         :verify_rspec_mocks_specs
     ]

desc 'Verifies other_spec_dir task ran correctly'
task :verify_other_specs do
  test_output = `rake other_specs`
  unless /1 example, 0 failures/.match(test_output)
    raise "Expected 1 passing example, but got output '#{test_output}'"
  end
  puts 'Test successful'
end

desc 'Will run a spec suite (rake opal_specs) and check for expected combination of failures and successes'
task :verify_opal_specs do
  test_output = `rake opal_specs`
  raise "Expected test runner to fail due to failed tests, but got return code of #{$?.exitstatus}" if $?.success?
  count_match = /(\d+) examples, (\d+) failures, (\d+) pending/.match(test_output)
  raise 'Expected a finished count of test failures/success/etc. but did not see it' unless count_match
  total, failed, pending = count_match.captures

  actual_failures = []
  test_output.scan /\d+\) (.*)/ do |match|
    actual_failures << match[0].strip
  end
  actual_failures.sort!

  failure_messages = []

  bad_strings = [/.*is still running, after block problem.*/,
                 /.*should not have.*/,
                 /.*Expected \d+ after hits but got \d+.*/,
                 /.*Expected \d+ around hits but got \d+.*/]

  bad_strings.each do |regex|
    test_output.scan(regex) do |match|
      failure_messages << "Expected not to see #{regex} in output, but found match #{match}"
    end
  end

  expected_pending_count = 12
  expected_failures = File.read('spec/opal/expected_failures.txt').split("\n").compact.sort

  if actual_failures != expected_failures
    unexpected = actual_failures - expected_failures
    missing = expected_failures - actual_failures
    failure_messages << "Expected test failures do not match actual\n"
    failure_messages << "\nUnexpected fails:\n#{unexpected.join("\n")}\n\nMissing fails:\n#{missing.join("\n")}\n\n"
  end

  failure_messages << "Expected #{expected_pending_count} pending examples but actual was #{pending}" unless pending == expected_pending_count.to_s

  if failure_messages.empty?
    puts 'Test successful!'
    puts "#{total} total specs, #{failed} expected failures, #{pending} expected pending"
  else
    raise "Test failed, reasons:\n\n#{failure_messages.join("\n")}\n"
  end
end

desc "Build build/opal-rspec.js"
task :dist do
  require 'fileutils'
  FileUtils.mkdir_p 'build'

  builder = Opal::Builder.new(stubs: Opal::Processor.stubbed_files, # stubs already specified in lib/opal/rspec.rb
                              compiler_options: {dynamic_require_severity: :ignore}) # RSpec is full of dynamic requires
  src = builder.build('opal-rspec')

  min = uglify src
  gzp = gzip min

  File.open('build/opal-rspec.js', 'w+') do |out|
    out << src
  end

  puts "development: #{src.size}, minified: #{min.size}, gzipped: #{gzp.size}"
end

# Used for uglifying source to minify
def uglify(str)
  IO.popen('uglifyjs', 'r+') do |i|
    i.puts str
    i.close_write
    return i.read
  end
rescue Errno::ENOENT
  $stderr.puts '"uglifyjs" command not found (install with: "npm install -g uglify-js")'
  nil
end

# Gzip code to check file size
def gzip(str)
  IO.popen('gzip -f', 'r+') do |i|
    i.puts str
    i.close_write
    return i.read
  end
rescue Errno::ENOENT
  $stderr.puts '"gzip" command not found, it is required to produce the .gz version'
  nil
end
