ENV['SPEC_OPTS'] = nil # Node will pick up real env vars

require 'opal/rspec/pre_require_fixes'
require 'opal/rspec/requires'
require 'opal/rspec/fixes'
require 'opal/rspec/formatter/browser_formatter'
require 'opal/rspec/runner'
require 'opal/rspec/async'

phantomjs = `typeof(callPhantom) !== "undefined"`
browser   = `typeof(document) !== "undefined"`
node      = `typeof(process) !== "undefined" && process.versions && process.versions.node`

case
when phantomjs
  require 'phantomjs'
when node
  require 'nodejs/kernel'
  require 'nodejs/io'
end

RSpec.configure do |config|
  # Set the HTML formatter as default when window.document is present, except
  # for known headless browsers like PhantomJS.
  config.default_formatter = ::Opal::RSpec::BrowserFormatter if browser && !phantomjs

  # Have to do this in 2 places. This will ensure the default formatter gets
  # the right IO, but need to do this here for custom formatters that will be
  # constructed BEFORE Runner.autorun runs (see runner.rb)
  err, out = ::RSpec::Core::Runner.get_opal_closed_tty_io
  config.output_stream = out
  config.error_stream = err

  # This shouldn't be in here, but RSpec uses undef to change this
  # configuration and that doesn't work well enough yet
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  # Legacy Async helpers
  config.include Opal::RSpec::AsyncHelpers
end
