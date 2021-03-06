# -*- encoding : utf-8 -*-

# Use this mailer to send notifications eg for newly created pages, sign ups
# and so on.

require 'open-uri'

class Notifications < ActionMailer::Base
  include ActionView::Helpers::SanitizeHelper

  default :from => ENV['APPLICATION_CONFIG_registration_from']

  # When a new user signed up, inform the adminstrator
  def sign_up(new_user)
    @user = new_user
    @notify_subject = strip_tags "NEW SIGN UP AT #{ENV['APPLICATION_CONFIG_name']}"
    mail( :to => ENV['APPLICATION_CONFIG_admin_notification_address'], :subject => @notify_subject)
  end

  def new_user(user)
    @user = user
    mail( to: "info@fitwit.com", from: "info@fitwit.com", subject: "New user #{@user.full_name}" )
  end

  def account_created(user)
    @user = user
    attachments['WhyYourWorkoutIsNotWorking7StepstoFixIt.pdf'] = open("https://s3.amazonaws.com/FitWitSite/pdfs/WhyYourWorkoutIsNotWorking7StepstoFixIt.pdf").read
    mail( to: @user.email, subject: "Thank you for registering at FitWit.com!", from: "info@fitwit.com" )
  end

  # Inform the admin when a user cancel an account.
  def cancel_account(user_info)
    @user_info = user_info
    @notify_subject = strip_tags "USER CANCELED ACCOUNT AT #{ENV['APPLICATION_CONFIG_name']}"
    mail( :to => ENV['APPLICATION_CONFIG_admin_notification_address'], :subject => @notify_subject)
  end

  # Inform the admin if a user confirms an account
  def account_confirmed(user)
    @notify_subject = strip_tags( "USER CONFIRMED ACCOUNT AT #{ENV['APPLICATION_CONFIG_name']}")
    @user = user
    mail( :to => ENV['APPLICATION_CONFIG_admin_notification_address'], :subject => @notify_subject)
  end

  # Inform admin when new postings created
  def new_posting_created(blog_id,posting_id)
    blog      = Blog.find(blog_id)
    posting   = blog.postings.find(posting_id)
    @blogtitle= blog.title
    @title    = posting.title
    @username = posting.user.full_name
    @content  = ContentItem::markdown(posting.body).html_safe
    @url      = blog_posting_url(blog,posting)
    @notify_subject = strip_tags "A NEW POSTING WAS CREATED AT #{ENV['APPLICATION_CONFIG_name']}"

    begin
      # Attach cover picture
      if posting.cover_picture_exists?
        if File.exist?(filename=posting.cover_picture.path)
          attachments[File::basename(filename)] = File.read(filename)
        end
      end

      # TODO: The following code doesn't work. Either there is a bug somewhere
      # TODO: in CBA or in Rails::Mail. Only the cover-pic arrives.
      # TODO: Check if it's possible to attach more files with Rails Mail - it should!
      # TODO: Fix testing attachments at all!
      # Attach attachments
      posting.attachments.each do |att|
        path = att.file.path.gsub(/\?.*$/,"")
        file = File::basename(path)
        if File.exist?(path)
          attachments[file] = File.read(path)
        end
      end
    rescue => e
      msg = "<br/><br/>*** ERROR ATTACHING FILE #{e.to_s} **** #{__FILE__}:#{__LINE__}"
      @content += msg.html_safe
      puts msg
    end

    mail( :to => ENV['APPLICATION_CONFIG_admin_notification_address'], :subject => @notify_subject)
  end

  # Infrom owner of commentable, and admin when a comment was posted
  # arg[0] = recipient,
  # arg[1] = commentable.title,
  # arg[2] = email,
  # arg[3] = name,
  # arg[4] = comment
  def new_comment_created(recipient,title,from_mail,from_name,comment, link_to_commentable)
    @notify_subject = "Your entry '#{title}', was commented by #{from_name}"
    @comment   = comment
    @from_name = from_name
    @from_mail = from_mail
    @link_to_commentable = link_to_commentable
    mail( :from => from_mail,
          :to => [ENV['APPLICATION_CONFIG_admin_notification_address'],recipient].uniq,
          :subjcect => @notify_subject
    )
  end

  # Invite User
  # arg[0] = Invitation-id
  def invite_user(invitation,subject,message)
    @subject = subject
    @sign_up_url = new_user_registration_url(:token => invitation.token)
    @invitation = invitation
    @message = message
    mail( :from => invitation.user.email,
          :to   => invitation.email,
          :subject => subject )
  end

  def send_contact_message(message)
    @message = message
    mail( from: message.email,
          subject: "[FitWit: Contact Form Inquiry]",
          to: "info@fitwit.com")
  end

  def confirmation_to_user(message)
    @message = message
    mail( from: "info@fitwit.com",
          subject: "Thank you for contacting FitWit!",
          to: message.email)
  end

  def inform_management_about_a_new_user(user, cart, order)
    @cart = cart
    @user = user
    @order = order
    time_slot_info = TimeSlot.find(cart.items.first.time_slot_id).short_title
    mail( :from => 'messenger@fitwit.com',
          :to   => 'management@fitwit.com',
          :subject => "New Camper: #{time_slot_info},$#{@order.amount/100}" )
  end

  def inform_customer_about_their_new_journey(user,cart)
    @cart = cart
    @user = user
    ['FitWitFitnessCampManual120301.pdf','FitWitNutritionGuide.pdf','GeneralWaiverandRelease2012.pdf'].each do |a|
     attachments[a] = open("https://s3.amazonaws.com/FitWitSite/pdfs/#{a}").read
    end
    mail( :from => 'messenger@fitwit.com',
          :to   => user.email,
          :subject => "Registration confirmed from FitWit.com" )
  end

end
