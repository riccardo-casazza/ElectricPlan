class VerifyAllRulesJob < ApplicationJob
  queue_as :default

  def perform
    # Verify all rules
    Rule.find_each do |rule|
      verifier = RuleVerifier.new(rule)
      verifier.verify
    end
  end
end
