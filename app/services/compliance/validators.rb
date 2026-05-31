module Compliance
  module Validators
    class ExclusiveType < BaseValidator
      def valid?
        return true unless resource.respond_to?(:items)
        all_item_type_names.all? { |t| t == validation["required_type"].downcase }
      end

      def context
        return {} unless resource.respond_to?(:items)
        required = validation["required_type"]
        non_matching = all_item_type_names.reject { |t| t == required.downcase }
        {
          "non_#{required}_items".to_sym => non_matching.join(", "),
          :non_light_items => (required == "light" ? non_matching.join(", ") : nil),
          :non_socket_items => (required == "socket" ? non_matching.join(", ") : nil)
        }.compact
      end
    end

    class MaxCount < BaseValidator
      TYPES = { "light_items" => "light", "socket_items" => "socket", "shutter_items" => "roller shutters" }.freeze

      def valid?
        type_name = TYPES[validation["attribute"]]
        return true unless type_name
        count_items_of_type(type_name) <= validation["max_value"]
      end

      def context
        type_name = TYPES[validation["attribute"]]
        return {} unless type_name
        { actual_count: count_items_of_type(type_name), max_value: validation["max_value"] }
      end
    end

    class MaxAttribute < BaseValidator
      def valid?
        attr = validation["attribute"]
        return true unless resource.respond_to?(attr)
        val = resource.public_send(attr)
        val.nil? || val <= validation["max_value"]
      end

      def context
        attr = validation["attribute"]
        { actual_value: resource.respond_to?(attr) ? resource.public_send(attr) : nil, max_value: validation["max_value"] }
      end
    end

    class AttributeInList < BaseValidator
      def valid?
        attr = validation["attribute"]
        return true unless resource.respond_to?(attr)
        validation["allowed_values"].include?(resource.public_send(attr))
      end

      def context
        attr = validation["attribute"]
        { actual_value: resource.respond_to?(attr) ? resource.public_send(attr) : nil, allowed_values: validation["allowed_values"].join(", ") }
      end
    end

    class AssociationAttribute < BaseValidator
      def valid?
        val = get_nested_value(validation["path"])
        val.nil? || val.to_s.downcase == validation["must_equal"].to_s.downcase
      end

      def context
        { actual_value: get_nested_value(validation["path"]), expected_value: validation["must_equal"] }
      end
    end

    class AssociationAttributeInList < BaseValidator
      def valid?
        val = get_nested_value(validation["path"])
        val.nil? || validation["allowed_values"].map(&:downcase).include?(val.to_s.downcase)
      end

      def context
        { actual_value: get_nested_value(validation["path"]), allowed_values: validation["allowed_values"].join(", ") }
      end
    end

    class AssociationCount < BaseValidator
      def valid?
        assoc = validation["association"]
        return true unless resource.respond_to?(assoc)
        resource.public_send(assoc).count <= validation["max_count"]
      end

      def context
        assoc = validation["association"]
        { actual_count: resource.respond_to?(assoc) ? resource.public_send(assoc).count : 0, max_count: validation["max_count"] }
      end
    end

    class MinCableSection < BaseValidator
      def valid?
        val = get_nested_value(validation["path"])
        return true if val.nil?
        min = validation["min_section"].to_f
        actual = val.to_f
        min.zero? || actual.zero? || actual >= min
      end

      def context
        { actual_value: get_nested_value(validation["path"]), min_section: validation["min_section"] }
      end
    end

    class MaxTotalPower < BaseValidator
      def valid?
        return true unless resource.respond_to?(:items)
        sum_power_for_type(validation["item_type"]) <= validation["max_power"]
      end

      def context
        total = resource.respond_to?(:items) ? sum_power_for_type(validation["item_type"]) : 0
        { total_power: total, max_power: validation["max_power"], item_type: validation["item_type"] }
      end
    end

    class BreakerExclusiveForType < BaseValidator
      def valid?
        return true unless resource.respond_to?(:items)
        types = validation["item_types"].map(&:downcase)
        return true unless resource.items.joins(:item_type).where("LOWER(item_types.name) IN (?)", types).exists?
        all_item_type_names.all? { |t| types.include?(t) }
      end

      def context
        types = validation["item_types"].map(&:downcase)
        non_allowed = all_item_type_names.reject { |t| types.include?(t) }
        { required_types: validation["item_types"].join(", "), non_allowed_items: non_allowed.join(", ") }
      end
    end

    class CurrentCableCombo < BaseValidator
      def valid?
        combos = validation["allowed_combos"]
        return true if combos.nil? || combos.empty?
        current = resource.output_max_current
        return true if current.nil?
        cable = get_nested_value("output_cable.section")
        if cable.nil?
          current <= combos.map { |c| c["max_current"] }.max
        else
          combos.any? { |c| current <= c["max_current"] && cable.to_f >= c["min_cable"].to_f }
        end
      end

      def context
        { actual_current: resource.output_max_current, actual_cable: get_nested_value("output_cable.section") }
      end
    end

    class PowerCurrentCableCombo < BaseValidator
      def valid?
        combos = validation["allowed_combos"]
        return true if combos.nil? || combos.empty? || !resource.respond_to?(:items)
        power = sum_power_for_type(validation["item_type"])
        return true if power.zero?
        current = resource.output_max_current
        return true if current.nil?
        combo = combos.find { |c| power <= c["max_power"] }
        return false if combo.nil?
        cable = get_nested_value("output_cable.section")
        current_ok = current >= combo["max_current"]
        cable.nil? ? current_ok : (current_ok && cable.to_f >= combo["min_cable"].to_f)
      end

      def context
        power = resource.respond_to?(:items) ? sum_power_for_type(validation["item_type"]) : 0
        { total_power: power, actual_current: resource.output_max_current, actual_cable: get_nested_value("output_cable.section") }
      end
    end

    class MinSockets < BaseValidator
      def valid?
        return true unless resource.respond_to?(:items)
        count_items_of_type("socket") >= validation["min_value"]
      end

      def context
        count = resource.respond_to?(:items) ? count_items_of_type("socket") : 0
        { actual_count: count, min_value: validation["min_value"],
          room_name: resource.respond_to?(:name) ? resource.name : "Unknown",
          surface_area: resource.respond_to?(:surface_area) ? resource.surface_area : nil }
      end
    end

    class MinSocketsByArea < BaseValidator
      def valid?
        return true unless resource.respond_to?(:items) && resource.respond_to?(:surface_area)
        count = count_items_of_type("socket")
        count >= min_required
      end

      def context
        count = resource.respond_to?(:items) ? count_items_of_type("socket") : 0
        area = resource.respond_to?(:surface_area) ? resource.surface_area.to_f : 0
        { actual_count: count, min_required: min_required,
          room_name: resource.respond_to?(:name) ? resource.name : "Unknown", surface_area: area }
      end

      private

      def min_required
        area = resource.respond_to?(:surface_area) ? resource.surface_area.to_f : 0
        min = validation["min_sockets"] || 1
        per_m2 = validation["sockets_per_m2"] || 0.25
        [min, (area * per_m2).ceil].max
      end
    end

    class LoadCalculation < BaseValidator
      def valid?
        return true unless resource.is_a?(ResidualCurrentDevice)
        totals = calculate_load
        resource.output_max_current >= totals[:required]
      end

      def context
        return {} unless resource.is_a?(ResidualCurrentDevice)
        totals = calculate_load
        { rcd_current: resource.output_max_current, required_current: totals[:required].round(1),
          full_load_sum: totals[:full], partial_load_sum: totals[:partial] }
      end

      private

      def calculate_load
        full_types = validation["full_load_types"] || []
        breakers = resource.breakers.includes(items: :item_type)
        full = 0
        partial = 0
        breakers.each do |b|
          next if b.items.empty?
          if b.items.any? { |i| full_types.include?(i.item_type.name.downcase) }
            full += b.output_max_current
          else
            partial += b.output_max_current
          end
        end
        { full: full, partial: partial, required: full + (partial * 0.5) }
      end
    end

    REGISTRY = {
      "exclusive_type" => ExclusiveType,
      "max_count" => MaxCount,
      "max_attribute" => MaxAttribute,
      "attribute_in_list" => AttributeInList,
      "association_attribute" => AssociationAttribute,
      "association_attribute_in_list" => AssociationAttributeInList,
      "association_count" => AssociationCount,
      "min_cable_section" => MinCableSection,
      "max_total_power" => MaxTotalPower,
      "breaker_exclusive_for_type" => BreakerExclusiveForType,
      "current_cable_combo" => CurrentCableCombo,
      "power_current_cable_combo" => PowerCurrentCableCombo,
      "min_sockets" => MinSockets,
      "min_sockets_by_area" => MinSocketsByArea,
      "load_calculation" => LoadCalculation
    }.freeze

    def self.for(type, resource, validation)
      klass = REGISTRY[type]
      klass&.new(resource, validation)
    end
  end
end
