# frozen_string_literal: true

module DataModeller
  module Generators
    class View < Layout
      def generate
        return if @config[:actions].blank?

        @model_classname = ActiveSupport::Inflector.camelize(@resource_name)

        @config[:actions].each_key do |action|
          next if %i[create update destroy].include?(action)

          send("generate_#{action}".to_sym)
        end

        generate_devise_views(@config[:properties][:devise]) if @config.dig(:properties, :devise)
      end

      private

      def generate_index
        init_new_file("#{@resources_name}/index.html.slim")

        add_line("h1 #{ActiveSupport::Inflector.humanize(@resources_name)}")
        add_line
        add_line("table class='table'", deeper: true)
        add_line('thead', deeper: true)
        add_line('tr', deeper: true)

        @config[:attributes].each do |attribute, props|
          next if props[:list_view_exclude]

          add_line("th scope='col' #{ActiveSupport::Inflector.humanize(attribute)}")
        end

        add_line("th scope='col' Email") if @config.dig(:properties, :devise) && @config[:properties][:devise]['database_authenticatable']
        add_line("th scope='col'")
        add_line("th scope='col'")
        add_line

        @nesting = 1
        add_line('tbody', deeper: true)
        add_line("= render partial: 'list_item', collection: @#{@resources_name}, as: :resource")
        add_line

        @nesting = 0
        add_line('br')
        add_line
        if @config.dig(:properties, :devise) && @config[:properties][:devise]['invitable']
          add_line("= link_to 'Invite New #{ActiveSupport::Inflector.humanize(@resource_name)}', new_#{@resource_name}_invitation_path")
        else
          add_line("= link_to 'New #{ActiveSupport::Inflector.humanize(@resource_name)}', new_#{@resource_name}_path")
        end

        init_new_file("#{@resources_name}/_list_item.html.slim")

        add_line('tr', deeper: true)

        @config[:attributes].each_with_index do |(attribute, props), i|
          next if props[:list_view_exclude]

          @nesting = 1
          add_line('td', deeper: true)
          add_line("a href=#{@resource_name}_path(resource)", deeper: true) if i.zero?
          if props[:type] == 'reference'
            attribute_shown_by = props[:shown_by] || 'name'
            add_line("= resource.#{attribute}.try(:#{attribute_shown_by})")
          else
            add_line("= resource.#{attribute}")
          end
        end

        add_line('td= resource.email') if @config.dig(:properties, :devise) && @config[:properties][:devise]['database_authenticatable']

        @nesting = 1
        add_line('td', deeper: true)
        add_line("a href=edit_#{@resource_name}_path(resource)", deeper: true)
        add_line("i class='fas fa-edit'")

        @nesting = 1
        add_line('td', deeper: true)
        add_line("a href=#{@resource_name}_path(resource) rel='nofollow' data-method='delete' data-confirm='Are you sure?'", deeper: true)
        add_line("i class='fas fa-trash-alt'")
      end

      def generate_show
        init_new_file("#{@resources_name}/show.html.slim")

        add_line("h1 #{ActiveSupport::Inflector.humanize(@resource_name)}")
        add_line
        add_line('p#notice= notice')
        add_line
        add_line("= render 'details', resource: @#{@resource_name}")

        init_new_file("#{@resources_name}/_details.html.slim")

        @config[:attributes].each do |attribute, props|
          next if props[:details_view_exclude]

          @nesting = 0
          add_line('p', deeper: true)
          add_line("b #{ActiveSupport::Inflector.humanize(attribute)}:&nbsp;")
          if props[:type] == 'reference'
            attribute_shown_by = props[:shown_by] || 'name'
            add_line("= resource.#{attribute}.try(:#{attribute_shown_by})")
          else
            add_line("= resource.#{attribute}")
          end
        end
      end

      def generate_new
        init_new_file("#{@resources_name}/new.html.slim")

        add_line("h1 New #{@resource_name}")
        add_line
        add_line("= render 'form', resource: @#{@resource_name}")

        generate_form
      end

      def generate_edit
        init_new_file("#{@resources_name}/edit.html.slim")

        add_line("h1 Editing #{@resource_name}")
        add_line
        add_line("= render 'form', resource: @#{@resource_name}")

        generate_form
      end

      def generate_form
        init_new_file("#{@resources_name}/_form.html.slim")

        add_line('= form_for resource do |f|', deeper: true)
        add_line('- if resource.errors.any?', deeper: true)
        add_line(".alert.alert-danger role='alert'", deeper: true)
        add_line("h4= \"\#{pluralize(resource.errors.count, \"error\")} prohibited this #{@resource_name} from being saved:\"")
        add_line('ul', deeper: true)
        add_line('- resource.errors.full_messages.each do |message|', deeper: true)
        add_line('li= message')
        add_line

        @config[:attributes].each do |attribute, props|
          next if props[:form_view_exclude]

          @nesting = 1
          add_line('.form-group.row', deeper: true)
          add_line("= f.label :#{attribute}, class: 'col-sm-2 col-form-label'")

          if props[:original_type] == 'password'
            add_line('.col-sm-10', deeper: true)
            add_line("= f.password_field :#{attribute}, autocomplete: 'off', class: 'form-control'")
          elsif props[:original_type] == 'email'
            add_line('.col-sm-10', deeper: true)
            add_line("= f.email_field :#{attribute}, autocomplete: 'email', class: 'form-control'")
          elsif props[:original_type] == 'money'
            add_line('.col-sm-3', deeper: true)
            add_line("= f.text_field :#{attribute}, autocomplete: 'off', class: 'form-control'")
          elsif props[:original_type] == 'enum'
            add_line('.col-sm-10', deeper: true)
            enum_values = ActiveSupport::Inflector.pluralize(attribute)
            add_line("= f.select :#{attribute}, #{@model_classname}.#{enum_values}.keys, { include_blank: true }, class: 'form-control'")
          elsif props[:type] == 'reference'
            attribute_name = "#{attribute}_id"
            attribute_model = props[:class_name] || ActiveSupport::Inflector.camelize(attribute)
            attribute_ref_by = 'id'
            attribute_shown_by = props[:shown_by] || 'name'
            add_line('.col-sm-10', deeper: true)
            add_line("= f.collection_select :#{attribute_name}, #{attribute_model}.all, :#{attribute_ref_by}, :#{attribute_shown_by}, { include_blank: true }, class: 'form-control'")
          elsif props[:type] == 'text'
            add_line('.col-sm-10', deeper: true)
            add_line("= f.text_area :#{attribute}, rows: 5, class: 'form-control'")
          elsif props[:type] == 'date'
            add_line('.col-sm-3', deeper: true)
            add_line("= f.text_field :#{attribute}, autocomplete: 'off', class: 'form-control datepicker'")
          else
            add_line('.col-sm-10', deeper: true)
            add_line("= f.text_field :#{attribute}, autocomplete: 'off', class: 'form-control'")
          end
        end

        if @config[:associations].present?
          @config[:associations].each do |association, props|
            next unless props[:type] == 'has_and_belongs_to_many'

            association_name = ActiveSupport::Inflector.singularize(association)

            @nesting = 1
            add_line('.form-group.row', deeper: true)
            add_line("= f.label :#{association_name}, class: 'col-sm-2 col-form-label'")

            attribute_name = "#{association_name}_ids"
            attribute_model = props[:class_name] || ActiveSupport::Inflector.camelize(association_name)
            attribute_ref_by = 'id'
            attribute_shown_by = props[:shown_by] || 'name'
            add_line('.col-sm-10', deeper: true)
            add_line("= f.collection_select :#{attribute_name}, #{attribute_model}.all, :#{attribute_ref_by}, :#{attribute_shown_by}, {}, multiple: true, size: 5, class: 'form-control'")
          end
        end

        @nesting = 1
        add_line('.form-group.row', deeper: true)
        add_line('.col-sm-10.offset-sm-2', deeper: true)
        add_line("= f.submit 'Save', class: 'btn btn-primary'")
        add_line("a.btn.btn-link href=#{@resources_name}_path role='button' Cancel")
      end

      def generate_devise_views(options)
        templates = %w[
          devise/shared/_error_messages.html.slim
          devise/shared/_links.html.slim
        ]

        templates << 'devise/sessions/new.html.slim' if options['database_authenticatable']

        if options['recoverable']
          templates << 'devise/passwords/new.html.slim'
          templates << 'devise/passwords/edit.html.slim'
          templates << 'devise/mailer/reset_password_instructions.html.slim'
          templates << 'devise/mailer/password_change.html.slim'
        end

        if options['confirmable']
          templates << 'devise/confirmations/new.html.slim'
          templates << 'devise/mailer/confirmation_instructions.html.slim'
        end

        if options['lockable']
          templates << 'devise/unlocks/new.html.slim'
          templates << 'devise/mailer/unlock_instructions.html.slim'
        end

        if options['invitable']
          templates << 'devise/invitations/new.html.slim'
          templates << 'devise/invitations/edit.html.slim'
          templates << 'devise/mailer/invitation_instructions.html.slim'
        end

        templates_path = Pathname.new(File.join(__dir__, '../../../data/templates')).cleanpath

        templates.each do |template|
          @files[template] = File.read(File.join(templates_path, template))
        end
      end
    end
  end
end
