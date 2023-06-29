class CallbacksController < Devise::OmniauthCallbacksController
  def github
    auth = request.env['omniauth.auth']
    @user = User.where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
    end
    sign_in @user
    redirect_to "/"
  end
end
