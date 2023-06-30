class OmniAuthService
  attr_reader :provider, :name, :force

  # @param [users-provider-class] provider the users provider record
  def initialize(provider, force: false)
    @provider      = provider
    @name        ||= provider.provider.to_sym
    @force         = force
    @token_options = []
    @refreshed     = false
  end

  delegate :expired?,      to: :provider
  delegate :access_token,  to: :provider
  delegate :refresh_token, to: :provider

  # do not refresh unless expired token
  def refresh
    return unless force || expired?

    refresh_provider_tokens
  end

  def refreshed?
    @refreshed
  end

  class << self
    def refresh!(provider, force: false)
      o = new(provider, force:)
      o.refresh
      o.refreshed?
    end
  end

  private
  def refresh_provider_tokens
    new_token = current_token.refresh!
    return if new_token.blank?

    provider.update(
      access_token:  new_token.token,
      expires_at:    Time.zone.at(new_token.expires_at),
      refresh_token: new_token.refresh_token
    )
    @refreshed = true
  end

  def strategy
    Devise.omniauth_configs[name].strategy_class.new(
      Devise.omniauth_configs[name].strategy.app,
      *Devise.omniauth_configs[name].args
    )
  end

  def current_token
    puts token_options
    OAuth2::AccessToken.new(
      strategy.client,
      access_token,
      **token_options
    )
  end

  def token_options
    options = {}
    options.merge({ refresh_token: }) if refresh_token
  end
end