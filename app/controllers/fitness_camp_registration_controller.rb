require 'pp'

class FitnessCampRegistrationController < ApplicationController
  # must change !!
  ssl_required  :consent, :save_order, :payment, :pay,
     :release_and_waiver_of_liability, :terms_of_participation

  before_filter :find_cart, :except => :empty_cart
  before_filter :ensure_items_in_cart, :only => [:view_cart, :consent, :payment]
  skip_before_filter :check_authentication, :check_authorization,
    :only => [:index, :add_to_cart, :empty_cart, :view_cart, :all_fitness_camps]

  def index
    @fit_wit_form = true
    @location_id = params[:id].to_i
    @location = Location.find(@location_id)
    @pagetitle = "Registrations for #{@location.name}"
    @fitnesscamps = FitnessCamp.find(:all,
      :conditions => ['location_id = ? and session_end_date >= ? and fitness_camps.session_active = true',
      @location_id, Date.today.to_s(:db)])
    @locations = Location.find(:all, :conditions => ['id <> ?',@location_id])
    @include_javascript = true
  end

  def add_to_cart
    begin
      timeslot = TimeSlot.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to access invalid product #{params[:id]}")
      redirect_to_index("Invalid Product")
    else
      @current_item = @cart.add_timeslot(timeslot)
      # now remove
      #redirect_to_index unless request.xhr?
      respond_to do |format|
        format.html { redirect_to :action => "all_fitness_camps" }
        format.js
      end
    end
  end

  def no_need_to_register
    @pagetitle = "You are a member, there is no need to register"
  end

  def release_and_waiver_of_liability
    @pagetitle = "Release and Waiver of Liability"
    @fit_wit_form = true
    user = User.find(session[:user_id])
    int_gender = user.gender
    unless session[:must_check] == true # this just ensures that we
      # are not rejected by the next page
      if not_assigned?(int_gender, params[:health_approval]) # then they
        # need to check some boxes
        #flash[:from_save_order] = "true" # TODO is this still needed
        flash[:notice] = 'You must answer all consent questions to proceed'
        flash[:checked_values] = params[:health_approval]
        redirect_to :action => 'consent'
      else # they need to make sure they have fully entered the data
        if button_hash = user_has_issues?(params[:health_approval]) # !issue_array.map{|title,value,content| value}.all? # only let 'em by if all required fields are non-empty
          flash[:notice] = "Please provide clarification for the questions marked below."
          flash[:checked_values] = params[:health_approval]
          flash[:button_hash] = button_hash
          redirect_to :action => 'consent'
        else # we can go forward, save the user information in the session
          session[:health_approval] = params[:health_approval]
        end # issue check
      end # big if
    end # check referral
  end

  def terms_of_participation
    @pagetitle = "Terms of Participation"
    @fit_wit_form = true
    unless session[:must_check_yes_on_terms] == true
      if params[:commit] == "Continue to Terms of Participation" # they submitted the consent form
        unless params[:agree_to_terms] == "yes" # then we add a membership
          session[:must_check] = true
          flash[:notice] = "Before proceeding, you must agree to the FitWit
                          Release and Waiver of Liability
                          by clicking on the form below."
          redirect_to :action => :release_and_waiver_of_liability
        else
          session[:must_check] = nil
        end
      end # commit check
    end # check to see if we need another chance
  end

  def process_fit_wit_history
    @user = User.find(session[:user_id])
    if @user.update_attributes(params[:user])
      flash[:notice] = 'FitWit History Updated.'
      redirect_to :action => :view_cart
    else
      flash[:notice] = 'error'
      raise RuntimeError, "fit_wit_history update error"
      redirect_to :action => :view_cart
    end
  end

  def view_cart
    # this page shows the @cart contents to the user
    # the next page is the consent page
    # just check to see if the user is logged in
    unless @user = User.find_by_id(session[:user_id])
      flash[:notice] = "You must log in to complete the registration process." +
        " If you do not have an account. Please sign-up before proceeding."
      session[:return_to] = request.request_uri
      redirect_to(:controller => 'login', :action => 'login')
    else # they are logged in
      if @user.has_active_subscription # they need to be blocked from registration
        redirect_to(:action => 'no_need_to_register')
      end
      # now we check to see if they are adding a subscription
      if params[:commit] == "Return to cart" # they submitted the consent form
        if params[:agree_to_terms] == "yes" # then we add a membership
          @cart.new_membership = true
        else # they didn't agree to the          # terms as needed
          flash[:notice] = "You must agree to the terms of this membership
                            by clicking on the consent form below before proceeding."
          redirect_to :action => :membership_info
        end
      end
      @fit_wit_form = true
      @include_jquery = true
      @existing_time_slots = @user.time_slots
      @pagetitle = 'View FitWit Cart'
      @vet_status = @user.veteran_status
      delete_existing_camps_from_cart(@cart)
      @cart_view =  true
      # 0 \equiv normal
      # 1 \equiv vet
      # 2 \equiv supervet
    end
  end

  def add_discounts
    # this function processes the data from our form
    if request.post?
      if params[:addfriend]
        if params[:friends_name].empty?
          flash[:notice] = "You must provide a name for your friend"
        else
          # keys gets the hash values, we want the first as an integer
          item_count = params[:addfriend].keys.first.to_i
          # we need to save all existing forms
          @cart.items[item_count].bring_a_friend(params[:friends_name])
        end
        redirect_to :action => :view_cart
      elsif params[:delfriend]
        friend_info = params[:delfriend].keys.first.split('_').collect {|n| n.to_i}
        # we need to save all existing forms
        @cart.items[friend_info[0]].delete_a_friend(friend_info[1])
        redirect_to :action => :view_cart
      elsif !params[:coupon_code].blank?
        code = CouponCode.find_by_code(params[:coupon_code])
        msg = "Sorry, that coupon code was not found."
        if code
          if !code.live?
            msg = "Sorry, that code is no longer active"
            msg = "Sorry, that code has expired" if code.expired?
            msg = "Sorry, that code has been used the maximum number of times" if code.used_up?
          else
            # Live coupon code
            msg = "Coupon code applied!"
            @cart.coupon_code = code
          end
        end
        
        flash[:notice] = msg
        redirect_to :action => :view_cart
      elsif params[:pay_by_session]
        item_count = params[:pay_by_session].keys.first.to_i
        # um, what is going on here?
        @cart.items[item_count].pay_by_session = !@cart.items[item_count].pay_by_session
        redirect_to :action => :view_cart
      elsif params[:define_pay_by_sessions]
        session_detail = params[:define_pay_by_sessions].keys.first.split('_').collect{|n| n.to_i}
        @cart.items[session_detail[0]].number_of_sessions = session_detail[1]
        redirect_to :action => :view_cart
      else # let's move on to the next step
        if @cart.items.collect{|i| \
              [i.pay_by_session, i.number_of_sessions]}.any? {|u, v| u && v == 0}
          flash[:notice] = "You need to select a session number"
          redirect_to :action => :view_cart
        else
          @cart.items.each_with_index do |ci, i| # go through each item in cart
            price = params["item#{i}"][:price].to_f
            # price = fitness_camp_price(previous_camp_count = 0, friend_count = 0, pay_by_session = nil)
            ci.price = price
          end # cart item iteration
          redirect_to :action => :consent
        end # total price check
      end # params check
    end # post check
  end

  # def

  def membership_info
    @pagetitle = "Membership Information"
    @fit_wit_form = true
  end

  def consent
    # the purpose of the consent view is to let the user view their
    # health history then they can go on to the payment view
    # testing
    # if form element agree_to_terms is not 'yes' then we must
    # redirect back to membership_info
    @fit_wit_form = true
    @include_jquery = true
    @pagetitle = "Consent"
    @user = User.find(session[:user_id])
    # which path do we want to go down, membership or payment
    @checked_values = flash[:checked_values] || []
    @button_hash = flash[:button_hash] || {}
    session[:referrer] = {:controller => :registration, :action => "consent"}
    @membership = @cart.new_membership # this need to be here ??
    # for health consent form
    @names_of_titles_that_require_more_information = flash[:names_of_titles_that_require_more_information] || []
  end

  def health_history
    # just a process node at this point
    @user = User.find(session[:user_id])
    # @back_page = request.env["HTTP_REFERER"]
    unless request.put?
      # needed still? maybe a raise here
    else
      # zero out all unchecked explanations
      user_params = zero_out_all_unchecked_explanations(params[:user])
      if @user.update_attributes(user_params)
        if names_of_titles_that_require_more_information = \
            user_has_not_explained_themself(params[:user]) #names_of_titles_that_require_more_information.empty?
          flash[:notice] = <<-END_OF_STRING
          You need to provide clarification for all
          health history items
          END_OF_STRING
          flash[:names_of_titles_that_require_more_information] = \
            names_of_titles_that_require_more_information
          redirect_to '/registration/consent'
        else
          flash[:notice] = 'Health History Updated.'
          # TODO NEED TO GET THIS WORKING FROM REGISTRATION
          my_referrer = !session[:referrer].nil? ? \
            session[:referrer] : {:controller => 'my_fit_wit', :action => 'index'}
          redirect_to '/registration/consent'
