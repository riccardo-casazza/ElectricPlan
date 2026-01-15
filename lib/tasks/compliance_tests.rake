namespace :test do
  desc "Run compliance engine tests"
  task compliance: :environment do
    require "minitest"
    require "minitest/autorun"

    # Load test helper manually
    ENV["RAILS_ENV"] = "test"
    require Rails.root.join("test", "test_helper")

    # Disable parallel testing to avoid the Rails 8 bug
    ActiveSupport::TestCase.parallelize(workers: 1)

    # Load and run the compliance tests
    require Rails.root.join("test", "services", "compliance_engine_test")

    # Run tests
    exit_code = Minitest.run([])
    exit(exit_code) if exit_code != 0
  end
end
