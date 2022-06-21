# frozen_string_literal: true

module DataModeller
  module Generators
    class Route < Base
      def generate
        init_new_file('routes.rb')

        add_line('# frozen_string_literal: true')
        add_line

        add_line('Rails.application.routes.draw do', deeper: true)

        add_line('# Data Modeller: begin')
        generate_routes
        add_line('# Data Modeller: end')

        add_line('end')
      end

      private

      def generate_routes
        @configs.each_with_index do |(name, config), i|
          next if config[:actions].blank?

          resources = ActiveSupport::Inflector.pluralize(name)
          add_line("devise_for :#{resources}") if config.dig(:properties, :devise).present?

          if config[:actions].keys.sort == %i[index show new edit create update destroy].sort
            add_line("resources :#{resources}")
          else
            add_line("resources :#{resources}, only: %i[#{config[:actions].keys.join(' ')}]")
          end

          add_line("root to: '#{resources}#index'") if i.zero?
        end
      end
    end
  end
end
