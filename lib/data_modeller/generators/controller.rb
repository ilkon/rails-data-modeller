# frozen_string_literal: true

module DataModeller
  module Generators
    class Controller < Base
      def generate
        basename = "#{@resources_name}_controller"
        init_new_file("#{basename}.rb")

        add_line('# frozen_string_literal: true')
        add_line

        add_line("class #{ActiveSupport::Inflector.camelize(basename)} < ApplicationController", deeper: true)

        %i[filters actions].each do |section|
          content_count = @current_file.count
          send("generate_#{section}".to_sym)

          add_line if @current_file.count > content_count
        end

        add_line('end')
      end

      private

      def generate_filters
        add_line("before_action :set_#{@resource_name}, only: %i[show edit update destroy]")
        add_line("before_action :authenticate_#{@config[:authenticate][:as]}!") if @config[:authenticate]
      end

      def generate_actions
        return if @config[:actions].blank?

        @model_classname = ActiveSupport::Inflector.camelize(@resource_name)

        @config[:actions].each do |action, props|
          content_count = @current_file.count
          send("generate_#{action}".to_sym, props)

          add_line if @current_file.count > content_count
        end

        add_line('private')
        add_line

        %i[set_resource resource_params].each do |action|
          content_count = @current_file.count
          send("generate_#{action}".to_sym)

          add_line if @current_file.count > content_count
        end
      end

      def generate_index(_props)
        add_line('def index', deeper: true)

        add_line("@#{@resources_name} = #{@model_classname}.all")

        add_line('end')
      end

      def generate_show(_props)
        add_line('def show; end')
      end

      def generate_new(_props)
        add_line('def new', deeper: true)
        add_line("@#{@resource_name} = #{@model_classname}.new")
        add_line('end')
      end

      def generate_edit(_props)
        add_line('def edit; end')
      end

      def generate_create(_props)
        add_line('def create', deeper: true)
        add_line("@#{@resource_name} = #{@model_classname}.new(#{@resource_name}_params)")
        add_line
        add_line("if @#{@resource_name}.save", deeper: true)
        add_line("redirect_to #{@resources_name}_path, notice: '#{ActiveSupport::Inflector.humanize(@resource_name)} was successfully created.'")
        add_line('else', deeper: true)
        add_line('render :new')
        add_line('end')
        add_line('end')
      end

      def generate_update(_props)
        add_line('def update', deeper: true)
        add_line("if @#{@resource_name}.update(#{@resource_name}_params)", deeper: true)
        add_line("redirect_to #{@resources_name}_path, notice: '#{ActiveSupport::Inflector.humanize(@resource_name)} was successfully updated.'")
        add_line('else', deeper: true)
        add_line('render :edit')
        add_line('end')
        add_line('end')
      end

      def generate_destroy(_props)
        add_line('def destroy', deeper: true)
        add_line("@#{@resource_name}.destroy")
        add_line("redirect_to #{@resources_name}_path, notice: '#{ActiveSupport::Inflector.humanize(@resource_name)} was successfully destroyed.'")
        add_line('end')
      end

      def generate_set_resource
        add_line("def set_#{@resource_name}", deeper: true)

        add_line("@#{@resource_name} = #{@model_classname}.find(params[:id])")

        add_line('end')
      end

      def generate_resource_params
        attributes = @config[:attributes].each_with_object([]) do |(attribute, props), arr|
          attribute_name = props[:type] == 'reference' ? "#{attribute}_id" : attribute
          arr << ":#{attribute_name}" unless props[:form_view_exclude]
        end

        if @config[:associations].present?
          @config[:associations].each do |association, props|
            next unless props[:type] == 'has_and_belongs_to_many'

            attributes << "{ #{ActiveSupport::Inflector.singularize(association)}_ids: [] }"
          end
        end

        add_line("def #{@resource_name}_params", deeper: true)
        add_line("params.require(:#{@resource_name}).permit(#{attributes.join(', ')})")
        add_line('end')
      end
    end
  end
end
