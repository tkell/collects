class UsersController < ApplicationController
  skip_before_action :authenticate_user, only: [:new, :create], if: -> { method_defined?(:authenticate_user) }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      respond_to do |format|
        format.json { render json: { message: "User created successfully" }, status: :created }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    @user = User.find(params[:id])

    if @user.update(user_params)
      respond_to do |format|
        format.json { render json: { message: "User updated successfully" }, status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @user = User.find(params[:id])

    ActiveRecord::Base.transaction do
      @user.playbacks.destroy_all
      @user.annotations.destroy_all

      @user.collections.each do |collection|
        collection.gardens.each do |garden|
          garden.garden_releases.destroy_all
          garden.destroy
        end
        collection.releases.destroy_all
        collection.destroy
      end

      @user.destroy
    end

    respond_to do |format|
      format.json { render json: { message: "User and all associated data deleted successfully" }, status: :ok }
    end
  rescue => e
    respond_to do |format|
      format.json { render json: { error: "Failed to delete user: #{e.message}" }, status: :unprocessable_entity }
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :username, :password, :password_confirmation)
  end
end
