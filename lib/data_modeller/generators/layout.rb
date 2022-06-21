# frozen_string_literal: true

module DataModeller
  module Generators
    class Layout < Base
      def generate
        generate_navbar
      end

      private

      def generate_navbar
        init_new_file('layouts/_navbar.html.slim')

        add_line('nav.navbar.navbar-expand-lg.navbar-light.bg-light', deeper: true)
        add_line('.container', deeper: true)
        add_line("a.navbar-brand href='/' Brand")
        add_line("button.navbar-toggler aria-controls='navbarSupportedContent' aria-expanded='false' aria-label='Toggle navigation' " \
                 "data-target='#navbarSupportedContent' data-toggle='collapse' type='button'", deeper: true)
        add_line('span.navbar-toggler-icon')
        @nesting = 2
        add_line('#navbarSupportedContent.collapse.navbar-collapse', deeper: true)
        add_line('ul.navbar-nav.mr-auto', deeper: true)
        add_line('li.nav-item', deeper: true)
        add_line("a.nav-link href='/'", deeper: true)
        add_line('| Home')

        use_devise = false
        @configs.each do |name, config|
          use_devise = true if config.dig(:properties, :devise)

          next if config[:actions].blank?

          resources = ActiveSupport::Inflector.pluralize(name)
          title = ActiveSupport::Inflector.humanize(resources)

          @nesting = 4
          add_line('- if current_user', deeper: true) if @config[:authenticate]
          add_line("li class=\"nav-item \#{controller_name == '#{resources}' && 'active'}\"", deeper: true)
          add_line("a.nav-link href=#{resources}_path", deeper: true)
          add_line("| #{title}")
        end

        return unless use_devise

        @nesting = 3
        add_line('ul.navbar-nav', deeper: true)
        add_line('- if current_user', deeper: true)
        add_line('li.nav-item.dropdown', deeper: true)
        add_line("a#userDropdown.nav-link.dropdown-toggle aria-expanded='false' aria-haspopup='true' data-toggle='dropdown' href='#' role='button'", deeper: true)
        add_line('= current_user.name')
        @nesting -= 1
        add_line(".dropdown-menu aria-labelledby='userDropdown'", deeper: true)
        add_line('a.dropdown-item href="#" Profile')
        add_line('a.dropdown-item href=destroy_user_session_path', deeper: true)
        add_line('| Log out')
        @nesting = 4
        add_line('- else', deeper: true)
        add_line('li.nav-item', deeper: true)
        add_line('a.nav-link href=new_user_session_path', deeper: true)
        add_line('| Log in')
      end

      def add_line(line = nil, deeper: false)
        if line.blank?
          @current_file << ''
        else
          @current_file << "#{INDENT_CHAR * INDENT_NUM * @nesting}#{line}"
          @nesting += 1 if deeper
        end
      end
    end
  end
end
