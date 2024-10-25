
class SshKeyController < ApplicationController
  def new; end

  def create
    current_user.ssh_public_keys.create!(ssh_key_params)
    flash[:notice] = "SSH key \"#{ssh_key_params[:name]}\" added"
    redirect_to user_index_path
  end

  def destroy
    deleted_key = current_user.ssh_public_keys.find(params[:id]).destroy!
    flash[:notice] = "SSH key \"#{deleted_key.name}\" deleted"
    redirect_to user_index_path
  end

  private

  def ssh_key_params
    params.require(:ssh_public_key).permit(:name, :key)
  end
end
