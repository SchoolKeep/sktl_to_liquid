# frozen_string_literal: true

RSpec.describe SktlToLiquid::Converter do
  context "atoms" do
    it "converts loop" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ courses.each 'course' }}
              {{ partial 'course' }}
            {{ end }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% for course in courses %}
            {% include "course" %}
          {% endfor %}
        LIQUID
      )
    end

    it "converts pluralize" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ pluralize(count, t('.course.one'), t('.course.many')) }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% pluralize count, .course %}
        LIQUID
      )
    end

    it "converts t" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ t('.hello') }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% t .hello %}
        LIQUID
      )
    end

    it "converts variable" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ variable }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {{ variable }}
        LIQUID
      )
    end

    it "converts if" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ if current_school.filtering_enabled? }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% if current_school.filtering_enabled? %}
        LIQUID
      )
    end

    it "converts if &" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ if current_school.filtering_enabled? & current_person.filterable_catalog_categories.any? }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% if current_school.filtering_enabled? and current_person.filterable_catalog_categories.any? %}
        LIQUID
      )
    end

    it "converts if |" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ if current_school.filtering_enabled? | current_person.filterable_catalog_categories.any? }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% if current_school.filtering_enabled? or current_person.filterable_catalog_categories.any? %}
        LIQUID
      )
    end

    it "converts unless" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ unless current_school.filtering_enabled? }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% unless current_school.filtering_enabled? %}
        LIQUID
      )
    end

    it "converts unless &" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ unless current_school.filtering_enabled? & current_person.filterable_catalog_categories.any? }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% unless current_school.filtering_enabled? and current_person.filterable_catalog_categories.any? %}
        LIQUID
      )
    end

    it "converts unless |" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ unless current_school.filtering_enabled? | current_person.filterable_catalog_categories.any? }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% unless current_school.filtering_enabled? or current_person.filterable_catalog_categories.any? %}
        LIQUID
      )
    end

    it "converts downcase" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ course.name.downcase }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {{ course.name | downcase }}
        LIQUID
      )
    end

    it "converts replace" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ course.enrollment_url.replace('catalog', 'syllabus').replace('/enrollments', '') }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {{ course.enrollment_url | replace: "catalog", "syllabus" | replace: "/enrollments", "" }}
        LIQUID
      )
    end

    it "converts truncate_words" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ person.name.truncate_words 1, '' }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {{ person.name | truncatewords: 1, "" }}
        LIQUID
      )
    end

    it "converts many filters" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ course.name.downcase.replace( ' ', '_' ).replace( ':', '' ) }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {{ course.name | downcase | replace: " ", "_" | replace: ":", "" }}
        LIQUID
      )
    end

    it "converts minus string" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ course.enrollment_url - 'Course' }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {{ course.enrollment_url | minus: 'Course' }}
        LIQUID
      )
    end

    it "converts minus number" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ course.enrollment_url - 1 }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {{ course.enrollment_url | minus: 1 }}
        LIQUID
      )
    end

    it "converts plus number" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ course.enrollment_url + 1 }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {{ course.enrollment_url | plus: 1 }}
        LIQUID
      )
    end

    it "converts plus string" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ course.enrollment_url + 'Course' }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {{ course.enrollment_url | plus: 'Course' }}
        LIQUID
      )
    end

    it "converts equal" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ course.enrollment_url = 'Course' }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {{ course.enrollment_url == 'Course' }}
        LIQUID
      )
    end

    it "converts app" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ if app('commerce').active? }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% if current_school.apps.commerce.active? %}
        LIQUID
      )
    end

    it "converts if display_search_form" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ if display_search_form }}
              <li class="uk-padding-top">
                {{ partial 'search_form' }}
              </li>
            {{ end }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% search %}
            <li class="uk-padding-top">
              {% include "search_form" %}
            </li>
          {% endsearch %}
        LIQUID
      )
    end

    it "converts if display_catalog_search_form" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ if display_catalog_search_form }}
              <li class="uk-padding-top">
                {{ partial 'search_form' }}
              </li>
            {{ end }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% catalog_search %}
            <li class="uk-padding-top">
              {% include "search_form" %}
            </li>
          {% endcatalog_search %}
        LIQUID
      )
    end

    it "converts learning_path_item" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ learning_path_item learning_path.current_person_learning_path_item }}
              <button class="uk-button uk-float-right completion-button">
                {{ t('.continue') }}
              </button>
            {{ end }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% learning_path_item learning_path.current_person_learning_path_item %}
            <button class="uk-button uk-float-right completion-button">
              {% t .continue %}
            </button>
          {% endlearning_path_item %}
        LIQUID
      )
    end

    it "converts enrolled_in_learning_path?" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ if current_person.enrolled_in_learning_path?(learning_path) }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% if current_person.enrolled_in_learning_path? %}
        LIQUID
      )
    end

    it "converts enrolled_in_course?" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ if current_person.enrolled_in_course?(course) }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% if current_person.enrolled_in_course? %}
        LIQUID
      )
    end

    it "converts if current_person" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ if current_person }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {% if current_person.signed_in? %}
        LIQUID
      )
    end

    it "converts if no_filter_selected_class" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            class="{{ no_filter_selected_class }}"
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          class="uk-text-bold"
        LIQUID
      )
    end

    it "converts strange way to display progress" do
      expect(
        SktlToLiquid::Converter.new(
          <<~SKTL
            {{ course.progress_text - ' Complete' }}
          SKTL
        ).convert
      ).to eq(
        <<~LIQUID
          {{ course.progress }}%
        LIQUID
      )
    end
  end
end
