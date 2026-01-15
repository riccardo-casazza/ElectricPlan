#!/usr/bin/env ruby
# Manual test runner to bypass Rails 8/Minitest 6 compatibility issues
# This will be replaced once the issue is resolved

ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "minitest/autorun"

# Disable Rails line filtering that causes the ArgumentError
Rails::TestUnit::Runner.singleton_class.prepend(Module.new do
  def run(args = [])
    # Run with default options, bypassing line filtering
    Minitest.run([])
  end
end)

# Load the compliance test
require_relative "services/compliance_engine_test"
