# frozen_string_literal: true

class SktlToLiquid::Type
  FILTERS = [:replace, :truncate_words, :downcase].freeze
  OPERATORS = [:greater, :or, :and, :equals, :subtract, :differs, :add].freeze

  def initialize(segment)
    @segment = segment
  end

  def to_sym
    type = segment.keys.first

    if type == :chain && loop_each_segment?
      :loop
    elsif type == :call_or_variable && else_segment?
      :else
    elsif type == :call && display_search_form_segment?
      :display_search_form
    elsif type == :call && partial_segment?
      :partial
    elsif type == :call && enrolled_in_segment?
      :enrolled_in?
    elsif type == :call && access_course_segment?
      :access_course?
    elsif type == :call && pluralize_segment?
      :pluralize
    elsif type == :chain && app_segment?
      :app
    elsif type == :call && learning_path_item_segment?
      :learning_path_item
    elsif type == :call && filter_segment?
      :filter
    elsif type == :call_or_variable && filter_segment?
      :filter
    else
      type
    end
  end

  private

  attr_reader :segment

  def loop_each_segment?
    segment[:chain].select { |s| s.key?(:call) }.any? { |s| s.dig(:call, :name).to_sym == :each }
  end

  def else_segment?
    segment.dig(:call_or_variable, :name).to_sym == :else
  end

  def partial_segment?
    segment.dig(:call, :name).to_sym == :partial
  end

  def app_segment?
    segment[:chain].any? { |s| s.dig(:call, :name)&.to_sym == :app }
  end

  def enrolled_in_segment?
    [
      :enrolled_in_learning_path?,
      :enrolled_in_course?,
      :progress_text
    ].include?(segment.dig(:call, :name).to_sym)
  end

  def access_course_segment?
    [
      :access_course?
    ].include?(segment.dig(:call, :name).to_sym)
  end

  def pluralize_segment?
    segment.dig(:call, :name).to_sym == :pluralize
  end

  def learning_path_item_segment?
    segment.dig(:call, :name).to_sym == :learning_path_item
  end

  def display_search_form_segment?
    return false if segment.dig(:call, :name).to_sym != :if

    [
      :display_search_form,
      :display_catalog_search_form
    ].include?(segment.dig(:call, :args, :call_or_variable, :name)&.to_sym)
  end

  def filter_segment?
    FILTERS.include?(segment.dig(:call, :name)&.to_sym) ||
      FILTERS.include?(segment.dig(:call_or_variable, :name)&.to_sym)
  end
end
