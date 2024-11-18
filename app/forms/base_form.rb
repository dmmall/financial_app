# frozen_string_literal: true

class BaseForm
  MISSING = Object.new.freeze

  include ActiveModel::Model
  include ActiveSupport::Callbacks
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Attributes
  include ActiveRecord::AttributeMethods::BeforeTypeCast

  define_callbacks :save
  define_callbacks :initialize

  attr_reader :result

  class << self
    # Define form input params.
    #
    # All params stored in the `attributes` Hash,
    # this method defines accessors.
    #
    # The attributes list is stored in the class to
    # be used in generating filtering data for strong parameters.
    def attributes(*attrs)
      attrs.each { |name| attribute(name) }
    end

    # Define form input params with default: MISSING
    # need for assign_attributes to model, when not all parameters can be passed
    # `#passed_attributes` return attributes without MISSING value
    def optional_attributes(*attrs)
      attrs.each { |name| optional_attribute(name) }
    end

    def optional_attribute(name, type = ActiveModel::Type::Value.new, **options)
      attribute(name, type, **options.merge(default: MISSING))
    end

    def attribute(name, type = ActiveModel::Type::Value.new, **options)
      super
      # Add predicate methods for boolean types
      alias_method :"#{name}?", name if type == :boolean || type.is_a?(ActiveModel::Type::Boolean)

      # Is attribute passed
      define_method :"#{name}_passed?" do
        public_send("#{name}_before_type_cast") != MISSING
      end
    end

    def validate_model(model_name, **options)
      validate lambda {
        model = send(model_name)
        model.validate
        promote_errors(model)
      }, options
    end

    def after_save(*args, &block)
      set_callback :save, :after, *args, &block
    end

    def after_initialize(*args, &block)
      set_callback :initialize, :after, *args, &block
    end

    def without_unknown_attrs(attributes = {})
      new(
        attributes.select do |k|
          public_method_defined?("#{k}=")
        end
      )
    end

    def event_name
      "form.#{model_name.singular}.saved"
    end
  end

  def initialize(*)
    run_callbacks(:initialize) do
      super
    end
  end

  delegate :event_name, to: :class

  def passed_attributes
    attrs = attributes.reject { |attr, _val| public_send("#{attr}_before_type_cast") == MISSING }
    attrs.with_indifferent_access
  end

  def save
    return false unless valid?

    run_callbacks(:save) do
      @result = with_transaction { persist! }
    end

    notify_subscribers
    true
  end

  private

  def persist!
    raise_not_implemented :persist!
  end

  def with_transaction(&block)
    ApplicationRecord.transaction(&block)
  end

  # To receive notification with form object create class subscriber with process method
  # in ./subscribers
  def notify_subscribers
    ActiveSupport::Notifications.instrument(event_name, self)
  end

  # Merge errors from other record to form errors
  # Useful if you want to combine model errors
  # with form errors.
  #
  #   validate :validate_model
  #
  #   def validate_model
  #     return if model.valid?
  #
  #     promote_errors(model)
  #   end
  def promote_errors(other)
    other.errors.each do |error|
      errors.add(error.attribute, error.message)
    end
  end

  def raise_not_implemented(name)
    raise NotImplementedError, "Method #{self.class.name}##{name} must be defined"
  end

  def missing?(value)
    value == MISSING
  end
end