#          redirect_to(my_referrer)
        end # check for adequate information entered
      else # error
        flash[:notice] = 'FitWit history update error'
        redirect_to '/registration/consent'
        #raise RuntimeError, "fit_wit_history update error"
      end #user attribute update check
    end # form submission check
  end


  def payment
    # here the user enters credit card information
    # after data are entered, the user calls the method 'pay'
    @fit_wit_form = true
    @pagetitle = "Complete Payment"
    @health_approval = session[:health_approval]
    @health_approval.delete_if {|key, value| key =~ /_explanation$/ && value == "Please explain"}
    @order_amount = @cart.total_price
    @myuser = User.find(session[:user_id])
    @cc_errors = flash[:cc_errors] if flash[:cc_errors]
    @membership = @cart.new_membership
  end

  def pay
    # this method gets the whole registration process going
    # this method is currently way too long and desperately needs refactoring
    @order = Order.find(params[:id])
    @credit_card = ActiveMerchant::Billing::CreditCard.new(params[:credit_card])
    is_membership = @cart.new_membership
    if @credit_card.valid? #=> auto-detects the card type
      @user = User.find(session[:user_id])
      options = build_options(@user, params[:billing_address][:us_state],
        params[:billing_address][:zip],
        params[:billing_address][:city],
        params[:billing_address][:address1],
        params[:billing_address][:address2])
      if is_membership
        subscription = @order.create_subscription(@credit_card, options)
        is_success = subscription.success?
      else
        purchase = @order.authorize_payment(@credit_card, options)
        is_success = purchase.success?
      end
      if is_success
        send_emails(is_membership,@user,@order,@cart)
        update_user_information(@user, params)
        # time to register the user for the class
        @order.register_timeslots_from_cart(@cart)
        session[:cart] = nil
        session[:health_approval] = nil
        unless is_membership
          capture = @order.capture_payment
          if capture.success?
            flash[:membership] = "false"
            redirect_to :action => :registration_success, :id => @order.id
          else
            flash[:notice] = 'capture failed'
            redirect_to :action => :payment, :id => @order.id # not :back
          end
        else
          # we need to let the world know that a user has a membership
          @user.has_active_subscription = true
          @user.save
          flash[:membership] = "true"
          redirect_to :action => :registration_success, :id => @order.id
        end # membership check
      else
        #if purchase.params['missingField'].nil?
        flash[:notice] = "!! " + purchase.message + "<br />"  +
          purchase.params['missingField'].to_s
        #flash[:notice] = ": " + purchase.errors.full_messages.join(', ')
        redirect_to :action => :payment, :id => @order.id
      end
    else
      flash[:cc_errors] = @credit_card.errors.full_messages   #build_cc_errors(@credit_card.errors)

      redirect_to :action => :payment, :id => @order.id
    end
  end

  def save_order
    #@include_javascript = true
    usr_id = session[:user_id]
    # clear the referrer
    session[:referrer] = nil # remove
    if params[:commit] == "Proceed to Payment" # they submitted the consent form
      unless params[:agree_to_terms] == "yes" # then we add a membership
        session[:must_check_yes_on_terms] = true
        flash[:notice] = "Before proceeding, you must agree to the
                          FitWit Terms of Participation
                          by clicking on the form below."
        redirect_to :action => :terms_of_participation
      else
        session[:must_check_yes_on_terms] = nil
        #amount = @cart.total_price*100 # convert to cents
        @membership = @cart.new_membership
        #logger.info(build_desc(params[:health_approval]))
        if @membership
          # we will use desc to get their participation in the total
          @order = Order.new(:user_id => usr_id,
            :amount => 50*100,
            :description => build_desc(session[:health_approval]))
        else
          @order = Order.new(:user_id => usr_id,
            :amount => @cart.total_price*100,
            :coupon_code => @cart.coupon_code,
            :description => build_desc(session[:health_approval]))
        end # membership check
        #session[:health_approval] = params[:health_approval]
        if @order.save!
          redirect_to :action => :payment, :id => @order.id
        else # something went wrong
          flash[:notice] = "error saving order"
          redirect_to_index(@order.errors,1)
        end # save error check
      end # agree to term check
    end # commit check
  end # def

  def empty_cart
    #@include_javascript = true
    @location_id = params[:id]
    session[:cart] = nil
    #redirect_to_index(nil,params[:id])
    flash[:notice] = "Your cart is now empty. You may start again by adding any of the camps below."
    unless @location_id
      redirect_to :action => "all_fitness_camps"
    else
      redirect_to :action => "index", :id => @location_id
    end
  end

  def registration_success
    @pagetitle = 'Successful Registration'
    # need successful registrations
    @registrations = Order.find(params[:id]).registrations
    @user = User.find(session[:user_id])
    (flash[:membership] == "true") ? @membership = true : @membership = nil
  end

  def all_fitness_camps
    @pagetitle = 'Register for a Fitness Camp'
    @include_jquery = true
    @fit_wit_form = true
    @mystates = Location.find_all_states
    # TODO: change to active fitness camps and camps with time_slots
    @fitness_camps = FitnessCamp.find(:all,
                                   :joins => 'INNER JOIN time_slots ON time_slots.fitness_camp_id = fitness_camps.id',
                                   :select => 'fitness_camps.*, count(time_slots.id) time_slots_count',
                                   :conditions => ['fitness_camps.session_active = true AND fitness_camps.session_end_date >= ?',  Date.today.to_s(:db)],
                                   :group => 'time_slots.fitness_camp_id HAVING time_slots_count > 0',
                                   :order => 'session_start_date ASC')
    #      :conditions => 'fitness_camps.session_active = true',
  end

  private

  def zero_out_all_unchecked_explanations(user_params)
    condition_params = user_params.reject {|key, value| \
        key =~ /_explanation$/ || \
        value == "true" || \
        key == "fitness_level" }
    condition_params.each do |key, value|  # for each false condition set the params equal to ""
      explanation_name = "#{key}_explanation".to_sym
      user_params[explanation_name] = "" if user_params[explanation_name]
    end
    return user_params
  end

  def user_has_not_explained_themself(user_params)
    #condition_params = params.keys.map{|k| k.to_s}.grep(/[^(_explanation)]$/)
    condition_params = user_params.reject {|key, value| key =~ /_explanation$/ || \
        value == "false" || key == 'fitness_level'}
    names_of_titles_that_require_more_information = [] # initialize

    condition_params.each do |key, value|
      field_content = user_params["#{key}_explanation".to_sym]
      if field_content =~ /^\s*$/ || field_content == "Please enter an explanation"
        names_of_titles_that_require_more_information << key
      end
    end

    if names_of_titles_that_require_more_information.empty?
      return nil
    else
      return names_of_titles_that_require_more_information
    end

  end

  def build_desc(health_approval_hash)
    # this builds the description for the user's order
    out = ""
    health_approval_hash.each do |method, value|
      if method =~ /_explanation$/
        out += "#{method.humanize} is \"#{value}\"\n"
      end
    end
    unless out.empty?
      return out
    else
      return "No participation issues noted"
    end
  end

  def user_has_issues?(health_hash)
    # assume no issue
    # 1 => matters for both (gender 1 or 2)
    # 2 => matters just for women (gender = 2)
