class OpalClosedTtyIO < IO
  include IO::Writable

  def initialize(io_type)
    raise "Unknown IO type #{io_type}!" unless [:stdout, :stderr].include?(io_type)
    self.write_proc = case io_type
                      when :stdout then $stdout.write_proc
                      when :stderr then $stderr.write_proc
                      end
    @tty = true
  end

  # We're deferring to stdout here, which doesn't need to be closed, but RSpec::BaseTextFormatter doesn't know that, so override this
  def closed?
    true
  end
end
