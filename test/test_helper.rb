ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Require storage adapters for testing
require_relative "../app/services/storage_adapters/storage_backend"
require_relative "../app/services/storage_adapters/database_storage_adapter"
require_relative "../app/services/storage_adapters/local_file_storage_adapter"
require_relative "../app/services/storage_adapters/s3_storage_adapter"
require_relative "../app/services/storage_adapters/ftp_storage_adapter"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
