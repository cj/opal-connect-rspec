module ::RSpec
  module Support
    module Warnings
      def warn_with(message, options={})
        call_site = options.fetch(:call_site) { CallerFilter.first_non_rspec_line }
        # mutable strings
        # message << " Use #{options[:replacement]} instead." if options[:replacement]
        message += " Use #{options[:replacement]} instead." if options[:replacement]
        # message << " Called from #{call_site}." if call_site
        message += " Called from #{call_site}." if call_site
        Support.warning_notifier.call message
      end

      alias_method :support_warn_with, :warn_with
    end
  end
  extend RSpec::Support::Warnings
end
