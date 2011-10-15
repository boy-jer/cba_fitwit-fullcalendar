# Redirect all mails to the developer in development mode and
# show the original recipient in the subject.
class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "DEVELOPMENT MAIL - #{message.to} #{message.subject}"
    message.to = ENV['APPLICATION_CONFIG_admin_notification_address']
  end
end
