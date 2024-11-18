# frozen_string_literal: true

class FutureDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    return if value.is_a?(Time) && value > Time.current

    record.errors.add(attribute, :must_be_future)
  end
end
