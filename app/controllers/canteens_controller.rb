class CanteensController < ApplicationController
  before_action :new_resource, only: [:new, :create]
  before_action :load_resource, only: [:show, :update, :edit, :fetch]
  load_and_authorize_resource

  def index
    @canteens = @user.canteens.order(:name)
  end

  def new
    @canteens = Canteen.where state: 'wanted'
  end

  def create
    if @canteen.update canteen_params
      if params[:parser_id]
        flash[:notice] = t 'message.canteen_added'
        redirect_to new_parser_source_path(parser_id: params[:parser_id], canteen_id: @canteen)
      else
        flash[:notice] = t 'message.wanted_canteen_added'
        redirect_to wanted_canteens_path
      end
    else
      @canteens = Canteen.where state: 'wanted'
      render action: :new
    end
  end

  def edit
  end

  def update
    if @canteen.update canteen_params
      flash[:notice] = t 'message.canteen_saved'
      redirect_to user_canteens_path(@user)
    else
      render action: :edit
    end
  end

  def show
    if params[:date]
      @date  = Date.parse params[:date].to_s
    else
      @date  = Time.zone.now.to_date
    end

    @meals = @canteen.meals.for @date
  end

  def wanted
    @canteens = Canteen.where state: 'wanted'
  end

  def fetch
    if current_user.cannot?(:manage, @canteen) && \
       @canteen.last_fetched_at && \
       @canteen.last_fetched_at > Time.zone.now - 15.minutes
      return error_too_many_requests
    end
    updater = OpenMensa::Updater.new(@canteen)
    @result = {
      'status' => updater.update ? 'ok' : 'error'
    }
    json = @result.dup.update updater.stats
    @result.update updater.stats(false) if current_user.can? :manage, @canteen
    respond_to do |format|
      format.html
      format.json { render json: json }
    end
  end

  private

  def load_resource
    @canteen = Canteen.find params[:id]
  end

  def new_resource
    @canteen = Canteen.new
  end

  def canteen_params
    params.require(:canteen).permit(:address, :name, :latitude, :longitude, :city)
  end
end
