require 'rspec/support/spec'
require 'rspec/support/ruby_features'

require 'opal/progress_json_formatter' # verify case uses this
# Only doing this because any_instance causes the runner itself to break
CAUSES_SPECS_TO_CRASH = [
    /.*allow_any_instance.*/,
    /.*any_instance_of.*/
]

RSpec::Matchers.define :include_method do |expected|
  match do |actual|
    actual.map { |m| m.to_s }.include?(expected.to_s)
  end
end
require 'support/matchers'

module VerifyAndResetHelpers
  def verify(object)
    proxy = RSpec::Mocks.space.proxy_for(object)
    proxy.verify
  ensure
    proxy.reset # so it doesn't fail the verify after the example completes
  end

  def reset(object)
    RSpec::Mocks.space.proxy_for(object).reset
  end

  def verify_all
    RSpec::Mocks.space.verify_all
  ensure
    reset_all
  end

  def reset_all
    RSpec::Mocks.space.reset_all
  end
end

module VerificationHelpers
  def prevents(msg = //, &block)
    expect(&block).to raise_error(RSpec::Mocks::MockExpectationError, msg)
  end
end

require 'rspec/support/spec'

RSpec.configure do |config|
  config.expose_dsl_globally = false
  config.mock_with :rspec
  config.color = true
  config.order = :random

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    $default_rspec_mocks_syntax = mocks.syntax
    mocks.syntax = :expect
  end

  old_verbose = nil
  config.before(:each, :silence_warnings) do
    old_verbose = $VERBOSE
    $VERBOSE = nil
  end

  config.after(:each, :silence_warnings) do
    $VERBOSE = old_verbose
  end

  config.include VerifyAndResetHelpers
  config.include VerificationHelpers
  config.extend RSpec::Support::RubyFeatures
  config.include RSpec::Support::RubyFeatures
  config.filter_run_excluding full_description: Regexp.union(CAUSES_SPECS_TO_CRASH)
  #config.full_description = 'when verify_partial_doubles configuration option is set.*'
end

RSpec.shared_context "with syntax" do |syntax|
  orig_syntax = nil

  before(:all) do
    orig_syntax = RSpec::Mocks.configuration.syntax
    RSpec::Mocks.configuration.syntax = syntax
  end

  after(:all) do
    RSpec::Mocks.configuration.syntax = orig_syntax
  end
end


RSpec.shared_context "with isolated configuration" do
  orig_configuration = nil
  before do
    orig_configuration = RSpec::Mocks.configuration
    RSpec::Mocks.instance_variable_set(:@configuration, RSpec::Mocks::Configuration.new)
  end

  after do
    RSpec::Mocks.instance_variable_set(:@configuration, orig_configuration)
  end
end

RSpec.shared_context "with monkey-patched marshal" do
  before do
    RSpec::Mocks.configuration.patch_marshal_to_support_partial_doubles = true
  end

  after do
    RSpec::Mocks.configuration.patch_marshal_to_support_partial_doubles = false
  end
end

RSpec.shared_context "with the default mocks syntax" do
  orig_syntax = nil

  before(:all) do
    orig_syntax = RSpec::Mocks.configuration.syntax
    RSpec::Mocks.configuration.reset_syntaxes_to_default
  end

  after(:all) do
    RSpec::Mocks.configuration.syntax = orig_syntax
  end
end
