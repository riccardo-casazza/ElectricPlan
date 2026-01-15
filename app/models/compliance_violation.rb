# Plain Old Ruby Object to represent a compliance violation
# Not persisted to database - calculated on demand
class ComplianceViolation
  attr_reader :rule_code, :severity, :message, :help, :resource, :context

  def initialize(rule_code:, severity:, message:, help:, resource:, context: {})
    @rule_code = rule_code
    @severity = severity.to_sym
    @message = interpolate_message(message, context)
    @help = interpolate_message(help, context)
    @resource = resource
    @context = context
  end

  # Check if this is an error-level violation
  def error?
    severity == :error
  end

  # Check if this is a warning-level violation
  def warning?
    severity == :warning
  end

  # Get a human-readable resource identifier
  def resource_identifier
    resource.try(:name) || "#{resource.class.name} ##{resource.id}"
  end

  # Get CSS class for styling based on severity
  def css_class
    case severity
    when :error
      "violation-error"
    when :warning
      "violation-warning"
    when :info
      "violation-info"
    else
      "violation"
    end
  end

  private

  # Interpolate placeholders in message/help strings with context values
  # Examples: "{actual_count}" -> "5", "{non_light_items}" -> "socket, oven"
  def interpolate_message(template, context)
    return template if context.empty?

    result = template.dup
    context.each do |key, value|
      placeholder = "{#{key}}"
      result.gsub!(placeholder, value.to_s) if result.include?(placeholder)
    end
    result
  end
end
