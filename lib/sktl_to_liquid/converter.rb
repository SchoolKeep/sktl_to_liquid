# frozen_string_literal: true

class SktlToLiquid::Converter
  ARRAY_EMPTY_CHECK_EXPRESSIONS = [
    "courses",
    "course.instructors",
    "course.partnerships",
    "learning_path.instructors",
    "homepage.published_featured_courses",
    "learning_path.items",
    "current_person.filterable_catalog_categories",
    "current_person.filterable_learning_path_categories",
    "current_person.filterable_categories"
  ].freeze

  ConversionError = Class.new(StandardError)

  def initialize(body)
    @body = body
    @scope_stack = []
  end

  def convert
    liquid_template = ""

    template.parse[:template].each do |segment|
      liquid_template += convert_toplevel(segment)
    end

    post_process(liquid_template)
  end

  private

  attr_reader :body, :scope_stack

  def template
    @template ||= Scribble::Template.new(body)
  end

  # very specific use cases, easier to change this way
  def post_process(liquid_template)
    liquid_template = liquid_template.gsub(
      "{{ course.progress_text | minus: ' Complete' }}",
      "{{ course.progress }}%"
    )
    liquid_template = liquid_template.gsub(
      'class="{{ no_filter_selected_class }}"',
      'class="uk-text-bold"'
    )
    liquid_template
  end

  def convert_toplevel(segment)
    result = convert_segment(segment)

    case SktlToLiquid::Type.new(segment).to_sym
    when :chain, :call_or_variable
      "{{ #{result} }}"
    when :call, :ending, :loop, :else, :partial,
      :pluralize, :learning_path_item, :display_search_form
      "{% #{result} %}"
    else
      result
    end
  end

  def convert_segment(segment)
    type = SktlToLiquid::Type.new(segment).to_sym

    case type
    when :text, :string, :number
      convert_text(segment[type])
    when :chain
      convert_chain(segment[:chain])
    when :call_or_variable, :else
      convert_call_or_variable(segment[:call_or_variable])
    when :call
      convert_call(segment[:call])
    when :ending
      add_ending
    when :loop
      convert_loop(segment[:chain])
    when :partial
      convert_partial(segment[:call])
    when :enrolled_in?
      convert_enrolled_in(segment[:call])
    when :access_course?
      convert_access_course(segment[:call])
    when :pluralize
      convert_pluralize(segment[:call])
    when :app
      convert_app(segment[:chain])
    when :learning_path_item
      convert_learning_path_item(segment[:call])
    when :display_search_form
      convert_display_search_form(segment[:call])
    when :filter
      convert_filter(segment)
    when *SktlToLiquid::Type::OPERATORS
      convert_operator(segment)
    else
      raise ConversionError, "uknown segment: #{segment}"
    end
  end

  #
  # {:text=>" uk-container-center"@1838}
  #
  def convert_text(slice)
    slice.to_s
  end

  #
  # :chain=>[
  #   {:call_or_variable=>{:name=>"routes"@178}},
  #   {:call_or_variable=>{:name=>"my_content_path"@185}}]
  #
  def convert_chain(chain_segment)
    chain_body = ""

    chain_segment.each_with_index do |segment, index|
      is_filter = SktlToLiquid::Type::FILTERS.include?(segment.dig(:call, :name)&.to_sym) ||
        SktlToLiquid::Type::FILTERS.include?(segment.dig(:call_or_variable, :name)&.to_sym)

      if !index.zero? && !SktlToLiquid::Type::OPERATORS.include?(segment.keys.first) && !is_filter
        chain_body += "."
      end

      if is_filter
        chain_body += " "
      end

      chain_body += convert_segment(segment)
    end

    chain_body
  end

  #
  # :chain=>[
  #   {:call_or_variable=>{:name=>"course"@2197}},
  #   {:call_or_variable=>{:name=>"instructors"@2204}},
  #   {:call=>{:name=>"each"@2216, :args=>{:string=>"instructor"@2222}}}]
  #
  def convert_loop(segment)
    scope_stack << :for

    loop_segment = segment.dup

    single_element_part = loop_segment.pop[:call]
    single_element_part = convert_segment(single_element_part[:args])

    collection_part = convert_segment(
      chain: loop_segment
    )

    "for #{single_element_part} in #{collection_part}"
  end

  #
  # {:call_or_variable=>{:name=>"course"@1291}}
  #
  def convert_call_or_variable(slice)
    slice[:name].to_s
  end

  #
  # :call=>{
  #   :name=>"if"@1001,
  #   :args=>{
  #     :chain=>[
  #       {:call_or_variable=>{:name=>"course"@1004}},
  #       {:call_or_variable=>{:name=>"learner_can_retake?"@1011}}]}}}
  #
  def convert_call(call_segment)
    name = call_segment[:name].to_sym
    args = Array.wrap(call_segment[:args])
    call_arg = ""

    args.each_with_index do |arg, index|
      call_arg += convert_segment(arg)
      call_arg += ", " unless args.size == index + 1
    end

    if [:if, :unless].include?(name)
      scope_stack << name

      if ARRAY_EMPTY_CHECK_EXPRESSIONS.include?(call_arg)
        return "#{name} #{call_arg}.any?"
      end

      if ["current_person", "current_learner"].include?(call_arg)
        return "#{name} #{call_arg}.signed_in?"
      end
    end

    "#{name} #{call_arg}"
  end

  #
  # {:ending=>"end"@1861}
  #
  def add_ending
    "end#{scope_stack.pop}"
  end

  #
  # :call=>{
  #   :name=>"partial"@2216,
  #   :args=>{:string=>"_learning_path"@2222}}}
  #
  def convert_partial(call_segment)
    partial_name = call_segment.dig(:args, :string).to_sym

    "include \"#{partial_name}\""
  end

  #
  # sktl:
  # current_person.enrolled_in_learning_path?(learning_path)
  #
  # liquid:
  # current_person.enrolled_in_learning_path?
  #
  def convert_enrolled_in(segment)
    segment[:name].to_s
  end

  #
  # [DEPRECATED] SchoolWebsite::PersonDecorator#access_course? has been
  # renamed to SchoolWebsite::PersonDecorator#enrolled_in_course?. It will remain
  # available until custom templates switch to enrolled_in_course?.
  #
  def convert_access_course(_segment)
    "enrolled_in_course?"
  end

  #
  # sktl:
  # pluralize(
  #   learning_path.instructors.count,
  #   t('.instructor_bio_title.one'),
  #   t('.instructor_bio_title.many')
  # )
  #
  # liquid:
  # pluralize learning_path.instructors.count, .instructor_bio_title
  #
  # [{:chain=>[
  #    {:call_or_variable=>{:name=>"learning_path"@2373}},
  #    {:call_or_variable=>{:name=>"instructors"@2387}},
  #    {:call_or_variable=>{:name=>"count"@2399}}]
  #  },
  #  {:call=>{:name=>"t"@2406, :args=>{:string=>".instructor_bio_title.one"@2409}}},
  #  {:call=>{:name=>"t"@2438, :args=>{:string=>".instructor_bio_title.many"@2441}}}]
  #
  def convert_pluralize(segment)
    args = segment[:args]

    first_arg = convert_segment(args.first)
    second_arg = args.second.dig(:call, :args, :string).to_s.split(".").second
    second_arg = ".#{second_arg}"

    "pluralize #{first_arg}, #{second_arg}"
  end

  #
  # sktl:
  # app('commerce').active?
  #
  # liquid:
  # current_school.apps.commerce.active?
  #
  def convert_app(segment)
    name = segment.first.dig(:call, :args, :string).to_sym

    "current_school.apps.#{name}.active?"
  end

  #
  # {:greater=>{:op=>"> "@5426, :arg=>{:number=>"3"@5428}}}
  #
  def convert_operator(segment)
    seg = segment[segment.keys.first]
    op = seg[:op].to_s.strip

    operator_map = {
      "|" => "or",
      "&" => "and",
      "=" => "==",
      "-" => "| minus:",
      "+" => "| plus:",
      "!=" => "!=",
      ">" => ">",
      "<" => "<"
    }

    arg = seg[:arg].dup

    if ["=", "-", "+", "!="].include?(op) && arg[:string].present?
      arg[:string] = "'#{arg[:string]}'"
    end

    " #{operator_map[op]} #{convert_segment(arg)}"
  end

  #
  # {% learning_path_item learning_path.current_person_learning_path_item %}
  #   <button class="uk-button uk-float-right completion-button">
  #     {% t .continue %}
  #   </button>
  # {% endlearning_path_item %}
  #
  def convert_learning_path_item(segment)
    scope_stack << :learning_path_item
    convert_call(segment)
  end

  #
  # sktl:
  # {{ if display_search_form }}
  #   <li class="uk-padding-top">
  #     {{ partial 'search_form' }}
  #   </li>
  # {{ end }}
  #
  # liquid:
  #  {% search %}
  #    <li class="uk-padding-top">
  #      {% include "search_form" %}
  #    </li>
  #  {% endsearch %}
  #
  def convert_display_search_form(segment)
    name = segment.dig(:args, :call_or_variable, :name).to_sym

    if name == :display_search_form
      scope_stack << :search
      "search"
    elsif name == :display_catalog_search_form
      scope_stack << :catalog_search
      "catalog_search"
    end
  end

  #
  # sktl:
  # {{ course.enrollment_url.replace('catalog', 'syllabus').replace('/enrollments', '') }}
  # {{ person.name.truncate_words 1, '' }}
  # {{ course.name.downcase }}
  #
  # liquid:
  # {{ course.enrollment_url | replace: 'catalog', 'syllabus' | replace: '/enrollments', '' }}
  # {{ person.name | truncatewords: 1, '' }}
  # {{ course.name | downcase }}
  #
  def convert_filter(segment)
    name = segment[segment.keys.first][:name].to_sym
    seg_args = segment[segment.keys.first][:args]

    if seg_args.nil?
      return "| #{name}"
    end

    args = seg_args.map { |arg|
      if arg[:number].present?
        arg[:number].to_s
      else
        "\"#{arg[:string]}\""
      end
    }.join(", ")

    name_map = {
      replace: :replace,
      truncate_words: :truncatewords
    }

    "| #{name_map[name]}: #{args}"
  end
end
