module AutoRuleVerification
  extend ActiveSupport::Concern

  included do
    after_commit :verify_all_rules, on: [ :create, :update, :destroy ], unless: :skip_rule_verification?
  end

  private

  def skip_rule_verification?
    # Don't trigger verification for Rule and RuleViolation models to avoid infinite loops
    self.class.in?([ Rule, RuleViolation ])
  end

  def verify_all_rules
    # Run verification for all rules in the background
    # We use after_commit to ensure the transaction is complete
    VerifyAllRulesJob.perform_later
  end
end
