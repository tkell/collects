class LinkedAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_linked_account, only: %i[show destroy]

  def index
    @linked_accounts = current_user.linked_accounts
    render json: @linked_accounts, only: %i[id provider created_at updated_at],
           methods: [:expired?]
  end

  def show
    if @linked_account
      render json: @linked_account, only: %i[id provider created_at updated_at],
             methods: [:expired?]
    else
      render json: { error: 'Linked account not found' }, status: :not_found
    end
  end

  def destroy
    if @linked_account&.destroy
      render json: { success: true, message: 'Linked account removed successfully' }
    else
      render json: { error: 'Failed to remove linked account' }, status: :unprocessable_entity
    end
  end

  private

  def set_linked_account
    @linked_account = current_user.linked_accounts.find_by(id: params[:id])
  end
end
