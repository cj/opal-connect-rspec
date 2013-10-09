require 'opal'
require 'opal-rspec'

# make sure should and expect syntax are both loaded
RSpec::Expectations::Syntax.enable_should
RSpec::Expectations::Syntax.enable_expect

# opal doesnt yet support module_exec for defining methods in modules properly
module RSpec::Matchers
  alias_method :expect, :expect
end

# enable_should uses module_exec which does not donate methods to bridged classes
module Kernel
  alias should should
  alias should_not should_not
end

# Module#include should also include constants (as should class subclassing)
RSpec::Core::ExampleGroup::AllHookMemoizedHash = RSpec::Core::MemoizedHelpers::AllHookMemoizedHash

# bad.. something is going wrong inside hooks - so set hooks to empty, for now
# or is it a problem with Array.public_instance_methods(false) adding all array
# methods to this class and thus breaking things like `self.class.new`
class RSpec::Core::Hooks::HookCollection
  def for(a)
    RSpec::Core::Hooks::HookCollection.new.with(a)
  end
end

class RSpec::Core::Hooks::AroundHookCollection
  def for(a)
    RSpec::Core::Hooks::AroundHookCollection.new.with(a)
  end
end

describe "Adam" do
  it "should eat" do
    1.should == 1
  end
end

describe "Benjamin" do
  it "likes cream in his tea" do
    1.should == 3
  end

  it "should eat bacon" do
    "bacon".should be_a_kind_of(String)
  end
end

class OpalRSpecRunner
  def initialize(options={}, configuration=RSpec::configuration, world=RSpec::world)
    @options        = options
    @configuration  = configuration
    @world          = world
  end

  def run(err, out)
    # load specs by the time this runs!
    @configuration.error_stream = err
    @configuration.output_stream ||= out

    puts "Examples to run: #{@world.example_count}"
    begin
      @configuration.run_hook(:before, :suite)
      @world.example_groups.map {|g| g.run(reporter) }.all? ? 0 : @configuration.failure_exit_code
    ensure
      @configuration.run_hook(:after, :suite)
    end
  end

  def reporter
    return @reporter if @reporter

    @reporter = BasicObject.new
    def @reporter.method_missing(*args); Kernel.p args; end
    def @reporter.example_failed(example)
      exception = example.metadata[:execution_result][:exception]

      Kernel.puts "FAILED: #{example.description}"
      Kernel.puts "#{exception.class.name}: #{exception.message}"
    end

    def @reporter.example_started(example)
      Kernel.puts "starting: #{example.description}"
    end

    def @reporter.example_passed(example)
      Kernel.puts "PASSED: #{example.description}"
    end

    @reporter
  end
end

OpalRSpecRunner.new.run($stdout, $stdout)