require 'spec_helper'
require 'logger'

describe CircuitBreaker do
  $LOGGER = Logger.new(STDOUT)
  class TestClass
    def do_something args
      sleep 1
      args
    end
  end

  before(:each) do
    @t = TestClass.new
    @cb = CircuitBreaker::CircuitHandler.new { |args| @t.do_something args }
  end


  it 'has a version number' do
    expect(CircuitBreaker::VERSION).not_to be nil
  end

  context "when closed" do
    it 'should raise error when timeout' do
      @cb.invocation_timeout = 0.01

      expect { @cb.call(5) }.to raise_error("execution expired")
      expect(@cb.state).to equal(:closed)
    end

    it 'should succeed when time is not out' do
      expect(@cb.call(5)).to equal(5)
      expect(@cb.state).to equal(:closed)
    end

  end
end
