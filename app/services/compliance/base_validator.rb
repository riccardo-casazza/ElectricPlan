module Compliance
  class BaseValidator
    attr_reader :resource, :validation

    def initialize(resource, validation)
      @resource = resource
      @validation = validation
    end

    def valid?
      raise NotImplementedError
    end

    def context
      raise NotImplementedError
    end

    protected

    # Query helpers
    def items_of_type(type_name)
      return Item.none unless resource.respond_to?(:items)
      resource.items.joins(:item_type).where("LOWER(item_types.name) = ?", type_name.downcase)
    end

    def has_items_of_type?(type_name)
      items_of_type(type_name).exists?
    end

    def count_items_of_type(type_name)
      items_of_type(type_name).count
    end

    def sum_power_for_type(type_name)
      items_of_type(type_name).sum(:power_watts)
    end

    def all_item_type_names
      return [] unless resource.respond_to?(:items)
      resource.items.joins(:item_type).pluck("LOWER(item_types.name)").uniq
    end

    def get_nested_value(path)
      return nil unless resource

      parts = path.to_s.split(".")
      parts.shift if parts.first&.downcase == resource.class.name.downcase

      parts.reduce(resource) do |obj, method|
        return nil if obj.nil?
        return nil unless obj.respond_to?(method)
        obj.public_send(method)
      end
    end
  end
end
