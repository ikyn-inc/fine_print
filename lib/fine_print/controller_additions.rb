module FinePrint
  module ControllerAdditions
    #
    # Internally these methods think of contract names as strings, not symbols.
    # Any names passed in as symbols are converted to strings.
    #
    def self.included(base)
      base.extend(ClassMethods)
    end

    def fine_print_skipped_contract_names
      @fine_print_skipped_contract_names ||= []
    end

    # See the README
    def fine_print_return
      redirect_to session.delete(:fine_print_return_to) || root_path
    end

    module ClassMethods
      # See the README
      def fine_print_get_signatures(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}

        filter_options = options.except(*FinePrint::SIGNATURE_OPTIONS)
        fine_print_options = options.slice(*FinePrint::SIGNATURE_OPTIONS)

        # Convert all names to string
        names = args.flatten.collect{|n| n.to_s}

        class_eval do
          before_filter(filter_options) do |controller|
            # If the user isn't signed in, they can't sign a contract.  Since there 
            # may be some pages that logged in and non-logged in users can visit,
            # just return quietly instead of raising an exception.
            user = FinePrint.current_user_proc.call(self)
            return true unless FinePrint.can_sign?(user)

            contract_names = names - fine_print_skipped_contract_names

            # Bail if nothing to do
            return true if contract_names.blank?

            unsigned_contract_names = 
              FinePrint.get_unsigned_contract_names(user, contract_names)

            # Ignore contracts that don't yet exist or aren't yet published (happens 
            # when adding code that requires a new contract but before that contract 
            # has been added and published)
            unsigned_contract_names.reject!{|name| FinePrint.get_contract(name).blank?}

            return true if unsigned_contract_names.empty?

            # http://stackoverflow.com/a/2165727/1664216
            session[:fine_print_return_to] = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
            # http://stackoverflow.com/a/6561953
            path = fine_print_options[:pose_contracts_path] || FinePrint.pose_contracts_path
            redirect_to path + (path.include?('?') ? '&' : '?') + {:terms => unsigned_contract_names}.to_query
          end
        end
      end

      # See the README
      def fine_print_skip_signatures(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}

        # Convert all names to string
        names = args.flatten.collect{|n| n.to_s}

        class_eval do
          prepend_before_filter(options) do |controller|
            fine_print_skipped_contract_names.push(*names)
          end
        end
      end
    end
  end
end

ActionController::Base.send :include, FinePrint::ControllerAdditions
