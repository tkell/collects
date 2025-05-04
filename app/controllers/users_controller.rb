class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      render json: { message: "User created successfully" }, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authenticate_user
    @user = User.find(params[:id])

    if @user.update(user_params)
      render json: { message: "User updated successfully" }, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authenticate_user
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

    render json: { message: "User and all associated data deleted successfully" }, status: :ok
  rescue => e
    render json: { error: "Failed to delete user: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def user_params
    params.permit(:email, :username, :password, :password_confirmation)
  end
end
