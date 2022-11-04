require 'responders'

module FinePrint
  class ApplicationController < ::ActionController::Base
    respond_to :html

    FinePrint.config.concerns.each do |concern|
      include concern.to_s.capitalize.constantize
    end


    before_action :get_user, :can_manage

    layout FinePrint.config.layout

    helper FinePrint.config.helpers

    protected

    def get_user
      @user = instance_exec &FinePrint.config.current_user_proc
    end

    def can_manage
      instance_exec @user, &FinePrint.config.authenticate_manager_proc
    end
  end
end
