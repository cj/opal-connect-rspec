require 'file'
require 'dir'
require 'thread'

require 'rspec/core'
require 'rspec/mocks'
require 'rspec-expectations'

# For now, we don't support mocking. This placeholder in rspec-core allows that.
# use any mocking. win.
require 'rspec/core/mocking/with_absolutely_nothing'

# String#<< is not supported by Opal
module RSpec::Expectations
  def self.fail_with(message, expected = nil, actual = nil)
    if !message
      raise ArgumentError, "Failure message is nil. Does your matcher define the " +
                           "appropriate failure_message_for_* method to return a string?"
    end

    raise RSpec::Expectations::ExpectationNotMetError.new(message)
  end
end

# Opal does not support mutable strings
module RSpec::Matchers::Pretty
  def underscore(camel_cased_word)
    word = camel_cased_word.to_s.dup
    word = word.gsub(/([A-Z]+)([A-Z][a-z])/,'$1_$2')
    word = word.gsub(/([a-z\d])([A-Z])/,'$1_$2')
    word = word.tr("-", "_")
    word = word.downcase
    word
  end
end