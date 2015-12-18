#  vim: set autoindent et fileencoding=utf-8 filetype=ruby sts=2 sw=2 ts=4 : 

require 'bundler/setup'
require 'rack/contrib'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'i18n'
require 'i18n/backend/fallbacks'
require 'twilio-ruby'
require 'soracom'
require 'redcarpet'

use Rack::Locale
use Rack::TwilioWebhookAuthentication, ENV['TWILIO_TOKEN'], /\/twilio/ if ENV['TWILIO_TOKEN'] =~ /\S/ 

configure do
  I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
  I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
  I18n.backend.load_translations
  I18n.default_locale = :ja

  set :views, settings.root
end

before '/twilio*' do
  lang = (request.env['rack.locale'] == "ja") ? "ja-JP" : request.env['rack.locale']
  @say_config = { voice: "alice", language: lang }
  if ENV['SORACOM_EMAIL'] !~ /\S/ || ENV['SORACOM_PASSWORD'] !~ /\S/
    response = Twilio::TwiML::Response.new do |r|
      r.Say I18n.t('twilio.not_configured'), @say_config
      r.Hangup
    end.text
    halt response
  end
end

get '/' do
  markdown :README
end

get '/twilio' do
  Twilio::TwiML::Response.new do |r|
    r.Gather timeout: 60, action: "/twilio_dispatch", method: "POST", numDigits: 1 do |g|
      g.Say I18n.t('twilio.guidance'), @say_config
    end
  end.text
end

post '/twilio_dispatch' do
  case params[:Digits]
  when "1"
    redirect '/twilio_activate'
  when "2"
    redirect '/twilio_deactivate'
  else
    Twilio::TwiML::Response.new do |r|
      r.Say I18n.t('twilio.argument_error'), @say_config
      r.Redirect "/twilio", method: "GET"
    end.text
  end
end

['activate', 'deactivate'].each do |api|
  path = "/twilio_#{api}"
  get path do
    Twilio::TwiML::Response.new do |r|
      r.Gather timeout: 60, action: path, method: "POST", numDigits: 15 do |g|
        g.Say I18n.t('twilio.input_imsi'), @say_config
      end
    end.text
  end

  post path do
    begin
      c = Soracom::Client.new
      c.send "#{api}_subscriber", params[:Digits]
      Twilio::TwiML::Response.new do |r|
        r.Say I18n.t('twilio.process_completed'), @say_config
        r.Redirect "/twilio", method: "GET"
      end.text
    rescue
      Twilio::TwiML::Response.new do |r|
        r.Say I18n.t('twilio.process_failed'), @say_config
        r.Redirect "/twilio", method: "GET"
      end.text
    end
  end
end
