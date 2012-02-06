# -*- encoding : utf-8 -*-

class UsersController < ApplicationController

  load_and_authorize_resource :except => [:hide_notification, :show_notification, :notifications]
  respond_to :html, :js

  def index
    @user_count = User.count
    params[:order] ||= "created_at"
    params[:direction] ||= "asc"
    @users = User.order_by([params[:order].to_sym,params[:direction].to_sym]).reject {|u|
      !can? :read, u
    }.paginate( :page => params[:page],
                :per_page => ENV['CONSTANTS_paginate_users_per_page']
			  )

    respond_to do |format|
       format.js 
       format.html 
    end
  end

  def show
    @google_maps = true
  end

  def edit_role
    if is_current_user?(@user)
      redirect_to registrations_path, :alert => t(:you_can_not_change_your_own_role)
    end
  end

  def update_role
    @user.update_attributes!(params[:user])
    redirect_to registrations_path, :notice => t(:role_of_user_updated,:user => @user.name)
  end

  def crop_avatar
    if !@user.new_avatar?
      redirect_to @user, :notice => flash[:notice]
    elsif is_in_crop_mode?
      if @user.update_attributes(params[:user])
        if params[:user][:crop_x].present?
          @user.avatar.reprocess!
        end
        render :show
      else
        redirect_to edit_user_path(@user), :error => @user.errors.map(&:to_s).join("<br />")
      end
    end
  end

  def destroy
    @user.delete
    redirect_to registrations_path,
      :notice => t(:user_deleted)
  end

  # GET /hide_notification/:created_at_as_id
  def show_notification
    if user_signed_in?
      ts = Time.at(params[:id].to_i)
      notification = current_user.user_notifications.where(:created_at => ts).first
      unless notification.nil?
        notification.hidden = false
        current_user.save!
        notice = t(:notification_successfully_shown)
        error = nil
      else
        notice = nil
        error = t(:notification_cannot_be_shown)
      end
      redirect_to :back, :notice => notice, :alert => error
    end
  end

  # GET /hide_notification/:created_at_as_id
  def hide_notification
    if user_signed_in?
      ts = Time.at(params[:id].to_i)
      notification = current_user.user_notifications.where(:created_at => ts).first
      unless notification.nil?
        notification.hidden = true
        current_user.save!
        notice = t(:notification_successfully_hidden)
        error = nil
      else
        notice = nil
        error = t(:notification_cannot_be_hidden)
      end
      redirect_to :back, :notice => notice, :alert => error
    end
  end

  def notifications
    @notifications = current_user.user_notifications.unscoped.desc(:created_at)
  end

  def details
    respond_to do |format|
       format.js
       format.html
    end
  end

  def autocomplete_ids
    redirect_to root_path, alert: t(:access_denied) unless current_user
    respond_to do |format|
       format.json { 
         render :json => User.any_of({ name: /#{params[:q]}/i }, { email: /#{params[:q]}/i })
                             .only(:id,:name,:email)
                             .map{ |user| 
                               [
                                 :id   => user.id.to_s, 
                                 :name => user.name + " (#{user.email})"
                               ]
                              }
                             .flatten
       }
     end
  end
  
  def my_group_ids
    redirect_to root_path, alert: t(:access_denied) unless current_user
    respond_to do |format|
       format.json { 
         render :json => current_user.user_groups
                             .map{ |group| 
                               [
                                 :id   => group.id.to_s, 
                                 :name => group.name
                               ]
                              }
                             .flatten
       }
     end
  end

private
  def is_in_crop_mode?
    params[:user] &&
    params[:user][:crop_x] && params[:user][:crop_y] &&
    params[:user][:crop_w] && params[:user][:crop_h]
  end
end
