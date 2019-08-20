# frozen_string_literal: true

class TrialRegistrationsController < RegistrationsController

  private

  def sign_up_params
    params.require(:user).permit(:username, :email, :email_confirmation, :name, :password, :skip_confirmation)
  end
end
