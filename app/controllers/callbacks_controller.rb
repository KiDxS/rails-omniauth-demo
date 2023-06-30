class CallbacksController < Devise::OmniauthCallbacksController
  def github
    auth = request.env['omniauth.auth']
    service = Service.where(provider: auth.provider, uid: auth.uid).first
    if service.present?
      user = service.user
      OmniAuthService.refresh!(auth)
    else
      user = User.create(email: auth.info.email, password: Devise.friendly_token[0, 20])
      user.services.create(
        provider: auth.provider, uid: auth.uid, access_token: auth.credentials.token,
        access_token_secret: auth.credentials.secret,
        refresh_token: auth.credentials.refresh_token, expires_at: auth.credentials.expires_at
      )
    end
    sign_in user
    redirect_to '/'
  end
end