#     issues = [['participation_approved','No',0],
#               ['taking_medications','Yes',0],
#               ['post_menopausal_female','N/A',1],
#               ['taking_estrogen','N/A',1]]
    field_info = {:participation_approved => 'No',
                  :taking_medications => 'Yes'}
    button_hash = {}
    more_info_needed = false
    field_info.each do |title, yes_value|
      button_hash.merge!(title => {})
      if (health_hash[title] == yes_value)
        explanation_content = health_hash["#{title}_explanation"] || "Please explain"
        unless explanation_content.empty? ||
            explanation_content =~ /^\s*$/ ||
            explanation_content == "Please explain"
           button_hash[title].merge!(:explanation_sufficient => true)
        else
          more_info_needed = true
        end
        button_hash[title].merge!(:tag_content => explanation_content)
      end
    end # each
    # if button_hash[title] is not empty, then put button hash
    # forward, otherwise return nil (false)
    return more_info_needed && button_hash
  end

  def send_emails(is_membership, user, order,cart)
    unless is_membership
      inform_management = Postman.create_new_order(user,
        order,
        params[:credit_card],
        session[:health_approval],
        cart)
      inform_customer = Postman.create_inform_customer(user,
        order,
        params[:credit_card],
        session[:health_approval],
        cart)
    else
      inform_management = Postman.create_inform_ben_membership(user,
        order,
        params[:credit_card],
        session[:health_approval],
        cart)
      inform_customer = Postman.create_inform_user_membership(user,
        order,
        params[:credit_card],
        session[:health_approval],
        cart)
    end
    Postman.deliver(inform_management)
    Postman.deliver(inform_customer)
  end

  def update_user_information(user, params)
    info_hash = { }
    user.first_name = params[:billing_address][:first_name] unless params[:billing_address][:first_name].blank?
    user.last_name =  params[:billing_address][:last_name] unless params[:billing_address][:last_name].blank?
    user.email_address = params[:billing_address][:email_address] unless params[:billing_address][:email_address].blank?
    user.street_address1 =  params[:billing_address][:street_address1] unless params[:billing_address][:street_address1].blank?
    user.street_address2 =  params[:billing_address][:street_address2] unless params[:billing_address][:street_address2].blank?
    user.city =  params[:billing_address][:city] unless params[:billing_address][:city].blank?
    user.us_state = params[:billing_address][:us_state] unless params[:billing_address][:us_state].blank?
    user.zip = params[:billing_address][:zip] unless params[:billing_address][:zip].blank?
    if user.save! && info_hash.size > 0
      flash[:notice] = "Updated user information"
    end
  end

  def redirect_to_index(msg = nil, my_id = nil)
    flash[:notice] = msg if msg
    if my_id.nil?
      redirect_to :action => :index
    else
      redirect_to :action => :index, :id => my_id
    end
  end

  def find_cart
    @cart = (session[:cart] ||= Cart.new)
  end

  def ensure_items_in_cart
    unless @cart.total_items > 0 || @cart.new_membership
      flash[:notice] = "you need a non-empty cart to view this page"
      redirect_to :action => 'all_fitness_camps'
    end
  end

  def not_assigned?(int_gender, health_hash)
    out = false
    if health_hash.nil?
      out = true
    else
      out = health_hash[:participation_approved].nil? || out
      out = health_hash[:taking_medications].nil? || out
      if int_gender == 2
        out = health_hash[:post_menopausal_female].nil? || out
        out = health_hash[:taking_estrogen].nil? || out
      end
    end
    out
  end

  def build_options(u, state = nil, zip = nil, city = nil, address1 = nil, address2 = nil)
    # this is my attempt at populating the options hash for the credit card
    options = {
      :email => u.email,
      :billing_address => {
        :name => u.full_name,
        :address1 => address1 || u.street_address1,
        :address2 => address2 || u.street_address2,
        :city => city || u.city,
        :state => state || u.us_state,
        :country => 'US',
        :zip => zip || u.zip,
        :phone => u.primary_phone}
    }
    return options
  end

  def delete_existing_camps_from_cart(cart)
    # this should be completely deprecated
    deleted = nil  # bool to let us know if we had to delete a class
    del_items = '' # since the user had already registered for it
    # should really make a subroutine for this -- just check to see if
    # there is a class in the cart that the user is already registered for
    # TODO tbb 0812 -- this really needs refactored
    cart.items.each do |ci|
      if @existing_time_slots.include?(ci.timeslot)
        del_items += "#{ci.timeslot.short_title}<br />"
        cart.items.delete(ci)
        deleted = true
      end
    end
    if deleted
      flash[:notice] = "You have previously registered for:<br />#{del_items}" +
        " We have removed any existing registrations from your cart." +
        " Please continue."
      redirect_to :back
    end
  end

end