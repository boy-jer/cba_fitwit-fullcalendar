# -*- encoding : utf-8 -*-

module UsersHelper # :nodoc:
  
  def options_for_user_role(current=nil)
    options_for_select( (0..(User::ROLES.count-1)).map {|i| [ User::ROLES[i].to_s.humanize, i] }, current )
  end
  
end
