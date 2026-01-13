class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Include automatic rule verification for all models
  include AutoRuleVerification
end
