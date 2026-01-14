module ApplicationHelper
  # Render compliance alerts for a resource
  # Options:
  #   include_upstream: include violations from parent resources (default: false)
  #   include_downstream: include violations from child resources (default: false)
  #   show_resource_link: show link to affected resource (default: false)
  def compliance_alerts_for(resource, options = {})
    return unless resource.respond_to?(:compliance_violations)

    violations = []

    # Add direct violations
    violations.concat(resource.compliance_violations)

    # Add upstream violations if requested
    if options[:include_upstream]
      violations.concat(resource.upstream_violations)
    end

    # Add downstream violations if requested
    if options[:include_downstream]
      violations.concat(resource.downstream_violations)
    end

    # Remove duplicates
    violations.uniq!

    return if violations.empty?

    render partial: "shared/compliance_alerts", locals: {
      violations: violations,
      show_resource_link: options[:show_resource_link] || false
    }
  end

  # Check if a resource has compliance errors
  def has_compliance_errors?(resource)
    resource.respond_to?(:has_compliance_errors?) && resource.has_compliance_errors?
  end

  # Get compliance status badge for display
  def compliance_status_badge(resource)
    return "" unless resource.respond_to?(:compliance_violations)

    if resource.compliant?
      content_tag(:span, "✓ Compliant", class: "badge badge-success")
    elsif resource.has_compliance_errors?
      content_tag(:span, "✗ Errors", class: "badge badge-error")
    elsif resource.has_compliance_warnings?
      content_tag(:span, "⚠ Warnings", class: "badge badge-warning")
    end
  end
end
