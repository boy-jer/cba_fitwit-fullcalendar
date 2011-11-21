require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe FitWitWorkoutsController do

  # This should return the minimal set of attributes required to create a valid
  # FitWitWorkout. As you add validations to FitWitWorkout, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {}
  end

  describe "GET index" do
    it "assigns all fit_wit_workouts as @fit_wit_workouts" do
      fit_wit_workout = FitWitWorkout.create! valid_attributes
      get :index
      assigns(:fit_wit_workouts).should eq([fit_wit_workout])
    end
  end

  describe "GET show" do
    it "assigns the requested fit_wit_workout as @fit_wit_workout" do
      fit_wit_workout = FitWitWorkout.create! valid_attributes
      get :show, :id => fit_wit_workout.id.to_s
      assigns(:fit_wit_workout).should eq(fit_wit_workout)
    end
  end

  describe "GET new" do
    it "assigns a new fit_wit_workout as @fit_wit_workout" do
      get :new
      assigns(:fit_wit_workout).should be_a_new(FitWitWorkout)
    end
  end

  describe "GET edit" do
    it "assigns the requested fit_wit_workout as @fit_wit_workout" do
      fit_wit_workout = FitWitWorkout.create! valid_attributes
      get :edit, :id => fit_wit_workout.id.to_s
      assigns(:fit_wit_workout).should eq(fit_wit_workout)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new FitWitWorkout" do
        expect {
          post :create, :fit_wit_workout => valid_attributes
        }.to change(FitWitWorkout, :count).by(1)
      end

      it "assigns a newly created fit_wit_workout as @fit_wit_workout" do
        post :create, :fit_wit_workout => valid_attributes
        assigns(:fit_wit_workout).should be_a(FitWitWorkout)
        assigns(:fit_wit_workout).should be_persisted
      end

      it "redirects to the created fit_wit_workout" do
        post :create, :fit_wit_workout => valid_attributes
        response.should redirect_to(FitWitWorkout.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved fit_wit_workout as @fit_wit_workout" do
        # Trigger the behavior that occurs when invalid params are submitted
        FitWitWorkout.any_instance.stub(:save).and_return(false)
        post :create, :fit_wit_workout => {}
        assigns(:fit_wit_workout).should be_a_new(FitWitWorkout)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        FitWitWorkout.any_instance.stub(:save).and_return(false)
        post :create, :fit_wit_workout => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested fit_wit_workout" do
        fit_wit_workout = FitWitWorkout.create! valid_attributes
        # Assuming there are no other fit_wit_workouts in the database, this
        # specifies that the FitWitWorkout created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        FitWitWorkout.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => fit_wit_workout.id, :fit_wit_workout => {'these' => 'params'}
      end

      it "assigns the requested fit_wit_workout as @fit_wit_workout" do
        fit_wit_workout = FitWitWorkout.create! valid_attributes
        put :update, :id => fit_wit_workout.id, :fit_wit_workout => valid_attributes
        assigns(:fit_wit_workout).should eq(fit_wit_workout)
      end

      it "redirects to the fit_wit_workout" do
        fit_wit_workout = FitWitWorkout.create! valid_attributes
        put :update, :id => fit_wit_workout.id, :fit_wit_workout => valid_attributes
        response.should redirect_to(fit_wit_workout)
      end
    end

    describe "with invalid params" do
      it "assigns the fit_wit_workout as @fit_wit_workout" do
        fit_wit_workout = FitWitWorkout.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        FitWitWorkout.any_instance.stub(:save).and_return(false)
        put :update, :id => fit_wit_workout.id.to_s, :fit_wit_workout => {}
        assigns(:fit_wit_workout).should eq(fit_wit_workout)
      end

      it "re-renders the 'edit' template" do
        fit_wit_workout = FitWitWorkout.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        FitWitWorkout.any_instance.stub(:save).and_return(false)
        put :update, :id => fit_wit_workout.id.to_s, :fit_wit_workout => {}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested fit_wit_workout" do
      fit_wit_workout = FitWitWorkout.create! valid_attributes
      expect {
        delete :destroy, :id => fit_wit_workout.id.to_s
      }.to change(FitWitWorkout, :count).by(-1)
    end

    it "redirects to the fit_wit_workouts list" do
      fit_wit_workout = FitWitWorkout.create! valid_attributes
      delete :destroy, :id => fit_wit_workout.id.to_s
      response.should redirect_to(fit_wit_workouts_url)
    end
  end

end