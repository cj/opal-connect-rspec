require_relative 'formatter/opal_closed_tty_io'

module ::RSpec::Core
  class Runner
    class << self
      def get_opal_closed_tty_io
        std_out = OpalClosedTtyIO.new :stdout
        std_err = OpalClosedTtyIO.new :stderr
        [std_err, std_out]
      end

      def autorun
        # see NoCarriageReturnIO source for why this is being done (not on Node though)
        err, out = get_opal_closed_tty_io
        # Have to do this in 2 places. This will ensure the default formatter
        # gets the right IO, but need to do this in config for custom
        # formatters that will be constructed BEFORE this runs, see rspec.rb
        run(ARGV, err, out).then do |status|
          exit(status.to_i)
        end
      end

      def run(args, err=$stderr, out=$stdout)
        options = ConfigurationOptions.new(args)
        new(options).run(err, out)
      end
    end

    def run_groups_async(example_groups, reporter)
      results = []
      last_promise = example_groups.inject(Promise.value(true)) do |previous_promise, group|
        previous_promise.then do |result|
          results << result
          group.run reporter
        end
      end
      last_promise.then do |result|
        results << result
        results.all? ? 0 : @configuration.failure_exit_code
      end
    end

    def run_specs(example_groups)
      @configuration.reporter.report_async(@world.example_count(example_groups)) do |reporter|
        hook_context = SuiteHookContext.new
        Promise.value.then do
          @configuration.hooks.run(:before, :suite, hook_context)
          run_groups_async example_groups, reporter
        end.ensure do |result|
          @configuration.hooks.run(:after, :suite, hook_context)
          result
        end
      end
    end
  end
end
