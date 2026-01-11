class BreakersController < ApplicationController
  before_action :set_breaker, only: %i[ show edit update destroy ]

  # GET /breakers or /breakers.json
  def index
    @breakers = Breaker.all
  end

  # GET /breakers/1 or /breakers/1.json
  def show
  end

  # GET /breakers/new
  def new
    @new_breaker = Breaker.new
    @breakers = Breaker.all
    render :index
  end

  # GET /breakers/1/edit
  def edit
    @breakers = Breaker.all
    @new_breaker = @breaker
    render :index
  end

  # POST /breakers or /breakers.json
  def create
    @breaker = Breaker.new(breaker_params)

    respond_to do |format|
      if @breaker.save
        format.html { redirect_to breakers_path, notice: "Breaker was successfully created." }
        format.json { render :show, status: :created, location: @breaker }
      else
        @new_breaker = @breaker
        @breakers = Breaker.all
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @breaker.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /breakers/1 or /breakers/1.json
  def update
    respond_to do |format|
      if @breaker.update(breaker_params)
        format.html { redirect_to breakers_path, notice: "Breaker was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @breaker }
      else
        @new_breaker = @breaker
        @breakers = Breaker.all
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @breaker.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /breakers/1 or /breakers/1.json
  def destroy
    @breaker.destroy!

    respond_to do |format|
      format.html { redirect_to breakers_path, notice: "Breaker was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_breaker
      @breaker = Breaker.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def breaker_params
      params.expect(breaker: [ :residual_current_device_id, :position, :max_current, :description, :name ])
    end
end
